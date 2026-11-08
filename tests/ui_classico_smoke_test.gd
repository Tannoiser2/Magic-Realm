## Run: godot --headless --path . --script res://tests/ui_classico_smoke_test.gd
## Avvia davvero l'interfaccia e seleziona la modalita classica.
extends SceneTree

func _init() -> void:
	call_deferred("_prova")

func _prova() -> void:
	var scena = load("res://scenes/main.tscn")
	assert(scena is PackedScene)
	var main = scena.instantiate()
	root.add_child(main)
	await process_frame
	main.call("_scegli_menu", "edizione", "classico")
	assert(main.get("scelte_menu")["edizione"] == "classico")
	main.call("_nuova_partita")
	await process_frame
	var g = main.get("g")
	assert(g != null)
	assert(g.e_classico())
	assert(g.mappa.pezzi.size() == 20)
	assert(g.s["giorni_max"] == 28)
	assert(g.umano().has("vp"))
	print("PASS: la UI avvia una vera partita classica")
	quit()
