extends SceneTree
func _init() -> void:
	var t := "Amazzone è mort{oa}!"
	var i := t.find("{oa}")
	print(i, " ", t.rfind("Amazzone", i), " ", t.rfind("Amazzone"))
	quit()
