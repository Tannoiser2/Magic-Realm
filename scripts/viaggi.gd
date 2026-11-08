## Viaggiatori e Punti Vittoria assegnati (scenario 6, il gioco completo).
## Nomadi, missioni, compiti e visitatori; le campagne restano sui loro riquadri.
class_name Viaggi
extends RefCounted

var r: Reame

const CATEGORIE := ["grandi", "inc", "fama", "noto", "oro"]
const NOMI_CAT := {"grandi": "Grandi tesori", "inc": "Incantesimi", "fama": "Fama", "noto": "Notorietà", "oro": "Oro"}
const UNITA := {"grandi": 1, "inc": 2, "fama": 10, "noto": 20, "oro": 30}
const TIPI := {"N": "Nomade", "M": "Missione", "T": "Compito", "V": "Visitatore", "C": "Campagna"}

func _init(reame: Reame) -> void:
	r = reame

static func v(id: String) -> Dictionary:
	return Dati.viaggiatori.get(id, {})

func attivi() -> bool:
	return r.s.get("scenario", 1) >= 6

# ------------------------------------------------------------ preparazione
func prepara() -> void:
	var ids: Array = Dati.viaggiatori.keys()
	r.mescola(ids)
	var box := []
	for sito in Arcano.SITI_TESORI:
		box.append("s:" + sito)
	for gid in Dati.nativi["gruppi"]:
		box.append("n:" + gid)
	r.s["viaggi"] = {}
	for i in range(ids.size()):
		r.s["viaggi"][ids[i]] = {"box": box[i % box.size()], "dove": "", "su": false, "chi": ""}
	# i visitatori vendono tesori e incantesimi
	var piccoli: Array = r.s.get("fuori_gioco", [])
	var mazzi: Dictionary = r.s.get("mazzi_inc", {})
	r.s["visitatori"] = {}
	var cfg := {"scholar": [3, 0], "merchant": [5, 0], "crone": [0, 2], "shaman": [0, 2], "warlock": [0, 2], "priest": [0, 2]}
	var tipi: Array = mazzi.keys()
	for id in cfg:
		var b := {"tesori": [], "inc": [], "oggetti": []}
		for i in range(int(cfg[id][0])):
			if not piccoli.is_empty():
				b["tesori"].append(piccoli.pop_back())
		for i in range(int(cfg[id][1])):
			var t: String = tipi[r.rng.randi_range(0, tipi.size() - 1)]
			if not mazzi[t].is_empty():
				b["inc"].append(mazzi[t].pop_back())
		r.s["visitatori"][id] = b
	for p in r.s["pg"]:
		assegna_pv_ia(p)

func assegna_pv_ia(p: Dictionary) -> void:
	var magico := int(Dati.personaggi[p["pg"]].get("magia", 0)) > 0
	p["vp"] = {"grandi": 2, "inc": 3, "fama": 3, "noto": 2, "oro": 2} if magico else {"grandi": 2, "inc": 0, "fama": 4, "noto": 4, "oro": 2}

# ------------------------------------------------------------ viaggiatori sulla mappa
func rilascia(box: String, k: String) -> void:
	if not attivi():
		return
	for id in r.s["viaggi"]:
		var x: Dictionary = r.s["viaggi"][id]
		if x["box"] == box and x["dove"] == "" and x["chi"] == "":
			x["dove"] = k
			x["box"] = ""
			r.scrivi("Un viaggiatore lascia il suo riquadro e compare a %s." % r.nome_r(k), "mostri")

func qui(k: String, su := true) -> Array:
	var a := []
	for id in r.s.get("viaggi", {}):
		var x: Dictionary = r.s["viaggi"][id]
		if x["dove"] == k and x["chi"] == "" and (x["su"] or not su):
			a.append(id)
	return a

func fine_turno(p: Dictionary) -> void:
	if not attivi():
		return
	var t := r.tessera(p["dove"])
	for id in r.s["viaggi"]:
		var x: Dictionary = r.s["viaggi"][id]
		if x["dove"] != "" and not x["su"] and r.tessera(x["dove"]) == t:
			x["su"] = true
			r.scrivi("Si rivela un viaggiatore a %s: %s (%s)." % [r.nome_r(x["dove"]), v(id)["nome"], TIPI[v(id)["tipo"]]], "mostri")
	# missioni e compiti si prendono pagando notorietà o fama
	for id in qui(p["dove"]):
		var d := v(id)
		if d["tipo"] == "M" and not (id in p.get("presi", [])) and int(p["noto"]) >= 10:
			if await r.decidi(p, "viaggiatore", {"id": id, "testo": "Prendere la missione «%s» per 10 punti Notorietà? Portala a destinazione entro la fine del mese." % d["nome"]}):
				_prendi_missione(p, id)
		elif d["tipo"] == "T" and not (id in p.get("presi", [])) and int(p["fama"]) >= 5 and p.get("compito", {}).is_empty():
			if await r.decidi(p, "viaggiatore", {"id": id, "testo": "Prendere il compito «%s» per 5 punti Fama? Visita le radure di quattro siti entro la fine del mese." % d["nome"]}):
				_prendi_compito(p, id)

func _prendi_missione(p: Dictionary, id: String) -> void:
	var d := v(id)
	var dw: String = d["eff"]["dest"]
	if r.abitazione_in(p["dove"]) == dw:
		dw = d["eff"]["alt"]
	if not r.s["abitazioni"].has(dw):
		r.scrivi("La destinazione della missione non è ancora sulla mappa.")
		return
	var dest: String = r.s["abitazioni"][dw]
	var dist := r.ia._distanza(p, p["dove"], dest)
	var oro: int = mini(30, 2 * maxi(1, dist))
	p["noto"] -= 10
	p["presi"] = p.get("presi", []) + [id]
	p["missioni_v"] = p.get("missioni_v", []) + [{"id": id, "dest": dest, "oro": oro}]
	r.s["viaggi"][id]["chi"] = p["pid"]
	r.s["viaggi"][id]["dove"] = ""
	r.scrivi("%s prende la missione %s: portarla a %s (%d oro)." % [p["nome"], d["nome"], Dati.ABITAZIONI[dw], oro], "bene")

func _prendi_compito(p: Dictionary, id: String) -> void:
	p["fama"] -= 5
	p["presi"] = p.get("presi", []) + [id]
	p["compito"] = {"id": id, "visti": []}
	r.s["viaggi"][id]["chi"] = p["pid"]
	r.s["viaggi"][id]["dove"] = ""
	r.scrivi("%s prende il compito %s." % [p["nome"], v(id)["nome"]], "bene")

func fine_fase(p: Dictionary) -> void:
	if not attivi():
		return
	for m in p.get("missioni_v", []).duplicate():
		if p["dove"] == m["dest"]:
			p["missioni_v"].erase(m)
			p["noto"] += 10
			p["oro"] += int(m["oro"])
			r.s["viaggi"][m["id"]]["chi"] = ""
			r.s["viaggi"][m["id"]]["dove"] = p["dove"]
			r.scrivi("%s completa la missione %s: riprende 10 Notorietà e guadagna %d oro." % [p["nome"], v(m["id"])["nome"], int(m["oro"])], "bene")
			deduci(p, 1)
	var c: Dictionary = p.get("compito", {})
	if not c.is_empty() and not c.get("fatto", false):
		for sito in _siti_della_radura(p["dove"]):
			if sito in v(c["id"])["eff"]["siti"] and not (sito in c["visti"]):
				c["visti"].append(sito)
				r.scrivi("%s raggiunge %s per il compito %s (%d/4)." % [p["nome"], r.arcano.nome_sito(sito), v(c["id"])["nome"], c["visti"].size()])
		if c["visti"].size() >= 4:
			c["fatto"] = true
			p["fama"] += 5
			r.scrivi("%s completa il compito %s: riprende 5 Fama e al prossimo incontro con i nativi otterrà il prezzo migliore." % [p["nome"], v(c["id"])["nome"]], "bene")
			deduci(p, 1)

func _siti_della_radura(k: String) -> Array:
	var a := []
	var t := r.tessera(k)
	var n := Mappa.numero_di(k)
	for x in r.s["tessere"][str(t)]["rossi"]:
		var c: Dictionary = Dati.segnalini[x]
		if c["tipo"] == "sito" and int(c["radura"]) == n:
			a.append(str(c["nome_base"]).to_lower())
	return a

func usa_dono(p: Dictionary) -> bool:
	## un compito completato vale come «Dono» al prossimo tiro sugli incontri
	var c: Dictionary = p.get("compito", {})
	if c.get("fatto", false):
		r.s["viaggi"][c["id"]]["chi"] = ""
		r.s["viaggi"][c["id"]]["dove"] = p["dove"]
		p["compito"] = {}
		r.scrivi("%s usa il compito completato: ottiene il prezzo migliore." % p["nome"], "bene")
		return true
	return false

# ------------------------------------------------------------ nomadi
func sera(p: Dictionary) -> void:
	if not attivi():
		return
	# il nomade della sera prima se ne va al tramonto
	if p.get("nomade", "") != "":
		var id: String = p["nomade"]
		r.s["viaggi"][id]["chi"] = ""
		r.s["viaggi"][id]["dove"] = p["dove"]
		p["nomade"] = ""
		r.arcano.sincronizza(p)
	if int(p["oro"]) < 1:
		return
	for id in qui(p["dove"]):
		if v(id)["tipo"] != "N":
			continue
		if await r.decidi(p, "viaggiatore", {"id": id, "testo": "Prendere con te il nomade «%s» fino a domani al tramonto, per 1 oro?" % v(id)["nome"]}):
			p["oro"] -= 1
			p["nomade"] = id
			r.s["viaggi"][id]["chi"] = p["pid"]
			r.s["viaggi"][id]["dove"] = ""
			r.scrivi("%s ingaggia il nomade %s per un oro." % [p["nome"], v(id)["nome"]], "bene")
			r.arcano.sincronizza(p)
			return

func fine_mese() -> void:
	## a fine mese falliscono missioni e compiti non completati
	for p in r.vivi():
		for m in p.get("missioni_v", []):
			r.s["viaggi"][m["id"]]["chi"] = ""
			r.s["viaggi"][m["id"]]["dove"] = p["dove"]
			r.scrivi("%s fallisce la missione %s." % [p["nome"], v(m["id"])["nome"]], "male")
		p["missioni_v"] = []
		var c: Dictionary = p.get("compito", {})
		if not c.is_empty() and not c.get("fatto", false):
			r.s["viaggi"][c["id"]]["chi"] = ""
			r.s["viaggi"][c["id"]]["dove"] = p["dove"]
			p["compito"] = {}
			r.scrivi("%s fallisce il compito %s." % [p["nome"], v(c["id"])["nome"]], "male")

# ------------------------------------------------------------ visitatori (commercio)
func visitatori_qui(k: String) -> Array:
	var a := []
	for id in qui(k):
		if v(id)["tipo"] == "V":
			a.append(id)
	return a

# ------------------------------------------------------------ punti vittoria assegnati
func valori(p: Dictionary) -> Dictionary:
	var grandi := 0
	for o in p["oggetti"]:
		if Arcano.e_tesoro(o["id"]) and Arcano.tesoro(o["id"]).get("grande", false):
			grandi += 1
	var inc := 0
	for id in p.get("incantesimi", []):
		if not (id in p.get("inc_iniziali", [])) and r.arcano.lanciabile_in_teoria(p, id):
			inc += 1
	var fama: int = int(p["fama"]) + r.arcano.fama_tesori(p)
	if "Disgusto" in p["maledizioni"]:
		fama = mini(fama, -1)
	var oro: int = -1 if "Ceneri" in p["maledizioni"] else int(p["oro"])
	return {"grandi": grandi, "inc": inc, "fama": fama, "noto": int(p["noto"]) + r.arcano.noto_tesori(p), "oro": oro}

func requisiti(p: Dictionary) -> Array:
	var val := valori(p)
	var a := []
	for c in CATEGORIE:
		var need: int = int(p.get("vp", {}).get(c, 0)) * UNITA[c]
		a.append({"cat": c, "nome": NOMI_CAT[c], "ha": int(val[c]), "serve": need, "ok": int(val[c]) >= need})
	return a

func soddisfatti(p: Dictionary) -> bool:
	for x in requisiti(p):
		if not x["ok"]:
			return false
	return true

func punteggio(p: Dictionary) -> int:
	var tot := 0
	for x in requisiti(p):
		if x["ha"] > x["serve"]:
			tot += (x["ha"] - x["serve"]) / UNITA[x["cat"]]
		elif not x["ok"]:
			tot -= int(ceil(float(x["serve"] - x["ha"]) / UNITA[x["cat"]]))
	return tot

func deduci(p: Dictionary, n: int) -> void:
	## toglie punti assegnati dalla categoria più lontana dal traguardo
	if not attivi() or not p.has("vp"):
		return
	for i in range(n):
		var best := ""
		var bd := -9999.0
		for x in requisiti(p):
			if int(p["vp"][x["cat"]]) <= 0:
				continue
			var manca: float = float(x["serve"] - x["ha"]) / UNITA[x["cat"]]
			if manca > bd:
				bd = manca
				best = x["cat"]
		if best == "":
			return
		p["vp"][best] = int(p["vp"][best]) - 1
		r.scrivi("%s toglie un Punto Vittoria assegnato a %s." % [p["nome"], NOMI_CAT[best]], "bene")
