## Verifica dei profili: godot --headless --path . --script res://tests/profili_regole_test.gd
extends SceneTree

func _init() -> void:
	for n in range(1, 7):
		var p := ProfiliRegole.super_scenario(n)
		assert(ProfiliRegole.valido(p))
		assert(p["scenario"] == n)
		assert(ProfiliRegole.abilitata(p, "magia") == (n >= 4))
		assert(ProfiliRegole.abilitata(p, "nativi") == (n >= 5))
		assert(ProfiliRegole.abilitata(p, "viaggiatori") == (n >= 6))
	for n in range(1, 5):
		var p := ProfiliRegole.classico_incontro(n)
		assert(ProfiliRegole.valido(p))
		assert(not p["implementato"])
		assert(p["giorni"] == 28)
		assert(not ProfiliRegole.abilitata(p, "viaggiatori"))
	var c := ProfiliRegole.classico_completo()
	assert(c["pv_assegnati"] == 5)
	assert(c["mappa"] == "classico_20")
	print("Profili di regole: OK (configurazioni; non gameplay)")
	quit()
