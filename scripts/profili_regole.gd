## Configurazioni dati per la futura selezione delle regole.
## Non sostituisce ancora la logica dei sei scenari esistenti.
class_name ProfiliRegole
extends RefCounted

const SUPER := "super"
const CLASSICO := "classico"
const PERSONALIZZATO := "personalizzato"

const FUNZIONI := ["esplorazione", "mostri", "combattimento_mostri", "combattimento_pg", "tesori", "magia", "nativi", "commercio", "ingaggio", "viaggiatori", "visitatori", "missioni_viaggiatori", "cavalli"]

static func super_scenario(numero: int) -> Dictionary:
	assert(numero >= 1 and numero <= 6)
	return {
		"id": "super_%d" % numero, "famiglia": SUPER, "scenario": numero,
		"mappa": "super_40", "giorni": 84 if numero == 6 else 56,
		"pv_assegnati": 12 if numero == 6 else 0,
		"funzioni": {
			"esplorazione": true, "mostri": numero >= 3,
			"combattimento_mostri": numero >= 3,
			"combattimento_pg": numero >= 2, "tesori": numero >= 4,
			"magia": numero >= 4, "nativi": numero >= 5,
			"commercio": numero >= 5, "ingaggio": numero >= 5,
			"viaggiatori": numero >= 6, "visitatori": numero >= 6,
			"missioni_viaggiatori": numero >= 6, "cavalli": false
		},
		"implementato": true
	}

static func classico_incontro(numero: int) -> Dictionary:
	assert(numero >= 1 and numero <= 4)
	var completo := numero == 4
	return {
		"id": "classico_incontro_%d" % numero, "famiglia": CLASSICO,
		"incontro": numero, "mappa": "classico_20", "giorni": 28,
		"pv_assegnati": 5 if completo else 0,
		"funzioni": {
			"esplorazione": true, "mostri": true,
			"combattimento_mostri": numero >= 2,
			"combattimento_pg": numero >= 3, "tesori": true,
			"magia": numero >= 4, "nativi": true,
			"commercio": true, "ingaggio": numero >= 3,
			"viaggiatori": false, "visitatori": true,
			"missioni_viaggiatori": numero >= 3, "cavalli": true
		},
		"implementato": false
	}

static func classico_completo() -> Dictionary:
	var profilo := classico_incontro(4)
	profilo["id"] = "classico_completo"
	profilo["incontro"] = 0
	return profilo

static func valido(profilo: Dictionary) -> bool:
	if not profilo.has("famiglia") or not profilo.has("funzioni"):
		return false
	for k in FUNZIONI:
		if not profilo["funzioni"].has(k):
			return false
	return profilo.get("giorni", 0) > 0

static func abilitata(profilo: Dictionary, funzione: String) -> bool:
	return bool(profilo.get("funzioni", {}).get(funzione, false))
