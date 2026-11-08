## Preparazione dei segnalini per il Magic Realm originale (seconda edizione).
## Usa solo i pezzi originali gia presenti nel database Super.
class_name PreparazioneClassica
extends RefCounted

const SITI := [
	"sito_altar", "sito_cairns", "sito_hoard", "sito_lair",
	"sito_pool", "sito_shrine", "sito_statue", "sito_vault"
]
const SUONI := [
	"flutter_1", "flutter_2", "howl_4", "howl_5", "patter_2",
	"patter_5", "roar_4", "roar_6", "slither_3", "slither_6"
]
const PERSI := {"C": "perduto_city", "M": "perduto_castle"}
const GRUPPI := {
	"C": MappaClassica.CAVE,
	"M": MappaClassica.MONTAGNE,
	"V": MappaClassica.VALLI,
	"W": MappaClassica.BOSCHI
}

static func _mescola(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var x = a[i]
		a[i] = a[j]
		a[j] = x

static func _controlla_database() -> bool:
	Dati.carica()
	for id in SITI + SUONI + PERSI.values():
		if not Dati.segnalini.has(id):
			push_error("Segnalino classico mancante: %s" % id)
			return false
	for categoria in GRUPPI:
		for parola in ["bones", "dank", "ruins", "smoke", "stink"]:
			if not Dati.segnalini.has("%s_%s" % [parola, categoria.to_lower()]):
				push_error("Avviso classico mancante: %s %s" % [parola, categoria])
				return false
	return true

static func prepara(rng: RandomNumberGenerator) -> Dictionary:
	if not _controlla_database():
		return {}
	var tessere := {}
	for t in MappaClassica.TESSERE_CLASSICHE:
		tessere[str(t)] = {"avviso": "", "rossi": [], "scoperti": false, "evocati": [], "aggiunti": false}
	var segnalini_rossi: Array = SITI.duplicate()
	segnalini_rossi.append_array(SUONI)
	_mescola(segnalini_rossi, rng)
	var riserve := {
		"perduto_city": segnalini_rossi.slice(0, 5),
		"perduto_castle": segnalini_rossi.slice(5, 10)
	}
	var rimasti: Array = segnalini_rossi.slice(10)
	for categoria in ["C", "M", "V", "W"]:
		var avvisi := []
		for parola in ["bones", "dank", "ruins", "smoke", "stink"]:
			avvisi.append("%s_%s" % [parola, categoria.to_lower()])
		_mescola(avvisi, rng)
		var tessere_categoria: Array = GRUPPI[categoria].duplicate()
		_mescola(tessere_categoria, rng)
		for i in range(5):
			tessere[str(tessere_categoria[i])]["avviso"] = avvisi[i]
	for categoria in ["C", "M"]:
		var rossi := rimasti.slice(0, 4)
		rimasti = rimasti.slice(4)
		rossi.append(PERSI[categoria])
		_mescola(rossi, rng)
		var ts: Array = GRUPPI[categoria].duplicate()
		_mescola(ts, rng)
		for i in range(5):
			tessere[str(ts[i])]["rossi"] = [rossi[i]]
	return {"tessere": tessere, "riserve": riserve, "pool_rossi": []}
