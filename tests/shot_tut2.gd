extends SceneTree
var main
func _initialize() -> void:
	root.size = Vector2i(1180, 820)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_scena()
func _scena() -> void:
	for i in 10: await process_frame
	main._avvia_tutorial()
	for i in 20: await process_frame
	for k in 4:
		main.tut.avanti()
		for i in 5: await process_frame
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/tutA.png")
	main._rispondi([{"a": "M", "dest": "x"}])
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/tutB.png")
	quit()
