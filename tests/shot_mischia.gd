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
	var g = main.g
	var u = g.umano()
	var ids := []
	for id in g.s["mostri"]:
		if g.s["mostri"][id]["tipo"] in ["troll", "goblin_lancia"] and ids.size() < 2:
			ids.append(id)
	main.g.combat.C = {"pos": {ids[0]: {"riga": "smash", "col": "duck"}, ids[1]: {"riga": "swing", "col": "charge"}}, "assegnati": {ids[0]: u["pid"], ids[1]: u["pid"]}, "uso": {}}
	for id in ids: g.s["mostri"][id]["dove"] = u["dove"]
	main.mischia = {"modo": "attacco", "cerchio": "thrust", "casella": "charge", "scudo": "thrust"}
	await main._apri_modale("Mischia: attacco, manovra e scudo")
	main._pannello_mischia({"scudo": true, "missile": false, "bersaglio": ids[0], "arma": "spada_corta", "sforzo": 0, "fight": [2, 4], "move": [0, 1]})
	main._ricentra()
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/mischia.png")
	quit()
