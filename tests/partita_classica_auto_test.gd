## Run: godot --headless --path . --script res://tests/partita_classica_auto_test.gd
## Full 28-day automatic playthrough in classic mode.
extends SceneTree

func _init() -> void:
	for seed in [11, 22, 33]:
		var g := Reame.new()
		g.auto_umano = true
		assert(g.nuova_con_profilo(ProfiliRegole.classico_completo(),
			"amazzone", ["capitano", "elfo"], seed))
		assert(g.e_classico())
		assert(g.mappa.pezzi.size() == 20)
		assert(g.s["giorni_max"] == 28)
		var save := g.esporta()
		var h := Reame.new()
		h.importa(JSON.parse_string(JSON.stringify(save)))
		h.auto_umano = true
		assert(h.e_classico())
		assert(h.mappa is MappaClassica)
		assert(h.mappa.pezzi.size() == 20)
		assert(PunteggioClassico.valida_assegnazione(h.umano()["vp"], false))
		await h.gioca()
		assert(h.s["fine"] in ["vittoria", "sconfitta"])
		assert(h.s["giorno"] <= 29)
		print("CLASSIC GAME seed=%d end=%s day=%d score=%d" % [seed, h.s["fine"], h.s["giorno"], h.pv(h.umano())])
	# Verifica separata del ramo di conclusione del ventottesimo giorno.
	var finale := Reame.new()
	assert(finale.nuova_con_profilo(ProfiliRegole.classico_completo(), "amazzone", [], 98765))
	finale.umano()["oro"] = 1000
	finale.s["giorno"] = 27
	finale.controlla_vittoria()
	assert(finale.s["fine"] == "")
	finale.s["giorno"] = 28
	finale.controlla_vittoria()
	assert(finale.s["fine"] == "vittoria")
	assert(finale.s["vincitori"].has("p0"))
	print("PASS: end-of-month classic victory at day 28")
	print("PASS: three classic AI sessions terminated; not all survived to day 28")
	quit()
