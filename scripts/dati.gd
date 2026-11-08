## Dati statici del gioco (tessere, personaggi, mostri, oggetti, missioni), letti dai file JSON di data/.
class_name Dati
extends RefCounted

static var _pronti := false
static var tessere: Array = []
static var personaggi: Dictionary = {}
static var ordine_pg: Array = []
static var mostri: Dictionary = {}
static var oggetti: Dictionary = {}
static var segnalini: Dictionary = {}
static var missioni: Dictionary = {}
static var elenco_missioni: Array = []
static var tesori: Dictionary = {}
static var incantesimi: Dictionary = {}
static var nativi: Dictionary = {}
static var viaggiatori: Dictionary = {}

const PESI := ["-", "L", "M", "H", "T", "X"]
const NOMI_PESO := {"-": "Trascurabile", "L": "Leggero", "M": "Medio", "H": "Pesante", "T": "Tremendo", "X": "Massimo"}
const CATEGORIE := {"M": "Montagna", "C": "Grotte", "F": "Foresta", "R": "Rovine", "V": "Valle", "H": "Colli", "W": "Bosco", "S": "Torrente"}
const ABITAZIONI := {"locanda": "Locanda", "casa": "Casa", "cappella": "Cappella", "corpo_guardia": "Corpo di Guardia",
	"borgo": "Borgo", "casolare": "Casolare", "insediamento": "Insediamento", "capanna": "Capanna",
	"fuoco_piccolo": "Fuoco piccolo", "fuoco_grande": "Fuoco grande", "campo_piccolo": "Accampamento piccolo", "campo_grande": "Accampamento grande"}
const TIPI_RADURA := {"W": "bosco", "M": "montagna", "C": "grotta", "A": "acqua"}

static func carica() -> void:
	if _pronti:
		return
	tessere = _json("res://data/tessere.json")
	for p in _json("res://data/personaggi.json"):
		personaggi[p["id"]] = p
		ordine_pg.append(p["id"])
	mostri = _json("res://data/mostri.json")
	oggetti = _json("res://data/oggetti.json")
	for s in _json("res://data/segnalini.json"):
		segnalini[s["id"]] = s
	elenco_missioni = _json("res://data/missioni.json")
	for m in elenco_missioni:
		missioni[m["id"]] = m
	tesori = _json("res://data/tesori.json")
	incantesimi = _json("res://data/incantesimi.json")
	nativi = _json("res://data/nativi.json")
	viaggiatori = _json("res://data/viaggiatori.json")
	# i nativi combattono come le pedine dei mostri: registro i loro tipi
	for gid in nativi["gruppi"]:
		var g: Dictionary = nativi["gruppi"][gid]
		for m in g["membri"]:
			mostri["tipi"][m["id"]] = {"nome": "%s (%s)" % [m["tipo_it"], g["nome"]], "plurale": g["nome"], "peso": m["peso"],
				"chiaro": m["luce"], "scuro": m["buio"], "fama": 0, "noto": m["noto"], "oro": m["oro"], "lung": [m["lung"], m["lung"]],
				"armato": m["armato"], "vola": false, "missile": [m["missile"] and m["luce"][0] != "", m["missile"]], "incant": null, "extra": null, "nativo": gid}
	_pronti = true

static func _json(p: String):
	var f := FileAccess.open(p, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())

static func peso_i(p: String) -> int:
	var i := PESI.find(p)
	return max(i, 0)

static func peso_s(i: int) -> String:
	return PESI[clampi(i, 0, 5)]

## "H5*" -> {"f": "H", "v": 5, "s": 1}; "" -> nessun attacco; "V2" -> incantesimo
static func attacco(s: String) -> Dictionary:
	if s == "":
		return {"f": "", "v": 0, "s": 0}
	var f := s.substr(0, 1)
	var resto := s.substr(1)
	var st := resto.count("*")
	var num := resto.replace("*", "")
	return {"f": f, "v": int(num) if num != "" else 0, "s": st}

static func tipo_mostro(t: String) -> Dictionary:
	if mostri["tipi"].has(t):
		return mostri["tipi"][t]
	return mostri["extra"].get(t, {})

static func nome_arma(id: String) -> String:
	if oggetti["armi"].has(id):
		return oggetti["armi"][id]["nome"]
	if oggetti["armature"].has(id):
		return oggetti["armature"][id]["nome"]
	if tesori.has(id):
		return tesori[id]["nome"]
	return id
