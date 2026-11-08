## Screenshot di prova: xvfb-run godot --path . --script res://tests/screenshot.gd
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
	var im := root.get_viewport().get_texture().get_image()
	im.save_png("/tmp/shot_%s.png" % nome)
	print("foto ", nome)

func _attesa(n := 20) -> void:
	for i in range(n):
		await process_frame

func _scena() -> void:
	await _attesa(10)
	await _foto("menu")
	main.scelte_menu = {"scenario": int(OS.get_environment("SC")) if OS.get_environment("SC") != "" else 3, "pg": "amazzone", "rivali": 2}
	main._nuova_partita()
	await _attesa(30)
	await _foto("alba")
	main.hud.visible = false
	var c0 = main.bersaglio_cam
	main.bersaglio_cam = Vector3(0, 0, 0)
	for i in range(main.g.mappa.pezzi.size()):
		var cc = main.g.mappa.centro(i)
		main.bersaglio_cam += Vector3(cc.x, 0, cc.y) / main.g.mappa.pezzi.size()
	main.distanza = 21.0
	main.pitch = -1.45
	main._aggiorna_camera()
	await _attesa(5)
	await _foto("mappa")
	main.hud.visible = true
	main.distanza = 3.2
	main.pitch = -0.9
	main.bersaglio_cam = c0
	main._aggiorna_camera()
	await _attesa(5)
	await _foto("vicino")
	main.distanza = 8.0
	main.pitch = -1.0
	main._aggiorna_camera()
	# aggiungo un movimento verso una radura vicina e qualche attività
	var u = main.g.umano()
	var vic: Array = main.g.vicini_di(u, u["dove"])
	if not vic.is_empty():
		main._clic(vic[0])
	main._aggiungi("S")
	await _attesa(5)
	await _foto("piano")
	main.g.auto_umano = false
	var giri := 0
	var fatte := {}
	while giri < 2500 and main.g.s["fine"] == "":
		giri += 1
		await process_frame
		var r: Dictionary = main.g.richiesta
		if r.is_empty():
			continue
		var t: String = r["tipo"]
		if not fatte.has(t) and t != "piano":
			fatte[t] = true
			await _attesa(4)
			await _foto(t)
		var risp = main.g.ia.decidi(main.g.umano(), t, r["dati"])
		main._rispondi(risp)
		if main.g.s["giorno"] >= 4 and fatte.size() >= 6:
			break
	await _attesa(10)
	await _foto("fine")
	print("giorno ", main.g.s["giorno"], " richieste viste ", fatte.keys())
	quit()
