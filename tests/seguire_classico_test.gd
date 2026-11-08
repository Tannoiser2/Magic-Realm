## godot --headless --path . --script res://tests/seguire_classico_test.gd
extends SceneTree

func _init() -> void:
	call_deferred("_prova")

func _prova() -> void:
	var g := Reame.new()
	assert(g.nuova_con_profilo(ProfiliRegole.classico_incontro(3), "amazzone", ["capitano"], 4401))
	var guida: Dictionary = g.P("p0")
	var seguace: Dictionary = g.P("p1")
	seguace["dove"] = guida["dove"]
	seguace["segue"] = guida["pid"]
	seguace["piano"] = [{"a": "F", "guida": guida["pid"]}]
	assert(g._seguitori_di(guida).size() == 1)
	g.s["attivo"] = guida["pid"]
	var destinazione := ""
	for e in g.mappa.vicini.get(guida["dove"], []):
		if e["tipo"] == "strada":
			destinazione = e["b"]
			break
	if destinazione == "":
		for e in g.mappa.vicini.get(guida["dove"], []):
			destinazione = e["b"]
			break
	assert(destinazione != "")
	await g._muovi(guida, destinazione)
	assert(guida["dove"] == destinazione)
	assert(seguace["dove"] == destinazione)
	g.s.erase("attivo")
	guida["piano"] = [{"a": "H"}]
	seguace["nascosto"] = false
	await g.esegui_turno(guida)
	assert(seguace["nascosto"] == guida["nascosto"])
	assert(seguace["turno_fatto"])
	assert(str(seguace.get("segue", "")) == "")
	var vecchio := Reame.new()
	assert(vecchio.nuova_con_profilo(ProfiliRegole.classico_incontro(2), "amazzone", ["capitano"], 4401))
	vecchio.P("p1")["segue"] = "p0"
	assert(vecchio._seguitori_di(vecchio.P("p0")).is_empty())
	print("PASS: FOLLOW moves together, shares HIDE and disabled before Encounter III")
	quit()
