extends SceneTree
func _init() -> void:
	var sc := int(OS.get_environment("SC"))
	var g := Reame.new()
	g.auto_umano = true
	var pgs := ["amazzone", "capitano", "nano", "cavaliere_nero"] if sc >= 2 else ["ragazza_boschi", "elfo", "druido", "capitano"]
	if sc >= 4: pgs = Array(OS.get_environment("PGS").split(",")) if OS.get_environment("PGS") != "" else ["mago", "stregone", "amazzone", "re_stregone"]
	g.nuova(sc, pgs[0], pgs.slice(1), int(OS.get_environment("SEME")))
	g.s["giorni_max"] = int(OS.get_environment("GIORNI"))
	g.s["prova"] = true
	g.messaggio.connect(func(t, _tp): print(g.s["giorno"], " ", t))
	await g.gioca()
	for p in g.s["pg"]: print(p["nome"], " PV ", g.pv(p), " morto ", p["morto"])
	quit()
