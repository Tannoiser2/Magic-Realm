## Test d'integrazione: quattro Encounter e separazione delle regole.
## godot --headless --path . --script res://tests/quattro_encounter_test.gd
extends SceneTree

func _init() -> void:
	for i in range(1, 5):
		var regole := ProfiliRegole.classico_incontro(i)
		assert(ProfiliRegole.valido(regole))
		assert(regole["implementato"])
		var g := Reame.new()
		g.auto_umano = true
		assert(g.nuova_con_profilo(regole, "amazzone", ["capitano"], 2300 + i))
		assert(g.e_classico())
		assert(g.incontro_classico() == i)
		assert(g.mappa.pezzi.size() == 20)
		assert(g.s["giorni_max"] == 28)
		assert(g.usa_regola("mostri"))
		assert(g.usa_regola("commercio"))
		assert(g.usa_regola("combattimento_mostri") == (i >= 2))
		assert(g.usa_regola("combattimento_pg") == (i >= 3))
		assert(g.usa_regola("ingaggio") == (i >= 3))
		assert(g.usa_regola("magia") == (i >= 4))
		assert(g.umano()["vp"]["inc"] == 0)
		if i < 4:
			assert(g.umano()["incantesimi"].is_empty())
		var copy: Dictionary = JSON.parse_string(JSON.stringify(g.esporta()))
		var restored := Reame.new()
		restored.importa(copy)
		assert(restored.incontro_classico() == i)
		assert(restored.mappa.pezzi.size() == 20)
		assert(restored.usa_regola("magia") == (i >= 4))
		print("ENCOUNTER %d setup e salvataggio OK" % i)
	print("PASS: quattro Encounter indipendenti")
	quit()
