## Percorre tutto il tutorial guidato rispondendo come un giocatore diligente.
extends SceneTree
var main
func _initialize() -> void:
	root.size = Vector2i(1180, 820)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_giro()

func _giro() -> void:
	for i in 10: await process_frame
	main._avvia_tutorial()
	var g = main.g
	var foto := 0
	for giro in range(600):
		await process_frame
		var tut = main.tut
		if tut == null:
			print("TUTORIAL FINITO al giro ", giro)
			break
		var st: Dictionary = tut.corrente()
		var req: Dictionary = g.richiesta
		if giro % 40 == 5 and foto < 6:
			root.get_viewport().get_texture().get_image().save_png("/tmp/tut_auto_%d.png" % foto)
			foto += 1
		if st.get("tipo", "") == "ok" and not tut.in_attesa:
			print("OK  ", tut.i, " ", str(st["lez"]))
			for k in 3: await process_frame
			tut.avanti()
			continue
		if req.is_empty():
			continue
		var u = g.umano()
		var x = null
		var t: String = req["tipo"]
		var testo: String = tut.testo()
		if t == "piano":
			if testo.find("radura") >= 0 and tut.dati.has("kA") and st.get("tipo") == "piano" and testo.find("{") < 0 and testo.find("Movimento") < 0 and testo.find("tocca sulla mappa") < 0:
				pass
			if st.get("tipo") == "piano":
				if testo.find("Tocca sulla mappa la radura") >= 0:
					x = [{"a": "M", "dest": tut.dati["kA"]}, {"a": "M", "dest": tut.dati["kB"]}, {"a": "S"}]
				elif testo.find("PRIMA attività") >= 0:
					x = [{"a": "H"}, {"a": "R"}]
				elif testo.find("ALLERTA") >= 0:
					x = [{"a": "A"}, {"a": "R"}]
				elif testo.find("INCANTO") >= 0:
					x = [{"a": "E"}, {"a": "E"}]
				elif testo.find("COMMERCIO") >= 0:
					x = [{"a": "T"}]
				else:
					x = [{"a": "S"}]
			else:
				continue
		elif st.get("tipo") == "risposta" and st.get("req") == t:
			match t:
				"tabella": x = {"tabella": "saccheggia", "fonte": "m:" + u["dove"]} if testo.find("Saccheggia") >= 0 else {"tabella": "scruta", "radura": u["dove"]}
				"bersaglio": x = tut.dati["gob"]
				"mischia":
					var f := -1
					var mv := -1
					for ci in range(u["chits"].size()):
						var c = u["chits"][ci]
						if c["stato"] == "a" and c["tipo"] == "F" and f < 0: f = ci
						if c["stato"] == "a" and c["tipo"] == "M" and mv < 0: mv = ci
					x = {"attacco": {"cerchio": "thrust", "chit": f}, "manovra": {"casella": "dodge", "chit": mv}, "scudo": "swing"}
				"incanto":
					var opz: Array = req["dati"]["opzioni"]
					for k in range(opz.size()):
						if opz[k]["tipo"] == "chit" and u["chits"][opz[k]["i"]]["magia"] == "I":
							x = k
							break
				"incantesimo_sera": x = {"inc": "i_make_whole", "mezzo": 0}
				"commercio": x = {"gruppo": "order", "tipo": "vendi", "oggetti": ["t_lucky_charm"]}
		else:
			x = g.ia.decidi(u, t, req["dati"])
		print("RISP ", tut.i, " ", t, " -> ", str(x).substr(0, 80))
		if t in ["mischia", "incanto", "tabella"] and st.get("tipo") == "risposta":
			for k in 8: await process_frame
			root.get_viewport().get_texture().get_image().save_png("/tmp/tut_%s_%d.png" % [t, tut.i])
		main._rispondi(x)
	for r in g.log_righe.slice(max(0, g.log_righe.size() - 60)):
		print("   ", r[0])
	quit()
