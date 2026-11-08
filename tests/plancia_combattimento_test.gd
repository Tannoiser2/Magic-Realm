## Test: Godot --headless --path . --script res://tests/plancia_combattimento_test.gd
## Verifica che la plancia risponda alle tre selezioni senza modificare il motore.
extends SceneTree

func _init() -> void:
	call_deferred("_prova")

func _trova_bottone(n: Node, nome: String) -> Button:
	if n is Button and (n as Button).text == nome:
		return n as Button
	for c in n.get_children():
		var trovato := _trova_bottone(c, nome)
		if trovato != null:
			return trovato
	return null

func _prova() -> void:
	var scena: PackedScene = load("res://scenes/main.tscn")
	var main := scena.instantiate()
	root.add_child(main)
	await process_frame
	main.call("_scegli_menu", "edizione", "classico")
	main.call("_nuova_partita")
	await process_frame
	assert(main.get("g") != null)
	main.set("mischia", {"modo":"attacco", "cerchio":"thrust", "f":[], "m":[], "casella":"dodge", "scudo":"thrust"})
	var box: Node = main.get("box_modale")
	main.call("_plancia_mischia", {"scudo":true})
	var attacco := _trova_bottone(box, "Fendente")
	var manovra := _trova_bottone(box, "Abbassarsi")
	var difesa := _trova_bottone(box, "Proteggi: Colpo dall'alto")
	assert(attacco != null and manovra != null and difesa != null)
	attacco.emit_signal("pressed")
	manovra.emit_signal("pressed")
	difesa.emit_signal("pressed")
	assert(main.get("mischia")["cerchio"] == "swing")
	assert(main.get("mischia")["casella"] == "duck")
	assert(main.get("mischia")["scudo"] == "smash")
	print("PASS: interactive melee board attack, maneuver and shield controls")
	quit()
