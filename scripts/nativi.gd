## Nativi (scenario 5 e seguenti): gruppi nelle abitazioni, rapporti, Tabella degli incontri,
## commercio, ingaggio, blocchi e battaglie. I nativi sulla mappa sono gestiti come pedine
## della tabella dei mostri (con la chiave "nativo"), ma non si muovono e attaccano solo chi combattono.
class_name Nativi
extends RefCounted

var r: Reame

const GRUPPI_CLASSICI := ["bashkars", "company", "guard", "lancers", "order", "patrol", "rogues", "soldiers", "woodfolk"]

const COLONNE := ["nemico", "ostile", "neutrale", "amichevole", "alleato"]
const NOMI_REL := {-2: "Nemico", -1: "Ostile", 0: "Neutrale", 1: "Amichevole", 2: "Alleato"}
## Tabella degli incontri (Meeting Table) del Super Realm: riga = dado, colonna = rapporto
const INCONTRI := {
	-2: ["insulto", "sfida", "battaglia", "battaglia", "battaglia", "battaglia"],
	-1: ["x4", "niente", "niente", "insulto", "sfida", "battaglia"],
	0: ["occasione", "x3", "x4", "niente", "niente", "guai"],
	1: ["occasione", "x2", "x2", "x3", "x4", "niente"],
	2: ["dono", "x1", "x2", "x3", "x4", "x4"]}
const NOMI_ESITO := {"insulto": "Insulto", "sfida": "Sfida", "battaglia": "Blocco/Battaglia", "niente": "Nessun accordo", "occasione": "Occasione",
	"guai": "Guai", "dono": "Dono", "x1": "Prezzo ×1", "x2": "Prezzo ×2", "x3": "Prezzo ×3", "x4": "Prezzo ×4"}

func _init(reame: Reame) -> void:
	r = reame

static func gruppo(gid: String) -> Dictionary:
	if gid.begins_with("v:"):
		return {"nome": Viaggi.v(gid.substr(2)).get("nome", "?"), "vagante": false}
	return Dati.nativi["gruppi"].get(gid, {})

func _box(gid: String) -> Dictionary:
	if gid.begins_with("v:"):
		return r.s["visitatori"].get(gid.substr(2), {"tesori": [], "inc": [], "oggetti": []})
	return r.s["nativi"][gid]["box"]

func attivi() -> bool:
	return r.usa_regola("nativi")

# ------------------------------------------------------------ preparazione
func prepara() -> void:
	r.s["nativi"] = {}
	r.s["riga_nativi"] = 1
	var piccoli: Array = r.s.get("fuori_gioco", [])
	var mazzi: Dictionary = r.s.get("mazzi_inc", {})
	for gid in Dati.nativi["gruppi"]:
		var g := gruppo(gid)
		var box := {"tesori": [], "inc": [], "oggetti": []}
		if not g["vagante"]:
			for i in range(2):
				if not piccoli.is_empty():
					box["tesori"].append(piccoli.pop_back())
		for t in g["inc"]:
			if not mazzi.get(t, []).is_empty():
				box["inc"].append(mazzi[t].pop_back())
		for o in g["oggetti"]:
			box["oggetti"].append({"id": o, "attivo": false, "allerta": false, "danno": 0, "scudo": "thrust"})
		r.s["nativi"][gid] = {"box": box, "in_mappa": false, "ingaggio": "", "scadenza": 0, "ostili": {}, "membri": []}
		# ogni membro diventa una pedina nella tabella dei mostri
		for m in g["membri"]:
			var id: String = "n_" + m["id"]
			r.s["mostri"][id] = {"id": id, "tipo": m["id"], "img": m["id"], "dove": "", "lato": 0, "morto": false, "bloccato": false, "casa": ["n", gid], "nativo": gid}
			r.s["nativi"][gid]["membri"].append(id)
	# le guarnigioni partono nelle loro abitazioni
	for gid in Dati.nativi["gruppi"]:
		if r.e_classico() and not (gid in GRUPPI_CLASSICI):
			continue
		var g := gruppo(gid)
		var gar = g.get("guarnigione")
		if gar != null and r.s["abitazioni"].has(gar):
			compari(gid, r.s["abitazioni"][gar], false)

func compari(gid: String, k: String, annuncia := true) -> void:
	var st: Dictionary = r.s["nativi"][gid]
	st["in_mappa"] = true
	st["dove"] = k
	for id in st["membri"]:
		var m: Dictionary = r.s["mostri"][id]
		if not m["morto"]:
			m["dove"] = k
	if annuncia:
		r.scrivi("Compaiono %s a %s." % [gruppo(gid)["nome"], r.nome_r(k)], "mostri")

func vivi(gid: String) -> Array:
	var a := []
	for id in r.s["nativi"][gid]["membri"]:
		var m: Dictionary = r.s["mostri"][id]
		if not m["morto"]:
			a.append(m)
	return a

func capo(gid: String) -> Dictionary:
	for m in vivi(gid):
		if str(m["tipo"]).ends_with("_hq"):
			return m
	return {}

func gruppi_in(k: String, solo_liberi := true) -> Array:
	var a := []
	for gid in r.s.get("nativi", {}):
		var st: Dictionary = r.s["nativi"][gid]
		if solo_liberi and st["ingaggio"] != "":
			continue
		for m in vivi(gid):
			if m["dove"] == k:
				a.append(gid)
				break
	return a

# ------------------------------------------------------------ rapporti
func rapporto(p: Dictionary, gid: String) -> int:
	if gid.begins_with("v:"):
		return int(Dati.nativi["relazioni"].get(p["pg"], {}).get(gid.substr(2), 0))
	if p.get("rel", {}).has(gid):
		return int(p["rel"][gid])
	var base: Dictionary = Dati.nativi["relazioni"].get(p["pg"], {})
	if base.has(gid):
		return int(base[gid])
	return -2 if gruppo(gid)["vagante"] else 0

func cambia_rapporto(p: Dictionary, gid: String, d: int) -> void:
	if not p.has("rel"):
		p["rel"] = {}
	p["rel"][gid] = clampi(rapporto(p, gid) + d, -2, 2)

func incontro(p: Dictionary, gid: String, rel: int, affare := false) -> String:
	## un tiro sulla Tabella degli incontri; occasione e guai spostano di colonna
	if affare and r.s["scenario"] >= 6 and r.viaggi.usa_dono(p):
		return "x1"
	var col := rel
	for giro in range(3):
		var t := r.tiro(p, "incontro")
		var es: String = INCONTRI[col][t[0] - 1]
		r.scrivi("%s tira sulla Tabella degli incontri (%s, dado %d): %s." % [p["nome"], NOMI_REL[col], t[0], NOMI_ESITO[es]])
		if es == "occasione" and col < 2:
			col += 1
			continue
		if es == "guai":
			col = -1
			continue
		return es
	return "niente"

# ------------------------------------------------------------ apparizioni
func tiro_alba() -> void:
	r.s["riga_nativi"] = r.d6()

func fine_turno(p: Dictionary) -> void:
	var k: String = p["dove"]
	var dw := r.abitazione_in(k)
	var riga: int = int(r.s.get("riga_nativi", 1))
	if dw != "":
		for gid in Dati.nativi["gruppi"]:
			if r.e_classico() and not (gid in GRUPPI_CLASSICI):
				continue
			var g := gruppo(gid)
			var st: Dictionary = r.s["nativi"][gid]
			if g["vagante"] or st["in_mappa"] or int(g.get("riga", 0)) != riga or not (dw in g["abitazioni"]):
				continue
			if vivi(gid).is_empty():
				continue
			compari(gid, k)
	# i nativi vaganti compaiono dai Luoghi Perduti della tessera
	var t := r.tessera(k)
	var rm: int = int(r.s.get("riga_mostri", 0))
	for x in r.s["tessere"][str(t)]["rossi"]:
		var c: Dictionary = Dati.segnalini[x]
		if c["tipo"] != "perduto":
			continue
		for gid in Dati.nativi["gruppi"]:
			if r.e_classico() and not (gid in GRUPPI_CLASSICI):
				continue
			var g := gruppo(gid)
			if not g["vagante"] or r.s["nativi"][gid]["in_mappa"] or str(g["perduto"]) != str(c["nome_base"]) or not (rm in g["righe"]):
				continue
			compari(gid, Mappa.chiave(t, int(c["radura"])))

# ------------------------------------------------------------ blocchi
func blocco(p: Dictionary) -> bool:
	if r.e_classico() and not r.usa_regola("combattimento_pg"):
		return false
	## a fine fase, chi è allo scoperto con nativi ostili o nemici tira sugli incontri
	if p["nascosto"]:
		return false
	for gid in gruppi_in(p["dove"]):
		var rel := rapporto(p, gid)
		if rel > -1:
			continue
		var es := incontro(p, gid, rel)
		if _esito_ostile(p, gid, es):
			r.scrivi("%s bloccano %s: stasera combatteranno." % [gruppo(gid)["nome"], p["nome"]], "male")
			p["bloccato"] = true
			return true
	return false

func _esito_ostile(p: Dictionary, gid: String, es: String) -> bool:
	if gid.begins_with("v:"):
		return false
	match es:
		"battaglia":
			r.s["nativi"][gid]["ostili"][p["pid"]] = true
			return true
		"insulto":
			p["noto"] -= 5
			r.scrivi("%s ingoia l'insulto e perde 5 punti Notorietà." % p["nome"])
		"sfida":
			p["fama"] -= 5
			r.scrivi("%s rifiuta la sfida e perde 5 punti Fama." % p["nome"])
	return false

func inizio_combattimento(k: String) -> void:
	if r.e_classico() and not r.usa_regola("combattimento_pg"):
		return
	## all'inizio del combattimento chi è allo scoperto tira per ogni gruppo ostile o nemico
	for p in r.vivi():
		if p["dove"] != k or p["nascosto"]:
			continue
		for gid in gruppi_in(k):
			if r.s["nativi"][gid]["ostili"].has(p["pid"]):
				continue
			var rel := rapporto(p, gid)
			if rel <= -1:
				var es := incontro(p, gid, rel)
				if _esito_ostile(p, gid, es):
					r.scrivi("%s attaccano %s!" % [gruppo(gid)["nome"], p["nome"]], "male")

func ostile_a(m: Dictionary, p: Dictionary) -> bool:
	var gid: String = m.get("nativo", "")
	if gid == "":
		return true
	var st: Dictionary = r.s["nativi"][gid]
	if st["ingaggio"] != "":
		return false
	return st["ostili"].has(p["pid"])

func fine_giorno() -> void:
	for gid in r.s.get("nativi", {}):
		var st: Dictionary = r.s["nativi"][gid]
		st["ostili"] = {}
		if st["ingaggio"] != "" and int(st["scadenza"]) <= int(r.s["giorno"]):
			var chi := r.P(st["ingaggio"])
			st["ingaggio"] = ""
			r.scrivi("%s finiscono il loro ingaggio con %s e restano a %s." % [gruppo(gid)["nome"], chi.get("nome", "?"), r.nome_r(_dove_gruppo(gid))])

func _dove_gruppo(gid: String) -> String:
	for m in vivi(gid):
		return m["dove"]
	return ""

func segui(p: Dictionary) -> void:
	## i nativi ingaggiati si spostano con chi li ha assunti
	for gid in r.s.get("nativi", {}):
		if r.s["nativi"][gid]["ingaggio"] == p["pid"]:
			for m in vivi(gid):
				m["dove"] = p["dove"]

func ingaggiati(p: Dictionary) -> Array:
	var a := []
	for gid in r.s.get("nativi", {}):
		if r.s["nativi"][gid]["ingaggio"] == p["pid"]:
			for m in vivi(gid):
				if m["dove"] == p["dove"]:
					a.append(m)
	return a

func uccisione(p: Dictionary, m: Dictionary) -> void:
	var gid: String = m.get("nativo", "")
	if gid == "":
		return
	r.s["nativi"][gid]["ostili"][p["pid"]] = true
	if rapporto(p, gid) > -2:
		p["rel"] = p.get("rel", {})
		p["rel"][gid] = -2
		r.scrivi("%s ora sono nemici di %s." % [gruppo(gid)["nome"], p["nome"]], "male")
	# chi uccide un nativo prende il suo compenso in oro
	var d := Dati.tipo_mostro(m["tipo"])
	p["oro"] += int(d.get("oro", 0))

# ------------------------------------------------------------ commercio
func valore(o) -> int:
	## valore in oro di un oggetto (tesoro, arma, armatura, incantesimo)
	if o is String:
		if Dati.incantesimi.has(o):
			return 10
		return int(Arcano.tesoro(o).get("oro", 0))
	var id: String = o["id"]
	if Arcano.e_tesoro(id):
		return int(Arcano.tesoro(id)["oro"])
	var d: Dictionary = Dati.oggetti["armi"].get(id, Dati.oggetti["armature"].get(id, {}))
	var v: int = int(d.get("oro", 0))
	if int(o.get("danno", 0)) > 0:
		v = max(1, v - 2)
	return v

func merce(gid: String) -> Array:
	var box: Dictionary = _box(gid)
	var a := []
	for i in range(box["tesori"].size()):
		var id: String = box["tesori"][i]
		a.append({"k": "t", "i": i, "id": id, "nome": Arcano.tesoro(id)["nome"], "oro": valore(id)})
	for i in range(box["inc"].size()):
		var id: String = box["inc"][i]
		a.append({"k": "s", "i": i, "id": id, "nome": "Incantesimo: " + Arcano.inc(id)["nome"], "oro": 10})
	for i in range(box["oggetti"].size()):
		var o: Dictionary = box["oggetti"][i]
		a.append({"k": "o", "i": i, "id": o["id"], "nome": Dati.nome_arma(o["id"]), "oro": valore(o)})
	return a

func opzioni_commercio(p: Dictionary) -> Array:
	var a := []
	for gid in gruppi_in(p["dove"]):
		if capo(gid).is_empty() or r.s["nativi"][gid]["ostili"].has(p["pid"]):
			continue
		a.append({"gruppo": gid, "nome": gruppo(gid)["nome"], "rapporto": NOMI_REL[rapporto(p, gid)], "merce": merce(gid)})
	if r.s["scenario"] >= 6:
		for id in r.viaggi.visitatori_qui(p["dove"]):
			var x := {"gruppo": "v:" + id, "nome": Viaggi.v(id)["nome"], "rapporto": NOMI_REL[rapporto(p, "v:" + id)], "merce": []}
			if id == "blacksmith":
				x["servizio"] = "Ripara un'armatura danneggiata (5 oro, 10 per l'armatura completa)"
			elif id == "cleric":
				x["servizio"] = "Toglie una maledizione o un'ipnosi (5 oro)"
			else:
				x["merce"] = merce("v:" + id)
			a.append(x)
	return a

func attivita_commercio(p: Dictionary) -> void:
	var opz := opzioni_commercio(p)
	if opz.is_empty():
		r.scrivi("%s non trova nessun capo nativo con cui commerciare." % p["nome"])
		return
	var vendibili := []
	for o in p["oggetti"]:
		vendibili.append({"id": o["id"], "nome": Dati.nome_arma(o["id"]), "oro": valore(o)})
	var sc = await r.decidi(p, "commercio", {"gruppi": opz, "vendibili": vendibili, "oro": p["oro"]})
	if not (sc is Dictionary) or not sc.has("gruppo"):
		r.scrivi("%s non conclude affari." % p["nome"])
		return
	var gid: String = str(sc["gruppo"])
	var ok := false
	for x in opz:
		if x["gruppo"] == gid:
			ok = true
	if not ok:
		return
	if sc.get("tipo", "") == "servizio":
		_servizio(p, gid)
	elif sc.get("tipo", "") == "vendi":
		_vendi(p, gid, sc.get("oggetti", []))
	else:
		await _compra(p, gid, sc)
	r.cambiato.emit()

func _servizio(p: Dictionary, gid: String) -> void:
	if gid == "v:blacksmith":
		for o in p["oggetti"]:
			if int(o.get("danno", 0)) > 0:
				var c := 10 if o["id"] == "armatura" else 5
				if int(p["oro"]) < c:
					r.scrivi("%s non ha %d oro per il Fabbro." % [p["nome"], c])
					return
				p["oro"] -= c
				o["danno"] = 0
				r.scrivi("Il Fabbro ripara %s di %s per %d oro." % [Dati.nome_arma(o["id"]), p["nome"], c], "bene")
				return
		r.scrivi("%s non ha armature da riparare." % p["nome"])
	elif gid == "v:cleric":
		if p["maledizioni"].is_empty() or int(p["oro"]) < 5:
			r.scrivi("Il Chierico non può fare nulla per %s." % p["nome"])
			return
		p["oro"] -= 5
		var n: String = p["maledizioni"].pop_back()
		r.scrivi("Il Chierico libera %s da «%s» per 5 oro." % [p["nome"], n], "bene")

func _vendi(p: Dictionary, gid: String, ids: Array) -> void:
	var box: Dictionary = _box(gid)
	var tot := 0
	var nomi := []
	for id in ids:
		for o in p["oggetti"]:
			if o["id"] == id:
				tot += valore(o)
				nomi.append(Dati.nome_arma(id))
				p["oggetti"].erase(o)
				if Arcano.e_tesoro(id):
					box["tesori"].append(id)
					var fc = Arcano.tesoro(id).get("fama_cond")
					if fc is Array and str(fc[1]).to_lower() == gid:
						p["fama"] += int(fc[0])
						r.scrivi("%s apprezzano molto %s: +%d Fama." % [gruppo(gid)["nome"], Dati.nome_arma(id), int(fc[0])], "bene")
				else:
					var x: Dictionary = o.duplicate()
					x["attivo"] = false
					box["oggetti"].append(x)
				break
	if nomi.is_empty():
		return
	p["oro"] += tot
	r.scrivi("%s vende %s a %s per %d oro." % [p["nome"], ", ".join(nomi), gruppo(gid)["nome"], tot], "bene")
	r.arcano.sincronizza(p)

func _compra(p: Dictionary, gid: String, sc: Dictionary) -> void:
	var lista := merce(gid)
	var idx := int(sc.get("merce", -1))
	if idx < 0 or idx >= lista.size():
		return
	var x: Dictionary = lista[idx]
	if not gid.begins_with("v:"):
		r.viaggi.rilascia("n:" + gid, p["dove"])
	var es := incontro(p, gid, rapporto(p, gid), true)
	if p["nascosto"] and es == "battaglia":
		p["nascosto"] = false
	if es in ["battaglia", "insulto", "sfida"]:
		if _esito_ostile(p, gid, es):
			r.scrivi("%s non vogliono trattare: bloccano %s!" % [gruppo(gid)["nome"], p["nome"]], "male")
			p["bloccato"] = true
		return
	if es == "niente":
		r.scrivi("%s non vogliono vendere %s." % [gruppo(gid)["nome"], x["nome"]])
		return
	var prezzo := 0
	if es == "dono":
		prezzo = 0
		cambia_rapporto(p, gid, -1)
		r.scrivi("%s regalano %s a %s (il loro rapporto peggiora di un livello)." % [gruppo(gid)["nome"], x["nome"], p["nome"]], "bene")
	else:
		prezzo = int(x["oro"]) * int(es.substr(1))
	if prezzo > int(p["oro"]):
		var paga = await r.decidi(p, "conferma", {"testo": "%s chiedono %d oro per %s, ma ne hai solo %d." % [gruppo(gid)["nome"], prezzo, x["nome"], p["oro"]], "puo": false})
		r.scrivi("%s non ha abbastanza oro per %s (servono %d)." % [p["nome"], x["nome"], prezzo])
		return
	if prezzo > 0:
		var ok = await r.decidi(p, "conferma", {"testo": "%s chiedono %d oro per %s (hai %d oro). Compri?" % [gruppo(gid)["nome"], prezzo, x["nome"], p["oro"]], "puo": true})
		if not ok:
			r.scrivi("%s rinuncia all'acquisto." % p["nome"])
			return
	p["oro"] -= prezzo
	var box: Dictionary = _box(gid)
	match x["k"]:
		"t":
			box["tesori"].remove_at(int(x["i"]))
			p["oggetti"].append({"id": x["id"], "attivo": true, "allerta": false, "danno": 0})
		"s":
			box["inc"].remove_at(int(x["i"]))
			r.arcano.impara(p, x["id"])
		"o":
			var o: Dictionary = box["oggetti"][int(x["i"])]
			box["oggetti"].remove_at(int(x["i"]))
			o["attivo"] = false
			p["oggetti"].append(o)
	r.scrivi("%s compra %s per %d oro." % [p["nome"], x["nome"], prezzo], "bene")
	r.arcano.sincronizza(p)

# ------------------------------------------------------------ ingaggio
func costo_ingaggio(gid: String) -> int:
	var c := 0
	for m in vivi(gid):
		c += int(Dati.tipo_mostro(m["tipo"]).get("oro", 0))
	return c

func opzioni_ingaggio(p: Dictionary) -> Array:
	var a := []
	for gid in gruppi_in(p["dove"]):
		if capo(gid).is_empty() or r.s["nativi"][gid]["ostili"].has(p["pid"]):
			continue
		a.append({"gruppo": gid, "nome": gruppo(gid)["nome"], "rapporto": NOMI_REL[rapporto(p, gid)], "membri": vivi(gid).size(), "oro": costo_ingaggio(gid)})
	return a

func attivita_ingaggio(p: Dictionary) -> void:
	var opz := opzioni_ingaggio(p)
	if opz.is_empty():
		r.scrivi("%s non trova nativi da ingaggiare." % p["nome"])
		return
	var sc = await r.decidi(p, "ingaggio", {"gruppi": opz, "oro": p["oro"]})
	if not (sc is Dictionary) or not sc.has("gruppo"):
		return
	var gid: String = str(sc["gruppo"])
	var base := costo_ingaggio(gid)
	var es := incontro(p, gid, rapporto(p, gid), true)
	if es in ["battaglia", "insulto", "sfida"]:
		if _esito_ostile(p, gid, es):
			p["nascosto"] = false
			p["bloccato"] = true
			r.scrivi("%s si offendono e bloccano %s!" % [gruppo(gid)["nome"], p["nome"]], "male")
		return
	if es == "niente":
		r.scrivi("%s non accettano l'ingaggio." % gruppo(gid)["nome"])
		return
	var prezzo := 0 if es == "dono" else base * int(es.substr(1))
	if prezzo > int(p["oro"]):
		r.scrivi("%s chiedono %d oro: %s non può permetterselo." % [gruppo(gid)["nome"], prezzo, p["nome"]])
		return
	if prezzo > 0:
		var ok = await r.decidi(p, "conferma", {"testo": "%s chiedono %d oro per seguirti per due settimane (hai %d oro). Li ingaggi?" % [gruppo(gid)["nome"], prezzo, p["oro"]], "puo": true})
		if not ok:
			return
	p["oro"] -= prezzo
	var st: Dictionary = r.s["nativi"][gid]
	st["ingaggio"] = p["pid"]
	st["scadenza"] = int(r.s["giorno"]) + 14
	r.scrivi("%s ingaggia %s per %d oro: lo seguiranno e combatteranno per lui per 14 giorni." % [p["nome"], gruppo(gid)["nome"], prezzo], "bene")
	r.cambiato.emit()

# ------------------------------------------------------------ punteggio
func pv_oro(p: Dictionary) -> int:
	return max(0, int(p["oro"])) / 30
