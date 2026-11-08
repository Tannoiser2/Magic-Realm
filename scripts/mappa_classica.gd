## Generatore separato per le 20 tessere del Magic Realm, seconda edizione.
## Prototipo non ancora collegato alla modalita giocabile.
class_name MappaClassica
extends Mappa

# Cinque cave, cinque montagne, cinque valli, cinque boschi.
const CAVE := [4, 5, 6, 7, 18]
const MONTAGNE := [3, 13, 14, 15, 16]
const VALLI := [21, 22, 23, 24, 25]
const BOSCHI := [26, 27, 28, 29, 30]
const TESSERE_CLASSICHE := CAVE + MONTAGNE + VALLI + BOSCHI
const BORDERLAND := 5

func _raggiungibili_borderland() -> Dictionary:
	var accessibili := {}
	var coda: Array = []
	# Tutte le radure della Borderland sono punti di riferimento:
	# la verifica dei singoli percorsi interni e gestita dal grafo.
	for k in radure:
		if radure[k]["t"] == BORDERLAND:
			accessibili[k] = true
			coda.append(k)
	while not coda.is_empty():
		var k: String = coda.pop_front()
		for e in vicini.get(k, []):
			if not accessibili.has(e["b"]):
				accessibili[e["b"]] = true
				coda.append(e["b"])
	return accessibili

func _valida_posa(t: int) -> bool:
	_costruisci_grafo()
	var raggiunti := _raggiungibili_borderland()
	var radure_t := radure_tessera(t)
	if radure_t.is_empty():
		return false
	var n := 0
	for k in radure_t:
		if raggiunti.has(k):
			n += 1
	# High Pass e Ledges hanno sei radure disconnesse: tutte devono
	# risultare raggiungibili, non basta un solo collegamento.
	if t == 4 or t == 15:
		return n == radure_t.size()
	return n > 0

func _rimuovi_ultima() -> void:
	var p: Dictionary = pezzi.pop_back()
	per_cella.erase(Vector2i(int(p["q"]), int(p["r"])))
	per_tessera.erase(int(p["t"]))

func genera_classica(rng: RandomNumberGenerator, tentativi := 200) -> bool:
	for tentativo in range(tentativi):
		pezzi.clear()
		per_cella.clear()
		per_tessera.clear()
		_metti(BORDERLAND, Vector2i.ZERO, rng.randi_range(0, 5))
		var rimaste: Array = TESSERE_CLASSICHE.duplicate()
		rimaste.erase(BORDERLAND)
		_mescola(rimaste, rng)
		var fallita := false
		while not rimaste.is_empty():
			var candidati: Array = []
			var celle_viste := {}
			for p in pezzi:
				var origine := Vector2i(int(p["q"]), int(p["r"]))
				for w in range(6):
					var cella: Vector2i = origine + DIR[w]
					if per_cella.has(cella) or celle_viste.has(cella):
						continue
					celle_viste[cella] = true
					for t in rimaste:
						for rot in range(6):
							var prova: Array = _combacia(int(t), cella, rot)
							var minimo_vicini := 1 if pezzi.size() == 1 else 2
							if prova[0] and int(prova[1]) >= minimo_vicini and not prova[2].is_empty():
								candidati.append({"t": int(t), "c": cella, "rot": rot})
			if candidati.is_empty():
				fallita = true
				break
			_mescola(candidati, rng)
			var aggiunto := false
			for candidato in candidati:
				_metti(int(candidato["t"]), candidato["c"], int(candidato["rot"]))
				if _valida_posa(int(candidato["t"])):
					rimaste.erase(int(candidato["t"]))
					aggiunto = true
					break
				_rimuovi_ultima()
			if not aggiunto:
				fallita = true
				break
		if not fallita and pezzi.size() == 20:
			_costruisci_grafo()
			if _connessa_classica():
				return true
	pezzi.clear()
	per_cella.clear()
	per_tessera.clear()
	vicini.clear()
	radure.clear()
	push_warning("Mappa classica: nessuna disposizione valida dopo %d tentativi" % tentativi)
	return false

func _connessa_classica() -> bool:
	if pezzi.size() != 20 or per_tessera.size() != 20:
		return false
	var raggiunti := _raggiungibili_borderland()
	for t in TESSERE_CLASSICHE:
		var radure_t := radure_tessera(t)
		var n := 0
		for k in radure_t:
			if raggiunti.has(k):
				n += 1
		if n == 0 or ((t == 4 or t == 15) and n != radure_t.size()):
			return false
	return true
