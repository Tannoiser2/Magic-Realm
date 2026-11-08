extends SceneTree
var main
func _initialize() -> void:
	root.size = Vector2i(1600, 950)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_scena()
func _foto(nome: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/s6_%s.png" % nome)
	print("foto ", nome)
func _attesa(n := 20) -> void:
	for i in range(n):
		await process_frame
func _scena() -> void:
	await _attesa(10)
	main.scelte_menu["scenario"] = 6
	main._mostra_menu()
	await _attesa(5)
	await _foto("menu")
	main.scelte_menu = {"scenario": 6, "pg": "capitano", "rivali": 2}
	main._nuova_partita()
	await _attesa(30)
	await _foto("pv")
	var g = main.g
	g.rispondi({"grandi": 2, "inc": 0, "fama": 4, "noto": 4, "oro": 2})
	await _attesa(20)
	var u = g.umano()
	await _foto("scheda")
	var opz = g.nativi.opzioni_commercio(u)
	var vend = u["oggetti"].map(func(o): return {"id": o["id"], "nome": Dati.nome_arma(o["id"]), "oro": g.nativi.valore(o)})
	main._richiesta_commercio({"tipo": "commercio", "dati": {"gruppi": opz, "vendibili": vend, "oro": u["oro"]}})
	await _attesa(5)
	await _foto("commercio")
	main.modale.visible = false
	main.distanza = 4.0
	main.bersaglio_cam = main._v3(g.mappa.radure[u["dove"]]["pos"])
	main._aggiorna_camera()
	await _attesa(5)
	await _foto("locanda")
	quit()
