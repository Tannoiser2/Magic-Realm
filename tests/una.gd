extends SceneTree
func _init() -> void:
	var sc := int(OS.get_environment("SC"))
	var g := Reame.new()
	g.auto_umano = true
	var pgs := ["amazzone", "capitano", "nano", "cavaliere_nero"] if sc >= 2 else ["ragazza_boschi", "elfo", "druido", "capitano"]
	g.nuova(sc, pgs[0], pgs.slice(1), int(OS.get_environment("SEME")))
	g.s["giorni_max"] = int(OS.get_environment("GIORNI"))
	g.s["prova"] = true
	await g.gioca()
	for r in g.log_righe:
		print(r[2], " ", r[0])
	quit()
