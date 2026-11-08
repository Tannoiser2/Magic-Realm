## Esecuzione: CLASSIC_ENCOUNTER=1 godot --headless --path . --script res://tests/ui_incontro_classico_test.gd
extends SceneTree

func _init() -> void:
	call_deferred("_prova")

func _prova() -> void:
	var n: int = int(OS.get_environment("CLASSIC_ENCOUNTER"))
	assert(n >= 1 and n <= 4)
	var scena: PackedScene = load("res://scenes/main.tscn")
	var main = scena.instantiate()
	root.add_child(main)
	await process_frame
	main.call("_scegli_menu", "edizione", "classico")
	main.call("_scegli_menu", "incontro_classico", n)
	await process_frame
	assert(int(main.get("scelte_menu")["incontro_classico"]) == n)
	main.call("_nuova_partita")
	await process_frame
	var g: Reame = main.get("g")
	assert(g != null)
	assert(g.e_classico())
	assert(g.incontro_classico() == n)
	assert(g.mappa.pezzi.size() == 20)
	assert(g.s["giorni_max"] == 28)
	print("PASS: Encounter %d playable in Godot UI" % n)
	quit()
