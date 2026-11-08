## Screenshot dello scenario 4: xvfb-run godot --path . --script res://tests/screenshot4.gd
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
	im.save_png("/tmp/s4_%s.png" % nome)
	print("foto ", nome)

func _attesa(n := 20) -> void:
	for i in range(n):
		await process_frame

func _scena() -> void:
	await _attesa(10)
	main.scelte_menu["scenario"] = 4
	main._mostra_menu()
	await _attesa(5)
	await _foto("menu")
	main.scelte_menu = {"scenario": 4, "pg": "mago", "rivali": 2}
	main._nuova_partita()
	await _attesa(30)
	var g = main.g
	var u = g.umano()
	for id in ["t_crystal_ball", "t_power_boots", "t_golden_crown", "t_amulet", "t_elemental_ring"]:
		u["oggetti"].append({"id": id, "attivo": true, "allerta": false, "danno": 0})
	g.arcano.sincronizza(u)
	for c in u["chits"]:
		if c["tipo"] == "G" and c["magia"] == "IV":
			c["colore"] = true
			break
	main._aggiorna_scheda()
	main._pannello_piano()
	await _attesa(5)
	await _foto("scheda")
	main._carta_tesoro("t_crystal_ball")
	await _attesa(5)
	await _foto("carta")
	main.modale.visible = false
	# tabella con saccheggio
	main._richiesta_tabella({"tipo": "tabella", "dati": {"radure": [u["dove"]], "fonti": {"saccheggia": [{"id": "s:hoard", "nome": "Bottino (9 carte)"}], "rune": [{"id": "s:altar", "nome": "Altare"}]}}})
	await _attesa(5)
	await _foto("tabella")
	main.modale.visible = false
	main._richiesta_sera({"tipo": "incantesimo_sera", "dati": {"lista": g.arcano.lanciabili(u, false)}})
	await _attesa(5)
	await _foto("sera")
	print("lanciabili ", g.arcano.lanciabili(u, true).map(func(x): return x["inc"]))
	print("inc ", u["incantesimi"])
	quit()
