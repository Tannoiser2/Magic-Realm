## Test del mazzo originale 20 avvisi + 18 suoni/siti + 2 perduti.
extends SceneTree

func _init() -> void:
	for seed in [1, 17, 4711, 2026]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var s := PreparazioneClassica.prepara(rng)
		assert(not s.is_empty())
		assert(s["tessere"].size() == 20)
		var avvisi := {}
		var rossi := {}
		for t in s["tessere"]:
			var st: Dictionary = s["tessere"][t]
			assert(st["avviso"] != "")
			assert(not avvisi.has(st["avviso"]))
			avvisi[st["avviso"]] = true
			for id in st["rossi"]:
				assert(not rossi.has(id))
				rossi[id] = true
		assert(avvisi.size() == 20)
		assert(rossi.size() == 10)
		assert(rossi.has("perduto_city"))
		assert(rossi.has("perduto_castle"))
		var tutti_rossi := {}
		for id in rossi:
			tutti_rossi[id] = true
		for id in s["riserve"]:
			assert(s["riserve"][id].size() == 5)
			for x in s["riserve"][id]:
				assert(not tutti_rossi.has(x))
				tutti_rossi[x] = true
		assert(tutti_rossi.size() == 20)
	print("PASS: segnalini classici, 4 semi")
	quit()
