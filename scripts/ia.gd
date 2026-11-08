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
	var resto := n - pl.size()
	var arrivato: bool = percorso.is_empty() or (pl.size() > 0 and pl[pl.size() - 1].get("dest", "") == dest)
	for i in range(resto):
		if r.s["scenario"] >= 3 and i == resto - 1 and not obiettivo.get("caccia", false):
			pl.append({"a": "H"})
		elif obiettivo.get("cerca", false) and arrivato:
			pl.append({"a": "S"})
		elif r.s["scenario"] >= 2 and sal[1] + sal[2] > 0:
			pl.append({"a": "R"})
		elif r.s["scenario"] >= 2 and not r.arma_attiva(p).is_empty() and not r.arma_attiva(p)["allerta"]:
			pl.append({"a": "A"})
		elif r.s["scenario"] >= 2:
			pl.append({"a": "H"})
		else:
			pl.append({"a": "S"})
	return pl

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
	if not d["fuga"].is_empty() and (sal[0] <= 4 or _assegnati_pericolosi(p) or _imbattibili(p)):
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
