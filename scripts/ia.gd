## Intelligenza dei personaggi rivali (e del giocatore nelle partite automatiche):
## pianifica la giornata, sceglie le tabelle di ricerca, combatte, riposa.
class_name IA
extends RefCounted

var r: Reame

func _init(reame: Reame) -> void:
	r = reame

func decidi(p: Dictionary, tipo: String, d: Dictionary):
	match tipo:
		"piano": return piano(p, d["fasi"])
		"tabella": return tabella(p, d)
		"scelta": return scelta(p, d)
		"riposo": return riposo(p, d)
		"blocca": return r.s["scenario"] == 2 and _forte_contro(p, r.P(d["bersaglio"]))
		"combatti_pg": return false
		"anticipa": return true
		"adesca": return []
		"carica": return {}
		"azione": return azione(p, d)
		"bersaglio": return bersaglio(p, d)
		"mischia": return mischia(p, d)
		"fatica": return _meno_utile(p, d["opzioni"], true)
		"ferita": return _meno_utile(p, d["opzioni"], false)
		"incanto": return _incanto(p, d)
		"incantesimo_sera": return _sera(p, d)
		"commercio": return _commercio(p, d)
		"viaggiatore": return _viaggiatore(p, d)
		"assegna_pv": return {}
		"ingaggio": return _ingaggio(p, d)
		"conferma": return d.get("puo", false) and d["testo"].find("ingaggi") < 0
	return null

func vuole_berserk(_p: Dictionary) -> bool:
	return true

# ------------------------------------------------------------ pianificazione
func _n_fasi(d: Dictionary) -> int:
	return int(d["base"]) + int(d["luce"]) + d["extra"].size()

func _stato_salute(p: Dictionary) -> Array:
	var a := 0
	var f := 0
	var w := 0
	for c in p["chits"]:
		match c["stato"]:
			"a": a += 1
			"f": f += 1
			"w": w += 1
	return [a, f, w]

func piano(p: Dictionary, d: Dictionary) -> Array:
	var n := _n_fasi(d)
	var sal := _stato_salute(p)
	var pl := []
	# troppo malconcio: riposa
	if r.s["scenario"] >= 2 and (sal[1] + sal[2] >= 4 or r.movimento_max(p) < r.carico_max(p)):
		for i in range(n):
			pl.append({"a": "R"})
		if r.s["scenario"] >= 3 and not p["nascosto"]:
			pl[0] = {"a": "H"}
		return pl
	var obiettivo := _obiettivo(p)
	var dest: String = obiettivo.get("dest", "")
	var percorso: Array = []
	if dest != "" and dest != p["dove"]:
		percorso = percorso_verso(p, p["dove"], dest)
	var fasi_mov := 0
	for k in percorso:
		var costo: int = k[1]
		if fasi_mov + costo > n - (1 if obiettivo.get("cerca", false) else 0):
			break
		for j in range(costo):
			pl.append({"a": "M", "dest": k[0]})
		fasi_mov += costo
	if r.s["scenario"] >= 3 and _mostri_in_tessera(p) and not obiettivo.get("caccia", false) and pl.size() < n:
		pl.push_front({"a": "H"})
		while pl.size() > n:
			pl.pop_back()
	if r.usa_regola("commercio") and pl.is_empty() and not _da_vendere(p).is_empty() and not r.nativi.opzioni_commercio(p).is_empty():
		pl.append({"a": "T"})
	if r.usa_regola("magia") and _vuole_incantare(p) and pl.size() <= n - 2:
		pl.append({"a": "E"})
		pl.append({"a": "E"})
	var resto := n - pl.size()
	var arrivato: bool = percorso.is_empty() or (pl.size() > 0 and pl[pl.size() - 1].get("dest", "") == dest)
	for i in range(resto):
		if r.s["scenario"] >= 3 and i == resto - 1 and not obiettivo.get("caccia", false):
			pl.append({"a": "H"})
		elif obiettivo.get("cerca", false) and arrivato:
			pl.append({"a": "S"})
		elif r.s["scenario"] >= 2 and sal[1] + sal[2] > 0:
			pl.append({"a": "R"})
		elif r.usa_regola("combattimento_mostri") and not r.arma_attiva(p).is_empty() and not r.arma_attiva(p)["allerta"]:
			pl.append({"a": "A"})
		elif r.s["scenario"] >= 2:
			pl.append({"a": "H"})
		else:
			pl.append({"a": "S"})
	return pl

func _vuole_incantare(p: Dictionary) -> bool:
	if not r.arcano.chit_colore(p).is_empty():
		return false
	var per_tipo := {}
	for c in p["chits"]:
		if c["tipo"] == "G" and c["stato"] == "a":
			per_tipo[c["magia"]] = per_tipo.get(c["magia"], 0) + 1
	for id in p.get("incantesimi", []):
		var x := Arcano.inc(id)
		if x["eff"] == "" or x["colore"] == "any":
			continue
		for t in Arcano.TIPO_COLORE:
			if Arcano.TIPO_COLORE[t] == x["colore"] and per_tipo.get(t, 0) >= 1 and per_tipo.get(x["tipo"], 0) >= (2 if t == x["tipo"] else 1):
				return true
	return false

func _mostri_in_tessera(p: Dictionary) -> bool:
	var t := r.tessera(p["dove"])
	for id in r.s["mostri"]:
		var m: Dictionary = r.s["mostri"][id]
		if not m["morto"] and m["dove"] != "" and r.tessera(m["dove"]) == t:
			return true
	return false

func _obiettivo(p: Dictionary) -> Dictionary:
	var sc: int = r.s["scenario"]
	if sc == 2:
		var best := ""
		var bd := 999
		for q in r.vivi():
			if q == p:
				continue
			var dd := _distanza(p, p["dove"], q["dove"])
			if dd < bd:
				bd = dd
				best = q["dove"]
		return {"dest": best, "caccia": true}
	# siti e missioni conosciuti
	var mete := []
	for t in range(40):
		var st: Dictionary = r.s["tessere"][str(t)]
		if not (st["scoperti"] or p["sbirciati"].has(str(t))):
			continue
		if sc == 1:
			for q in r.s["missioni_pubbliche"]:
				if q in p["fatte"]:
					continue
				var m: Dictionary = Dati.missioni[q]
				var av: Dictionary = Dati.segnalini.get(st["avviso"], {})
				if "%s_%s" % [str(av.get("nome_base", "")).to_upper(), av.get("lettera", "")] == m["avviso"]:
					var n := r.radura_bersaglio_trek(t)
					if n > 0:
						mete.append(Mappa.chiave(t, n))
		else:
			for x in st["rossi"]:
				var c: Dictionary = Dati.segnalini[x]
				if c["tipo"] == "sito" and not (x in p["siti"]):
					mete.append(Mappa.chiave(t, int(c["radura"])))
				if c["tipo"] == "perduto":
					for q in r.s["missioni_pubbliche"]:
						if Dati.missioni[q]["tipo"] == "trova_perduto" and Dati.missioni[q]["perduto"] == str(c["nome_base"]).to_lower() and not (q in p["fatte"]):
							mete.append(Mappa.chiave(t, int(c["radura"])))
	if sc >= 4:
		for x in p["siti"]:
			var c: Dictionary = Dati.segnalini[x]
			var sito := str(c["nome_base"]).to_lower()
			var st: Dictionary = r.s["siti_tesori"].get(sito, {})
			if st.is_empty() or (st["carte"].is_empty() and (st["inc"].is_empty() or int(r.def_pg(p).get("magia", 0)) == 0)):
				continue
			if not st["aperto"] and not _puo_aprire(p):
				continue
			for t2 in range(40):
				if x in r.s["tessere"][str(t2)]["rossi"]:
					mete.append(Mappa.chiave(t2, int(c["radura"])))
		for w in p.get("twt", []):
			if not r.s["twt"][w]["carte"].is_empty() and r.s["twt"][w]["dove"] != "":
				mete.append(r.s["twt"][w]["dove"])
		for k2 in r.s.get("mucchi", {}):
			if not r.s["mucchi"][k2].is_empty() and _distanza(p, p["dove"], k2) <= 4:
				mete.append(k2)
	var best := ""
	var bd := 999
	for k in mete:
		if not r.mappa.radure.has(k):
			continue
		var dd := _distanza(p, p["dove"], k) + r.rng.randi_range(0, 2) + _affollamento(p, k)
		if dd < bd:
			bd = dd
			best = k
	if best != "":
		return {"dest": best, "cerca": true}
	# esplora: la tessera non ancora scoperta più vicina (nello scenario 1 delle categorie delle missioni)
	var cat_utili := {}
	if sc == 1:
		for q in r.s["missioni_pubbliche"]:
			if not (q in p["fatte"]):
				cat_utili[Dati.missioni[q]["gruppo"]] = true
	var dist := _dijkstra(p, p["dove"])
	var meta := ""
	var md := 999
	for k in dist:
		var t := r.tessera(k)
		var st: Dictionary = r.s["tessere"][str(t)]
		if st["scoperti"] or p["sbirciati"].has(str(t)):
			continue
		if Dati.tessere[t]["cl"].size() < 6 and sc != 1:
			continue
		if sc == 1 and not cat_utili.has(r.cat_tessera(t)):
			continue
		var dk: int = dist[k] + r.rng.randi_range(0, 3) + _affollamento(p, k)
		if dk < md:
			md = dk
			meta = k
	if meta != "":
		return {"dest": meta, "cerca": sc == 1}
	return {"dest": "", "cerca": true}

func _puo_aprire(p: Dictionary) -> bool:
	if not r.arcano.eff(p, "chiave").is_empty():
		return true
	for c in p["chits"]:
		if c["tipo"] in ["M", "F"] and str(c.get("forza", "")) == "T":
			return true
	return false

func _affollamento(p: Dictionary, k: String) -> int:
	var t := r.tessera(k)
	var n := 0
	for q in r.vivi():
		if q != p and r.tessera(q["dove"]) == t:
			n += 4
	return n

func _distanza(p: Dictionary, a: String, b: String) -> int:
	var d := _dijkstra(p, a)
	return d.get(b, 999)

func _dijkstra(p: Dictionary, a: String) -> Dictionary:
	var dist := {a: 0}
	var aperti := [a]
	while not aperti.is_empty():
		var best := 0
		for i in range(aperti.size()):
			if dist[aperti[i]] < dist[aperti[best]]:
				best = i
		var k: String = aperti[best]
		aperti.remove_at(best)
		for b in r.vicini_di(p, k):
			var c: int = dist[k] + r.costo_mossa(p, k, b) + (1 if r.tipo_radura(b) == "C" else 0)
			if c < dist.get(b, 99999):
				dist[b] = c
				aperti.append(b)
	return dist

func percorso_verso(p: Dictionary, a: String, b: String) -> Array:
	## [[radura, costo], ...]
	var dist := {a: 0}
	var prev := {}
	var aperti := [a]
	while not aperti.is_empty():
		var best := 0
		for i in range(aperti.size()):
			if dist[aperti[i]] < dist[aperti[best]]:
				best = i
		var k: String = aperti[best]
		aperti.remove_at(best)
		if k == b:
			break
		for x in r.vicini_di(p, k):
			var c: int = dist[k] + r.costo_mossa(p, k, x) + (1 if r.tipo_radura(x) == "C" else 0)
			if c < dist.get(x, 99999):
				dist[x] = c
				prev[x] = k
				aperti.append(x)
	if not prev.has(b):
		return []
	var cam := []
	var k := b
	while k != a:
		cam.push_front([k, r.costo_mossa(p, prev[k], k)])
		k = prev[k]
	return cam

# ------------------------------------------------------------ ricerca
func tabella(p: Dictionary, _d: Dictionary) -> Dictionary:
	var fo: Dictionary = _d.get("fonti", {})
	if not fo.get("saccheggia", []).is_empty():
		return {"tabella": "saccheggia", "fonte": fo["saccheggia"][0]["id"]}
	if r.usa_regola("magia") and not fo.get("rune", []).is_empty() and (int(r.def_pg(p).get("magia", 0)) > 0 or r.rng.randi_range(0, 2) == 0):
		return {"tabella": "rune", "fonte": fo["rune"][0]["id"]}
	var t := r.tessera(p["dove"])
	if p["indizi"].has(str(t)):
		return {"tabella": "localizza", "radura": p["dove"]}
	if r.s["scenario"] >= 2 and r.rng.randi_range(0, 3) == 0:
		return {"tabella": "cerca", "radura": p["dove"]}
	return {"tabella": "scruta", "radura": p["dove"]}

func scelta(p: Dictionary, d: Dictionary) -> String:
	var t := r.tessera(p["dove"])
	if p["indizi"].has(str(t)) or r.s["scenario"] != 2:
		return "scopri"
	return "sentieri"

# ------------------------------------------------------------ riposo
func riposo(p: Dictionary, d: Dictionary) -> int:
	var opz: Array = d["opzioni"]
	var best := 0
	var bv := -99
	for i in range(opz.size()):
		var o: Dictionary = opz[i]
		var c: Dictionary = p["chits"][o["i"]]
		var v := 0
		if c["tipo"] == "M": v += 3
		if c["tipo"] == "F": v += 2
		if o["da"] == "w": v += 1
		if o["resto"] >= 0: v -= 2
		if v > bv:
			bv = v
			best = i
	return best

# ------------------------------------------------------------ combattimento
func _potenza(p: Dictionary) -> int:
	var a := r.arma_attiva(p)
	var id: String = a.get("id", "pugnale")
	var w: Dictionary = Dati.oggetti["armi"][id]
	var lato: Array = w["inallerta"]
	var h := Dati.peso_i(lato[0]) + int(lato[1])
	var forza := 0
	for i in r.chit_attivi(p):
		var c: Dictionary = p["chits"][i]
		if c["tipo"] == "F":
			forza = max(forza, r.forza_chit(c))
	if not w["missile"] and forza > Dati.peso_i(w["peso"]):
		h += 1
	return h

func _forte_contro(p: Dictionary, q: Dictionary) -> bool:
	if q.is_empty():
		return false
	return _potenza(p) >= r.vulnerabilita(q) - 1

func azione(p: Dictionary, d: Dictionary) -> Dictionary:
	var sal := _stato_salute(p)
	var magia := _incantesimo_combattimento(p, d)
	if not magia.is_empty() and (sal[0] > 3 or d["fuga"].is_empty()):
		return magia
	if not d["fuga"].is_empty() and (sal[0] <= 4 or _assegnati_pericolosi(p) or _imbattibili(p) or _letali(p)):
		return {"tipo": "fuga", "chit": d["fuga"][0]}
	if d["berserk"] >= 0:
		return {"tipo": "berserk", "chit": d["berserk"]}
	if d["riflessi"] >= 0:
		return {"tipo": "riflessi", "chit": d["riflessi"]}
	if not d["allerta"].is_empty() and r.combat.C.get("round", 1) == 1:
		var best: int = d["allerta"][0]
		for i in d["allerta"]:
			if p["chits"][i]["sforzi"] < p["chits"][best]["sforzi"]:
				best = i
		if p["chits"][best]["sforzi"] == 0:
			return {"tipo": "allerta", "chit": best}
	return {}

func _incantesimo_combattimento(p: Dictionary, d: Dictionary) -> Dictionary:
	var C: Dictionary = r.combat.C
	var mostri := []
	for b in d.get("bersagli_inc", []):
		if not str(b).begins_with("p"):
			mostri.append(b)
	var miei := []
	for mid in C.get("assegnati", {}):
		if C["assegnati"][mid] == p["pid"]:
			miei.append(mid)
	for x in d.get("incantesimi", []):
		var e: String = Arcano.inc(x["inc"])["eff"]
		if e in ["vampata", "pietre"] and not mostri.is_empty():
			return {"tipo": "incantesimo", "inc": x["inc"], "mezzo": 0, "bersaglio": mostri[0]}
		if e in ["fulmine", "ghiaccio"] and not mostri.is_empty():
			return {"tipo": "incantesimo", "inc": x["inc"], "mezzo": 0, "bersaglio": miei[0] if not miei.is_empty() else mostri[0]}
		if e == "pace" and not miei.is_empty():
			return {"tipo": "incantesimo", "inc": x["inc"], "mezzo": 0, "bersaglio": miei[0]}
		if e == "esorcismo":
			for b in mostri:
				if r.M(b)["tipo"] in Arcano.DEMONI:
					return {"tipo": "incantesimo", "inc": x["inc"], "mezzo": 0, "bersaglio": b}
		if e in ["corteccia", "protezione", "scudo_sacro"] and not miei.is_empty():
			return {"tipo": "incantesimo", "inc": x["inc"], "mezzo": 0, "bersaglio": p["pid"]}
	return {}

func _incanto(p: Dictionary, d: Dictionary) -> int:
	var opz: Array = d["opzioni"]
	for i in range(opz.size()):
		if opz[i]["tipo"] == "chit":
			return i
	return 0

func _sera(p: Dictionary, d: Dictionary) -> Dictionary:
	var sal := _stato_salute(p)
	for x in d["lista"]:
		var e: String = Arcano.inc(x["inc"])["eff"]
		if e == "guarigione" and sal[1] + sal[2] >= 3:
			return {"inc": x["inc"], "mezzo": 0}
		if e == "rimedio" and not p["maledizioni"].is_empty():
			return {"inc": x["inc"], "mezzo": 0}
		if e in ["fase_S", "fase_H", "fase_A", "fiuto", "sfortuna_cerca"] and not p["effetti"].has(e) and sal[0] >= 6:
			if e == "sfortuna_cerca":
				continue
			return {"inc": x["inc"], "mezzo": 0}
	return {}

func _da_vendere(p: Dictionary) -> Array:
	var a := []
	var armi := 0
	for o in p["oggetti"]:
		if Dati.oggetti["armi"].has(o["id"]):
			armi += 1
	for o in p["oggetti"]:
		if Arcano.e_tesoro(o["id"]):
			var t := Arcano.tesoro(o["id"])
			if t.get("eff", {}).is_empty() and not t.get("grande", false) and int(t["oro"]) > 0:
				a.append(o["id"])
		elif Dati.oggetti["armi"].has(o["id"]) and not o["attivo"] and armi > 1:
			a.append(o["id"])
	return a

func _viaggiatore(p: Dictionary, d: Dictionary) -> bool:
	var t: String = Viaggi.v(d["id"]).get("tipo", "")
	if t == "N":
		return int(p["oro"]) >= 3
	return t in ["M", "T"]

func _commercio(p: Dictionary, d: Dictionary) -> Dictionary:
	var v := _da_vendere(p)
	if v.is_empty() or d["gruppi"].is_empty():
		return {}
	return {"gruppo": d["gruppi"][0]["gruppo"], "tipo": "vendi", "oggetti": v}

func _ingaggio(p: Dictionary, d: Dictionary) -> Dictionary:
	for g in d["gruppi"]:
		if int(g["oro"]) * 2 <= int(p["oro"]) and g["rapporto"] in ["Amichevole", "Alleato"]:
			return {"gruppo": g["gruppo"]}
	return {}

func _letali(p: Dictionary) -> bool:
	## qualcuno che mi attacca può uccidermi con un colpo solo
	var C: Dictionary = r.combat.C
	var vu := r.vulnerabilita(p)
	for mid in C.get("assegnati", {}):
		if C["assegnati"][mid] == p["pid"]:
			var m := r.M(mid)
			var d := Dati.tipo_mostro(m["tipo"])
			for lato in [d["chiaro"], d["scuro"]]:
				var at := Dati.attacco(str(lato[0]))
				if at["f"] != "" and Dati.peso_i(at["f"]) + int(at["s"]) >= vu:
					return true
	return false

func _imbattibili(p: Dictionary) -> bool:
	var C: Dictionary = r.combat.C
	var pot := _potenza(p)
	for mid in C.get("assegnati", {}):
		if C["assegnati"][mid] == p["pid"]:
			var m := r.M(mid)
			if Dati.peso_i(Dati.tipo_mostro(m["tipo"])["peso"]) > pot:
				return true
	return false

func _assegnati_pericolosi(p: Dictionary) -> bool:
	var C: Dictionary = r.combat.C
	for mid in C.get("assegnati", {}):
		if C["assegnati"][mid] == p["pid"]:
			var m := r.M(mid)
			var pe: String = Dati.tipo_mostro(m["tipo"])["peso"]
			if Dati.peso_i(pe) > _potenza(p) and m["lato"] == 1:
				return true
	return false

func bersaglio(p: Dictionary, d: Dictionary) -> String:
	var C: Dictionary = r.combat.C
	var pot := _potenza(p)
	var miei := []
	for mid in C.get("assegnati", {}):
		if C["assegnati"][mid] == p["pid"] and mid in d["bersagli"]:
			miei.append(mid)
	var best := ""
	var bv := -99
	for id in miei:
		var m := r.M(id)
		var vul := Dati.peso_i(Dati.tipo_mostro(m["tipo"])["peso"])
		if pot < vul:
			continue
		var v := 10 - vul
		if v > bv:
			bv = v
			best = id
	if best != "":
		return best
	if r.s["scenario"] == 2 or (p["umano"] and r.auto_umano and r.s["scenario"] == 2):
		for id in d["bersagli"]:
			if id.begins_with("p"):
				return id
	return ""

func mischia(p: Dictionary, d: Dictionary) -> Dictionary:
	var res := {}
	var sforzo: int = d["sforzo"]
	var furia := r.ha_abilita(p, "furia")
	var dirs := ["thrust", "swing", "smash"]
	var mans := ["charge", "dodge", "duck"]
	if d["bersaglio"] != "" and not d["fight"].is_empty():
		var best := -1
		var bv := -999
		for i in d["fight"]:
			var c: Dictionary = p["chits"][i]
			if not furia and sforzo + int(c["sforzi"]) > 2:
				continue
			var v: int = r.forza_chit(c) * 10 - r.vel_chit(p, c) * 3 - int(c["sforzi"]) * 2
			if v > bv:
				bv = v
				best = i
		if best >= 0:
			res["attacco"] = {"cerchio": dirs[r.rng.randi_range(0, 2)], "chit": best}
			sforzo += int(p["chits"][best]["sforzi"])
	if not d["move"].is_empty() and d.get("minacciato", true):
		var best := -1
		var bv := -999
		for i in d["move"]:
			var c: Dictionary = p["chits"][i]
			if not furia and sforzo + int(c["sforzi"]) > 2:
				continue
			var v: int = -r.vel_chit(p, c) * 3 - int(c["sforzi"])
			if v > bv:
				bv = v
				best = i
		if best >= 0:
			res["manovra"] = {"casella": mans[r.rng.randi_range(0, 2)], "chit": best}
	res["scudo"] = dirs[r.rng.randi_range(0, 2)]
	return res

func _meno_utile(p: Dictionary, opz: Array, fatica: bool) -> int:
	var best: int = opz[0]
	var bv := 999
	for i in opz:
		var c: Dictionary = p["chits"][i]
		var v := 0
		match c["tipo"]:
			"G": v = 0
			"M": v = 20 - int(c["vel"]) + r.forza_chit(c)
			"F": v = 24 - int(c["vel"]) + r.forza_chit(c)
			_: v = 10
		if fatica:
			v += int(c["sforzi"]) * 3
		if v < bv:
			bv = v
			best = i
	return best
