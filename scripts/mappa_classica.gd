## Generatore sperimentale delle 20 tessere del Magic Realm (2a edizione).
## Basato sugli ID in data/tessere.json; non usato dalle partite finche test e regole non sono approvati.
class_name MappaClassica
extends Mappa

# 5 tessere Cave, 5 Mountain, 5 Valley, 5 Woods.
const TESSERE_CLASSICHE := [
	4, 5, 6, 7, 18,
	3, 13, 14, 15, 16,
	21, 22, 23, 24, 25,
	26, 27, 28, 29, 30
]
const BORDERLAND := 5

func genera_classica(rng: RandomNumberGenerator, tentativi := 100) -> bool:
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
			var candidati := []
			# Privilegiare una disposizione con non oltre tre vicini, mantenendo il reame leggibile.
			for t in rimaste:
				for p in pezzi:
					var origine := Vector2i(int(p["q"]), int(p["r"]))
					for w in range(6):
						var c: Vector2i = origine + DIR[w]
						if per_cella.has(c):
							continue
						for rot in range(6):
							var prova: Array = _combacia(int(t), c, rot)
							if prova[0] and not prova[2].is_empty():
								var penalita: int = max(0, int(prova[1]) - 3) * 5
								candidati.append({"t": int(t), "c": c, "rot": rot, "peso": penalita})
			if candidati.is_empty():
				fallita = true
				break
			# Campionamento tra candidati validi, non selezione della prima tessera possibile.
			var migliori := []
			var minimo := 9999
			for x in candidati:
				if x["peso"] < minimo:
					minimo = x["peso"]
					migliori = [x]
				elif x["peso"] == minimo:
					migliori.append(x)
			var scelta: Dictionary = migliori[rng.randi_range(0, migliori.size() - 1)]
			_metti(scelta["t"], scelta["c"], scelta["rot"])
			rimaste.erase(scelta["t"])
		if not fallita and pezzi.size() == 20:
			_costruisci_grafo()
			if _connessa_classica():
				return true
	pezzi.clear()
	per_cella.clear()
	per_tessera.clear()
	vicini.clear()
	radure.clear()
	push_warning("Mappa classica: impossibile costruire 20 tessere col seme corrente")
	return false

func _connessa_classica() -> bool:
	if pezzi.size() != 20 or per_tessera.size() != 20:
		return false
	# Le radure interne di una stessa tessera possono essere disgiunte:
	# controlliamo la connessione tra tessere tramite i varchi reali.
	var collegamenti := {}
	for t in TESSERE_CLASSICHE:
		collegamenti[t] = {}
	for k in vicini:
		var a: int = radure[k]["t"]
		for e in vicini[k]:
			var b: int = radure[e["b"]]["t"]
			if a != b:
				collegamenti[a][b] = true
	var coda: Array = [BORDERLAND]
	var visti := {BORDERLAND: true}
	while not coda.is_empty():
		var t: int = coda.pop_front()
		for x in collegamenti[t]:
			if not visti.has(x):
				visti[x] = true
				coda.append(x)
	return visti.size() == 20
