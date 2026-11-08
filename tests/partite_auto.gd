## Partite automatiche: godot --headless --script res://tests/partite_auto.gd
extends SceneTree

func _init() -> void:
	var scen := OS.get_environment("SCENARI")
	var lista: Array = Array(scen.split(",")) if scen != "" else ["1", "2", "3"]
	for sc in lista:
		for seme in [11, 22, 33]:
			var g := Reame.new()
			g.auto_umano = true
			var pgs := ["amazzone", "capitano", "nano", "cavaliere_nero"] if int(sc) >= 2 else ["ragazza_boschi", "elfo", "druido", "capitano"]
			if int(sc) >= 4: pgs = ["mago", "stregone", "amazzone", "re_stregone"]
			g.nuova(int(sc), pgs[0], pgs.slice(1), seme)
			if int(sc) >= 3: g.s["giorni_max"] = 40
			g.s["prova"] = true
			var t0 := Time.get_ticks_msec()
			await g.gioca()
			var js := JSON.stringify(g.esporta())
			var h := Reame.new()
			h.importa(JSON.parse_string(js))
			var righe := []
			for p in g.s["pg"]:
				righe.append("%s%s PV%d f%d n%d siti%d miss%d uccisi%s tesori%d inc%d/%d twt%d" % [p["nome"], " (morto)" if p["morto"] else "", g.pv(p), p["fama"], p["noto"], p["siti"].size(), p["fatte"].size(), str(p["uccisi"]) if p["uccisi"].size() < 5 else str(p["uccisi"].size()), p["oggetti"].filter(func(o): return Dati.tesori.has(o["id"])).size(), p.get("incantesimi", []).size(), p.get("inc_iniziali", []).size(), p.get("twt", []).size()])
			print("scenario %s seme %d: %s giorno %d (%d ms) json %d KB\n   %s" % [sc, seme, g.s["fine"], g.s["giorno"], Time.get_ticks_msec() - t0, js.length() / 1024, "\n   ".join(righe)])
	quit()
