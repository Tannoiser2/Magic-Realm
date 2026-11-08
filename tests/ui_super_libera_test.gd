## Run: godot --headless --path . --script res://tests/ui_super_libera_test.gd
## Free play exposes all Super rules independently from the six progressive scenarios.
extends SceneTree

func _init() -> void:
	call_deferred("_prova")

func _prova() -> void:
	var scena = load("res://scenes/main.tscn")
	assert(scena is PackedScene)
	var main = scena.instantiate()
	root.add_child(main)
	await process_frame
	assert(main.get("scelte_menu")["edizione"] == "super")
	main.call("_scegli_menu", "partita_libera", true)
	main.call("_scegli_menu", "durata_libera", 56)
	assert(main.get("scelte_menu")["partita_libera"])
	assert(main.call("_percorso_salvataggio", "super") != main.call("_percorso_salvataggio", "classico"))
	main.call("_nuova_partita")
	await process_frame
	var g = main.get("g")
	assert(g != null)
	assert(not g.e_classico())
	assert(g.s["scenario"] == 6)
	assert(g.s["giorni_max"] == 56)
	assert(g.s["partita_libera"])
	assert(g.usa_regola("viaggiatori"))
	assert(g.usa_regola("magia"))
	assert(g.usa_regola("nativi"))
	print("PASS: Super free-play game, full rules, 56 days, independent saves")
	quit()
