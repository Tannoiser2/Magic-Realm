## Tesori e magia (scenario 4 e seguenti): siti con i tesori, saccheggio, rune, incantesimi,
## segnalini di colore, tessere incantate e oggetti con effetti speciali.
class_name Arcano
extends RefCounted

var r: Reame

const SITI_TESORI := {"hoard": [5, 4, []], "lair": [3, 4, []], "pit": [4, 4, []], "altar": [4, 0, ["II", "III"]],
	"shrine": [2, 2, ["I", "V"]], "den": [3, 2, []], "pool": [3, 6, []], "tower": [3, 1, ["IV", "VI"]],
	"vault": [5, 0, []], "tomb": [5, 0, []], "cairns": [1, 6, []], "statue": [1, 2, ["VII", "VII", "VIII"]],
	"spire": [3, 1, ["IV", "VI"]], "garden": [1, 2, ["II", "III", "VIII"]], "maze": [4, 1, []], "temple": [1, 3, ["I", "V"]]}
const TIPO_COLORE := {"I": "white", "II": "grey", "III": "gold", "IV": "purple", "V": "black"}
const NOMI_COLORE := {"white": "bianco", "grey": "grigio", "gold": "oro", "purple": "viola", "black": "nero", "any": "qualsiasi"}
const RUNE := ["impara", "impara", "impara", "risveglia", "maledizione", "niente"]
const VISIONE := ["scelta", "segnalini", "tesori", "percepisci", "scopri", "niente"]
const DURATE := {"Instant": "istantaneo", "Attack": "attacco", "Combat": "combattimento", "Day": "giorno", "Permanent": "permanente",
	"Phase": "fase", "Fly": "volo", "Move": "movimento"}
## incantesimi che si lanciano solo in combattimento contro altri
const SOLO_COMBATTIMENTO := ["vampata", "pietre", "fulmine", "ghiaccio", "inondazione", "crollo", "pace", "smussa", "esorcismo", "anima"]
const DEMONI := ["demone", "demone_alato", "imp", "vampiro", "succubo"]
const NON_MORTI := ["fantasma", "scheletro", "cavaliere_scheletro", "spettro", "ghoul", "scheletro_arciere"]

func _init(reame: Reame) -> void:
	r = reame

func attiva() -> bool:
	return r.s.get("scenario", 1) >= 4

# ------------------------------------------------------------ dati
static func tesoro(id: String) -> Dictionary:
	return Dati.tesori.get(id, {})

static func inc(id: String) -> Dictionary:
	return Dati.incantesimi.get(id, {})

static func e_tesoro(id: String) -> bool:
	return Dati.tesori.has(id)

func eff(p: Dictionary, chiave: String) -> Array:
	## valori dell'effetto `chiave` dei tesori attivi del personaggio
	var a := []
	for o in p["oggetti"]:
		if not o.get("attivo", false) or not e_tesoro(o["id"]):
			continue
		var e: Dictionary = tesoro(o["id"]).get("eff", {})
		if e.has(chiave):
			a.append(e[chiave])
	return a

func effetto(p: Dictionary, chiave: String) -> bool:
	return p.get("effetti", {}).has(chiave)

# ------------------------------------------------------------ preparazione
func prepara() -> void:
	var grandi := []
	var piccoli := []
	var twt := []
	for id in Dati.tesori:
		match tesoro(id)["taglia"]:
			"G": grandi.append(id)
			"P": piccoli.append(id)
			"W": twt.append(id)
	r.mescola(grandi)
	r.mescola(piccoli)
	var mazzi := {}
	for id in Dati.incantesimi:
		var t: String = inc(id)["tipo"]
		if not mazzi.has(t):
			mazzi[t] = []
		mazzi[t].append(id)
	for t in mazzi:
		r.mescola(mazzi[t])
	r.s["mazzi_inc"] = mazzi
	# dieci tesori grandi vanno sulla tabella dei Tesori nei tesori
	var tabella_twt: Array = grandi.slice(0, 10)
	grandi = grandi.slice(10)
	var per_siti: Array = grandi + twt
	r.mescola(per_siti)
	r.s["siti_tesori"] = {}
	for sito in SITI_TESORI:
		var cfg: Array = SITI_TESORI[sito]
		var carte := []
		for i in range(int(cfg[0])):
			if not per_siti.is_empty(): carte.append(per_siti.pop_back())
		for i in range(int(cfg[1])):
			if not piccoli.is_empty(): carte.append(piccoli.pop_back())
		var spells := []
		for t in cfg[2]:
			if not mazzi.get(t, []).is_empty():
				spells.append(mazzi[t].pop_back())
		r.s["siti_tesori"][sito] = {"carte": carte, "inc": spells, "aperto": not (sito in ["vault", "tomb"])}
	r.s["fuori_gioco"] = piccoli
	# luoghi dei Tesori nei tesori
	r.s["twt"] = {}
	var luoghi := []
	for id in twt:
		r.s["twt"][id] = {"carte": [], "inc": [], "dove": ""}
		if tesoro(id)["twt"] in ["luogo", "forziere"]:
			luoghi.append(id)
	var i := 0
	for x in tabella_twt:
		r.s["twt"][luoghi[i % luoghi.size()]]["carte"].append(x)
		i += 1
	var tipi := mazzi.keys()
	for id in luoghi:
		if tesoro(id)["twt"] != "luogo":
			continue
		var n := 3 if id == "w_mage_library" else (0 if id == "w_crypt_of_the_knight" else 1)
		for j in range(n):
			var t: String = tipi[r.rng.randi_range(0, tipi.size() - 1)]
			if not mazzi[t].is_empty():
				r.s["twt"][id]["inc"].append(mazzi[t].pop_back())
	# artefatti, libri e pergamene ricevono i loro incantesimi
	r.s["libri"] = {}
	for id in Dati.tesori:
		var tt: Array = tesoro(id).get("eff", {}).get("inc", [])
		if tt.is_empty():
			continue
		var l := []
		for t in tt:
			if not mazzi.get(t, []).is_empty():
				l.append(mazzi[t].pop_back())
		r.s["libri"][id] = l
	r.s["mucchi"] = {}

func incantesimi_iniziali(p: Dictionary) -> void:
	## i personaggi che conoscono la magia partono con i loro incantesimi (scelti tra quelli dei loro tipi)
	p["incantesimi"] = []
	p["effetti"] = {}
	p["meditato"] = -1
	var d: Dictionary = r.def_pg(p)
	var tipi := {}
	for c in d["chits"]:
		if c["tipo"] == "G":
			tipi[c["magia"]] = true
	var n: int = mini(tipi.size(), 4)
	if n <= 0:
		return
	var buoni := []
	var altri := []
	for id in Dati.incantesimi:
		var x := inc(id)
		if not tipi.has(x["tipo"]):
			continue
		if x["eff"] != "":
			buoni.append(id)
		else:
			altri.append(id)
	r.mescola(buoni)
	r.mescola(altri)
	# preferisce gli attacchi, poi gli altri incantesimi attivi
	buoni.sort_custom(func(a, b): return int(inc(a)["durata"] == "Attack") > int(inc(b)["durata"] == "Attack"))
	var lista: Array = buoni + altri
	for i in range(min(n, lista.size())):
		p["incantesimi"].append(lista[i])
	p["inc_iniziali"] = p["incantesimi"].duplicate()

# ------------------------------------------------------------ segnalini dei tesori (stivali, guanti)
func sincronizza(p: Dictionary) -> void:
	## i tesori attivi che valgono come segnalini d'azione diventano segnalini virtuali in coda
	var tenuti := []
	for c in p["chits"]:
		if not c.has("tes"):
			tenuti.append(c)
	for o in p["oggetti"]:
		if not o.get("attivo", false) or not e_tesoro(o["id"]):
			continue
		var ch = tesoro(o["id"]).get("eff", {}).get("chit")
		if ch is Array:
			tenuti.append({"tipo": ch[0], "forza": ch[1], "vel": int(ch[2]), "sforzi": 0, "stato": "a", "tes": o["id"]})
	p["chits"] = tenuti

# ------------------------------------------------------------ colori
func colori_tessera(t: int) -> Array:
	var st: Dictionary = r.s["tessere"][str(t)]
	if not st.get("incantata", false):
		return []
	match r.cat_tessera(t):
		"W", "F": return ["gold"]
		"M", "C": return ["purple"]
		"H":
			var rm: int = int(r.s.get("riga_mostri", 1))
			return ["gold"] if rm <= 2 else (["grey"] if rm <= 4 else ["purple"])
	return ["grey"]

func colore_settimana() -> String:
	var g: int = r.s["giorno"]
	var gm := (g - 1) % 28 + 1
	var mese := (g - 1) / 28 + 1
	match gm:
		7: return "white" if mese % 2 == 1 else "black"
		14: return "grey"
		21: return "purple"
		28: return "gold"
	return ""

func colori_radura(k: String) -> Array:
	var a := []
	if k == "":
		return a
	a.append_array(colori_tessera(r.tessera(k)))
	var cs := colore_settimana()
	if cs != "":
		a.append(cs)
	if r.abitazione_in(k) == "cappella":
		a.append("white")
	for q in r.vivi():
		if q["dove"] != k:
			continue
		for c in eff(q, "colore"):
			a.append(c)
	for o in r.s.get("mucchi", {}).get(k, []):
		var c = tesoro(o["id"]).get("eff", {}).get("colore")
		if c != null:
			a.append(c)
	for w in r.s.get("twt", {}):
		if r.s["twt"][w]["dove"] == k and tesoro(w).get("colore") != null:
			a.append(tesoro(w)["colore"])
	for m in r.s.get("mostri", {}).values():
		if m["dove"] == k and not m["morto"] and str(m["tipo"]).begins_with("anomalia"):
			var col := {"anomalia_grigia": ["grey"], "anomalia_oro": ["gold"], "anomalia_viola": ["purple"], "anomalia_prisma": ["grey", "gold", "purple"]}
			a.append_array(col.get(m["tipo"], []))
	var u := []
	for c in a:
		if not (c in u):
			u.append(c)
	return u

func chit_colore(p: Dictionary) -> Array:
	## indici dei segnalini magici incantati (segnalini di colore) disponibili
	var a := []
	for i in range(p["chits"].size()):
		var c: Dictionary = p["chits"][i]
		if c.get("colore", false) and c["stato"] == "a":
			a.append(i)
	return a

func colore_disponibile(p: Dictionary, col: String) -> Dictionary:
	## {"ok": bool, "chit": indice del segnalino di colore da consumare o -1}
	var rad := colori_radura(p["dove"])
	if col == "any" and not rad.is_empty():
		return {"ok": true, "chit": -1}
	if col in rad:
		return {"ok": true, "chit": -1}
	for i in chit_colore(p):
		var c: Dictionary = p["chits"][i]
		if col == "any" or TIPO_COLORE.get(c["magia"], "") == col:
			return {"ok": true, "chit": i}
	return {"ok": false, "chit": -1}

# ------------------------------------------------------------ fasi extra e tiri
func fasi_extra(p: Dictionary) -> Array:
	var a := []
	for f in eff(p, "fase"):
		match str(f):
			"grotta":
				if r.tipo_radura(p["dove"]) == "C": a.append("*")
			"HR", "T":
				if r.s["scenario"] >= 5: a.append(f)
			_:
				a.append(f)
	for e in p.get("effetti", {}):
		if str(e).begins_with("fase_"):
			a.append(str(e).substr(5))
	return a

func un_dado(p: Dictionary, contesto: String) -> bool:
	for u in eff(p, "undado"):
		if u == "tutto" or u == contesto:
			return true
	return false

func modifica_tiro(p: Dictionary, contesto: String) -> int:
	var m := 0
	for d in eff(p, "mod"):
		m += int(d.get("tutto", 0)) + int(d.get(contesto, 0))
	if effetto(p, "sfortuna"): m += 1
	if contesto == "cerca" and effetto(p, "sfortuna_cerca"): m += 1
	if contesto == "cerca":
		for mp in eff(p, "mappa"):
			var t := r.tessera(p["dove"])
			if mp == "R" and r.cat_tessera(t) == "R":
				m -= 1
			for x in r.s["tessere"][str(t)]["rossi"]:
				if str(Dati.segnalini[x].get("nome_base", "")) == mp:
					m -= 1
	if effetto(p, "fortuna"):
		p["effetti"].erase("fortuna")
		m -= 1
	return m

func puo_volare(p: Dictionary) -> bool:
	return not eff(p, "vola").is_empty() or effetto(p, "vola")

func limite_sforzo(p: Dictionary) -> int:
	var l := 2
	for x in eff(p, "sforzo"):
		l = max(l, int(x))
	return l

# ------------------------------------------------------------ saccheggio e rune
func nome_sito(sito: String) -> String:
	for id in Dati.segnalini:
		var c: Dictionary = Dati.segnalini[id]
		if c["tipo"] == "sito" and str(c.get("nome_base", "")).to_lower() == sito:
			return str(c["nome"]).rstrip(" 0123456789")
	return sito

func siti_qui(p: Dictionary) -> Array:
	## siti scoperti dal personaggio nella sua radura
	var a := []
	var t := r.tessera(p["dove"])
	var n := Mappa.numero_di(p["dove"])
	for x in r.s["tessere"][str(t)]["rossi"]:
		var c: Dictionary = Dati.segnalini[x]
		if c["tipo"] == "sito" and int(c["radura"]) == n and x in p["siti"]:
			a.append(str(c["nome_base"]).to_lower())
	return a

func fonti(p: Dictionary) -> Dictionary:
	## da dove si può saccheggiare o leggere rune in questa radura
	var sac := []
	var run := []
	if not attiva():
		return {"saccheggia": sac, "rune": run}
	var k: String = p["dove"]
	for sito in siti_qui(p):
		var st: Dictionary = r.s["siti_tesori"].get(sito, {})
		if st.is_empty():
			continue
		if not st["carte"].is_empty():
			sac.append({"id": "s:" + sito, "nome": "%s (%d carte)" % [nome_sito(sito), st["carte"].size()]})
		if not st["inc"].is_empty() and not _tutti_noti(p, st["inc"]):
			run.append({"id": "s:" + sito, "nome": nome_sito(sito)})
	if not r.s["mucchi"].get(k, []).is_empty():
		sac.append({"id": "m:" + k, "nome": "Oggetti abbandonati (%d)" % r.s["mucchi"][k].size()})
	for w in p.get("twt", []):
		var tw: Dictionary = r.s["twt"][w]
		if tw["dove"] != k:
			continue
		if not tw["carte"].is_empty():
			sac.append({"id": "w:" + w, "nome": "%s (%d carte)" % [tesoro(w)["nome"], tw["carte"].size()]})
		if not tw["inc"].is_empty() and not _tutti_noti(p, tw["inc"]):
			run.append({"id": "w:" + w, "nome": tesoro(w)["nome"]})
	for o in p["oggetti"]:
		if o.get("attivo", false) and r.s["libri"].has(o["id"]) and not _tutti_noti(p, r.s["libri"][o["id"]]):
			run.append({"id": "l:" + o["id"], "nome": tesoro(o["id"])["nome"]})
	return {"saccheggia": sac, "rune": run}

func _tutti_noti(p: Dictionary, l: Array) -> bool:
	for x in l:
		if not (x in p["incantesimi"]):
			return false
	return true

func _affatica_uno(p: Dictionary, motivo: String) -> bool:
	## affatica un segnalino con almeno un asterisco (il meno utile)
	var best := -1
	for i in range(p["chits"].size()):
		var c: Dictionary = p["chits"][i]
		if c["stato"] == "a" and int(c["sforzi"]) > 0 and not c.has("tes"):
			if best < 0 or int(c["sforzi"]) < int(p["chits"][best]["sforzi"]):
				best = i
	if best < 0:
		r.scrivi("%s non ha segnalini da affaticare per %s." % [p["nome"], motivo])
		return false
	p["chits"][best]["stato"] = "f"
	r.scrivi("%s affatica %s per %s." % [p["nome"], r.descr_chit(p["chits"][best]), motivo])
	return true

func _chit_tremendo(p: Dictionary) -> int:
	for i in range(p["chits"].size()):
		var c: Dictionary = p["chits"][i]
		if c["stato"] == "a" and c["tipo"] in ["M", "F"] and str(c.get("forza", "")) == "T":
			return i
	return -1

func _ha_chiave(p: Dictionary) -> bool:
	return not eff(p, "chiave").is_empty()

func _apri(p: Dictionary, cosa: String) -> bool:
	## Sotterraneo, Tomba e Forziere: servono le chiavi o un segnalino di forza Tremenda
	if _ha_chiave(p):
		r.scrivi("%s apre %s con le chiavi." % [p["nome"], cosa], "bene")
		return true
	var i := _chit_tremendo(p)
	if i >= 0:
		if not p["chits"][i].has("tes"):
			p["chits"][i]["stato"] = "f"
		r.scrivi("%s forza %s con la sua forza Tremenda." % [p["nome"], cosa], "bene")
		return true
	r.scrivi("%s non riesce ad aprire %s: servono le chiavi o un segnalino di forza Tremenda." % [p["nome"], cosa])
	return false

func saccheggia(p: Dictionary, fonte: String) -> void:
	var tipo := fonte.substr(0, 1)
	var id := fonte.substr(2)
	var pila: Array = []
	var nome := ""
	if tipo == "s":
		var st: Dictionary = r.s["siti_tesori"][id]
		nome = nome_sito(id)
		if not st["aperto"]:
			if not _apri(p, nome):
				return
			st["aperto"] = true
		if id == "cairns" and not _affatica_uno(p, "scavare tra i Tumuli"):
			return
		if id == "pit":
			if p.get("fossa", -1) != r.s["giorno"]:
				p["fossa"] = r.s["giorno"]
				r.scrivi("%s si cala nella Fossa: alla prossima ricerca potrà saccheggiarla." % p["nome"])
				return
			p.erase("fossa")
		pila = st["carte"]
	elif tipo == "m":
		pila = r.s["mucchi"][id]
		nome = "gli oggetti abbandonati"
	elif tipo == "w":
		pila = r.s["twt"][id]["carte"]
		nome = tesoro(id)["nome"]
	if pila.is_empty():
		r.scrivi("Non c'è più nulla da prendere in %s." % nome)
		return
	var t := r.tiro(p, "saccheggia")
	var n: int = t[0]
	if n > pila.size():
		r.scrivi("%s saccheggia %s (dado %d): non trova nulla." % [p["nome"], nome, n])
		if tipo == "s" and id == "maze":
			p["labirinto"] = true
		return
	var x = pila[n - 1]
	pila.remove_at(n - 1)
	if tipo == "m":
		var o: Dictionary = x
		o["attivo"] = false
		p["oggetti"].append(o)
		r.scrivi("%s raccoglie %s (dado %d)." % [p["nome"], Dati.nome_arma(o["id"]), n], "bene")
		_attiva_nuovo(p, o)
	else:
		r.scrivi("%s saccheggia %s (dado %d)." % [p["nome"], nome, n], "bene")
		_ricevi_carta(p, str(x), pila, tipo == "s" and id == "pool")
	if tipo == "s" and id == "maze":
		p["labirinto"] = true
		r.scrivi("%s si perde nel Labirinto: il prossimo movimento lo porterà in una radura a caso della tessera." % p["nome"], "male")
	sincronizza(p)
	r.cambiato.emit()

func _ricevi_carta(p: Dictionary, id: String, pila: Array, stagno: bool) -> void:
	var d := tesoro(id)
	if d.get("taglia", "") == "W":
		match d["twt"]:
			"luogo":
				pila.append(id)
				r.s["twt"][id]["dove"] = p["dove"]
				if not (id in p.get("twt", [])):
					p["twt"].append(id)
				r.scrivi("%s scopre un luogo nascosto: %s!" % [p["nome"], d["nome"]], "bene")
			"forziere":
				if _apri(p, "il Forziere"):
					var dentro: Array = r.s["twt"][id]["carte"]
					r.scrivi("Nel Forziere ci sono %d tesori." % dentro.size(), "bene")
					for c in dentro:
						_dai_tesoro(p, str(c))
					r.s["twt"][id]["carte"] = []
				else:
					pila.append(id)
			"maledizione":
				r.scrivi("%s trova %s: una maledizione lo colpisce!" % [p["nome"], d["nome"]], "male")
				maledici(p, "maledizione")
			"ipnosi":
				r.scrivi("%s trova %s: un'ipnosi lo colpisce!" % [p["nome"], d["nome"]], "male")
				maledici(p, "ipnosi")
		return
	if stagno:
		_affatica_uno(p, "immergersi nello Stagno")
	_dai_tesoro(p, id)

func _dai_tesoro(p: Dictionary, id: String) -> void:
	var o := {"id": id, "attivo": false, "allerta": false, "danno": 0}
	p["oggetti"].append(o)
	var d := tesoro(id)
	r.scrivi("%s ottiene %s%s." % [p["nome"], d["nome"], " (grande tesoro)" if d.get("grande", false) else ""], "bene")
	_attiva_nuovo(p, o)

func _attiva_nuovo(p: Dictionary, o: Dictionary) -> void:
	if e_tesoro(o["id"]):
		o["attivo"] = true
	elif Dati.oggetti["armature"].has(o["id"]):
		var gia := false
		for x in p["oggetti"]:
			if x != o and x["id"] == o["id"] and x["attivo"]:
				gia = true
		o["attivo"] = not gia
	sincronizza(p)

func maledici(p: Dictionary, che: String) -> void:
	if not eff(p, "pentagramma").is_empty():
		r.scrivi("Il Pentagramma protegge %s." % p["nome"], "bene")
		return
	if che == "maledizione" and p["pg"] == "negromante":
		r.scrivi("%s è immun{oa} alle maledizioni." % p["nome"])
		return
	var lista: Array = Reame.MALEDIZIONI if che == "maledizione" else Reame.IPNOSI
	var n: String = lista[r.d6() - 1]
	if n in p["maledizioni"]:
		r.scrivi("%s subisce di nuovo «%s»." % [p["nome"], n])
		return
	p["maledizioni"].append(n)
	r.scrivi("%s è colpit{oa} da «%s»." % [p["nome"], n], "male")
	if n == "Avvizzimento":
		for c in p["chits"]:
			if c["stato"] == "a" and c["sforzi"] > 0:
				c["stato"] = "f"

func _pila_inc(fonte: String) -> Array:
	var tipo := fonte.substr(0, 1)
	var id := fonte.substr(2)
	match tipo:
		"s": return r.s["siti_tesori"][id]["inc"]
		"w": return r.s["twt"][id]["inc"]
		"l": return r.s["libri"].get(id, [])
	return []

func impara(p: Dictionary, id: String) -> void:
	if id in p["incantesimi"]:
		return
	p["incantesimi"].append(id)
	var lanc := lanciabile_in_teoria(p, id)
	r.scrivi("%s impara l'incantesimo %s%s." % [p["nome"], inc(id)["nome"], "" if lanc else " (non ha il segnalino magico per lanciarlo)"], "bene")

func rune(p: Dictionary, fonte: String) -> void:
	var pila := _pila_inc(fonte)
	if pila.is_empty():
		r.scrivi("Qui non ci sono rune da leggere.")
		return
	var t := r.tiro(p, "rune")
	var ris: String = RUNE[t[0] - 1]
	var nuovo := ""
	for x in pila:
		if not (x in p["incantesimi"]):
			nuovo = x
			break
	match ris:
		"impara":
			if nuovo == "":
				r.scrivi("%s legge le rune (dado %d) ma conosce già tutto." % [p["nome"], t[0]])
			else:
				r.scrivi("%s legge le rune (dado %d): impara e risveglia l'incantesimo." % [p["nome"], t[0]])
				impara(p, nuovo)
				if fonte.begins_with("s:") or fonte.begins_with("w:"):
					pila.erase(nuovo)
					pila.append(nuovo)
		"risveglia":
			r.scrivi("%s legge le rune (dado %d): risveglia %s ma non lo impara." % [p["nome"], t[0], inc(nuovo)["nome"] if nuovo != "" else "l'incantesimo"])
		"maledizione":
			r.scrivi("%s legge le rune (dado %d): Maledizione!" % [p["nome"], t[0]], "male")
			maledici(p, "maledizione")
		_:
			r.scrivi("%s legge le rune (dado %d): niente." % [p["nome"], t[0]])
	r.cambiato.emit()

func visione_magica(p: Dictionary) -> void:
	## il Re Stregone (e chi ne ha la capacità) cerca con la Visione magica
	var t := r.tiro(p, "cerca")
	var ris: String = VISIONE[t[0] - 1]
	r.scrivi("%s usa la Visione magica (dado %d)." % [p["nome"], t[0]])
	var f := fonti(p)
	match ris:
		"scelta", "tesori", "segnalini":
			if not f["saccheggia"].is_empty():
				var fonte: String = f["saccheggia"][0]["id"]
				var pila: Array = []
				if fonte.begins_with("s:"):
					var st: Dictionary = r.s["siti_tesori"][fonte.substr(2)]
					if st["aperto"]: pila = st["carte"]
				elif fonte.begins_with("m:"):
					pila = r.s["mucchi"][fonte.substr(2)]
				if not pila.is_empty():
					var x = pila.pop_front()
					if x is Dictionary:
						p["oggetti"].append(x)
						_attiva_nuovo(p, x)
					else:
						_ricevi_carta(p, str(x), pila, false)
					sincronizza(p)
					return
			if ris == "scelta":
				r.scopri_segnalini(p, p["dove"])
			else:
				r.scrivi("Non c'è nulla da prendere qui.")
		"percepisci":
			for x in f["rune"]:
				for id in _pila_inc(x["id"]):
					if not (id in p["incantesimi"]):
						impara(p, id)
						return
			r.scrivi("Nessun incantesimo da percepire qui.")
		"scopri":
			r.scopri_segnalini(p, p["dove"])
		_:
			r.scrivi("La Visione non rivela nulla.")

# ------------------------------------------------------------ incantare (attività E)
func opzioni_incanto(p: Dictionary) -> Array:
	var a := []
	for i in range(p["chits"].size()):
		var c: Dictionary = p["chits"][i]
		if c["tipo"] == "G" and c["stato"] == "a" and not c.get("colore", false) and TIPO_COLORE.has(c["magia"]):
			a.append({"tipo": "chit", "i": i, "testo": "Incanta %s: diventa un segnalino %s" % [r.descr_chit(c), NOMI_COLORE[TIPO_COLORE[c["magia"]]]]})
	var t := r.tessera(p["dove"])
	var inc_t: bool = r.s["tessere"][str(t)].get("incantata", false)
	for i in range(p["chits"].size()):
		var c: Dictionary = p["chits"][i]
		if c["tipo"] == "G" and c["stato"] == "a" and not c.get("colore", false) and TIPO_COLORE.has(c["magia"]):
			var col: String = TIPO_COLORE[c["magia"]]
			var ok := col in colori_radura(p["dove"])
			if not ok:
				for j in chit_colore(p):
					if j != i and TIPO_COLORE.get(p["chits"][j]["magia"], "") == col:
						ok = true
			if ok:
				a.append({"tipo": "tessera", "i": i, "testo": "%s la tessera %s con %s" % ["Disincanta" if inc_t else "Incanta", Dati.tessere[t]["nome"], r.descr_chit(c)]})
				break
	return a

func attivita_incanto(p: Dictionary) -> void:
	if p.get("meditato", -1) != r.s["giorno"]:
		p["meditato"] = r.s["giorno"]
		r.scrivi("%s medita e si prepara a incantare." % p["nome"])
		return
	var opz := opzioni_incanto(p)
	if opz.is_empty():
		r.scrivi("%s non ha nulla da incantare." % p["nome"])
		return
	var sc = await r.decidi(p, "incanto", {"opzioni": opz})
	var i: int = int(sc) if (sc is int or sc is float) and int(sc) >= 0 and int(sc) < opz.size() else 0
	var o: Dictionary = opz[i]
	var c: Dictionary = p["chits"][o["i"]]
	if o["tipo"] == "chit":
		c["colore"] = true
		r.scrivi("%s incanta %s: ora è un segnalino di colore %s." % [p["nome"], r.descr_chit(c), NOMI_COLORE[TIPO_COLORE[c["magia"]]]], "bene")
	else:
		var col: String = TIPO_COLORE[c["magia"]]
		if not (col in colori_radura(p["dove"])):
			for j in chit_colore(p):
				if TIPO_COLORE.get(p["chits"][j]["magia"], "") == col:
					p["chits"][j]["colore"] = false
					p["chits"][j]["stato"] = "f"
					break
		c["stato"] = "f"
		var t := r.tessera(p["dove"])
		var st: Dictionary = r.s["tessere"][str(t)]
		st["incantata"] = not st.get("incantata", false)
		r.scrivi("%s %s la tessera %s." % [p["nome"], "incanta" if st["incantata"] else "disincanta", Dati.tessere[t]["nome"]], "bene")
	r.cambiato.emit()

# ------------------------------------------------------------ lancio degli incantesimi
func lanciabile_in_teoria(p: Dictionary, id: String) -> bool:
	var t: String = inc(id)["tipo"]
	for c in p["chits"]:
		if c["tipo"] == "G" and c["magia"] == t:
			return true
	for x in eff(p, "anello"):
		if x == t:
			return true
	return false

func mezzi(p: Dictionary, id: String, vel_max := 99, usati := {}) -> Array:
	## modi di lanciare l'incantesimo: segnalini magici del tipo giusto o anelli
	var t: String = inc(id)["tipo"]
	var a := []
	for i in range(p["chits"].size()):
		var c: Dictionary = p["chits"][i]
		if c["tipo"] == "G" and c["magia"] == t and c["stato"] == "a" and not c.get("colore", false) and int(c["vel"]) <= vel_max and not usati.has(i):
			a.append({"chit": i, "testo": r.descr_chit(c)})
	for o in p["oggetti"]:
		if o.get("attivo", false) and e_tesoro(o["id"]) and str(tesoro(o["id"]).get("eff", {}).get("anello", "")) == t:
			if p.get("anelli", {}).get(o["id"], -1) != r.s["giorno"]:
				a.append({"anello": o["id"], "testo": tesoro(o["id"])["nome"]})
	return a

func lanciabili(p: Dictionary, in_combattimento: bool, vel_max := 99, usati := {}) -> Array:
	var a := []
	if not attiva() or "Svuotato" in p["maledizioni"]:
		return a
	for id in p.get("incantesimi", []):
		var x := inc(id)
		if x.is_empty() or x["eff"] == "":
			continue
		if not in_combattimento and x["eff"] in SOLO_COMBATTIMENTO:
			continue
		if not _condizione(p, x["eff"]):
			continue
		var col := colore_disponibile(p, x["colore"])
		if not col["ok"]:
			continue
		var mz := mezzi(p, id, vel_max, usati)
		if mz.is_empty():
			continue
		a.append({"inc": id, "mezzi": mz, "colore": col["chit"]})
	return a

func _condizione(p: Dictionary, e: String) -> bool:
	var tr := r.tipo_radura(p["dove"])
	match e:
		"fulmine": return tr == "M"
		"crollo", "fase_*": return tr == "C"
		"inondazione": return tr != "M"
		"persuasione": return r.s["scenario"] >= 5
	return true

func paga(p: Dictionary, id: String, mezzo: Dictionary, chit_colore_i: int) -> int:
	## lega il segnalino all'incantesimo e consuma il colore; restituisce l'indice del segnalino legato (-1 se anello)
	if chit_colore_i >= 0 and chit_colore_i < p["chits"].size():
		var cc: Dictionary = p["chits"][chit_colore_i]
		cc["colore"] = false
		cc["stato"] = "f"
	if mezzo.has("anello"):
		if not p.has("anelli"):
			p["anelli"] = {}
		p["anelli"][mezzo["anello"]] = r.s["giorno"]
		return -1
	var ci: int = int(mezzo["chit"])
	p["chits"][ci]["stato"] = "s"
	p["chits"][ci]["legato"] = id
	return ci

func sciogli(p: Dictionary, id: String) -> void:
	## l'incantesimo finisce: il segnalino legato si affatica
	for c in p["chits"]:
		if c.get("legato", "") == id:
			c.erase("legato")
			c["stato"] = "f"

func applica_effetto_giorno(p: Dictionary, bersaglio: Dictionary, id: String) -> void:
	## effetti che durano fino alla sera successiva (o permanenti)
	var x := inc(id)
	var e: String = x["eff"]
	if not bersaglio.has("effetti"):
		bersaglio["effetti"] = {}
	var fine: int = 9999 if x["durata"] == "Permanent" else int(r.s["giorno"]) + 1
	if e == "fiuto":
		bersaglio["effetti"]["fiuto"] = fine
	else:
		bersaglio["effetti"][e] = fine
	bersaglio["effetti_inc"] = bersaglio.get("effetti_inc", {})
	bersaglio["effetti_inc"][e] = {"inc": id, "da": p["pid"]}
	r.scrivi("%s lancia %s su %s." % [p["nome"], x["nome"], "se stess{oa}" if bersaglio == p else bersaglio["nome"]], "bene")

func lancia_istantaneo(p: Dictionary, q: Dictionary, id: String) -> void:
	var x := inc(id)
	r.scrivi("%s lancia %s%s." % [p["nome"], x["nome"], "" if q == p else " su " + q["nome"]], "bene")
	match x["eff"]:
		"guarigione":
			for c in q["chits"]:
				if c["stato"] in ["f", "w"] and not c.has("legato"):
					c["stato"] = "a"
			for o in q["oggetti"]:
				o["danno"] = 0
			r.scrivi("%s è guarit{oa} del tutto." % q["nome"], "bene")
		"benedizione":
			q["fama"] += 5
			r.scrivi("%s guadagna 5 punti Fama." % q["nome"], "bene")
		"rimedio":
			if not q["maledizioni"].is_empty():
				var n: String = q["maledizioni"].pop_back()
				r.scrivi("%s è liberat{oa} da «%s»." % [q["nome"], n], "bene")
		"dissolvi":
			if not q.get("effetti", {}).is_empty():
				var k = q["effetti"].keys()[0]
				q["effetti"].erase(k)
				r.scrivi("Un incantesimo su %s si spezza." % q["nome"])
		"uccello":
			var t := r.rng.randi_range(0, 39)
			q["indizi"][str(t)] = true
			r.sbircia(q, t)
		"maledizione":
			maledici(q, "maledizione")
		"ipnosi":
			maledici(q, "ipnosi")
		"abisso":
			var t := r.d6()
			r.scrivi("Il Potere dell'Abisso colpisce %s: %s." % [q["nome"], Reame.ABISSO[t - 1]], "male")
			match t:
				1, 2:
					if not q.get("protetto_magia", false):
						for c in q["chits"]:
							if c["stato"] == "a":
								c["stato"] = "w"
								break
				3:
					for c in q["chits"]:
						if c["stato"] == "a" and c.get("forza", "") in ["L", "M"]:
							c["stato"] = "w"
				4:
					for c in q["chits"]:
						if c["stato"] == "a" and c["sforzi"] > 0:
							c["stato"] = "w"
				5:
					for c in q["chits"]:
						if c["tipo"] == "G" and c["stato"] == "a":
							c["stato"] = "f"
				6:
					for o in q["oggetti"]:
						if Dati.oggetti["armature"].has(o["id"]):
							o["danno"] = 1

func sera_incantesimi(p: Dictionary) -> void:
	## alla sera, chi non combatte può lanciare incantesimi su di sé
	var l := lanciabili(p, false)
	if l.is_empty():
		return
	var sc = await r.decidi(p, "incantesimo_sera", {"lista": l})
	if not (sc is Dictionary) or not sc.has("inc"):
		return
	var scelto: Dictionary = {}
	for x in l:
		if x["inc"] == sc["inc"]:
			scelto = x
	if scelto.is_empty():
		return
	var mz: Dictionary = scelto["mezzi"][clampi(int(sc.get("mezzo", 0)), 0, scelto["mezzi"].size() - 1)]
	var id: String = scelto["inc"]
	var x := inc(id)
	paga(p, id, mz, int(scelto["colore"]))
	if x["durata"] in ["Instant"]:
		lancia_istantaneo(p, p, id)
		sciogli(p, id)
	else:
		applica_effetto_giorno(p, p, id)
	r.cambiato.emit()

func scadenze() -> void:
	## a mezzanotte finiscono gli effetti scaduti e si liberano i segnalini legati
	for p in r.vivi():
		var ef: Dictionary = p.get("effetti", {})
		for e in ef.keys():
			if int(ef[e]) <= int(r.s["giorno"]):
				ef.erase(e)
				var info: Dictionary = p.get("effetti_inc", {}).get(e, {})
				if not info.is_empty():
					var caster := r.P(info["da"])
					if not caster.is_empty():
						sciogli(caster, info["inc"])
					p["effetti_inc"].erase(e)

# ------------------------------------------------------------ oggetti monouso
func usa(p: Dictionary, id: String) -> bool:
	var o := {}
	for x in p["oggetti"]:
		if x["id"] == id:
			o = x
	if o.is_empty():
		return false
	match str(tesoro(id).get("eff", {}).get("monouso", "")):
		"amuleto":
			if p["maledizioni"].is_empty():
				return false
			var n: String = p["maledizioni"].pop_back()
			r.scrivi("%s usa l'Amuleto e si libera da «%s»." % [p["nome"], n], "bene")
		"ripara":
			var fatto := false
			for x in p["oggetti"]:
				if int(x.get("danno", 0)) > 0:
					x["danno"] = 0
					fatto = true
					r.scrivi("%s ripara %s." % [p["nome"], Dati.nome_arma(x["id"])], "bene")
					break
			if not fatto:
				return false
		_:
			return false
	p["oggetti"].erase(o)
	r.cambiato.emit()
	return true

# ------------------------------------------------------------ punteggio
func pv_extra(p: Dictionary) -> int:
	var tot := 0
	for o in p["oggetti"]:
		if e_tesoro(o["id"]) and tesoro(o["id"]).get("grande", false):
			tot += 1
	var appresi := 0
	for id in p.get("incantesimi", []):
		if not (id in p.get("inc_iniziali", [])) and lanciabile_in_teoria(p, id):
			appresi += 1
	tot += appresi / 2
	tot += p.get("twt", []).size()
	return tot

func fama_tesori(p: Dictionary) -> int:
	var f := 0
	for o in p["oggetti"]:
		if e_tesoro(o["id"]):
			f += int(tesoro(o["id"])["fama"])
	return f

func noto_tesori(p: Dictionary) -> int:
	var f := 0
	for o in p["oggetti"]:
		if e_tesoro(o["id"]):
			f += int(tesoro(o["id"])["noto"])
	return f

# ------------------------------------------------------------ descrizioni per la scheda
static func descrivi_tesoro(id: String) -> String:
	var d := tesoro(id)
	if d.is_empty():
		return ""
	var righe := []
	var tipo := "Grande tesoro" if d.get("grande", false) else ("Tesoro grande" if d["taglia"] == "G" else "Tesoro piccolo")
	righe.append("%s · peso %s · oro %d" % [tipo, Dati.NOMI_PESO.get(str(d["peso"]), "-"), int(d["oro"])])
	var fn := []
	if int(d["fama"]) != 0: fn.append("fama %d" % int(d["fama"]))
	if int(d["noto"]) != 0: fn.append("notorietà %d" % int(d["noto"]))
	if d.get("fama_cond") != null: fn.append("fama %d se venduto ai nativi" % int(d["fama_cond"][0]))
	if not fn.is_empty(): righe.append(", ".join(fn).capitalize().substr(0, 1) + ", ".join(fn).substr(1))
	var e: Dictionary = d.get("eff", {})
	var nomi_fase := {"S": "RICERCA", "H": "NASCONDERSI", "A": "ALLERTA", "R": "RIPOSO", "E": "INCANTO", "T": "COMMERCIO", "HR": "INGAGGIO", "*": "qualsiasi attività"}
	var nomi_tab := {"tutto": "tutte le tabelle", "cerca": "le tabelle di ricerca", "nascondi": "nascondersi", "saccheggia": "il Saccheggio", "rune": "la Lettura delle rune"}
	if e.has("fase"):
		if e["fase"] == "grotta":
			righe.append("Una fase in più quando inizi il turno in una grotta.")
		else:
			righe.append("Una fase in più ogni giorno: %s." % nomi_fase.get(e["fase"], e["fase"]))
	if e.has("chit"):
		righe.append("Vale come segnalino %s %s%d (non si affatica e non si ferisce)." % ["Movimento" if e["chit"][0] == "M" else "Combattimento", e["chit"][1], int(e["chit"][2])])
	if e.has("undado"):
		righe.append("Tiri un solo dado per %s." % nomi_tab.get(e["undado"], e["undado"]))
	if e.has("mod"):
		for k in e["mod"]:
			righe.append("%+d ai tiri su %s." % [int(e["mod"][k]), {"tutto": "tutte le tabelle", "cerca": "le tabelle di ricerca", "rune": "la Lettura delle rune", "missile": "la tabella dei Proiettili"}.get(k, k)])
	if e.has("mappa"):
		righe.append("-1 alle ricerche nelle tessere con %s." % ("Rovine" if e["mappa"] == "R" else {"City": "la Città Perduta", "Castle": "il Castello Perduto", "Palace": "il Palazzo Perduto", "Fortress": "la Fortezza Perduta"}[e["mappa"]]))
	if e.has("colore"):
		righe.append("Fonte di magia %s nella radura in cui si trova." % NOMI_COLORE[e["colore"]])
	if e.has("inc"):
		righe.append("Contiene %d incantesim%s (tipo %s): si imparano con la Lettura delle rune." % [e["inc"].size(), "o" if e["inc"].size() == 1 else "i", ", ".join(e["inc"])])
	if e.has("anello"):
		righe.append("Una volta al giorno vale come segnalino Magia %s (velocità 0) per lanciare un incantesimo." % e["anello"])
	if e.has("para"):
		righe.append("Para i colpi %s; si distrugge quando viene colpito." % {"thrust": "di affondo", "swing": "di fendente", "smash": "dall'alto"}[e["para"]])
	if e.has("sforzo"):
		righe.append("Puoi giocare fino a %s asterischi di sforzo per round." % ("qualsiasi numero di" if int(e["sforzo"]) >= 9 else str(e["sforzo"])))
	if e.has("vola"):
		righe.append("Permette di VOLARE verso una tessera vicina (si atterra in una radura a caso).")
	if e.has("pentagramma"):
		righe.append("Immune a maledizioni e ipnosi.")
	if e.has("santo"):
		righe.append("Demoni, imp, succubi e vampiri non possono attaccarti.")
	if e.has("stella"):
		righe.append("La tua arma ha una stella di affilatura in più.")
	if e.has("chiave"):
		righe.append("Apre il Sotterraneo, la Tomba e il Forziere.")
	if e.has("riposo"):
		righe.append({"tutti": "Quando riposi recuperi tutti i segnalini affaticati.", "ferite": "Quando riposi curi anche le ferite.", "doppio": "Ogni riposo vale doppio."}[e["riposo"]])
	match str(e.get("monouso", "")):
		"amuleto": righe.append("Monouso (clic sulla carta): toglie una maledizione o un'ipnosi.")
		"ripara": righe.append("Monouso (clic sulla carta): ripara un'armatura danneggiata.")
		"luce": righe.append("Monouso in combattimento: placa tutti i mostri della radura.")
		"lampo": righe.append("Monouso.")
	if e.has("testo"):
		righe.append(e["testo"])
	if righe.size() == 2 or (righe.size() == 1):
		righe.append("Effetto speciale non ancora gestito: conta per il suo valore.")
	return "\n".join(righe)

static func descrivi_inc(id: String) -> String:
	var x := inc(id)
	var t := "Tipo %s · colore %s · %s\n%s" % [x["tipo"], NOMI_COLORE.get(x["colore"], x["colore"]), DURATE.get(x["durata"], x["durata"]), x["testo"]]
	if x["eff"] == "":
		t += "\n(Non ancora lanciabile in questa versione.)"
	return t
