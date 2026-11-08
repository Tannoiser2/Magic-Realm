## Esecuzione: godot --headless --path . --script res://tests/punteggio_classico_test.gd
extends SceneTree

func _init() -> void:
	var punti := {"grandi": 2, "inc": 0, "fama": 3, "noto": 0, "oro": 0}
	assert(PunteggioClassico.valida_assegnazione(punti, false))
	var valori := {"grandi": 2, "inc": 0, "fama": 30, "noto": 0, "oro": 0}
	assert(PunteggioClassico.calcola(punti, valori, 0, false)["totale"] == 0)
	valori["grandi"] = 3
	assert(PunteggioClassico.calcola(punti, valori, 0, false)["categorie"]["grandi"]["totale"] == 3)
	valori["grandi"] = 1
	assert(PunteggioClassico.calcola(punti, valori, 0, false)["categorie"]["grandi"]["totale"] == -9)
	valori["grandi"] = 2
	valori["fama"] = 29
	assert(PunteggioClassico.calcola(punti, valori, 0, false)["categorie"]["fama"]["totale"] == -4)
	var oro := {"grandi": 0, "inc": 0, "fama": 0, "noto": 0, "oro": 5}
	assert(PunteggioClassico.calcola(oro, {"oro": 160}, 10, false)["totale"] == 0)
	assert(not PunteggioClassico.valida_assegnazione({"grandi": 6}))
	print("PASS: punteggio classico con penalita, bonus e rettifica oro")
	quit()
