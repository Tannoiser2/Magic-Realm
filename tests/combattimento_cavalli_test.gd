## godot --headless --path . --script res://tests/combattimento_cavalli_test.gd
extends SceneTree

func _init() -> void:
	var g := Reame.new()
	assert(g.nuova_con_profilo(ProfiliRegole.classico_incontro(2), "elfo", [], 4211))
	var p: Dictionary = g.umano()
	p["cavalli"].append(CavalliClassici.nuovo("pony_m2"))
	assert(CavalliClassici.attiva(p, "pony_m2", g.carico_max(p), g.vulnerabilita(p), false))
	var u := {"usati": {}, "sforzo": 0, "bersaglio": "", "attacco": {}, "parata": {}, "manovra": {},
		"scudo": "", "ferite": 0, "ucciso_da": "", "cariche": []}
	g.combat.C = {"k": p["dove"], "uso": {p["pid"]: u}, "assegnati": {},
		"magia": {"scudo_sacro": {}, "corteccia": {}, "protezione": {}, "smussati": {}}}
	var opts: Dictionary = g.combat._opzioni_mischia(p)
	assert(opts["cavallo"])
	assert(opts["move"].is_empty())
	g.combat._registra_mischia(p, {"manovra": {"cavallo": true, "casella": "dodge"}}, opts)
	assert(u["manovra"].get("cavallo", false))
	assert(int(u["manovra"]["tempo"]) == 2)
	var monster_id: String = str(g.s["mostri"].keys()[0])
	var attacco := {"da": monster_id, "at": {"f": "H", "s": 0}, "dir": "swing", "missile": false, "rosso": false}
	assert(not g.combat._colpisci_pg(p, attacco, null))
	assert(not p["morto"])
	assert(p["cavalli"].is_empty())
	assert(int(u["ferite"]) == 0)
	# Un destriero corazzato neutralizza una stella di sharpness.
	p["cavalli"].append(CavalliClassici.nuovo("guerra_t5"))
	assert(CavalliClassici.attiva(p, "guerra_t5", g.carico_max(p), g.vulnerabilita(p), false))
	u["manovra"] = {"casella": "charge", "cavallo": true, "tempo": 5}
	var colpo := {"da": monster_id, "at": {"f": "H", "s": 1}, "dir": "thrust", "missile": false, "rosso": false}
	assert(not g.combat._colpisci_pg(p, colpo, null))
	assert(p["cavalli"].size() == 1)
	print("PASS: mounted maneuver, mount receives the blow, warhorse armor reduces sharpness")
	quit()
