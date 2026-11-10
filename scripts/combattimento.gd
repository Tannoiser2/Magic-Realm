## Combattimento serale in una radura: adescare, assegnazione casuale dei mostri, cariche, azioni
## (fuga, allerta, berserk), bersagli, mischia con attacchi, parate, manovre e armature,
## posizionamento dei mostri con i dadi, danni, fatica, ferite e disimpegno.
class_name Combattimento
extends RefCounted

var r: Reame
var C: Dictionary = {}     # stato del combattimento in corso (per la UI)

const DIREZIONI := {"thrust": "Affondo", "swing": "Fendente", "smash": "Colpo dall'alto"}
const MANOVRE := {"charge": "Carica", "dodge": "Schivata", "duck": "Abbassarsi"}
const INTERCETTA := {"thrust": "charge", "swing": "dodge", "smash": "duck"}
const RIGHE := ["thrust", "thrust", "swing", "swing", "smash", "smash"]
const COLONNE := ["charge", "charge", "dodge", "dodge", "duck", "duck"]

func _init(reame: Reame) -> void:
	r = reame

func attivo() -> bool:
	return not C.is_empty()

func _pg_qui(k: String) -> Array:
	return r.vivi().filter(func(p): return p["dove"] == k)

func _mostri_qui(k: String) -> Array:
	## mostri della radura e nativi in battaglia con qualcuno dei presenti
	var a := []
	for id in r.s["mostri"]:
		var m: Dictionary = r.s["mostri"][id]
		if r.e_classico() and m.has("nativo") and not r.usa_regola("combattimento_pg"):
			continue
		if m["dove"] == k and not m["morto"]:
			if m.has("nativo"):
				var st: Dictionary = r.s["nativi"][m["nativo"]]
				if st["ingaggio"] != "" or st["ostili"].is_empty():
					continue
				var c := false
				for pid in st["ostili"]:
					if r.P(pid).get("dove", "") == k and not r.P(pid).get("morto", true):
						c = true
				if not c:
					continue
			a.append(m)
	return a

func _alleati_qui(k: String) -> Array:
	var a := []
	if r.s.get("scenario", 1) < 5 or (r.e_classico() and not r.usa_regola("ingaggio")):
		return a
	for p in _pg_qui(k):
		a.append_array(r.nativi.ingaggiati(p))
	return a

func combatti(k: String) -> void:
	var pgs := _pg_qui(k)
	if pgs.is_empty() or r.s["scenario"] < 2 or (r.e_classico() and not r.usa_regola("combattimento_mostri")):
		return
	if r.s.get("tutorial", false) and pgs.all(func(q): return q["nascosto"]):
		return
	if r.s["scenario"] >= 5 and (not r.e_classico() or r.usa_regola("combattimento_pg")):
		r.nativi.inizio_combattimento(k)
	var mostri := _mostri_qui(k)
	var ostili := false
	if mostri.is_empty():
		if pgs.size() < 2 or (r.e_classico() and not r.usa_regola("combattimento_pg")):
			return
		if r.s["scenario"] == 2:
			ostili = true
		else:
			for p in pgs:
				var altri: Array = pgs.filter(func(q): return q != p and (not q["nascosto"] or p["nemici"]))
				if not altri.is_empty():
					var v = await r.decidi(p, "combatti_pg", {"altri": altri.map(func(q): return q["pid"])})
					if v:
						ostili = true
		if not ostili:
			return
	var ordine: Array = pgs.map(func(p): return p["pid"])
	r.mescola(ordine)
	for pid in ordine.duplicate():
		if r.ha_abilita(r.P(pid), "furia"):
			ordine.erase(pid)
			ordine.append(pid)
	C = {"k": k, "ordine": ordine, "assegnati": {}, "primo": true, "molt": {}, "round": 0, "quiete": 0, "eventi": [], "pos": {}, "uso": {},
		"magia": {"pace": {}, "corteccia": {}, "scudo_sacro": {}, "pentacolo": {}, "antimagia": {}, "protezione": {}, "grazia": {}, "arma_incantata": {}, "goblin": {}, "pipistrelli": {}, "luce": false},
		"legati": []}
	r.scrivi("Combattimento a %s." % r.nome_r(k), "titolo")
	r.cambiato.emit()
	var guardia := 0
	while guardia < 30:
		guardia += 1
		C["round"] += 1
		var ev := await _round()
		if ev:
			C["quiete"] = 0
		else:
			C["quiete"] += 1
		C["primo"] = false
		var restano := _pg_qui(k).filter(func(p): return p["pid"] in C["ordine"])
		var mon := _mostri_qui(k)
		if restano.is_empty() or r.s["fine"] != "":
			break
		if mon.is_empty() and (restano.size() < 2):
			break
		if C["quiete"] >= 2:
			break
		r.controlla_vittoria()
		if r.s["fine"] != "":
			break
	for m in _mostri_qui(k):
		m["lato"] = 0
		if m.has("ext"):
			m["ext"]["lato"] = 0
	r.scrivi("Il combattimento a %s termina." % r.nome_r(k))
	for x in C["legati"]:
		var q := _pg(x[0])
		if not q.is_empty():
			r.arcano.sciogli(q, x[1])
	for p in pgs:
		if not p["morto"] and r.usa_regola("magia"):
			r.arcano.sincronizza(p)
	C = {}
	r.cambiato.emit()

func _pg(pid: String) -> Dictionary:
	return r.P(pid)

func _in_lotta() -> Array:
	var a := []
	for pid in C["ordine"]:
		var p := _pg(pid)
		if not p["morto"] and p["dove"] == C["k"]:
			a.append(p)
	return a

func _lato(m: Dictionary) -> Array:
	var d := Dati.tipo_mostro(m["tipo"])
	var l: Array = d["scuro"] if m["lato"] == 1 else d["chiaro"]
	return l

func vel_mossa_mostro(m: Dictionary) -> int:
	var d := Dati.tipo_mostro(m["tipo"])
	if d.get("peso", "") == "X":
		return 99
	if m.has("ext") and m["ext"]["tipo"] == "cavallo_scheletro" and m["ext"]["vivo"]:
		return 6
	return int(_lato(m)[1])

# ------------------------------------------------------------ un round
func _round() -> bool:
	var k: String = C["k"]
	var ev := false
	C["uso"] = {}
	C["pos"] = {}
	C["colpi_t"] = {}
	for p in _in_lotta():
		if r.e_classico() and r.usa_regola("cavalli"):
			for cavallo in p.get("cavalli", []):
				cavallo["galoppo_usato"] = false
		C["uso"][p["pid"]] = {"usati": {}, "sforzo": 0, "cariche": [], "bersaglio": "", "attacco": {}, "parata": {}, "manovra": {}, "scudo": "", "ferite": 0, "ucciso_da": "", "incantesimo": {}}
	r.scrivi("— Round %d —" % C["round"], "round")
	r.cambiato.emit()
	var mostri := _mostri_qui(k)
	# 1) adescare
	if not mostri.is_empty():
		for p in _in_lotta():
			var liberi: Array = mostri.filter(func(m): return C["assegnati"].get(m["id"], "") != p["pid"] and not r.protetto(p, m))
			if liberi.is_empty():
				continue
			var sc = await r.decidi(p, "adesca", {"mostri": liberi.map(func(m): return m["id"])})
			if sc is Array and not sc.is_empty():
				for mid in sc:
					if r.M(mid).is_empty():
						continue
					C["assegnati"][mid] = p["pid"]
				if p["nascosto"]:
					p["nascosto"] = false
					ev = true
				r.scrivi("%s adesca %s." % [p["nome"], r._elenco_mostri(sc.map(func(x): return r.M(x)))])
	# 2) assegnazione casuale
	for m in mostri:
		var a: String = C["assegnati"].get(m["id"], "")
		if a != "" and not _pg(a)["morto"] and _pg(a)["dove"] == k:
			continue
		C["assegnati"].erase(m["id"])
		var cand: Array = _in_lotta().filter(func(p): return not p["nascosto"] and not r.protetto(p, m) and (not m.has("nativo") or r.nativi.ostile_a(m, p)))
		if cand.is_empty():
			continue
		var scelto: Dictionary = cand[0]
		if cand.size() > 1:
			var best := -1
			for p in cand:
				var t: int = max(r.d6(), r.d6()) * 10 + r.d6()
				if t > best:
					best = t
					scelto = p
		C["assegnati"][m["id"]] = scelto["pid"]
		r.scrivi("%s attacca %s." % [r.nome_mostro(m), scelto["nome"]], "mostri")
	r.cambiato.emit()
	# 3) cariche (tra personaggi)
	for p in _in_lotta():
		var bers: Array = _in_lotta().filter(func(q): return q != p and (not q["nascosto"] or p["nemici"]))
		if bers.is_empty():
			continue
		var chits := _chit_mossa_validi(p, 99)
		if chits.is_empty():
			continue
		var sc = await r.decidi(p, "carica", {"bersagli": bers.map(func(q): return q["pid"]), "chits": chits})
		if sc is Dictionary and sc.has("bersaglio") and sc.has("chit"):
			var q := _pg(sc["bersaglio"])
			var ci := int(sc["chit"])
			if q.is_empty() or not (ci in chits) or not _sforzo_ok(p, ci):
				continue
			_usa(p, ci)
			C["uso"][q["pid"]]["cariche"].append(r.vel_chit(p, p["chits"][ci]))
			if p["nascosto"] or q["nascosto"]:
				ev = true
			p["nascosto"] = false
			q["nascosto"] = false
			r.scrivi("%s carica %s." % [p["nome"], q["nome"]])
	# 4) azioni
	for p in _in_lotta():
		var opz := _opzioni_azione(p)
		var sc = await r.decidi(p, "azione", opz)
		if not (sc is Dictionary):
			continue
		match sc.get("tipo", ""):
			"fuga_cavallo":
				if opz.get("fuga_cavallo", false):
					var cavallo: Dictionary = r._cavallo_cavalcato(p)
					if not cavallo.is_empty(): cavallo["galoppo_usato"] = true
					_fuggi(p)
					ev = true
			"fuga":
				var ci := int(sc.get("chit", -1))
				if ci in opz["fuga"] and _sforzo_ok(p, ci):
					_usa(p, ci)
					_fuggi(p)
					ev = true
			"allerta":
				var ci := int(sc.get("chit", -1))
				if ci in opz["allerta"] and _sforzo_ok(p, ci):
					_usa(p, ci)
					var a := r.arma_attiva(p)
					if not a.is_empty():
						a["allerta"] = true
						r.scrivi("%s allerta %s." % [p["nome"], Dati.nome_arma(a["id"])])
			"berserk", "riflessi":
				var ci := int(sc.get("chit", -1))
				if ci >= 0 and ci < p["chits"].size() and p["chits"][ci]["stato"] == "a" and _sforzo_ok(p, ci):
					_usa(p, ci)
					if sc["tipo"] == "berserk":
						p["berserk"] = true
						r.scrivi("%s entra in furia berserk!" % p["nome"], "bene")
					else:
						var a := r.arma_attiva(p)
						if not a.is_empty():
							a["allerta"] = true
							r.scrivi("%s con i suoi riflessi allerta %s." % [p["nome"], Dati.nome_arma(a["id"])])
			"attiva":
				_attiva(p, str(sc.get("oggetto", "")))
			"incantesimo":
				_prepara_incantesimo(p, sc, opz)
			"usa":
				var o2 := str(sc.get("oggetto", ""))
				for x in p["oggetti"]:
					if x["id"] == o2 and str(Arcano.tesoro(o2).get("eff", {}).get("monouso", "")) == "luce":
						p["oggetti"].erase(x)
						C["magia"]["luce"] = true
						for mid in C["assegnati"].keys():
							C["assegnati"].erase(mid)
						r.scrivi("%s libera la Luce imbottigliata: i mostri della radura si placano." % p["nome"], "bene")
						break
			"abbandona":
				var o := str(sc.get("oggetto", ""))
				for x in p["oggetti"]:
					if x["id"] == o:
						p["oggetti"].erase(x)
						r.lascia(C["k"], x)
						r.scrivi("%s abbandona %s." % [p["nome"], Dati.nome_arma(o)])
						break
	r.cambiato.emit()
	# 5) bersagli (ordine casuale)
	var ord_b: Array = _in_lotta()
	r.mescola(ord_b)
	for p in ord_b:
		var bers := []
		for q in _in_lotta():
			if q != p and (not q["nascosto"] or p["nemici"]):
				bers.append(q["pid"])
		for m in _mostri_qui(k):
			bers.append(m["id"])
		if bers.is_empty():
			continue
		var sc = await r.decidi(p, "bersaglio", {"bersagli": bers})
		if sc is String and sc in bers:
			C["uso"][p["pid"]]["bersaglio"] = sc
			var a := r.arma_attiva(p)
			var missile: bool = not a.is_empty() and Dati.oggetti["armi"][a["id"]]["missile"]
			if p["nascosto"]:
				if missile:
					var t := r.tiro(p, "nascondi")
					if t[0] >= 6:
						p["nascosto"] = false
						ev = true
						r.scrivi("%s tenta un'imboscata ma si rivela." % p["nome"])
					else:
						r.scrivi("%s tira da nascosto (imboscata)." % p["nome"])
				else:
					p["nascosto"] = false
					ev = true
			if sc.begins_with("p"):
				var q := _pg(sc)
				if q["nascosto"]:
					q["nascosto"] = false
					ev = true
			r.scrivi("%s prende di mira %s." % [p["nome"], _nome(sc)])
	r.cambiato.emit()
	# all'inizio della mischia hanno effetto gli incantesimi
	if r.s["scenario"] >= 4:
		if await _risolvi_incantesimi():
			ev = true
	# 6) mischia: giocate dei personaggi
	for p in _in_lotta():
		var u: Dictionary = C["uso"][p["pid"]]
		var dati := _opzioni_mischia(p)
		var sc = await r.decidi(p, "mischia", dati)
		if not (sc is Dictionary):
			sc = {}
		_registra_mischia(p, sc, dati)
	# posizionamento dei mostri
	_posiziona_mostri()
	r.cambiato.emit()
	await r.pausa(0.3)
	# 7) risoluzione dei colpi
	if await _risolvi():
		ev = true
	if _attacchi_alleati():
		ev = true
	# 8) fatica e ferite
	for p in _in_lotta():
		if await _fatica_ferite(p):
			ev = true
	# cambi di tattica dei mostri tremendi
	for mid in C["colpi_t"]:
		var m := r.M(mid)
		if m.is_empty() or m["morto"] or m["lato"] == 1:
			continue
		var bersaglio: String = C["assegnati"].get(mid, "")
		if bersaglio != "" and not _pg(bersaglio)["morto"]:
			m["lato"] = 1
			ev = true
			r.scrivi("%s afferra la sua preda: ora fa danni Massimi e non lascia fuggire!" % r.nome_mostro(m), "male")
	r.cambiato.emit()
	return ev

func _nome(id: String) -> String:
	if id.begins_with("p"):
		return _pg(id)["nome"]
	var m := r.M(id)
	return r.nome_mostro(m) if not m.is_empty() else id

func _usa(p: Dictionary, ci: int) -> void:
	var u: Dictionary = C["uso"][p["pid"]]
	u["usati"][ci] = true
	u["sforzo"] += int(p["chits"][ci]["sforzi"])

func _sforzo_ok(p: Dictionary, ci: int) -> bool:
	var u: Dictionary = C["uso"][p["pid"]]
	if u["usati"].has(ci):
		return false
	if r.ha_abilita(p, "furia"):
		return true
	return u["sforzo"] + int(p["chits"][ci]["sforzi"]) <= (r.arcano.limite_sforzo(p) if r.s["scenario"] >= 4 else 2)

func _chit_mossa_validi(p: Dictionary, vel_max: int) -> Array:
	var a := []
	var carico := r.carico_max(p)
	if r.e_classico() and not r._cavallo_cavalcato(p).is_empty():
		return a # chi cavalca non gioca i MOVE chits per fuggire
	for i in r.chit_attivi(p):
		var c: Dictionary = p["chits"][i]
		if c["tipo"] == "M" and r.forza_chit(c) >= carico and r.vel_chit(p, c) < vel_max and not C["uso"][p["pid"]]["usati"].has(i):
			a.append(i)
	return a

func _minacce(p: Dictionary) -> int:
	## velocità più rapida tra cariche e mostri assegnati (le azioni devono essere più veloci)
	var v := 99
	for x in C["uso"][p["pid"]]["cariche"]:
		v = min(v, int(x))
	for mid in C["assegnati"]:
		if C["assegnati"][mid] == p["pid"]:
			v = min(v, vel_mossa_mostro(r.M(mid)))
	return v

func _trattenuto(p: Dictionary) -> bool:
	for mid in C["assegnati"]:
		if C["assegnati"][mid] == p["pid"]:
			var m := r.M(mid)
			if Dati.tipo_mostro(m["tipo"])["peso"] == "T" and m["lato"] == 1:
				return true
	return false

func _opzioni_azione(p: Dictionary) -> Dictionary:
	var v := _minacce(p)
	var fuga := []
	if not _trattenuto(p) and not ("Distratto" in p["maledizioni"]):
		fuga = _chit_mossa_validi(p, v)
	var cavallo: Dictionary = r._cavallo_cavalcato(p)
	var fuga_cavallo: bool = not cavallo.is_empty() and CavalliClassici.tempo(cavallo, not cavallo.get("galoppo_usato", false)) < v and not _trattenuto(p)
	var allerta := []
	var a := r.arma_attiva(p)
	if not a.is_empty() and not a["allerta"] and not ("Stanco" in p["maledizioni"]):
		for i in r.chit_attivi(p):
			var c: Dictionary = p["chits"][i]
			if c["tipo"] == "F" and r.vel_chit(p, c) < v and not C["uso"][p["pid"]]["usati"].has(i):
				allerta.append(i)
	var berserk := -1
	var riflessi := -1
	for i in r.chit_attivi(p):
		var c: Dictionary = p["chits"][i]
		if c["tipo"] == "B" and not p["berserk"] and int(c["vel"]) < v:
			berserk = i
		if c["tipo"] == "R" and not a.is_empty() and not a["allerta"]:
			riflessi = i
	var attivabili := []
	for o in p["oggetti"]:
		attivabili.append(o["id"])
	var incs := []
	var bers := []
	var usabili := []
	if r.s["scenario"] >= 4:
		incs = r.arcano.lanciabili(p, true, v, C["uso"][p["pid"]]["usati"])
		for q in _in_lotta():
			bers.append(q["pid"])
		for m in _mostri_qui(C["k"]):
			bers.append(m["id"])
		for o in p["oggetti"]:
			if str(Arcano.tesoro(o["id"]).get("eff", {}).get("monouso", "")) == "luce":
				usabili.append(o["id"])
	return {"fuga": fuga, "fuga_cavallo": fuga_cavallo, "allerta": allerta, "berserk": berserk, "riflessi": riflessi, "oggetti": attivabili, "minaccia": v,
		"incantesimi": incs, "bersagli_inc": bers, "usabili": usabili}

func _attiva(p: Dictionary, id: String) -> void:
	for o in p["oggetti"]:
		if o["id"] != id:
			continue
		if o["attivo"]:
			o["attivo"] = false
			r.scrivi("%s disattiva %s." % [p["nome"], Dati.nome_arma(id)])
			return
		var arma: bool = Dati.oggetti["armi"].has(id)
		for x in p["oggetti"]:
			if x != o and x["attivo"] and (x["id"] == id or (arma and Dati.oggetti["armi"].has(x["id"]))):
				x["attivo"] = false
		o["attivo"] = true
		r.scrivi("%s impugna %s." % [p["nome"], Dati.nome_arma(id)])
		return

func _fuggi(p: Dictionary) -> void:
	var k: String = C["k"]
	var dest: String = p.get("entrato_da", "")
	var vic := r.vicini_di(p, k)
	if not (dest in vic):
		dest = vic[r.rng.randi_range(0, vic.size() - 1)] if not vic.is_empty() else k
	r.scrivi("%s fugge verso %s!" % [p["nome"], r.nome_r(dest)], "bene")
	p["dove"] = dest
	for mid in C["assegnati"].keys():
		if C["assegnati"][mid] == p["pid"]:
			C["assegnati"].erase(mid)
	C["ordine"].erase(p["pid"])

func _opzioni_mischia(p: Dictionary) -> Dictionary:
	var a := r.arma_attiva(p)
	var peso_arma := r.peso_oggetto(a) if not a.is_empty() else 0
	var fight := []
	var move := []
	var carico := r.carico_max(p)
	var cavallo: Dictionary = r._cavallo_cavalcato(p)
	for i in r.chit_attivi(p):
		var c: Dictionary = p["chits"][i]
		if C["uso"][p["pid"]]["usati"].has(i):
			continue
		if c["tipo"] == "F" and r.forza_chit(c) >= peso_arma:
			fight.append(i)
		if cavallo.is_empty() and ((c["tipo"] == "M" and r.forza_chit(c) >= carico) or c["tipo"] == "D"):
			move.append(i)
	var ha_scudo := false
	for o in p["oggetti"]:
		if o["attivo"] and o["id"] == "scudo":
			ha_scudo = true
	var missile: bool = not a.is_empty() and Dati.oggetti["armi"][a["id"]]["missile"]
	var minacciato := false
	for mid in C["assegnati"]:
		if C["assegnati"][mid] == p["pid"]:
			minacciato = true
	for pid in C["uso"]:
		if C["uso"][pid]["bersaglio"] == p["pid"]:
			minacciato = true
	return {"fight": fight, "move": move, "cavallo": not cavallo.is_empty(), "tempo_cavallo": CavalliClassici.tempo(cavallo, not cavallo.get("galoppo_usato", false)) if not cavallo.is_empty() else 99, "scudo": ha_scudo, "missile": missile, "bersaglio": C["uso"][p["pid"]]["bersaglio"], "minacciato": minacciato,
		"sforzo": C["uso"][p["pid"]]["sforzo"], "arma": a.get("id", "pugnale")}

func _registra_mischia(p: Dictionary, sc: Dictionary, dati: Dictionary) -> void:
	var u: Dictionary = C["uso"][p["pid"]]
	var furia := r.ha_abilita(p, "furia")
	var at = sc.get("attacco")
	var pa = sc.get("parata")
	if at is Dictionary and at.has("chit") and u["bersaglio"] != "":
		var ci := int(at["chit"])
		if ci in dati["fight"] and _sforzo_ok(p, ci):
			_usa(p, ci)
			u["attacco"] = {"cerchio": at.get("cerchio", "thrust"), "chit": ci}
	elif pa is Dictionary and pa.has("chit") and u["bersaglio"] != "" and not dati["missile"]:
		var ci := int(pa["chit"])
		if ci in dati["fight"] and _sforzo_ok(p, ci):
			_usa(p, ci)
			u["parata"] = {"cerchio": pa.get("cerchio", "thrust"), "chit": ci}
	var ma = sc.get("manovra")
	if ma is Dictionary and ma.get("cavallo", false) and dati.get("cavallo", false):
		var cavallo: Dictionary = r._cavallo_cavalcato(p)
		if not cavallo.is_empty():
			var galoppa: bool = not cavallo.get("galoppo_usato", false)
			u["manovra"] = {"casella": ma.get("casella", "dodge"), "cavallo": true, "tempo": CavalliClassici.tempo(cavallo, galoppa)}
			if galoppa: cavallo["galoppo_usato"] = true
	elif ma is Dictionary and ma.has("chit"):
		var ci := int(ma["chit"])
		var cas: String = ma.get("casella", "charge")
		if p["chits"][ci]["tipo"] == "D":
			cas = "duck"
		if ci in dati["move"] and (_sforzo_ok(p, ci) or furia):
			_usa(p, ci)
			u["manovra"] = {"casella": cas, "chit": ci}
	u["scudo"] = sc.get("scudo", "thrust")
	for o in p["oggetti"]:
		if o["id"] == "scudo":
			o["scudo"] = u["scudo"]
	var parti := []
	if not u["attacco"].is_empty():
		parti.append("%s con %s" % [DIREZIONI[u["attacco"]["cerchio"]], r.descr_chit(p["chits"][u["attacco"]["chit"]])])
	if not u["parata"].is_empty():
		parti.append("parata %s" % DIREZIONI[u["parata"]["cerchio"]])
	if not u["manovra"].is_empty():
		parti.append("%s (%s)" % [MANOVRE[u["manovra"]["casella"]], "a cavallo" if u["manovra"].get("cavallo", false) else r.descr_chit(p["chits"][u["manovra"]["chit"]])])
	if not parti.is_empty():
		r.scrivi("%s: %s." % [p["nome"], ", ".join(parti)])

func _posiziona_mostri() -> void:
	var da_posizionare := {}
	for mid in C["assegnati"]:
		da_posizionare[mid] = true
	for pid in C["uso"]:
		var b: String = C["uso"][pid]["bersaglio"]
		if b.begins_with("m"):
			da_posizionare[b] = true
	for mid in da_posizionare:
		var m := r.M(mid)
		if m.is_empty() or m["morto"]:
			continue
		var rosso := r.d6()
		var bianco := r.d6()
		var riga: String = RIGHE[rosso - 1]
		var col: String = COLONNE[bianco - 1]
		C["pos"][mid] = {"riga": riga, "col": col, "dadi": [rosso, bianco]}
		var cambia: bool = INTERCETTA[riga] == col
		var d := Dati.tipo_mostro(m["tipo"])
		if cambia and d["peso"] != "T" and d["peso"] != "X":
			m["lato"] = 1 - m["lato"]
			r.scrivi("%s cambia tattica." % r.nome_mostro(m))
		if m.has("ext") and m["ext"]["vivo"]:
			var et: String = m["ext"]["tipo"]
			if et == "scudo_minotauro":
				C["pos"][mid]["scudo"] = RIGHE[bianco - 1]
			elif et == "cavallo_scheletro":
				var b2 := r.d6()
				C["pos"][mid]["cavallo"] = COLONNE[b2 - 1]
			else:
				var r2 := r.d6()
				var b2 := r.d6()
				C["pos"][mid]["ext"] = {"riga": RIGHE[r2 - 1], "col": COLONNE[b2 - 1]}
				if INTERCETTA[RIGHE[r2 - 1]] == COLONNE[b2 - 1]:
					m["ext"]["lato"] = 1 - m["ext"]["lato"]

# ------------------------------------------------------------ risoluzione
func _harm_base_pg(p: Dictionary, chit: Dictionary, cerchio: String, armatura: bool, con_stelle := true) -> int:
	var a := r.arma_attiva(p)
	var id: String = a.get("id", "pugnale")
	var w: Dictionary = Dati.oggetti["armi"][id]
	var lato: Array = w["inallerta"] if a.get("allerta", false) else w["normale"]
	var h := Dati.peso_i(lato[0])
	var forza := r.forza_chit(chit)
	if cerchio == "thrust" and r.ha_abilita(p, "affondo"):
		forza += 1
	if not w["missile"] and forza > Dati.peso_i(w["peso"]):
		h += 1
	if con_stelle:
		var st: int = int(lato[1])
		if r.s.get("scenario", 1) >= 4:
			st += r.arcano.eff(p, "stella").size()
			if r.arcano.effetto(p, "veleno") or (C.has("magia") and C["magia"]["arma_incantata"].has(p["pid"])):
				st += 1
		if armatura and st > 0:
			st -= 1
		h += st
	return h

func _vel_attacco_pg(p: Dictionary, chit: Dictionary) -> int:
	var a := r.arma_attiva(p)
	var w: Dictionary = Dati.oggetti["armi"][a.get("id", "pugnale")]
	var lato: Array = w["inallerta"] if a.get("allerta", false) else w["normale"]
	if int(lato[2]) > 0:
		return int(lato[2])
	return r.vel_chit(p, chit)

func _missile(h: int, dadi_uno: bool, mira: bool) -> Array:
	var t: int = r.d6() if dadi_uno else max(r.d6(), r.d6())
	if mira:
		t = max(1, t - 1)
	return [clampi(h + 3 - t, 0, 5), t]

func _risolvi() -> bool:
	var ev := false
	var k: String = C["k"]
	var colpi := []
	# attacchi e parate dei personaggi
	for p in _in_lotta():
		var u: Dictionary = C["uso"][p["pid"]]
		var a := r.arma_attiva(p)
		var w: Dictionary = Dati.oggetti["armi"][a.get("id", "pugnale")]
		for kind in ["attacco", "parata"]:
			if u[kind].is_empty():
				continue
			var ch: Dictionary = p["chits"][u[kind]["chit"]]
			colpi.append({"da": p["pid"], "verso": u["bersaglio"], "dir": u[kind]["cerchio"], "vel": _vel_attacco_pg(p, ch),
				"lung": int(w["lung"]), "parata": kind == "parata", "pg": true, "chit": u[kind]["chit"], "missile": bool(w["missile"]) and kind == "attacco"})
	# attacchi dei mostri (solo quelli assegnati attaccano)
	for mid in C["assegnati"]:
		var m := r.M(mid)
		var bers: String = C["assegnati"][mid]
		if m.is_empty() or m["morto"] or not C["pos"].has(mid):
			continue
		if _mostro_trattenuto(m, bers):
			continue
		var d := Dati.tipo_mostro(m["tipo"])
		var lato: Array = _lato(m)
		var at := Dati.attacco(str(lato[0]))
		if at["f"] != "":
			colpi.append({"da": mid, "verso": bers, "dir": C["pos"][mid]["riga"], "vel": int(at["v"]), "lung": int(d["lung"][m["lato"]]),
				"parata": false, "pg": false, "at": at, "missile": bool(d["missile"][m["lato"]]), "rosso": d["peso"] == "T" and m["lato"] == 1})
		if m.has("ext") and m["ext"]["vivo"] and C["pos"][mid].has("ext"):
			var e := Dati.tipo_mostro(m["ext"]["tipo"])
			var el: Array = e["scuro"] if m["ext"]["lato"] == 1 else e["chiaro"]
			var eat := Dati.attacco(str(el[0]))
			colpi.append({"da": mid, "ext": true, "verso": bers, "dir": C["pos"][mid]["ext"]["riga"], "vel": int(eat["v"]),
				"lung": int(e["lung"][m["ext"]["lato"]]), "parata": false, "pg": false, "at": eat, "missile": false, "rosso": false})
	var primo: bool = C["primo"]
	colpi.sort_custom(func(a, b):
		if primo:
			if a["lung"] != b["lung"]: return a["lung"] > b["lung"]
			if a["vel"] != b["vel"]: return a["vel"] < b["vel"]
		else:
			if a["vel"] != b["vel"]: return a["vel"] < b["vel"]
			if a["lung"] != b["lung"]: return a["lung"] > b["lung"]
		return a["parata"] and not b["parata"])
	var annullati := {}
	for i in range(colpi.size()):
		var c: Dictionary = colpi[i]
		if annullati.has(i) or _morto(c["da"]) or _morto(c["verso"]):
			continue
		if c["parata"]:
			# cerca un attacco del bersaglio contro chi para, non ancora risolto
			for j in range(i + 1, colpi.size()):
				var x: Dictionary = colpi[j]
				if annullati.has(j) or x["parata"] or x["da"] != c["verso"] or x["verso"] != c["da"]:
					continue
				if x["missile"] or x.get("rosso", false) or (x.has("at") and x["at"]["f"] in ["X", "V"]):
					continue
				if c["vel"] < x["vel"] or c["dir"] == x["dir"]:
					var hp := _harm_base_pg(_pg(c["da"]), _pg(c["da"])["chits"][c["chit"]], c["dir"], false, false)
					var ha := 0
					if x["pg"]:
						var q := _pg(x["da"])
						ha = _harm_base_pg(q, q["chits"][x["chit"]], x["dir"], false, false)
					else:
						ha = Dati.peso_i(x["at"]["f"])
					if hp >= ha:
						annullati[j] = true
						r.scrivi("%s para l'attacco di %s!" % [_nome(c["da"]), _nome(x["da"])], "bene")
						var a1 := r.arma_attiva(_pg(c["da"]))
						if not a1.is_empty(): a1["allerta"] = false
						if x["pg"]:
							var a2 := r.arma_attiva(_pg(x["da"]))
							if not a2.is_empty(): a2["allerta"] = false
						break
			continue
		# attacco: colpisce?
		var colpisce := false
		var bersaglio: String = c["verso"]
		var vel_m := 99
		var col := ""
		var sul_cavallo := false
		if bersaglio.begins_with("p"):
			var mu: Dictionary = C["uso"].get(bersaglio, {}).get("manovra", {})
			if mu.is_empty():
				colpisce = true
			else:
				var q := _pg(bersaglio)
				vel_m = int(mu["tempo"]) if mu.get("cavallo", false) else r.vel_chit(q, q["chits"][mu["chit"]])
				if C["magia"]["grazia"].has(bersaglio):
					vel_m -= 1
				col = mu["casella"]
		else:
			var m := r.M(bersaglio)
			var d := Dati.tipo_mostro(m["tipo"])
			if d["peso"] == "X":
				colpisce = true
			elif C["pos"].has(bersaglio):
				if C["pos"][bersaglio].has("cavallo") and m["ext"]["vivo"]:
					sul_cavallo = true
					col = C["pos"][bersaglio]["cavallo"]
					vel_m = 4
				else:
					col = C["pos"][bersaglio]["col"]
					vel_m = vel_mossa_mostro(m)
			else:
				colpisce = true
		if not colpisce:
			colpisce = c["vel"] < vel_m or INTERCETTA[c["dir"]] == col
		if not colpisce:
			if c["pg"]:
				var a := r.arma_attiva(_pg(c["da"]))
				if not a.is_empty() and not a["allerta"]:
					a["allerta"] = true
				r.scrivi("%s manca %s." % [_nome(c["da"]), _nome(bersaglio)])
			else:
				r.scrivi("%s manca %s." % [_nome(c["da"]) + (" (testa/arto)" if c.get("ext", false) else ""), _nome(bersaglio)])
			continue
		# colpo a segno
		if c["pg"]:
			var p := _pg(c["da"])
			var a := r.arma_attiva(p)
			if not a.is_empty():
				a["allerta"] = false
			if bersaglio.begins_with("p"):
				if await _colpisci_pg(_pg(bersaglio), c, p):
					ev = true
					_uccisione_pg(p, _pg(bersaglio))
			else:
				if _colpisci_mostro(r.M(bersaglio), c, p, sul_cavallo):
					ev = true
		else:
			var m := r.M(c["da"])
			if Dati.tipo_mostro(m["tipo"])["peso"] == "T":
				C["colpi_t"][m["id"]] = true
			if await _colpisci_pg(_pg(bersaglio), c, null):
				ev = true
	return ev

func _morto(id: String) -> bool:
	if id == "":
		return true
	if id.begins_with("p"):
		var p := _pg(id)
		return p["morto"] or C["uso"].get(id, {}).get("ucciso_da", "") != "" or p["dove"] != C["k"]
	var m := r.M(id)
	return m.is_empty() or m["morto"]

func _armatura_colpita(q: Dictionary, dir: String) -> Dictionary:
	var ordine := []
	for o in q["oggetti"]:
		if o["attivo"] and str(Arcano.tesoro(o["id"]).get("eff", {}).get("para", "")) == dir:
			ordine.append(o)
	for o in q["oggetti"]:
		if o["attivo"] and o["id"] == "scudo" and o.get("scudo", "") == dir:
			ordine.append(o)
	for o in q["oggetti"]:
		if not o["attivo"]:
			continue
		if o["id"] == "corazza" and dir in ["thrust", "swing"]:
			ordine.append(o)
		if o["id"] == "elmo" and dir == "smash":
			ordine.append(o)
	for o in q["oggetti"]:
		if o["attivo"] and o["id"] == "armatura":
			ordine.append(o)
	return ordine[0] if not ordine.is_empty() else {}

func _colpisci_pg(q: Dictionary, c: Dictionary, attaccante) -> bool:
	## restituisce true se il bersaglio muore
	var u: Dictionary = C["uso"][q["pid"]]
	if C.has("magia") and C["magia"]["scudo_sacro"].has(q["pid"]):
		C["magia"]["scudo_sacro"].erase(q["pid"])
		r.scrivi("Lo Scudo sacro ferma il colpo di %s contro %s." % [_nome(c["da"]), q["nome"]], "bene")
		return false
	var montato: Dictionary = r._cavallo_cavalcato(q)
	var su_cavallo: bool = not montato.is_empty() and bool(u.get("manovra", {}).get("cavallo", false)) and not c.get("rosso", false)
	var arm := {} if su_cavallo else _armatura_colpita(q, c["dir"])
	var corazzato: bool = (su_cavallo and CavalliClassici.tipo(montato) == "guerra") or (not su_cavallo and (not arm.is_empty() or (C.has("magia") and C["magia"]["corteccia"].has(q["pid"]))))
	var h := 0
	var testo := ""
	var x_puro := false
	if attaccante != null:
		var p: Dictionary = attaccante
		h = _harm_base_pg(p, p["chits"][c["chit"]], c["dir"], corazzato)
		if c["missile"]:
			var mt := _missile(h, r.ha_abilita(p, "arciere"), r.ha_abilita(p, "mira"))
			testo = " (proiettili, dado %d)" % mt[1]
			h = mt[0]
	else:
		var at: Dictionary = c["at"]
		var m := r.M(c["da"])
		if at["f"] == "V":
			_incantesimo(q, m)
			return q["morto"]
		if c.get("rosso", false) or at["f"] == "X":
			h = 5
			x_puro = true
		else:
			h = Dati.peso_i(at["f"])
			var st: int = int(at["s"])
			if C.has("magia") and C["magia"].get("smussati", {}).has(m["id"]):
				st = max(0, st - 1)
			if corazzato and st > 0:
				st -= 1
			h += st
			if c["missile"]:
				var uno: bool = m["tipo"].begins_with("anomalia") or m["tipo"] == "titano"
				var mt := _missile(h, uno, false)
				testo = " (proiettili, dado %d)" % mt[1]
				h = mt[0]
	var chi := _nome(c["da"])
	if su_cavallo:
		var soglia: int = Dati.peso_i(str(CavalliClassici.definizione(montato["id"])["vulnerabilita"]))
		if h >= soglia:
			q["cavalli"].erase(montato)
			r.scrivi("%s colpisce e uccide il cavallo di %s!" % [chi, q["nome"]], "male")
		else:
			r.scrivi("%s colpisce il cavallo di %s, che resiste." % [chi, q["nome"]])
		return false
	if (x_puro or (c["missile"] and h >= 5)) and true:
		if not arm.is_empty():
			q["oggetti"].erase(arm)
		r.scrivi("%s colpisce %s con forza Massima%s: è uccis{oa}!" % [chi, q["nome"], testo], "male")
		u["ucciso_da"] = c["da"]
		return true
	if not arm.is_empty():
		var pa := r.peso_oggetto(arm)
		var esito := "regge"
		if h > pa or (h == pa and arm["danno"] >= 1):
			q["oggetti"].erase(arm)
			esito = "è distrutto"
		elif h == pa:
			arm["danno"] = 1
			esito = "è danneggiato"
		if h >= 2:
			u["ferite"] += 1
		r.scrivi("%s colpisce %s sull'armatura (%s, danno %s%s): %s %s%s." % [chi, q["nome"], Dati.nome_arma(arm["id"]), Dati.NOMI_PESO[Dati.peso_s(h)], testo, Dati.nome_arma(arm["id"]), esito, ", una ferita" if h >= 2 else ""], "male")
		return false
	var vq := r.vulnerabilita(q)
	if C.has("magia") and C["magia"]["protezione"].has(q["pid"]):
		vq += 1
	if h >= vq:
		r.scrivi("%s colpisce %s con danno %s%s: è uccis{oa}!" % [chi, q["nome"], Dati.NOMI_PESO[Dati.peso_s(h)], testo], "male")
		u["ucciso_da"] = c["da"]
		return true
	if h >= 1:
		u["ferite"] += 1
		r.scrivi("%s colpisce %s (danno %s%s): una ferita." % [chi, q["nome"], Dati.NOMI_PESO[Dati.peso_s(h)], testo], "male")
	else:
		r.scrivi("%s colpisce %s senza fargli danno." % [chi, q["nome"]])
	return false

func _colpisci_mostro(m: Dictionary, c: Dictionary, p: Dictionary, sul_cavallo: bool) -> bool:
	var d := Dati.tipo_mostro(m["tipo"])
	var armato: bool = d.get("armato", false)
	var scudo := false
	if m["tipo"] == "minotauro" and m["ext"]["vivo"] and C["pos"].get(m["id"], {}).get("scudo", "") == c["dir"]:
		scudo = true
		armato = true
	if sul_cavallo:
		armato = true
	var h := _harm_base_pg(p, p["chits"][c["chit"]], c["dir"], armato)
	var testo := ""
	if c["missile"]:
		var mt := _missile(h, r.ha_abilita(p, "arciere"), r.ha_abilita(p, "mira"))
		h = mt[0]
		testo = " (proiettili, dado %d)" % mt[1]
	var nome := r.nome_mostro(m)
	if scudo:
		if h >= 4:
			m["ext"]["danno"] = int(m["ext"]["danno"]) + (2 if h > 4 else 1)
			if int(m["ext"]["danno"]) >= 2:
				m["ext"]["vivo"] = false
				r.scrivi("%s distrugge lo scudo del Minotauro%s." % [p["nome"], testo], "bene")
			else:
				r.scrivi("%s danneggia lo scudo del Minotauro%s." % [p["nome"], testo])
		else:
			r.scrivi("Lo scudo del Minotauro ferma il colpo di %s%s." % [p["nome"], testo])
		return false
	if sul_cavallo:
		if h >= 4:
			m["ext"]["vivo"] = false
			r.scrivi("%s abbatte il destriero del Cavaliere scheletro%s!" % [p["nome"], testo], "bene")
			return true
		r.scrivi("Il colpo di %s non ferma il destriero scheletro%s." % [p["nome"], testo])
		return false
	var vuln := Dati.peso_i(d["peso"])
	if h >= vuln:
		m["morto"] = true
		m["dove"] = ""
		C["assegnati"].erase(m["id"])
		var n: int = C["molt"].get(p["pid"], 0) + 1
		C["molt"][p["pid"]] = n
		r.scrivi("%s colpisce %s (danno %s%s)." % [p["nome"], nome, Dati.NOMI_PESO[Dati.peso_s(h)], testo])
		r.uccisione_mostro(p, m, n)
		return true
	r.scrivi("%s colpisce %s, ma il danno %s%s non basta." % [p["nome"], nome, Dati.NOMI_PESO[Dati.peso_s(h)], testo])
	return false

func _incantesimo(q: Dictionary, m: Dictionary) -> void:
	var inc: String = Dati.tipo_mostro(m["tipo"]).get("incant", "")
	var t := r.d6()
	if C.has("magia") and C["magia"]["antimagia"].has(q["pid"]):
		r.scrivi("La Protezione dalla magia respinge l'incantesimo di %s." % r.nome_mostro(m), "bene")
		return
	if r.s["scenario"] >= 4 and inc in ["maledizione", "ipnosi"]:
		r.scrivi("%s lancia un incantesimo su %s." % [r.nome_mostro(m), q["nome"]], "male")
		r.arcano.maledici(q, inc)
		return
	match inc:
		"maledizione":
			if q["pg"] == "negromante":
				r.scrivi("%s è immun{oa} alle maledizioni." % q["nome"])
				return
			var n: String = Reame.MALEDIZIONI[t - 1]
			_maledici(q, n, "maledizione")
		"ipnosi":
			_maledici(q, Reame.IPNOSI[t - 1], "ipnosi")
		"abisso":
			r.scrivi("%s scatena il Potere dell'Abisso su %s: %s!" % [r.nome_mostro(m), q["nome"], Reame.ABISSO[t - 1]], "male")
			match t:
				1:
					for x in _in_lotta():
						if not x["nascosto"]:
							C["uso"][x["pid"]]["ucciso_da"] = m["id"]
				2:
					C["uso"][q["pid"]]["ucciso_da"] = m["id"]
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

func _maledici(q: Dictionary, n: String, che: String) -> void:
	if n in q["maledizioni"]:
		r.scrivi("%s subisce di nuovo «%s», senza altri effetti." % [q["nome"], n])
		return
	q["maledizioni"].append(n)
	r.scrivi("%s è colpit{oa} da %s: «%s»." % [q["nome"], "una maledizione" if che == "maledizione" else "un'ipnosi", n], "male")
	if n == "Avvizzimento":
		for c in q["chits"]:
			if c["stato"] == "a" and c["sforzi"] > 0:
				c["stato"] = "f"

func _uccisione_pg(killer: Dictionary, vittima: Dictionary) -> void:
	pass

func _fatica_ferite(p: Dictionary) -> bool:
	var u: Dictionary = C["uso"][p["pid"]]
	var ev := false
	# fatica
	var da_affaticare := 0
	if r.ha_abilita(p, "furia"):
		da_affaticare = max(0, int(u["sforzo"]) - 1)
	elif int(u["sforzo"]) >= 2:
		da_affaticare = 1
	var guardia := 0
	while da_affaticare > 0 and guardia < 6:
		guardia += 1
		var opz := []
		for i in r.chit_attivi(p):
			var c: Dictionary = p["chits"][i]
			if c["sforzi"] > 0 and c["sforzi"] <= da_affaticare + 1 and not c.has("tes"):
				opz.append(i)
		if opz.is_empty():
			break
		var sc = await r.decidi(p, "fatica", {"opzioni": opz, "quanti": da_affaticare})
		var ci: int = int(sc) if (sc is int or sc is float) and int(sc) in opz else int(opz[0])
		var c: Dictionary = p["chits"][ci]
		c["stato"] = "f"
		da_affaticare -= int(c["sforzi"])
		r.scrivi("%s si affatica: %s." % [p["nome"], r.descr_chit(c)])
		ev = true
	# ferite
	var n := int(u["ferite"])
	while n > 0 and u["ucciso_da"] == "":
		var opz: Array = r.chit_attivi(p).filter(func(i): return not p["chits"][i].has("tes"))
		if opz.is_empty():
			for i in range(p["chits"].size()):
				if p["chits"][i]["stato"] == "f" and not p["chits"][i].has("tes"):
					opz.append(i)
		if opz.is_empty():
			u["ucciso_da"] = "ferite"
			break
		var sc = await r.decidi(p, "ferita", {"opzioni": opz, "quanti": n})
		var ci: int = int(sc) if (sc is int or sc is float) and int(sc) in opz else int(opz[0])
		p["chits"][ci]["stato"] = "w"
		r.scrivi("%s è ferit{oa}: %s." % [p["nome"], r.descr_chit(p["chits"][ci])], "male")
		n -= 1
		ev = true
	var tutti_feriti := true
	for c in p["chits"]:
		if c["stato"] != "w" and c["tipo"] != "C" and not c.has("tes"):
			tutti_feriti = false
	if tutti_feriti and u["ucciso_da"] == "":
		u["ucciso_da"] = "ferite"
	if u["ucciso_da"] != "":
		_morte(p, u["ucciso_da"])
		ev = true
	return ev

func _morte(p: Dictionary, da: String) -> void:
	p["morto"] = true
	var k: String = p["dove"]
	r.scrivi("%s è mort{oa}!" % p["nome"], "titolo")
	if da.begins_with("p"):
		var killer := _pg(da)
		if not killer.is_empty() and not killer["morto"]:
			killer["uccisi_pg"] += 1
			killer["noto"] += p["noto"]
			var n: int = C["molt"].get(killer["pid"], 0) + 1
			C["molt"][killer["pid"]] = n
			for o in p["oggetti"]:
				var x: Dictionary = o.duplicate()
				x["attivo"] = false
				killer["oggetti"].append(x)
			if not p["oggetti"].is_empty():
				r.scrivi("%s prende gli oggetti di %s." % [killer["nome"], p["nome"]])
	if not da.begins_with("p"):
		for o in p["oggetti"]:
			if not o.has("tes"):
				r.lascia(k, o)
	p["oggetti"] = []
	for mid in C["assegnati"].keys():
		if C["assegnati"][mid] == p["pid"]:
			C["assegnati"].erase(mid)
	C["ordine"].erase(p["pid"])
	p["dove_morte"] = k
	if r.e_classico() and int(r.s["giorno"]) < 28:
		# In seconda edizione un personaggio caduto puo rientrare dal giorno seguente.
		p["reingresso_giorno"] = int(r.s["giorno"]) + 1
	r.controlla_vittoria()

# ------------------------------------------------------------ incantesimi in combattimento
func _prepara_incantesimo(p: Dictionary, sc: Dictionary, opz: Dictionary) -> void:
	var scelto := {}
	for x in opz.get("incantesimi", []):
		if x["inc"] == sc.get("inc", ""):
			scelto = x
	if scelto.is_empty():
		return
	var mz: Dictionary = scelto["mezzi"][clampi(int(sc.get("mezzo", 0)), 0, scelto["mezzi"].size() - 1)]
	if mz.has("chit"):
		if not _sforzo_ok(p, int(mz["chit"])):
			r.scrivi("%s è troppo stanc{oa} per lanciare un incantesimo ora." % p["nome"])
			return
		_usa(p, int(mz["chit"]))
	var id: String = scelto["inc"]
	r.arcano.paga(p, id, mz, int(scelto["colore"]))
	var b: String = str(sc.get("bersaglio", p["pid"]))
	if not (b in opz.get("bersagli_inc", [])):
		b = p["pid"]
	C["uso"][p["pid"]]["incantesimo"] = {"inc": id, "bersaglio": b}
	if p["nascosto"] and Arcano.inc(id)["durata"] == "Attack":
		p["nascosto"] = false
	r.scrivi("%s prepara l'incantesimo %s." % [p["nome"], Arcano.inc(id)["nome"]])

func _mostro_trattenuto(m: Dictionary, bers: String) -> bool:
	var mg: Dictionary = C["magia"]
	if mg["luce"] or mg["pace"].has(m["id"]):
		return true
	if mg["pentacolo"].has(bers) and m["tipo"] in Arcano.DEMONI:
		return true
	if mg["goblin"].has(bers) and (str(m["tipo"]).begins_with("goblin") or m["tipo"] == "orco_m"):
		return true
	if mg["pipistrelli"].has(bers) and m["tipo"] == "pipistrello":
		return true
	if r.s["scenario"] >= 4 and bers.begins_with("p") and m["tipo"] in Arcano.DEMONI and not r.arcano.eff(_pg(bers), "santo").is_empty():
		return true
	return false

func _risolvi_incantesimi() -> bool:
	var ev := false
	for p in _in_lotta():
		var u: Dictionary = C["uso"][p["pid"]]
		if u["incantesimo"].is_empty():
			continue
		var id: String = u["incantesimo"]["inc"]
		var b: String = u["incantesimo"]["bersaglio"]
		var x := Arcano.inc(id)
		var e: String = x["eff"]
		var dur: String = x["durata"]
		r.scrivi("%s lancia %s!" % [p["nome"], x["nome"]], "bene")
		if b.begins_with("p") and C["magia"]["antimagia"].has(b) and b != p["pid"]:
			r.scrivi("La Protezione dalla magia respinge l'incantesimo.")
			r.arcano.sciogli(p, id)
			continue
		match e:
			"vampata":
				for m in _mostri_qui(C["k"]):
					if await _colpo_magico(p, m["id"], 1, 3, 13): ev = true
				if b.begins_with("p") and b != p["pid"]:
					if await _colpo_magico(p, b, 1, 3, 13): ev = true
			"pietre":
				var bs: Array = _mostri_qui(C["k"]).map(func(m): return m["id"])
				if bs.is_empty() and b != p["pid"]:
					bs = [b]
				if not bs.is_empty():
					for i in range(4):
						if await _colpo_magico(p, bs[i % bs.size()], 1, 1, 15): ev = true
			"fulmine":
				if await _colpo_magico(p, b, 2, 3, 18): ev = true
			"ghiaccio":
				if await _colpo_magico(p, b, 1, 3, 13): ev = true
			"inondazione":
				for q in _in_lotta():
					if await _colpo_magico(p, q["pid"], 2, 1, 18): ev = true
				for m in _mostri_qui(C["k"]):
					if await _colpo_magico(p, m["id"], 2, 1, 18): ev = true
			"crollo":
				for q in _in_lotta():
					if await _colpo_magico(p, q["pid"], 3, 0, 18, false): ev = true
				for m in _mostri_qui(C["k"]):
					if await _colpo_magico(p, m["id"], 3, 0, 18, false): ev = true
			"pace":
				if not b.begins_with("p"):
					C["magia"]["pace"][b] = true
					C["assegnati"].erase(b)
					r.scrivi("%s si placa e non attaccherà più." % _nome(b), "bene")
			"smussa":
				if not b.begins_with("p"):
					if not C["magia"].has("smussati"): C["magia"]["smussati"] = {}
					C["magia"]["smussati"][b] = true
			"esorcismo":
				for m in _mostri_qui(C["k"]):
					if m["tipo"] in Arcano.DEMONI:
						_uccidi_mostro(p, m)
						ev = true
			"anima":
				for m in _mostri_qui(C["k"]):
					if str(m["tipo"]).begins_with("scheletro") or m["tipo"] in Arcano.NON_MORTI:
						if r.d6() <= 3:
							_uccidi_mostro(p, m)
							ev = true
			"corteccia", "scudo_sacro", "pentacolo", "antimagia", "protezione", "grazia", "arma_incantata", "goblin", "pipistrelli":
				var chi: String = b if b.begins_with("p") else p["pid"]
				if e in ["goblin", "pipistrelli"]:
					chi = p["pid"]
				C["magia"][e][chi] = true
				r.scrivi("L'incantesimo protegge %s per questo combattimento." % _nome(chi), "bene")
				C["legati"].append([p["pid"], id])
				continue
			_:
				var q: Dictionary = _pg(b) if b.begins_with("p") else p
				if dur == "Instant":
					r.arcano.lancia_istantaneo(p, q, id)
				else:
					r.arcano.applica_effetto_giorno(p, q, id)
					continue
		r.arcano.sciogli(p, id)
		u["incantesimo"] = {}
	return ev

func _uccidi_mostro(p: Dictionary, m: Dictionary) -> void:
	m["morto"] = true
	m["dove"] = ""
	C["assegnati"].erase(m["id"])
	var n: int = C["molt"].get(p["pid"], 0) + 1
	C["molt"][p["pid"]] = n
	r.scrivi("%s è distrutto dalla magia." % r.nome_mostro(m), "bene")
	r.uccisione_mostro(p, m, n)

func _colpo_magico(p: Dictionary, bid: String, peso: int, stelle: int, _lung: int, missile := true) -> bool:
	## attacco di un incantesimo: restituisce true se il bersaglio muore
	if _morto(bid):
		return false
	if bid.begins_with("p"):
		var q := _pg(bid)
		if C["magia"]["antimagia"].has(bid) and bid != p["pid"]:
			return false
		var arm := _armatura_colpita(q, "smash")
		var st := stelle
		if (not arm.is_empty() or C["magia"]["corteccia"].has(bid)) and st > 0:
			st -= 1
		var h := peso + st
		var testo := ""
		if missile:
			var mt := _missile(h, false, false)
			h = mt[0]
			testo = " (dado %d)" % mt[1]
		var vq := r.vulnerabilita(q) + (1 if C["magia"]["protezione"].has(bid) else 0)
		if not arm.is_empty() and h < 5:
			if h >= r.peso_oggetto(arm):
				q["oggetti"].erase(arm)
				r.scrivi("La magia di %s distrugge %s di %s%s." % [p["nome"], Dati.nome_arma(arm["id"]), q["nome"], testo], "male")
			else:
				r.scrivi("L'armatura di %s regge alla magia%s." % [q["nome"], testo])
			if h >= 2:
				C["uso"][bid]["ferite"] += 1
			return false
		if h >= vq:
			r.scrivi("La magia di %s uccide %s%s!" % [p["nome"], q["nome"], testo], "male")
			C["uso"][bid]["ucciso_da"] = p["pid"] if q != p else "magia"
			return true
		if h >= 1:
			C["uso"][bid]["ferite"] += 1
			r.scrivi("La magia di %s ferisce %s%s." % [p["nome"], q["nome"], testo], "male")
		else:
			r.scrivi("La magia di %s non fa danno a %s%s." % [p["nome"], q["nome"], testo])
		return false
	var m := r.M(bid)
	var d := Dati.tipo_mostro(m["tipo"])
	var col: String = {"anomalia_grigia": "grey", "anomalia_oro": "gold", "anomalia_viola": "purple", "anomalia_prisma": "purple"}.get(m["tipo"], "")
	if col != "" and col == "purple":
		r.scrivi("%s è immune a questa magia." % r.nome_mostro(m))
		return false
	var st2 := stelle
	if d.get("armato", false) and st2 > 0:
		st2 -= 1
	var h2 := peso + st2
	var testo2 := ""
	if missile:
		var mt2 := _missile(h2, false, false)
		h2 = mt2[0]
		testo2 = " (dado %d)" % mt2[1]
	if h2 >= Dati.peso_i(d["peso"]):
		m["morto"] = true
		m["dove"] = ""
		C["assegnati"].erase(m["id"])
		var n: int = C["molt"].get(p["pid"], 0) + 1
		C["molt"][p["pid"]] = n
		r.scrivi("La magia di %s abbatte %s (danno %s%s)." % [p["nome"], r.nome_mostro(m), Dati.NOMI_PESO[Dati.peso_s(h2)], testo2], "bene")
		r.uccisione_mostro(p, m, n)
		return true
	r.scrivi("La magia di %s colpisce %s, ma non basta (danno %s%s)." % [p["nome"], r.nome_mostro(m), Dati.NOMI_PESO[Dati.peso_s(h2)], testo2])
	return false

# ------------------------------------------------------------ nativi ingaggiati
func _attacchi_alleati() -> bool:
	var ev := false
	for a in _alleati_qui(C["k"]):
		var nemici := _mostri_qui(C["k"])
		if nemici.is_empty():
			break
		var bersaglio: Dictionary = nemici[r.rng.randi_range(0, nemici.size() - 1)]
		var da := Dati.tipo_mostro(a["tipo"])
		var at := Dati.attacco(str(da["chiaro"][0]))
		if at["f"] == "":
			at = Dati.attacco(str(da["scuro"][0]))
		if at["f"] == "":
			continue
		var db := Dati.tipo_mostro(bersaglio["tipo"])
		var colpisce: bool = int(at["v"]) < vel_mossa_mostro(bersaglio) or r.d6() <= 2
		var nome_a: String = r.nome_mostro(a)
		if not colpisce:
			r.scrivi("%s manca %s." % [nome_a, r.nome_mostro(bersaglio)])
			continue
		var st: int = int(at["s"])
		if db.get("armato", false) and st > 0:
			st -= 1
		var h := Dati.peso_i(at["f"]) + st
		if h >= Dati.peso_i(db["peso"]):
			bersaglio["morto"] = true
			bersaglio["dove"] = ""
			C["assegnati"].erase(bersaglio["id"])
			r.scrivi("%s uccide %s." % [nome_a, r.nome_mostro(bersaglio)], "bene")
			var capo := r.P(r.s["nativi"][a["nativo"]]["ingaggio"])
			if not capo.is_empty():
				r.uccisione_mostro(capo, bersaglio, 1)
			ev = true
		else:
			r.scrivi("%s colpisce %s senza abbatterlo." % [nome_a, r.nome_mostro(bersaglio)])
	return ev
