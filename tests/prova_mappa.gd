extends SceneTree
func _init() -> void:
	var ok := 0
	for seme in range(6):
		var rng := RandomNumberGenerator.new()
		rng.seed = seme
		var t0 := Time.get_ticks_msec()
		var m := Mappa.new()
		m.genera(rng)
		var archi := 0
		for k in m.vicini: archi += m.vicini[k].size()
		print("seme ", seme, " pezzi ", m.pezzi.size(), " radure ", m.radure.size(), " archi ", archi/2, " fiume ", m.dist_grotta.size(), " ms ", Time.get_ticks_msec()-t0, " ok ", m._verifica())
	quit()
