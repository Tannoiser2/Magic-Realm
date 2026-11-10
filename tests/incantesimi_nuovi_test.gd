## godot --headless --path . --script res://tests/incantesimi_nuovi_test.gd
extends SceneTree

func _init() -> void:
	var g := Reame.new()
	g.nuova(5, "mago", ["nano"], 777)
	var p: Dictionary = g.umano()
	var q: Dictionary = g.s["pg"][1]
	var k: String = p["dove"]
	# montagna: la radura diventa di montagna fino a domani
	var prima := g.tipo_radura(k)
	g.arcano.applica_effetto_giorno(p, p, "i_mountain_surge")
	assert(g.tipo_radura(k) == "M")
	# venti: nessuno vola dalla radura
	p["effetti"]["vola"] = 99
	g.arcano.applica_effetto_giorno(p, p, "i_violent_winds")
	assert(not g.arcano.puo_volare(p))
	# nebbia: si scruta solo la propria radura
	g.arcano.applica_effetto_giorno(p, p, "i_fog")
	assert(g.radure_scrutabili(p) == [k])
	# tempesta: chi è nella tessera (non l'incantatore) ha una fase base in meno
	q["dove"] = k
	g.arcano.applica_effetto_giorno(p, p, "i_violent_storm")
	assert(int(g.fasi_disponibili(q)["base"]) == 1)
	assert(int(g.fasi_disponibili(p)["base"]) == 2)
	# rapporti con i nativi
	var gid: String = g.s["nativi"].keys()[0]
	var base: int = g.nativi.rapporto(p, gid)
	g.arcano.applica_effetto_giorno(p, p, "i_dazzle")
	assert(g.nativi.rapporto(p, gid) == clampi(base + 1, -2, 2))
	# scambio dei tipi magici
	assert(not g.arcano.tipo_ok(p, "II", "VIII"))
	g.arcano.applica_effetto_giorno(p, p, "i_witch_s_brew")
	assert(g.arcano.tipo_ok(p, "II", "VIII") and g.arcano.tipo_ok(p, "VIII", "II"))
	# luce accecante: non si blocca
	g.arcano.applica_effetto_giorno(p, p, "i_blinding_light")
	assert(g.arcano.effetto(p, "luce_accecante"))
	# scadenza a mezzanotte del giorno dopo
	g.s["giorno"] += 1
	g.arcano.scadenze()
	assert(g.tipo_radura(k) == prima)
	assert(not g.arcano.effetto(p, "luce_accecante"))
	print("PASS: 17 nuovi incantesimi lanciabili (luogo, rapporti, scambi, comandi)")
	quit()
