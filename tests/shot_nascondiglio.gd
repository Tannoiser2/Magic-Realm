## xvfb-run godot --path . --script res://tests/shot_nascondiglio.gd
extends SceneTree
var main
func _initialize() -> void:
	var dim := OS.get_environment("DIM")
	root.size = Vector2i(1180, 820) if dim == "" else Vector2i(int(dim.split("x")[0]), int(dim.split("x")[1]))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_scena()
func _attesa(n := 20) -> void:
	for i in range(n):
		await process_frame
func _foto(nome: String) -> void:
	await _attesa(3)
	root.get_viewport().get_texture().get_image().save_png("/tmp/nc_%s_%d.png" % [nome, root.size.x])
func _scena() -> void:
	await _attesa(10)
	main.scelte_menu["scenario"] = 4
	main.scelte_menu["pg"] = "amazzone"
	main.scelte_menu["rivali"] = 1
	main._nuova_partita()
	await _attesa(40)
	await _foto("piano")
	var u = main.g.umano()
	u["oro"] = 23
	var lista := []
	for o in u["oggetti"]:
		lista.append({"id": o["id"], "nome": Dati.nome_arma(o["id"])})
	main._richiesta_nascondiglio({"tipo": "nascondiglio", "dati": {"oggetti": lista, "oro": u["oro"]}})
	await _attesa(8)
	await _foto("modale")
	quit()
