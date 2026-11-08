## Esecuzione: godot --headless --path . --script res://tests/mappa_classica_test.gd
extends SceneTree

func _init() -> void:
	var seeds := [1, 7, 22, 12345, 98765]
	for seme in seeds:
		var rng := RandomNumberGenerator.new()
		rng.seed = seme
		var m := MappaClassica.new()
		assert(m.genera_classica(rng))
		assert(m.pezzi.size() == 20)
		assert(m.pezzi[0]["t"] == MappaClassica.BORDERLAND)
		var ids := {}
		for p in m.pezzi:
			ids[p["t"]] = true
		assert(ids.size() == 20)
		for t in MappaClassica.TESSERE_CLASSICHE:
			assert(ids.has(t))
		assert(m._connessa_classica())
	print("PASS: 20 tessere classiche in cinque semi")
	quit()
