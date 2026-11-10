## godot --headless --path . --script res://tests/nascondiglio_test.gd
extends SceneTree

func _init() -> void:
	var g := Reame.new()
	g.nuova(4, "amazzone", [], 4242)
	var p: Dictionary = g.umano()
	var o: Dictionary = p["oggetti"][0]
	p["oggetti"].erase(o)
	p["oro"] = 15
	var chiave: String = p["pid"] + "|" + p["dove"]
	g.s["nascondigli"] = {chiave: {"pid": p["pid"], "dove": p["dove"], "oggetti": [o], "oro": 7}}
	var f: Array = g.arcano.fonti(p)["saccheggia"]
	assert(f.any(func(x): return x["id"] == "x:" + chiave))
	var n: int = p["oggetti"].size()
	g.arcano.saccheggia(p, "x:" + chiave)
	assert(p["oggetti"].size() == n + 1)
	assert(p["oro"] == 22)
	assert(not g.s["nascondigli"].has(chiave))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(g.esporta()))
	assert(saved is Dictionary)
	print("PASS: nascondiglio (Cache) si recupera con la Ricerca senza tiro")
	quit()
