extends SceneTree
func _init() -> void:
	var g := Reame.new()
	g.auto_umano = true
	g.nuova(5, "capitano", ["amazzone"], 7)
	g.s["prova"] = true
	g.messaggio.connect(func(t, _tp): print(g.s["giorno"], " ", t))
	var p := g.umano()
	var inn: String = g.s["abitazioni"]["locanda"]
	print("Furfanti a ", g.nome_r(g.s["nativi"]["rogues"].get("dove", "")), " ; capitano a ", g.nome_r(p["dove"]))
	print("merce furfanti: ", g.nativi.merce("rogues").map(func(x): return "%s %d" % [x["nome"], x["oro"]]))
	p["oggetti"].append({"id": "t_gripping_dust", "attivo": false, "allerta": false, "danno": 0})
	await g.nativi.attivita_commercio(p)
	print("oro dopo vendita ", p["oro"])
	p["oro"] = 200
	p["rel"] = {"rogues": 1}
	await g.nativi.attivita_ingaggio(p)
	g.s["nativi"]["rogues"]["ingaggio"] = p["pid"]
	g.s["nativi"]["rogues"]["scadenza"] = 14
	p["nascosto"] = false
	print("ingaggio: ", g.s["nativi"]["rogues"]["ingaggio"], " alleati ", g.nativi.ingaggiati(p).size())
	# un mostro nella radura: combattono insieme
	for id in g.s["mostri"]:
		var m: Dictionary = g.s["mostri"][id]
		if m["tipo"] == "troll" and m["dove"] == "":
			m["dove"] = p["dove"]
			break
	await g.combat.combatti(p["dove"])
	# un gruppo nemico: blocchi
	p["rel"] = {"rogues": -2}
	g.s["nativi"]["rogues"]["ingaggio"] = ""
	p["nascosto"] = false
	print("blocco: ", g.nativi.blocco(p))
	await g.combat.combatti(p["dove"])
	quit()
