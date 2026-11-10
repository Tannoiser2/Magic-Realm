## godot --headless --path . --script res://tests/ripartenza_super_test.gd
extends SceneTree

func _init() -> void:
	var g := Reame.new()
	g.nuova(5, "amazzone", ["nano"], 5151)
	var u: Dictionary = g.umano()
	u["fama"] = 9
	u["oro"] = 40
	u["morto"] = true
	u["reingresso_giorno"] = 3
	g.s["giorno"] = 1
	g.controlla_vittoria()
	assert(g.s["fine"] == "")
	g.s["giorno"] = 3
	g._reingresso_super()
	var n: Dictionary = g.umano()
	assert(not n["morto"])
	assert(n["fama"] == 0 and n["oro"] == 10)
	assert(n["dove"] == g.s["abitazioni"]["locanda"])
	assert(int(n["ripartenze"]) == 1)
	# rigenerazione mensile dei nativi
	var gid: String = g.s["nativi"].keys()[0]
	var id: String = g.s["nativi"][gid]["membri"][0]
	g.s["mostri"][id]["morto"] = true
	g.nativi.rigenera_mese()
	assert(not g.s["mostri"][id]["morto"])
	print("PASS: nuovo inizio Super alla Locanda e rigenerazione mensile dei nativi")
	quit()
