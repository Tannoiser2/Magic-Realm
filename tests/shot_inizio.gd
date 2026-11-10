extends SceneTree
var main
func _initialize() -> void:
	var w := int(OS.get_environment("W")) if OS.get_environment("W") != "" else 1180
	var h := int(OS.get_environment("H")) if OS.get_environment("H") != "" else 820
	root.size = Vector2i(w, h)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_scena()
func _scena() -> void:
	for i in 10: await process_frame
	main.scelte_menu = {"scenario": int(OS.get_environment("SC")), "pg": "amazzone", "rivali": 2, "edizione": "super", "partita_libera": false}
	main._nuova_partita()
	for i in 40: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/inizio.png")
	if main.guida_pannello: main.guida_pannello.visible = false
	main._aggiungi("S")
	for i in 5: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/inizio2.png")
	print("dove ", main.g.umano()["dove"], " cam ", main.bersaglio_cam, " dist ", main.distanza)
	quit()
