## Run: godot --headless --path . --script res://tests/anteprima_classica_test.gd
## Verifica integrata di mappa, segnalini e isolamento dello stato Super.
extends SceneTree

func _init() -> void:
	for seed in [1, 7, 22, 12345, 98765]:
		var reame := Reame.new()
		var anteprima := reame.anteprima_classica(seed)
		assert(not anteprima.is_empty())
		assert(anteprima["mappa"].size() == 20)
		assert(anteprima["segnalini"]["tessere"].size() == 20)
		assert(anteprima["profilo"]["id"] == "classico_completo")
		assert(reame.s.is_empty())
		var copia := Reame.new().anteprima_classica(seed)
		assert(JSON.stringify(anteprima) == JSON.stringify(copia))
	print("PASS: anteprima classica 5 semi; nessuna modifica allo stato di gioco")
	quit()
