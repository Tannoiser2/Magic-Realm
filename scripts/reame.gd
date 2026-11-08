## Motore di Magic Realm (Super Realm, scenari introduttivi 1-3): stato della partita, preparazione,
## giornata (alba, sorgere del sole, giorno, tramonto, sera, mezzanotte), attività, mostri e missioni.
## Il combattimento serale sta in combattimento.gd, le decisioni dei rivali in ia.gd.
## Le decisioni del giocatore umano arrivano con il segnale «risposta»: il motore si ferma con await.
class_name Reame
extends RefCounted

signal chiede(richiesta)        # il motore aspetta una decisione dell'umano
signal risposta(dati)           # la UI risponde
signal cambiato                 # lo stato è cambiato: ridisegnare
signal messaggio(testo, tipo)   # riga di registro

var s: Dictionary = {}
var mappa: Mappa
var rng := RandomNumberGenerator.new()
var ia: IA
var combat: Combattimento
var arcano: Arcano
var richiesta: Dictionary = {}
var auto_umano := false          # nelle prove automatiche anche l'umano gioca da solo
var pausa_cb: Callable           # per rallentare le mosse dei rivali nella UI
var log_righe: Array = []
var in_corso := false

const RISULTATI := {"scelta": "Scelta", "indizi": "Indizi", "segreti": "Passaggi segreti", "sentieri": "Sentieri nascosti",
	"nemici": "Nemici nascosti", "scopri": "Scopri segnalini", "scopri_indizi": "Scopri indizi", "niente": "Niente"}
const TABELLE := {
	"cerca": ["scelta", "indizi", "segreti", "sentieri", "nemici", "niente"],
	"scruta": ["scopri", "indizi", "nemici", "nemici", "indizi", "niente"],
	"localizza": ["scelta", "scelta", "sentieri", "scopri_indizi", "scopri_indizi", "niente"]}
const NOMI_TABELLE := {"cerca": "Cerca", "scruta": "Scruta", "localizza": "Localizza"}
const ATTIVITA := {"M": "Movimento", "S": "Ricerca", "H": "Nascondersi", "A": "Allerta", "R": "Riposo", "E": "Incanto", "V": "Volo"}
const BOSCHI := ["Lost Woods", "Old Woods", "Dark Woods", "Deep Woods", "Lake Woods", "Nut Woods", "Maple Woods", "Pine Woods", "Linden Woods", "Oak Woods"]
const MALEDIZIONI := ["Nebbia agli occhi", "Squittio", "Avvizzimento", "Malattia", "Ceneri", "Disgusto"]
const IPNOSI := ["Indebolito", "Ebbro", "Placato", "Distratto", "Svuotato", "Stanco"]
const ABISSO := ["Si apre l'abisso di fuoco", "Portato via", "Terrore", "Piaga", "Oblio", "Ruggine"]

func _init() -> void:
	Dati.carica()
	ia = IA.new(self)
	combat = Combattimento.new(self)
	arcano = Arcano.new(self)

# ------------------------------------------------------------ utilità
func scrivi(t: String, tipo := "") -> void:
	while t.find("{oa}") >= 0:
		var i := t.find("{oa}")
		var best := -1
		var g := "m"
		for p in s.get("pg", []):
			var j := t.substr(0, i).rfind(p["nome"])
			if j > best:
				best = j
				g = Dati.personaggi[p["pg"]].get("genere", "m")
		t = t.substr(0, i) + ("a" if g == "f" else "o") + t.substr(i + 4)
	log_righe.append([t, tipo, s.get("giorno", 0)])
	if log_righe.size() > 400:
		log_righe = log_righe.slice(log_righe.size() - 400)
	messaggio.emit(t, tipo)

func d6() -> int:
	return rng.randi_range(1, 6)

func mescola(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp

func pausa(t: float):
	if pausa_cb.is_valid():
		return await pausa_cb.call(t)
	return null

func P(pid: String) -> Dictionary:
	for p in s["pg"]:
		if p["pid"] == pid:
			return p
	return {}

func M(mid: String) -> Dictionary:
	return s["mostri"].get(mid, {})

func umano() -> Dictionary:
	for p in s["pg"]:
		if p["umano"]:
			return p
	return {}

func vivi() -> Array:
	return s["pg"].filter(func(p): return not p["morto"])

func def_pg(p: Dictionary) -> Dictionary:
	return Dati.personaggi[p["pg"]]

func ha_abilita(p: Dictionary, a: String) -> bool:
	for x in def_pg(p)["abilita"]:
		if x["id"] == a:
			return true
	return false

func tessera(k: String) -> int:
	return Mappa.tessera_di(k)

func tipo_radura(k: String) -> String:
	return mappa.radure[k]["tipo"] if mappa.radure.has(k) else "W"

func cat_tessera(t: int) -> String:
	return Dati.tessere[t]["cat"]

func nome_r(k: String) -> String:
	return mappa.nome_radura(k)

func abitazione_in(k: String) -> String:
	for a in s["abitazioni"]:
		if s["abitazioni"][a] == k:
			return a
	return ""

## tiro standard: due dadi, si prende il più alto; con un'abilità se ne tira uno solo
func tiro(p: Dictionary, contesto: String) -> Array:
	var un_dado := false
	var k: String = p["dove"]
	var tr := tipo_radura(k)
	match contesto:
		"nascondi":
			un_dado = ha_abilita(p, "occultamento") or (ha_abilita(p, "grotte") and tr == "C") \
				or (ha_abilita(p, "uomo_frontiera") and tr == "M") or (ha_abilita(p, "inseguitrice") and Dati.tessere[tessera(k)]["nome_en"] in BOSCHI)
		"cerca":
			un_dado = (ha_abilita(p, "grotte") and tr == "C") or (ha_abilita(p, "uomo_frontiera") and tr == "M") \
				or (ha_abilita(p, "inseguitrice") and Dati.tessere[tessera(k)]["nome_en"] in BOSCHI)
	var mod := 0
	if s.get("scenario", 1) >= 4:
		un_dado = un_dado or arcano.un_dado(p, contesto)
		mod = arcano.modifica_tiro(p, contesto)
	if un_dado:
		var a := d6()
		return [clampi(a + mod, 1, 6), [a]]
	var a := d6()
	var b := d6()
	return [clampi(max(a, b) + mod, 1, 6), [a, b]]

# ------------------------------------------------------------ oggetti e segnalini d'azione
func peso_oggetto(o: Dictionary) -> int:
	if Dati.tesori.has(o["id"]):
		return Dati.peso_i(str(Dati.tesori[o["id"]]["peso"]))
	var d: Dictionary = Dati.oggetti["armi"].get(o["id"], Dati.oggetti["armature"].get(o["id"], {}))
	return Dati.peso_i(d.get("peso", "-"))

func arma_attiva(p: Dictionary) -> Dictionary:
	for o in p["oggetti"]:
		if o["attivo"] and Dati.oggetti["armi"].has(o["id"]):
			return o
	return {}

func carico_max(p: Dictionary) -> int:
	var m := 0
	for o in p["oggetti"]:
		m = max(m, peso_oggetto(o))
	return m

func forza_chit(c: Dictionary) -> int:
	return Dati.peso_i(c.get("forza", "-"))

func vel_chit(p: Dictionary, c: Dictionary) -> int:
	var v: int = c["vel"]
	if c["tipo"] == "M" and "Indebolito" in p["maledizioni"]:
		v += 1
	if c["tipo"] == "F" and "Placato" in p["maledizioni"]:
		v += 1
	return v

func movimento_max(p: Dictionary) -> int:
	var m := -1
	for c in p["chits"]:
		if c["tipo"] == "M" and c["stato"] == "a":
			m = max(m, forza_chit(c))
	return m

func chit_attivi(p: Dictionary) -> Array:
	var r := []
	for i in range(p["chits"].size()):
		if p["chits"][i]["stato"] == "a":
			r.append(i)
	return r

func vulnerabilita(p: Dictionary) -> int:
	if p.get("berserk", false):
		return 4
	return Dati.peso_i(def_pg(p)["vuln"])

func descr_chit(c: Dictionary) -> String:
	var nomi := {"M": "Movimento", "F": "Combattimento", "G": "Magia", "B": "Berserk", "R": "Riflessi", "D": "Abbassarsi"}
	var t: String = nomi.get(c["tipo"], "")
	if c["tipo"] == "G":
		return "Magia %s%d%s" % [c["magia"], c["vel"], "*".repeat(c["sforzi"])]
	return "%s %s%d%s" % [t, c["forza"], c["vel"], "*".repeat(c["sforzi"])]

# ------------------------------------------------------------ nuova partita
func nuova(scenario: int, pg_umano: String, rivali: Array, seme: int) -> void:
	rng.seed = seme
	mappa = Mappa.new()
	mappa.genera(rng)
	s = {"versione": 1, "scenario": scenario, "seme": seme, "giorno": 1, "fine": "", "vincitori": [],
		"mostri": {}, "tabella": [], "siti_box": {}, "abitazioni": {}, "tessere": {}, "riserve": {},
		"pool_rossi": [], "pg": [], "riga_mostri": 0, "missioni_pubbliche": [], "giorni_max": 56,
		"fase": "alba"}
	_prepara_segnalini()
	_prepara_abitazioni()
	if scenario >= 4:
		arcano.prepara()
	if scenario >= 3:
		_prepara_mostri()
	var tutti := [pg_umano] + rivali
	for i in range(tutti.size()):
		s["pg"].append(_nuovo_pg("p%d" % i, tutti[i], i == 0))
	_prepara_missioni()
	if ha_abilita(umano(), "esperienza"):
		pass
	scrivi("Il Reame è pronto: %d tessere, il fiume corre dalle Cascate alla Grotta." % mappa.pezzi.size(), "titolo")

func _nuovo_pg(pid: String, idp: String, um: bool) -> Dictionary:
	var d: Dictionary = Dati.personaggi[idp]
	var p := {"pid": pid, "pg": idp, "nome": d["nome"], "umano": um, "dove": "", "nascosto": true, "morto": false,
		"chits": [], "oggetti": [], "fama": 0, "noto": 0, "oro": 10, "missioni": [], "fatte": [], "siti": [],
		"scoperti": {}, "indizi": {}, "nemici": false, "maledizioni": [], "uccisi": {}, "uccisi_pg": 0,
		"berserk": false, "piano": [], "bloccato": false, "turno_fatto": false, "entrato_da": "", "sbirciati": {},
		"pv_missioni": 0, "dettagli": {}, "incantesimi": [], "inc_iniziali": [], "twt": [], "effetti": {}}
	for c in d["chits"]:
		var cc: Dictionary = c.duplicate()
		cc["stato"] = "a"
		p["chits"].append(cc)
	if s["scenario"] >= 2:
		for e in d["equip"]:
			p["oggetti"].append({"id": e, "attivo": true, "allerta": false, "danno": 0, "scudo": "thrust"})
	# partenza: Locanda; nello scenario 2 un'altra abitazione se ce n'è più d'una
	var dw: String = "locanda"
	var parts: Array = d["partenze"]
	if s["scenario"] == 2 and parts.size() > 1:
		var alt: Array = parts.filter(func(x): return x != "locanda" and s["abitazioni"].has(x))
		if not alt.is_empty():
			dw = alt[rng.randi_range(0, alt.size() - 1)]
	p["dove"] = s["abitazioni"].get(dw, s["abitazioni"]["locanda"])
	if s["scenario"] >= 4:
		arcano.incantesimi_iniziali(p)
	if ha_abilita(p, "esperienza"):
		for k in mappa.vicini:
			for e in mappa.vicini[k]:
				if e["tipo"] in ["nascosto", "segreto"]:
					p["scoperti"][e["id"]] = true
	return p

func _prepara_segnalini() -> void:
	var per_lettera := {}
	var rossi := []
	var perduti := {}
	for id in Dati.segnalini:
		var c: Dictionary = Dati.segnalini[id]
		match c["tipo"]:
			"avviso":
				if not per_lettera.has(c["lettera"]): per_lettera[c["lettera"]] = []
				per_lettera[c["lettera"]].append(id)
			"perduto":
				perduti[c["nome_base"]] = id
			_:
				rossi.append(id)
	mescola(rossi)
	# 20 nelle sezioni perdute, 5 ciascuna
	for nome in ["Castle", "City", "Palace", "Fortress"]:
		s["riserve"][perduti[nome]] = rossi.slice(0, 5)
		rossi = rossi.slice(5)
	var lettera_perduto := {"M": "Castle", "C": "City", "F": "Palace", "R": "Fortress"}
	for t in range(40):
		s["tessere"][str(t)] = {"avviso": "", "rossi": [], "scoperti": false, "evocati": [], "aggiunti": false}
	for cat in ["M", "C", "F", "R", "V", "H", "W", "S"]:
		var ts := []
		for t in range(40):
			if cat_tessera(t) == cat:
				ts.append(t)
		var av: Array = per_lettera[cat].duplicate()
		mescola(av)
		for i in range(ts.size()):
			s["tessere"][str(ts[i])]["avviso"] = av[i]
		if lettera_perduto.has(cat):
			var grp := [perduti[lettera_perduto[cat]]]
			for i in range(4):
				grp.append(rossi.pop_back())
			mescola(grp)
			for i in range(ts.size()):
				s["tessere"][str(ts[i])]["rossi"] = [grp[i]]
	s["pool_rossi"] = rossi

func _radura_abitazione(t: int) -> String:
	var k := Mappa.chiave(t, 5)
	if mappa.radure.has(k) and mappa.collegata_acqua(k):
		return k
	return Mappa.chiave(t, 4)

func _prepara_abitazioni() -> void:
	for t in range(40):
		var c := cat_tessera(t)
		if c != "V" and c != "H":
			continue
		var st: Dictionary = s["tessere"][str(t)]
		var av: Dictionary = Dati.segnalini[st["avviso"]]
		var dw = av.get("abitazione")
		st["scoperti"] = true
		if dw == null:
			continue
		if dw == "fantasmi":
			st["fantasmi"] = _radura_abitazione(t)
		else:
			s["abitazioni"][dw] = _radura_abitazione(t)

func _prepara_mostri() -> void:
	var imm: Dictionary = Dati.mostri["immagini"]
	var pronti := {}
	for tipo in imm:
		pronti[tipo] = imm[tipo].duplicate()
	var cont := [0]
	var nuovo := func(tipo: String) -> String:
		var id := "m%d" % cont[0]
		cont[0] += 1
		var img := ""
		if pronti.has(tipo) and not pronti[tipo].is_empty():
			img = pronti[tipo].pop_back()
		var mo := {"id": id, "tipo": tipo, "img": img, "dove": "", "lato": 0, "morto": false, "bloccato": false, "casa": []}
		var ex = Dati.tipo_mostro(tipo).get("extra")
		if ex != null:
			var eimg := ""
			if pronti.has(ex) and not pronti[ex].is_empty():
				eimg = pronti[ex].pop_back()
			mo["ext"] = {"tipo": ex, "img": eimg, "lato": 0, "vivo": true, "danno": 0}
		s["mostri"][id] = mo
		return id
	var gi := 0
	for g in Dati.mostri["gruppi"]:
		var stato := []
		for bi in range(g["riquadri"].size()):
			var box := []
			for voce in g["riquadri"][bi]:
				for j in range(int(voce[1])):
					var tipo: String = voce[0]
					if tipo == "lupo" or tipo == "ratto":
						tipo = tipo + ("_a" if j % 2 == 0 else "_b")
					var id: String = nuovo.call(tipo)
					s["mostri"][id]["casa"] = ["g", gi, bi]
					box.append(id)
			stato.append(box)
		s["tabella"].append(stato)
		gi += 1
	for sito in Dati.mostri["siti"]:
		var id: String = nuovo.call(Dati.mostri["siti"][sito][1])
		s["mostri"][id]["casa"] = ["s", sito]
		s["siti_box"][sito] = id
	# i fantasmi stanno subito sulla mappa
	for t in range(40):
		var st: Dictionary = s["tessere"][str(t)]
		if st.has("fantasmi"):
			for j in range(2):
				var id: String = nuovo.call("fantasma")
				s["mostri"][id]["dove"] = st["fantasmi"]
				s["mostri"][id]["casa"] = ["f", st["fantasmi"]]

func _prepara_missioni() -> void:
	var sc: int = s["scenario"]
	if sc == 1:
		for cat in ["C", "F", "M", "R"]:
			var q := []
			for m in Dati.elenco_missioni:
				if m["scenario"] == 1 and m["gruppo"] == cat:
					q.append(m["id"])
			mescola(q)
			s["missioni_pubbliche"].append(q[0])
	elif sc >= 3:
		var pub := []
		var priv := []
		for m in Dati.elenco_missioni:
			if m["scenario"] == 3:
				if m["mazzo"] == "pubblico":
					pub.append(m["id"])
				else:
					priv.append(m["id"])
		mescola(pub)
		mescola(priv)
		s["missioni_pubbliche"] = pub.slice(0, 5)
		for p in s["pg"]:
			p["missioni"] = [priv.pop_back()]

# ------------------------------------------------------------ salvataggio
func esporta() -> Dictionary:
	return {"s": s.duplicate(true), "mappa": mappa.esporta(), "rng": str(rng.state), "log": log_righe.slice(max(0, log_righe.size() - 120))}

func importa(d: Dictionary) -> void:
	s = d["s"]
	_numeri(s)
	mappa = Mappa.new()
	mappa.importa(d["mappa"])
	rng.state = int(d["rng"])
	log_righe = d.get("log", [])

func _numeri(x) -> void:
	## dopo il JSON i numeri interi tornano float: li sistemo dove servono
	for p in x["pg"]:
		for k in ["incantesimi", "inc_iniziali", "twt"]:
			if not p.has(k): p[k] = []
		if not p.has("effetti"): p["effetti"] = {}
		for c in p["chits"]:
			c["vel"] = int(c["vel"])
			c["sforzi"] = int(c["sforzi"])
		for k in ["fama", "noto", "oro", "uccisi_pg", "pv_missioni"]:
			p[k] = int(p[k])
		for k in p["uccisi"]:
			p["uccisi"][k] = int(p["uccisi"][k])
		for o in p["oggetti"]:
			o["danno"] = int(o["danno"])
	for k in ["scenario", "seme", "giorno", "riga_mostri", "giorni_max"]:
		x[k] = int(x[k])
	for id in x["mostri"]:
		var m: Dictionary = x["mostri"][id]
		m["lato"] = int(m["lato"])
		if m.has("ext"):
			m["ext"]["lato"] = int(m["ext"]["lato"])
		if m["casa"].size() == 3:
			m["casa"][1] = int(m["casa"][1])
			m["casa"][2] = int(m["casa"][2])

# ------------------------------------------------------------ decisioni
func decidi(p: Dictionary, tipo: String, dati: Dictionary):
	if not p["umano"] or auto_umano:
		return ia.decidi(p, tipo, dati)
	richiesta = {"tipo": tipo, "pid": p["pid"], "dati": dati}
	cambiato.emit()
	chiede.emit(richiesta)
	var r = await risposta
	richiesta = {}
	return r

func rispondi(r) -> void:
	risposta.emit(r)

# ------------------------------------------------------------ giornata
func gioca() -> void:
	## ciclo principale: un giorno dopo l'altro fino alla fine della partita
	in_corso = true
	while s["fine"] == "":
		await gioca_giorno()
	in_corso = false
	cambiato.emit()

func settimana_mese() -> String:
	var g: int = s["giorno"]
	var mese := (g - 1) / 28 + 1
	var gm := (g - 1) % 28 + 1
	return "Mese %d, giorno %d" % [mese, gm]

func gioca_giorno() -> void:
	s["fase"] = "alba"
	scrivi("— Giorno %d (%s) —" % [s["giorno"], settimana_mese()], "titolo")
	for p in vivi():
		p["bloccato"] = false
		p["turno_fatto"] = false
		p["entrato_da"] = ""
		if s["scenario"] >= 4:
			arcano.sincronizza(p)
			if arcano.effetto(p, "fiuto"):
				p["nemici"] = true
	# Alba: si registrano le attività
	for p in vivi():
		var r = await decidi(p, "piano", {"fasi": fasi_disponibili(p)})
		p["piano"] = r if r is Array else []
	# Sorgere del sole: tiro dei mostri
	if s["scenario"] >= 3:
		s["riga_mostri"] = d6()
		scrivi("Sorge il sole: si aggirano i mostri della riga %d (%s)." % [s["riga_mostri"], Dati.mostri["righe"][str(s["riga_mostri"])]], "mostri")
	s["fase"] = "giorno"
	cambiato.emit()
	# Giorno: turni in ordine casuale
	var ordine: Array = vivi().map(func(p): return p["pid"])
	mescola(ordine)
	var spadaccini: Array = ordine.filter(func(x): return ha_abilita(P(x), "astuto"))
	for x in spadaccini:
		ordine.erase(x)
	var fatti := {}
	while not ordine.is_empty() or not spadaccini.is_empty():
		var chi := ""
		for x in spadaccini.duplicate():
			var p := P(x)
			var vuole = true if ordine.is_empty() else await decidi(p, "anticipa", {"restanti": ordine.size()})
			if vuole:
				chi = x
				spadaccini.erase(x)
				break
		if chi == "":
			if ordine.is_empty():
				break
			chi = ordine.pop_front()
		var p := P(chi)
		if p["morto"]:
			continue
		if p["bloccato"]:
			scrivi("%s è bloccat{oa} e perde il turno." % p["nome"])
			p["turno_fatto"] = true
			continue
		await esegui_turno(p)
		fatti[chi] = true
		if s["fine"] != "":
			return
	# Tramonto e sera: combattimenti
	s["fase"] = "sera"
	cambiato.emit()
	await sera()
	# Mezzanotte
	mezzanotte()
	controlla_vittoria()
	s["giorno"] += 1
	if s["fine"] == "" and s["giorno"] > s["giorni_max"]:
		_fine_tempo()
	cambiato.emit()

func fasi_disponibili(p: Dictionary) -> Dictionary:
	## fasi base, di luce ed extra per la pianificazione
	var base := 2
	var luce := 0 if ha_abilita(p, "gambe_corte") else 2
	var extra := []
	if ha_abilita(p, "resistenza"): extra.append("M")
	if ha_abilita(p, "robusto") or ha_abilita(p, "salute"): extra.append("R")
	if ha_abilita(p, "sfuggente"): extra.append("H")
	if ha_abilita(p, "visione"): extra.append("S")
	if ha_abilita(p, "strumenti_magici") and s["scenario"] >= 2: extra.append("A")
	if ha_abilita(p, "reputazione") and abitazione_in(p["dove"]) != "": extra.append("*")
	if s["scenario"] >= 4:
		extra.append_array(arcano.fasi_extra(p))
	var grotta := tipo_radura(p["dove"]) == "C"
	return {"base": base, "luce": 0 if grotta else luce, "extra": extra, "grotta": grotta}

## costo in fasi per entrare nella radura b dalla radura a
func costo_mossa(p: Dictionary, a: String, b: String) -> int:
	var ta := tipo_radura(a)
	var tb := tipo_radura(b)
	if tb == "M" and ta != "M":
		return 1 if ha_abilita(p, "scalatore") else 2
	if tb == "A":
		if ha_abilita(p, "navigatore"):
			return 1
		if ta != "A":
			return 2
		var da: int = mappa.dist_grotta.get(a, 0)
		var db: int = mappa.dist_grotta.get(b, 0)
		return 2 if db > da else 1
	return 1

func arco_percorribile(p: Dictionary, e: Dictionary) -> bool:
	if e["tipo"] == "nascosto" or e["tipo"] == "segreto":
		return p["scoperti"].has(e["id"])
	return true

func vicini_di(p: Dictionary, k: String) -> Array:
	var r := []
	for e in mappa.vicini.get(k, []):
		if arco_percorribile(p, e) and not (e["b"] in r):
			r.append(e["b"])
	return r

func esegui_turno(p: Dictionary) -> void:
	s["attivo"] = p["pid"]
	scrivi("Turno di %s." % p["nome"], "turno")
	if s["scenario"] >= 2 and p["nascosto"]:
		p["nascosto"] = false
	cambiato.emit()
	await pausa(0.25)
	var st := {"base": 0, "luce": 0, "extra": fasi_disponibili(p)["extra"].duplicate(),
		"grotta": tipo_radura(p["dove"]) == "C", "max_luce": 0 if ha_abilita(p, "gambe_corte") else 2}
	var piano: Array = p["piano"]
	var i := 0
	while i < piano.size() and not p["bloccato"] and not p["morto"]:
		var a: Dictionary = piano[i]
		if a["a"] == "M":
			var n := 1
			while i + n < piano.size() and piano[i + n]["a"] == "M" and piano[i + n].get("dest", "") == a.get("dest", ""):
				n += 1
			var dest: String = a.get("dest", "")
			var costo := costo_mossa(p, p["dove"], dest) if mappa.radure.has(dest) else 1
			var ok := mappa.radure.has(dest) and dest in vicini_di(p, p["dove"])
			for j in range(n):
				var slot := _slot(p, st, "M")
				if slot == "":
					i = piano.size()
					break
				var grotta_coinvolta := tipo_radura(p["dove"]) == "C" or (ok and tipo_radura(dest) == "C")
				if grotta_coinvolta and (slot == "luce" or st["luce"] > 0):
					ok = false
				if j == costo - 1 and ok and j < n:
					await _muovi(p, dest)
					if tipo_radura(dest) == "C":
						st["grotta"] = true
				elif j == n - 1 and n < costo:
					scrivi("%s non riesce a raggiungere %s: servono %d fasi di movimento." % [p["nome"], nome_r(dest), costo])
				elif not ok and j == 0:
					scrivi("%s non può muovere verso %s." % [p["nome"], nome_r(dest) if mappa.radure.has(dest) else "?"])
				await fine_fase(p)
				if p["bloccato"] or p["morto"]:
					break
			i += n
			continue
		var slot := _slot(p, st, a["a"])
		if slot == "":
			break
		match a["a"]:
			"S": await attivita_ricerca(p)
			"H": attivita_nascondi(p)
			"A": attivita_allerta(p)
			"R": await attivita_riposo(p)
			"E": await arcano.attivita_incanto(p)
			"V": await attivita_volo(p, a.get("dest", ""))
		await fine_fase(p)
		i += 1
	if not p["morto"]:
		await fine_turno(p)
	p["turno_fatto"] = true
	s.erase("attivo")
	cambiato.emit()

func _slot(p: Dictionary, st: Dictionary, tipo: String) -> String:
	if tipo in st["extra"]:
		st["extra"].erase(tipo)
		return "extra"
	if "*" in st["extra"] and abitazione_in(p["dove"]) != "":
		st["extra"].erase("*")
		return "extra"
	if st["base"] < 2:
		st["base"] += 1
		return "base"
	if not st["grotta"] and st["luce"] < st["max_luce"]:
		st["luce"] += 1
		return "luce"
	return ""

func _muovi(p: Dictionary, dest: String) -> void:
	var mm := movimento_max(p)
	var lasciati := []
	for o in p["oggetti"].duplicate():
		if peso_oggetto(o) > mm:
			p["oggetti"].erase(o)
			lascia(p["dove"], o)
			lasciati.append(Dati.nome_arma(o["id"]))
	if not lasciati.is_empty():
		scrivi("%s non riesce a portare %s e lo abbandona." % [p["nome"], ", ".join(lasciati)], "male")
	if p.get("labirinto", false):
		p.erase("labirinto")
		var rr := mappa.radure_tessera(tessera(p["dove"]))
		var acaso: String = rr[rng.randi_range(0, rr.size() - 1)]
		if acaso != p["dove"]:
			scrivi("%s vaga perso nel Labirinto e finisce a %s." % [p["nome"], nome_r(acaso)], "male")
			dest = acaso
	# sentieri usati: chi li percorre li conosce
	p["entrato_da"] = p["dove"]
	p["dove"] = dest
	scrivi("%s si muove a %s." % [p["nome"], nome_r(dest)])
	cambiato.emit()
	await pausa(0.35)

func attivita_nascondi(p: Dictionary) -> void:
	if "Squittio" in p["maledizioni"]:
		scrivi("%s non può nascondersi (Squittio)." % p["nome"])
		return
	if p["nascosto"]:
		scrivi("%s è già nascosto." % p["nome"])
		return
	var t := tiro(p, "nascondi")
	if t[0] < 6:
		p["nascosto"] = true
		scrivi("%s si nasconde (dado %d)." % [p["nome"], t[0]], "bene")
	else:
		scrivi("%s non riesce a nascondersi (dado 6)." % p["nome"])

func attivita_allerta(p: Dictionary) -> void:
	if "Stanco" in p["maledizioni"]:
		scrivi("%s è stanc{oa} e non può allertare." % p["nome"])
		return
	if ha_abilita(p, "berserk") and not p["berserk"]:
		for c in p["chits"]:
			if c["tipo"] == "B" and c["stato"] == "a":
				if ia.vuole_berserk(p):
					c["stato"] = "f"
					p["berserk"] = true
					scrivi("%s entra in furia berserk: vulnerabilità Tremenda fino a mezzanotte." % p["nome"], "bene")
					return
	var a := arma_attiva(p)
	if a.is_empty():
		scrivi("%s non ha un'arma da allertare." % p["nome"])
		return
	a["allerta"] = true
	scrivi("%s allerta %s." % [p["nome"], Dati.nome_arma(a["id"])])

func attivita_riposo(p: Dictionary) -> void:
	if "Malattia" in p["maledizioni"]:
		scrivi("%s è malat{oa} e non può riposare." % p["nome"])
		return
	var volte := 2 if ha_abilita(p, "gambe_corte") else 1
	if s["scenario"] >= 4:
		var rp := arcano.eff(p, "riposo")
		if "tutti" in rp:
			var n := 0
			for c in p["chits"]:
				if c["stato"] == "f" and not c.has("legato"):
					c["stato"] = "a"
					n += 1
			scrivi("%s riposa tra i Fiori del riposo: %d segnalini tornano disponibili." % [p["nome"], n], "bene")
			if n > 0:
				return
		if "doppio" in rp:
			volte += 1
	for v in range(volte):
		var opz := opzioni_riposo(p)
		if opz.is_empty():
			if v == 0:
				scrivi("%s riposa, ma non ha nulla da recuperare." % p["nome"])
			return
		var sc = await decidi(p, "riposo", {"opzioni": opz})
		if sc == null or int(sc) < 0 or int(sc) >= opz.size():
			sc = 0
		var o: Dictionary = opz[int(sc)]
		applica_riposo(p, o)

func opzioni_riposo(p: Dictionary) -> Array:
	var r := []
	var avv: bool = "Avvizzimento" in p["maledizioni"]
	var ha_singolo := false
	for c in p["chits"]:
		if c["stato"] == "a" and c["sforzi"] == 1:
			ha_singolo = true
	for i in range(p["chits"].size()):
		var c: Dictionary = p["chits"][i]
		if c["tipo"] == "C":
			continue
		if c["stato"] == "w":
			if c["sforzi"] == 0:
				r.append({"i": i, "da": "w", "a": "a", "resto": -1})
			elif c["sforzi"] == 1:
				r.append({"i": i, "da": "w", "a": "f", "resto": -1})
			elif ha_singolo:
				r.append({"i": i, "da": "w", "a": "f", "resto": 1})
		elif c["stato"] == "f" and not avv:
			if c["sforzi"] == 1:
				r.append({"i": i, "da": "f", "a": "a", "resto": -1})
			elif c["sforzi"] >= 2 and ha_singolo:
				r.append({"i": i, "da": "f", "a": "a", "resto": 1})
	return r

func applica_riposo(p: Dictionary, o: Dictionary) -> void:
	var c: Dictionary = p["chits"][o["i"]]
	c["stato"] = o["a"]
	var testo := "%s riposa: %s %s." % [p["nome"], descr_chit(c), "torna disponibile" if o["a"] == "a" else "passa da ferito ad affaticato"]
	if o["resto"] >= 0:
		for c2 in p["chits"]:
			if c2 != c and c2["stato"] == "a" and c2["sforzi"] == 1:
				c2["stato"] = "f"
				testo += " (resto: affatica %s)" % descr_chit(c2)
				break
	scrivi(testo, "bene")
	cambiato.emit()

# ------------------------------------------------------------ ricerca
func radure_scrutabili(p: Dictionary) -> Array:
	var k: String = p["dove"]
	var r := [k]
	if tipo_radura(k) == "M":
		var t := tessera(k)
		for tt in [t] + mappa.tessere_adiacenti(t):
			for kk in mappa.radure_tessera(tt):
				if kk != k and tipo_radura(kk) != "C" and not (kk in r):
					r.append(kk)
	return r

func attivita_ricerca(p: Dictionary) -> void:
	if "Nebbia agli occhi" in p["maledizioni"]:
		scrivi("%s ha la nebbia agli occhi e non può cercare." % p["nome"])
		return
	if s["scenario"] >= 4 and p["pg"] == "re_stregone":
		arcano.visione_magica(p)
		cambiato.emit()
		return
	var fo: Dictionary = arcano.fonti(p) if s["scenario"] >= 4 else {"saccheggia": [], "rune": []}
	var sc = await decidi(p, "tabella", {"radure": radure_scrutabili(p), "fonti": fo})
	var tab: String = sc.get("tabella", "scruta") if sc is Dictionary else "scruta"
	if tab in ["saccheggia", "rune"]:
		var fonte: String = str(sc.get("fonte", ""))
		var ok := false
		for x in fo[tab]:
			if x["id"] == fonte:
				ok = true
		if not ok and not fo[tab].is_empty():
			fonte = fo[tab][0]["id"]
			ok = true
		if ok:
			if tab == "saccheggia":
				arcano.saccheggia(p, fonte)
			else:
				arcano.rune(p, fonte)
			return
		tab = "scruta"
	var dove: String = sc.get("radura", p["dove"]) if sc is Dictionary else p["dove"]
	if tab != "scruta" or not (dove in radure_scrutabili(p)):
		dove = p["dove"]
	var t := tiro(p, "cerca")
	var ris: String = TABELLE[tab][t[0] - 1]
	scrivi("%s tira su %s (dado %d): %s." % [p["nome"], NOMI_TABELLE[tab], t[0], RISULTATI[ris]])
	if ris == "scelta":
		var opz := ["indizi", "segreti", "sentieri", "nemici", "scopri", "scopri_indizi"]
		var c = await decidi(p, "scelta", {"opzioni": opz, "radura": dove})
		ris = c if c is String and c in opz else "scopri"
		scrivi("%s sceglie: %s." % [p["nome"], RISULTATI[ris]])
	await applica_ricerca(p, ris, dove)

func applica_ricerca(p: Dictionary, ris: String, dove: String) -> void:
	var t := tessera(dove)
	match ris:
		"indizi":
			p["indizi"][str(t)] = true
			sbircia(p, t)
		"segreti", "sentieri":
			var tipo := "segreto" if ris == "segreti" else "nascosto"
			var n := 0
			for e in mappa.vicini.get(p["dove"], []):
				if e["tipo"] == tipo and not p["scoperti"].has(e["id"]):
					p["scoperti"][e["id"]] = true
					n += 1
			if n > 0:
				scrivi("%s scopre %d %s." % [p["nome"], n, "passaggi segreti" if tipo == "segreto" else "sentieri nascosti"], "bene")
			else:
				scrivi("Nessun %s parte da qui." % ("passaggio segreto" if tipo == "segreto" else "sentiero nascosto"))
		"nemici":
			p["nemici"] = true
			scrivi("%s individua i nemici nascosti: oggi può bloccarli e attaccarli." % p["nome"], "bene")
		"scopri":
			scopri_segnalini(p, dove)
		"scopri_indizi":
			if p["indizi"].has(str(t)):
				scopri_segnalini(p, dove)
			else:
				scrivi("Senza indizi in questa tessera non si scopre nulla.")
	cambiato.emit()

func sbircia(p: Dictionary, t: int) -> void:
	_completa_rossi(t, false)
	var st: Dictionary = s["tessere"][str(t)]
	p["sbirciati"][str(t)] = true
	var nomi := []
	if st["avviso"] != "":
		nomi.append(Dati.segnalini[st["avviso"]]["nome"])
	for r in st["rossi"]:
		nomi.append(Dati.segnalini[r]["nome"])
	if p["umano"]:
		scrivi("Indizi su %s: %s." % [Dati.tessere[t]["nome"], ", ".join(nomi) if not nomi.is_empty() else "nessun segnalino"], "segreto")
	else:
		scrivi("%s raccoglie indizi su %s." % [p["nome"], Dati.tessere[t]["nome"]])

func scopri_segnalini(p: Dictionary, dove: String) -> void:
	var t := tessera(dove)
	_completa_rossi(t, false)
	p["sbirciati"][str(t)] = true
	var n := Mappa.numero_di(dove)
	var trovati := []
	for r in s["tessere"][str(t)]["rossi"]:
		var c: Dictionary = Dati.segnalini[r]
		if c["tipo"] == "sito" and int(c["radura"]) == n and not (r in p["siti"]):
			p["siti"].append(r)
			trovati.append(c["nome"])
	if trovati.is_empty():
		scrivi("%s cerca a fondo %s ma non trova siti." % [p["nome"], nome_r(dove)])
	else:
		scrivi("%s scopre il sito: %s!" % [p["nome"], ", ".join(trovati)], "bene")
	controlla_missioni_scoperta(p, dove)

func _completa_rossi(t: int, pubblico: bool) -> void:
	## scenario 1: le tessere da sei radure senza segnalino rosso ne ricevono uno a caso
	var st: Dictionary = s["tessere"][str(t)]
	if Dati.tessere[t]["cl"].size() == 6 and st["rossi"].is_empty() and not s["pool_rossi"].is_empty():
		st["rossi"].append(s["pool_rossi"].pop_back())
	if pubblico:
		_svela_perduto(t)

func _svela_perduto(t: int) -> void:
	var st: Dictionary = s["tessere"][str(t)]
	for r in st["rossi"].duplicate():
		if Dati.segnalini[r]["tipo"] == "perduto" and not st.get("perduto_aperto", false):
			st["perduto_aperto"] = true
			var ag: Array = s["riserve"].get(r, [])
			for x in ag:
				st["rossi"].append(x)
			scrivi("Si rivela %s: altri %d segnalini compaiono nella tessera %s!" % [Dati.segnalini[r]["nome"], ag.size(), Dati.tessere[t]["nome"]], "mostri")

# ------------------------------------------------------------ fine fase e fine turno
func fine_fase(p: Dictionary) -> void:
	controlla_missioni_fase(p)
	if s["scenario"] < 2 or p["morto"]:
		return
	var k: String = p["dove"]
	# i mostri bloccano chi non è nascosto
	if s["scenario"] >= 3 and not p["nascosto"]:
		var bl := []
		for id in s["mostri"]:
			var m: Dictionary = s["mostri"][id]
			if m["dove"] == k and not m["morto"] and not protetto(p, m):
				m["bloccato"] = true
				bl.append(m)
		if not bl.is_empty():
			p["bloccato"] = true
			scrivi("%s è bloccat{oa} da %s!" % [p["nome"], nome_mostro(bl[0]) + (" e altri" if bl.size() > 1 else "")], "male")
			cambiato.emit()
			return
	# blocchi tra personaggi
	for q in vivi():
		if q == p or q["dove"] != k:
			continue
		if not p["nascosto"] or q["nemici"]:
			var vuole = await decidi(q, "blocca", {"bersaglio": p["pid"]})
			if vuole:
				_blocco(q, p)
				return
		if not q["nascosto"] or p["nemici"]:
			var vuole2 = await decidi(p, "blocca", {"bersaglio": q["pid"]})
			if vuole2:
				_blocco(p, q)
				return

func _blocco(a: Dictionary, b: Dictionary) -> void:
	a["nascosto"] = false
	b["nascosto"] = false
	a["bloccato"] = true
	b["bloccato"] = true
	scrivi("%s blocca %s: si affronteranno stasera." % [a["nome"], b["nome"]], "male")
	cambiato.emit()

func protetto(p: Dictionary, m: Dictionary) -> bool:
	return ha_abilita(p, "protezione_celeste") and m["tipo"] in ["demone", "demone_alato", "imp", "vampiro", "succubo"]

func fine_turno(p: Dictionary) -> void:
	var k: String = p["dove"]
	var t := tessera(k)
	var st: Dictionary = s["tessere"][str(t)]
	# i segnalini della tessera si scoprono
	_completa_rossi(t, true)
	if not st["scoperti"]:
		st["scoperti"] = true
		var nomi := []
		if st["avviso"] != "":
			nomi.append(Dati.segnalini[st["avviso"]]["nome"])
		for r in st["rossi"]:
			nomi.append(Dati.segnalini[r]["nome"])
		scrivi("Si scoprono i segnalini di %s: %s." % [Dati.tessere[t]["nome"], ", ".join(nomi)], "mostri")
		var av = Dati.segnalini.get(st["avviso"], {}).get("abitazione")
		if av != null and av != "fantasmi" and not s["abitazioni"].has(av):
			s["abitazioni"][av] = _radura_abitazione(t)
			scrivi("Compare: %s." % Dati.ABITAZIONI[av], "mostri")
	if s["scenario"] >= 3:
		await muovi_ed_evoca(p)
	cambiato.emit()

func muovi_ed_evoca(p: Dictionary) -> void:
	var k: String = p["dove"]
	var t := tessera(k)
	var st: Dictionary = s["tessere"][str(t)]
	var riga: int = s["riga_mostri"]
	var mossi := []
	# 1) i mostri in agguato nella tessera raggiungono la radura
	for id in s["mostri"]:
		var m: Dictionary = s["mostri"][id]
		if m["morto"] or m["dove"] == "" or tessera(m["dove"]) != t or m["dove"] == k or m["bloccato"]:
			continue
		if Dati.tipo_mostro(m["tipo"])["peso"] == "X":
			continue
		if m["tipo"] == "fantasma" or riga_di(m["tipo"]) == riga:
			m["dove"] = k
			mossi.append(m)
	if not mossi.is_empty():
		scrivi("%s %s %s." % [_elenco_mostri(mossi), "raggiunge" if mossi.size() == 1 else "raggiungono", nome_r(k)], "mostri")
	# 2) evocazioni
	var pace := ha_abilita(p, "pace_natura")
	var evocati := []
	if not pace and st["avviso"] != "" and not (st["avviso"] in st["evocati"]):
		var c: Dictionary = Dati.segnalini[st["avviso"]]
		var chiave_s: String = "%s_%s" % [str(c["nome_base"]).to_upper(), c["lettera"]]
		var nuovi := _evoca(chiave_s, riga, k)
		if not nuovi.is_empty():
			st["evocati"].append(st["avviso"])
			evocati += nuovi
			scrivi("Il segnalino %s evoca %s in %s!" % [c["nome"], _elenco_mostri(nuovi), nome_r(k)], "mostri")
	var rossi: Array = st["rossi"].duplicate()
	rossi.sort_custom(func(a, b): return int(Dati.segnalini[a].get("radura", 0)) < int(Dati.segnalini[b].get("radura", 0)))
	for r in rossi:
		if r in st["evocati"]:
			continue
		var c: Dictionary = Dati.segnalini[r]
		var dest := Mappa.chiave(t, int(c.get("radura", 0)))
		if not mappa.radure.has(dest):
			continue
		var nuovi := []
		if c["tipo"] == "sito":
			var sito: String = str(c["nome_base"]).to_lower()
			var info: Array = Dati.mostri["siti"][sito]
			if int(info[0]) == riga and s["siti_box"].get(sito, "") != "":
				var id: String = s["siti_box"][sito]
				s["siti_box"][sito] = ""
				s["mostri"][id]["dove"] = dest
				s["mostri"][id]["sito"] = sito
				nuovi.append(s["mostri"][id])
		elif c["tipo"] == "suono" and not pace:
			var chiave_s: String = str(c["nome_base"]).to_upper()
			nuovi = _evoca(chiave_s + "_" + cat_tessera(t), riga, dest)
			if nuovi.is_empty():
				nuovi = _evoca(chiave_s + "_*", riga, dest)
			for m in nuovi:
				m["suono"] = r
		if not nuovi.is_empty():
			st["evocati"].append(r)
			evocati += nuovi
			scrivi("%s evoca %s in %s!" % [c["nome"], _elenco_mostri(nuovi), nome_r(dest)], "mostri")
	# 3) i mostri arrivati bloccano chi non è nascosto nella loro radura
	for m in mossi + evocati:
		for q in vivi():
			if q["dove"] == m["dove"] and not q["nascosto"] and not protetto(q, m):
				m["bloccato"] = true
				if not q["bloccato"]:
					q["bloccato"] = true
					scrivi("%s blocca %s." % [nome_mostro(m), q["nome"]], "male")
	if not (mossi + evocati).is_empty():
		cambiato.emit()
		await pausa(0.5)

func riga_di(tipo: String) -> int:
	for g in Dati.mostri["gruppi"]:
		for box in g["riquadri"]:
			for v in box:
				if tipo.begins_with(v[0]):
					return int(g["riga"])
	for sito in Dati.mostri["siti"]:
		if Dati.mostri["siti"][sito][1] == tipo:
			return int(Dati.mostri["siti"][sito][0])
	return 0

func _evoca(chiave_s: String, riga: int, dest: String) -> Array:
	var gi := 0
	for g in Dati.mostri["gruppi"]:
		if int(g["riga"]) == riga and chiave_s in g["segnalini"]:
			var stato: Array = s["tabella"][gi]
			for bi in range(stato.size()):
				if not stato[bi].is_empty():
					var r := []
					for id in stato[bi]:
						s["mostri"][id]["dove"] = dest
						r.append(s["mostri"][id])
					stato[bi] = []
					return r
		gi += 1
	return []

func nome_mostro(m: Dictionary) -> String:
	return Dati.tipo_mostro(m["tipo"]).get("nome", m["tipo"])

func _elenco_mostri(a: Array) -> String:
	var cont := {}
	for m in a:
		var n := nome_mostro(m)
		cont[n] = cont.get(n, 0) + 1
	var parti := []
	for n in cont:
		parti.append(("%d × %s" % [cont[n], n]) if cont[n] > 1 else n)
	return ", ".join(parti)

# ------------------------------------------------------------ sera e mezzanotte
func sera() -> void:
	var radure := {}
	for p in vivi():
		radure[p["dove"]] = true
	var ordine: Array = radure.keys()
	mescola(ordine)
	for k in ordine:
		await combat.combatti(k)
		if s["fine"] != "":
			return
	if s["scenario"] >= 4:
		for p in vivi():
			await arcano.sera_incantesimi(p)

func mezzanotte() -> void:
	s["fase"] = "mezzanotte"
	for t in s["tessere"]:
		s["tessere"][t]["evocati"] = []
	for id in s["mostri"]:
		s["mostri"][id]["bloccato"] = false
		s["mostri"][id]["lato"] = 0
		if s["mostri"][id].has("ext"):
			s["mostri"][id]["ext"]["lato"] = 0
	for p in vivi():
		p["indizi"] = {}
		p["nemici"] = false
		if p["berserk"]:
			p["berserk"] = false
		if abitazione_in(p["dove"]) == "cappella" and not p["maledizioni"].is_empty():
			scrivi("La Cappella libera %s da maledizioni e ipnosi." % p["nome"], "bene")
			p["maledizioni"] = []
	if s["scenario"] >= 4:
		arcano.scadenze()
	if s["giorno"] % 28 == 0 and s["scenario"] >= 3:
		_rigenerazione()

func _rigenerazione() -> void:
	scrivi("Fine del mese: tutti i mostri si rigenerano e tornano alla Tabella delle apparizioni.", "mostri")
	for g in s["tabella"]:
		for bi in range(g.size()):
			g[bi] = []
	for id in s["mostri"]:
		var m: Dictionary = s["mostri"][id]
		m["morto"] = false
		m["dove"] = ""
		if m.has("ext"):
			m["ext"]["vivo"] = true
			m["ext"]["danno"] = 0
		var c: Array = m["casa"]
		match c[0]:
			"g": s["tabella"][int(c[1])][int(c[2])].append(id)
			"s": s["siti_box"][c[1]] = id
			"f": m["dove"] = c[1]

# ------------------------------------------------------------ missioni e vittoria
func controlla_missioni_scoperta(p: Dictionary, dove: String) -> void:
	var t := tessera(dove)
	var n := Mappa.numero_di(dove)
	var st: Dictionary = s["tessere"][str(t)]
	for q in s["missioni_pubbliche"]:
		if q in p["fatte"]:
			continue
		var m: Dictionary = Dati.missioni[q]
		if m["tipo"] == "trek":
			var av: Dictionary = Dati.segnalini.get(st["avviso"], {})
			var chiave_s := "%s_%s" % [str(av.get("nome_base", "")).to_upper(), av.get("lettera", "")]
			if chiave_s == m["avviso"] and n == radura_bersaglio_trek(t):
				_compiuta(p, q)
		elif m["tipo"] == "trova_perduto":
			for r in st["rossi"]:
				var c: Dictionary = Dati.segnalini[r]
				if c["tipo"] == "perduto" and str(c["nome_base"]).to_lower() == m["perduto"] and int(c["radura"]) == n:
					_compiuta(p, q)

func radura_bersaglio_trek(t: int) -> int:
	var st: Dictionary = s["tessere"][str(t)]
	var sito := 0
	var suono := 0
	var altro := 0
	for r in st["rossi"]:
		var c: Dictionary = Dati.segnalini[r]
		if c["tipo"] == "sito": sito = max(sito, int(c["radura"]))
		elif c["tipo"] == "suono": suono = max(suono, int(c["radura"]))
		else: altro = max(altro, int(c.get("radura", 0)))
	if sito > 0: return sito
	if suono > 0: return suono
	return altro

func controlla_missioni_fase(_p: Dictionary) -> void:
	pass

func _compiuta(p: Dictionary, q: String) -> void:
	if q in p["fatte"]:
		return
	p["fatte"].append(q)
	var m: Dictionary = Dati.missioni[q]
	scrivi("%s completa la missione «%s» (+%d PV)." % [p["nome"], m["nome"], m["pv"]], "bene")

func uccisione_mostro(p: Dictionary, m: Dictionary, molt: int) -> void:
	var d := Dati.tipo_mostro(m["tipo"])
	var f: int = int(d.get("fama", 0)) * molt
	var n: int = int(d.get("noto", 0)) * molt
	p["fama"] += f
	p["noto"] += n
	p["uccisi"][m["tipo"]] = p["uccisi"].get(m["tipo"], 0) + 1
	scrivi("%s uccide %s: +%d fama, +%d notorietà%s." % [p["nome"], nome_mostro(m), f, n, (" (×%d)" % molt) if molt > 1 else ""], "bene")
	# missioni legate all'uccisione
	for q in s["missioni_pubbliche"] + p["missioni"]:
		if q in p["fatte"]:
			continue
		var mi: Dictionary = Dati.missioni[q]
		if mi["tipo"] == "uccidi_sito" and m.get("sito", "") == mi["sito"]:
			_compiuta(p, q)
		elif mi["tipo"] == "uccisioni":
			if mi.has("tipi"):
				var tot := 0
				for tp in mi["tipi"]:
					tot += p["uccisi"].get(tp, 0)
				if tot >= int(mi["quanti"]):
					_compiuta(p, q)
			elif mi.get("tipo2", "") == "suono" and m.get("suono", "") != "" and str(m["suono"]).begins_with(mi["suono"]) \
					and m["dove"] == _radura_suono(m["suono"]):
				_compiuta(p, q)

func _radura_suono(r: String) -> String:
	for t in s["tessere"]:
		if r in s["tessere"][t]["rossi"]:
			return Mappa.chiave(int(t), int(Dati.segnalini[r]["radura"]))
	return ""

func pv(p: Dictionary) -> int:
	var tot := 0
	for q in p["fatte"]:
		tot += int(Dati.missioni[q]["pv"])
	var sc: int = s["scenario"]
	if sc >= 3:
		tot += p["siti"].size()
		var fama: int = p["fama"]
		var noto: int = p["noto"]
		if sc >= 4:
			tot += arcano.pv_extra(p)
			fama += arcano.fama_tesori(p)
			noto += arcano.noto_tesori(p)
		if not ("Disgusto" in p["maledizioni"]):
			tot += max(0, fama) / 10
		elif sc >= 4:
			tot -= 1
		tot += max(0, noto) / 20
		for q in p["missioni"]:
			var mi: Dictionary = Dati.missioni[q]
			if mi["tipo"] == "per_uccisione":
				var n := 0
				for tp in p["uccisi"]:
					var peso: String = str(Dati.tipo_mostro(tp).get("peso", ""))
					if (mi["tipi"] as Array).has(tp) or (mi.get("peso") != null and peso == mi["peso"]):
						n += p["uccisi"][tp]
				tot += min(int(mi["max"]), n / int(mi["ogni"]))
	return tot

func controlla_vittoria() -> void:
	if s["fine"] != "":
		return
	var sc: int = s["scenario"]
	var v := []
	if sc == 1:
		for p in vivi():
			var tutte := true
			for q in s["missioni_pubbliche"]:
				if not (q in p["fatte"]):
					tutte = false
			if tutte:
				v.append(p)
	elif sc == 2:
		var rimasti := vivi()
		for p in rimasti:
			if p["uccisi_pg"] >= 4:
				v.append(p)
		if v.is_empty() and rimasti.size() <= 1:
			v = rimasti
	else:
		for p in vivi():
			if pv(p) >= 10:
				v.append(p)
	var u := umano()
	if s.get("prova", false):
		if vivi().is_empty():
			s["fine"] = "sconfitta"
		elif not v.is_empty():
			s["vincitori"] = v.map(func(p): return p["pid"])
			s["fine"] = "vittoria"
			scrivi("Vince %s!" % " e ".join(v.map(func(p): return p["nome"])), "titolo")
		return
	if u["morto"] and v.is_empty() and sc != 2:
		s["fine"] = "sconfitta"
		scrivi("%s è mort{oa}: la partita è finita." % u["nome"], "titolo")
		return
	if u["morto"] and sc == 2 and v.is_empty():
		s["fine"] = "sconfitta"
		scrivi("%s è mort{oa}: la partita è finita." % u["nome"], "titolo")
		return
	if not v.is_empty():
		s["vincitori"] = v.map(func(p): return p["pid"])
		s["fine"] = "vittoria" if u in v else "sconfitta"
		scrivi("Vince %s!" % " e ".join(v.map(func(p): return p["nome"])), "titolo")

func _fine_tempo() -> void:
	var migliore: Array = []
	var best := -1
	for p in vivi():
		var x: int = pv(p) if s["scenario"] != 2 else int(p["uccisi_pg"])
		if x > best:
			best = x
			migliore = [p]
		elif x == best:
			migliore.append(p)
	s["vincitori"] = migliore.map(func(p): return p["pid"])
	s["fine"] = "vittoria" if umano() in migliore else "sconfitta"
	scrivi("Il tempo è scaduto. Vince %s." % " e ".join(migliore.map(func(p): return p["nome"])), "titolo")

# ------------------------------------------------------------ oggetti a terra e volo
func lascia(k: String, o: Dictionary) -> void:
	if not s.has("mucchi") or k == "":
		return
	if not s["mucchi"].has(k):
		s["mucchi"][k] = []
	var x: Dictionary = o.duplicate()
	x["attivo"] = false
	s["mucchi"][k].append(x)

func attivita_volo(p: Dictionary, dest: String) -> void:
	if not arcano.puo_volare(p):
		scrivi("%s non può volare." % p["nome"])
		return
	if not mappa.radure.has(dest):
		return
	var t := tessera(dest)
	var qui := tessera(p["dove"])
	if t != qui and not (t in mappa.tessere_adiacenti(qui)):
		scrivi("%s può volare solo verso una tessera vicina." % p["nome"])
		return
	var rr: Array = mappa.radure_tessera(t).filter(func(k): return tipo_radura(k) != "C")
	if rr.is_empty():
		return
	var arrivo: String = rr[rng.randi_range(0, rr.size() - 1)]
	p["entrato_da"] = p["dove"]
	p["dove"] = arrivo
	scrivi("%s vola fino a %s e atterra a %s." % [p["nome"], Dati.tessere[t]["nome"], nome_r(arrivo)], "bene")
	cambiato.emit()
	await pausa(0.35)
