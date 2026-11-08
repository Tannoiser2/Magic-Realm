## godot --headless --path . --script res://tests/partite_quattro_encounter_test.gd
## Simulazioni end-to-end (non solo setup) delle quattro modalita originali.
extends SceneTree

func _init() -> void:
	call_deferred("_prova")

func _prova() -> void:
	for i in range(1, 5):
		var g := Reame.new()
		g.auto_umano = true
		assert(g.nuova_con_profilo(ProfiliRegole.classico_incontro(i), "amazzone", [], 9980 + i))
		assert(g.incontro_classico() == i)
		await g.gioca()
		assert(g.s["fine"] in ["vittoria", "sconfitta"])
		assert(int(g.s["giorno"]) <= 29)
		print("ENCOUNTER %d simulated day=%d end=%s" % [i, int(g.s["giorno"]), g.s["fine"]])
	print("PASS: 4 automatic encounters reached valid end state")
	quit()
