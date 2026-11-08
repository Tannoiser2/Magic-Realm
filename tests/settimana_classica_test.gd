## godot --headless --path . --script res://tests/settimana_classica_test.gd
extends SceneTree

func _init() -> void:
	var g := Reame.new()
	assert(g.nuova_con_profilo(ProfiliRegole.classico_incontro(2), "amazzone", [], 321))
	var target := ""
	for mid in g.s["mostri"]:
		var m: Dictionary = g.s["mostri"][mid]
		if not m.has("nativo") and m["casa"][0] == "g" and g.riga_di(m["tipo"]) == 1:
			target = mid
			break
	assert(target != "")
	var m: Dictionary = g.s["mostri"][target]
	var box: Array = g.s["tabella"][int(m["casa"][1])][int(m["casa"][2])]
	box.erase(target)
	m["morto"] = true
	m["dove"] = g.umano()["dove"]
	g.s["riga_mostri"] = 1
	g._ritorno_settimanale_classico()
	assert(not m["morto"])
	assert(m["dove"] == "")
	assert(target in box)
	var untouched := ""
	for mid in g.s["mostri"]:
		var n: Dictionary = g.s["mostri"][mid]
		if not n.has("nativo") and n["casa"][0] == "g" and g.riga_di(n["tipo"]) != 1:
			untouched = mid
			break
	assert(untouched != "")
	var another: Dictionary = g.s["mostri"][untouched]
	another["morto"] = true
	g._ritorno_settimanale_classico()
	assert(another["morto"])
	print("PASS: weekly Classic regeneration applies only to prowling row")
	quit()
