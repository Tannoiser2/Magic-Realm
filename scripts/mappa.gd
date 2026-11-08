## Il Reame: costruzione casuale della mappa a esagoni (fiume dalle Cascate alla Grotta, strade che combaciano)
## e grafo delle radure con strade, gallerie, sentieri nascosti, passaggi segreti e fiume.
class_name Mappa
extends RefCounted

const DIR := [Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0)]
const CASCATE := 31
const GROTTA := 34
const FIUMI := [32, 33, 35, 36, 37, 38, 39]

## pezzi: [{"t": indice tessera, "q", "r", "rot"}]
var pezzi: Array = []
var per_cella := {}       # Vector2i -> indice in pezzi
var per_tessera := {}     # t -> indice in pezzi
var vicini := {}          # chiave radura -> [{"a","b","tipo","id"}]
var radure := {}          # chiave -> {"t", "n", "tipo", "pos": Vector2}
var dist_grotta := {}     # radure d'acqua -> distanza lungo il fiume dalla Grotta
var _bordi := {}          # t -> Array di 6 {"k": "", "c": ""}

func _init() -> void:
	Dati.carica()
	for t in range(40):
		_bordi[t] = _calcola_bordi(t)

static func chiave(t: int, n) -> String:
	return "t%02d:%s" % [t, str(n)]

static func tessera_di(k: String) -> int:
	return int(k.substr(1, 2))

static func numero_di(k: String) -> int:
	return int(k.substr(4))

func _calcola_bordi(t: int) -> Array:
	var d: Dictionary = Dati.tessere[t]
	var b := []
	for i in range(6):
		b.append({"k": "", "c": ""})
	for lista in [["strade", "r"], ["fiume", "w"]]:
		for s in d[lista[0]]:
			var p: PackedStringArray = s.split("-")
			for j in range(2):
				if p[j].begins_with("e"):
					var e := int(p[j].substr(1))
					b[e] = {"k": lista[1], "c": p[1 - j]}
	return b

## bordo del mondo w della tessera t ruotata di rot
func bordo(t: int, rot: int, w: int) -> Dictionary:
	return _bordi[t][(w - rot + 6) % 6]

# ------------------------------------------------------------ costruzione
func genera(rng: RandomNumberGenerator) -> void:
	for tentativo in range(400):
		if _prova(rng, tentativo > 250):
			_costruisci_grafo()
			if _verifica():
				return
	push_warning("Mappa: uso l'ultima costruzione disponibile")
	_costruisci_grafo()

func _metti(t: int, c: Vector2i, rot: int) -> void:
	pezzi.append({"t": t, "q": c.x, "r": c.y, "rot": rot})
	per_cella[c] = pezzi.size() - 1
	per_tessera[t] = pezzi.size() - 1

func _combacia(t: int, c: Vector2i, rot: int) -> Array:
	## restituisce [valido, numero vicini, collegamenti [[mia radura, tessera vicina, sua radura]]]
	var nv := 0
	var links := []
	for w in range(6):
		var n: Vector2i = c + DIR[w]
		if not per_cella.has(n):
			continue
		nv += 1
		var p: Dictionary = pezzi[per_cella[n]]
		var mio: Dictionary = bordo(t, rot, w)
		var suo: Dictionary = bordo(p["t"], p["rot"], (w + 3) % 6)
		if mio["k"] != suo["k"]:
			return [false, nv, links]
		if mio["k"] != "":
			links.append([mio["c"], p["t"], suo["c"]])
	return [true, nv, links]

var _interni := {}   # t -> {n: [n vicini]}
var _conn := {}      # t -> {n: true} radure collegate al fiume

func _interno(t: int) -> Dictionary:
	if _interni.has(t):
		return _interni[t]
	var d: Dictionary = Dati.tessere[t]
	var a := {}
	for n in d["cl"]:
		a[str(n)] = []
	for lista in ["strade", "nascosti", "segreti", "fiume"]:
		for s in d[lista]:
			var p: PackedStringArray = s.split("-")
			if p[0].begins_with("e") or p[1].begins_with("e"):
				continue
			a[p[0]].append(p[1])
			a[p[1]].append(p[0])
	_interni[t] = a
	return a

func _chiudi(t: int, semi: Dictionary) -> Dictionary:
	var a := _interno(t)
	var vis := semi.duplicate()
	var coda: Array = semi.keys()
	while not coda.is_empty():
		var x: String = coda.pop_back()
		for y in a[x]:
			if not vis.has(y):
				vis[y] = true
				coda.append(y)
	return vis

func _ricalcola_conn() -> void:
	_conn.clear()
	for p in pezzi:
		var t: int = p["t"]
		var semi := {}
		for n in Dati.tessere[t]["cl"]:
			if Dati.tessere[t]["cl"][n][2] == "A":
				semi[str(n)] = true
		_conn[t] = _chiudi(t, semi)
	var cambiato := true
	while cambiato:
		cambiato = false
		for p in pezzi:
			var t: int = p["t"]
			for w in range(6):
				var n: Vector2i = Vector2i(p["q"], p["r"]) + DIR[w]
				if not per_cella.has(n):
					continue
				var p2: Dictionary = pezzi[per_cella[n]]
				var a := bordo(t, p["rot"], w)
				var b := bordo(p2["t"], p2["rot"], (w + 3) % 6)
				if a["k"] != "" and b["k"] != "" and _conn[p2["t"]].has(b["c"]) and not _conn[t].has(a["c"]):
					var semi: Dictionary = _conn[t]
					semi[a["c"]] = true
					_conn[t] = _chiudi(t, semi)
					cambiato = true

func _prova(rng: RandomNumberGenerator, _rilassato: bool) -> bool:
	pezzi.clear()
	per_cella.clear()
	per_tessera.clear()
	var rot0 := rng.randi_range(0, 5)
	_metti(CASCATE, Vector2i.ZERO, rot0)
	var aperto_cella := Vector2i.ZERO
	var aperto_w := -1
	for w in range(6):
		if bordo(CASCATE, rot0, w)["k"] == "w":
			aperto_w = w
	var fiumi: Array = FIUMI.duplicate()
	_mescola(fiumi, rng)
	fiumi.append(GROTTA)
	while not fiumi.is_empty():
		var cella: Vector2i = aperto_cella + DIR[aperto_w]
		if per_cella.has(cella):
			return false
		var messo := false
		for i in range(fiumi.size()):
			var t: int = fiumi[i]
			if t == GROTTA and fiumi.size() > 1:
				continue
			var opz := []
			for rot in range(6):
				if bordo(t, rot, (aperto_w + 3) % 6)["k"] != "w":
					continue
				var cb := _combacia(t, cella, rot)
				if not cb[0]:
					continue
				var altra := -1
				for w in range(6):
					if w != (aperto_w + 3) % 6 and bordo(t, rot, w)["k"] == "w":
						altra = w
				if altra >= 0 and per_cella.has(cella + DIR[altra]):
					continue
				opz.append([rot, altra])
			if opz.is_empty():
				continue
			var sc: Array = opz[rng.randi_range(0, opz.size() - 1)]
			_metti(t, cella, sc[0])
			fiumi.remove_at(i)
			aperto_cella = cella
			aperto_w = sc[1]
			messo = true
			break
		if not messo:
			return false
	_ricalcola_conn()
	var resto := []
	for t in range(40):
		if not per_tessera.has(t):
			resto.append(t)
	_mescola(resto, rng)
	while not resto.is_empty():
		var celle := {}
		for p in pezzi:
			for w in range(6):
				var n: Vector2i = Vector2i(p["q"], p["r"]) + DIR[w]
				if not per_cella.has(n):
					celle[n] = true
		var piazzato := false
		for i in range(resto.size()):
			var t: int = resto[i]
			var cand := []
			var tot := 0
			for cella in celle.keys():
				for rot in range(6):
					var cb := _combacia(t, cella, rot)
					if not cb[0] or cb[1] < (1 if pezzi.size() < 12 else 2):
						continue
					var buono := false
					for l in cb[2]:
						if _conn[l[1]].has(l[2]):
							buono = true
					if not buono:
						continue
					var peso: int = cb[1] * cb[1] + cb[2].size()
					tot += peso
					cand.append([cella, rot, peso])
			if cand.is_empty():
				continue
			var x := rng.randi_range(0, tot - 1)
			for c in cand:
				x -= c[2]
				if x < 0:
					_metti(t, c[0], c[1])
					break
			_ricalcola_conn()
			resto.remove_at(i)
			piazzato = true
			break
		if not piazzato:
			return false
	return true

func _mescola(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp

# ------------------------------------------------------------ grafo
func centro(i: int) -> Vector2:
	var p: Dictionary = pezzi[i]
	return Vector2(1.5 * p["q"], sqrt(3.0) * (p["r"] + p["q"] / 2.0))

func pos_locale(i: int, x: float, y: float) -> Vector2:
	var p: Dictionary = pezzi[i]
	var v := Vector2((x - 395.0) / 395.0, (y - 395.0) / 395.0)
	return centro(i) + v.rotated(deg_to_rad(60.0 * p["rot"]))

func _arco(a: String, b: String, tipo: String) -> void:
	var id := (a + "|" + b) if a < b else (b + "|" + a)
	for e in vicini.get(a, []):
		if e["b"] == b and e["tipo"] == tipo:
			return
	var e1 := {"a": a, "b": b, "tipo": tipo, "id": id}
	var e2 := {"a": b, "b": a, "tipo": tipo, "id": id}
	if not vicini.has(a): vicini[a] = []
	if not vicini.has(b): vicini[b] = []
	vicini[a].append(e1)
	vicini[b].append(e2)

func _costruisci_grafo() -> void:
	vicini.clear()
	radure.clear()
	for i in range(pezzi.size()):
		var t: int = pezzi[i]["t"]
		var d: Dictionary = Dati.tessere[t]
		for n in d["cl"]:
			var c: Array = d["cl"][n]
			var k := chiave(t, n)
			radure[k] = {"t": t, "n": int(n), "tipo": c[2], "pos": pos_locale(i, c[0], c[1])}
			vicini[k] = []
		for lista in [["strade", "strada"], ["nascosti", "nascosto"], ["segreti", "segreto"], ["fiume", "fiume"]]:
			for s in d[lista[0]]:
				var p: PackedStringArray = s.split("-")
				if p[0].begins_with("e") or p[1].begins_with("e"):
					continue
				_arco(chiave(t, p[0]), chiave(t, p[1]), lista[1])
	for i in range(pezzi.size()):
		var p: Dictionary = pezzi[i]
		for w in range(3):
			var n: Vector2i = Vector2i(p["q"], p["r"]) + DIR[w]
			if not per_cella.has(n):
				continue
			var p2: Dictionary = pezzi[per_cella[n]]
			var b1 := bordo(p["t"], p["rot"], w)
			var b2 := bordo(p2["t"], p2["rot"], (w + 3) % 6)
			if b1["k"] == "" or b2["k"] == "":
				continue
			var tipo := "fiume" if (b1["k"] == "w" and b2["k"] == "w") else "strada"
			_arco(chiave(p["t"], b1["c"]), chiave(p2["t"], b2["c"]), tipo)
	# distanze lungo il fiume dalla Grotta (per sapere se si va a monte o a valle)
	dist_grotta.clear()
	var inizio := ""
	for k in radure:
		if radure[k]["t"] == GROTTA and radure[k]["tipo"] == "A":
			inizio = k
	if inizio != "":
		var coda := [inizio]
		dist_grotta[inizio] = 0
		while not coda.is_empty():
			var k: String = coda.pop_front()
			for e in vicini[k]:
				if e["tipo"] == "fiume" and not dist_grotta.has(e["b"]):
					dist_grotta[e["b"]] = dist_grotta[k] + 1
					coda.append(e["b"])

func _verifica() -> bool:
	## ogni tessera deve avere almeno una radura collegata al fiume
	var visti := {}
	var coda := []
	for k in radure:
		if radure[k]["tipo"] == "A":
			visti[k] = true
			coda.append(k)
	while not coda.is_empty():
		var k: String = coda.pop_front()
		for e in vicini[k]:
			if not visti.has(e["b"]):
				visti[e["b"]] = true
				coda.append(e["b"])
	var ok := {}
	for k in visti:
		ok[radure[k]["t"]] = true
	return ok.size() == 40

func collegata_acqua(k: String) -> bool:
	var visti := {k: true}
	var coda := [k]
	while not coda.is_empty():
		var x: String = coda.pop_front()
		if radure[x]["tipo"] == "A":
			return true
		for e in vicini[x]:
			if not visti.has(e["b"]):
				visti[e["b"]] = true
				coda.append(e["b"])
	return false

func tessere_adiacenti(t: int) -> Array:
	var r := []
	var p: Dictionary = pezzi[per_tessera[t]]
	for w in range(6):
		var n: Vector2i = Vector2i(p["q"], p["r"]) + DIR[w]
		if per_cella.has(n):
			r.append(pezzi[per_cella[n]]["t"])
	return r

func radure_tessera(t: int) -> Array:
	var r := []
	for n in Dati.tessere[t]["cl"]:
		r.append(chiave(t, n))
	return r

func nome_radura(k: String) -> String:
	var t := tessera_di(k)
	return "%s %d" % [Dati.tessere[t]["nome"], numero_di(k)]

func sigla_radura(k: String) -> String:
	var t := tessera_di(k)
	return "%s%d" % [Dati.tessere[t]["sigla"], numero_di(k)]

func esporta() -> Array:
	return pezzi.duplicate(true)

func importa(a: Array) -> void:
	pezzi.clear()
	per_cella.clear()
	per_tessera.clear()
	for p in a:
		_metti(int(p["t"]), Vector2i(int(p["q"]), int(p["r"])), int(p["rot"]))
	_costruisci_grafo()
