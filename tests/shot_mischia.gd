extends SceneTree
var main
func _initialize() -> void:
	root.size = Vector2i(1180, 820)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_scena()
func _scena() -> void:
	for i in 10: await process_frame
	main.scelte_menu = {"scenario": 3, "pg": "amazzone", "rivali": 1, "edizione": "super", "partita_libera": false}
	main._nuova_partita()
	for i in 20: await process_frame
	if main.guida_pannello: main.guida_pannello.visible = false
	main.g.combat.C = {"pos": {}, "assegnati": {}, "uso": {}}
	main.mischia = {"modo": "attacco", "cerchio": "thrust", "casella": "charge", "scudo": "thrust"}
	main._apri_modale("Mischia")
	main._plancia_mischia({"scudo": true})
	main._ricentra()
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/mischia.png")
	quit()
