## godot --headless --path . --script res://tests/reingresso_classico_test.gd
extends SceneTree

func _init() -> void:
	call_deferred("_prova")

func _prova() -> void:
	var g := Reame.new()
	g.auto_umano = true
	assert(g.nuova_con_profilo(ProfiliRegole.classico_incontro(2), "amazzone", [], 600))
	var p := g.umano()
	p["oro"] = 500
	p["morto"] = true
	p["reingresso_giorno"] = 2
	g.s["giorno"] = 2
	await g._reingresso_classico()
	var restored := g.umano()
	assert(not restored["morto"])
	assert(restored["dove"] == g.s["abitazioni"]["locanda"])
	assert(restored["oro"] == 10)
	assert(restored["vp"]["inc"] == 0)
	assert(restored["reingresso_giorno"] == 0)
	assert(g.s["fine"] == "")
	print("PASS: character re-entry at Inn on next day, fresh inventory and victory requirements")
	quit()
