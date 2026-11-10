extends SceneTree
var main
func _initialize() -> void:
	root.size = Vector2i(1180, 820)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_scena()
func _scena() -> void:
	for i in 10: await process_frame
	for pg in [1, 9]:
		main._tutorial(pg)
		for i in 6: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/tut%d.png" % pg)
	quit()
