## Interfaccia di Magic Realm: menu, mappa 3D del Reame con tessere e pedine originali,
## scheda del personaggio, pianificazione dell'alba, decisioni e combattimento, registro, salvataggi.
extends Node

const SALVATAGGIO_SUPER := "user://partita_magicrealm.json"
const SALVATAGGIO_CLASSICO := "user://partita_magicrealm_classico.json"
const C_FONDO := Color(0.10, 0.07, 0.05)
const C_PERG := Color(0.93, 0.86, 0.70)
const C_PERG_SCURA := Color(0.80, 0.70, 0.52)
const C_INCHIOSTRO := Color(0.20, 0.12, 0.07)
const C_ORO := Color(0.85, 0.66, 0.25)
const C_ROSSO := Color(0.62, 0.13, 0.10)
const C_VERDE := Color(0.20, 0.42, 0.20)
const C_MOVE := Color8(58, 160, 192)
const C_FIGHT := Color8(200, 96, 42)
const C_MAGIA := Color8(128, 72, 160)
const ALTEZZA := 0.06

var g: Reame
var net: Node
var f_tit: Font
var f_txt: Font
var f_fell: Font
var tex := {}

# 3D
var mondo: Node3D
var cam: Camera3D
var bersaglio_cam := Vector3.ZERO
var yaw := 0.0
var pitch := -1.0
var distanza := 10.0
var nodo_tessere: Node3D
var nodo_pezzi: Node3D
var nodo_evid: Node3D
var trascina := 0
var tocchi := {}
var due_dita := false
var mouse_prec := Vector2.ZERO
var mouse_giu := Vector2.ZERO
var hover := ""

# UI
var ui: CanvasLayer
var menu: Control
var hud: Control
var lbl_giorno: Label
var lbl_fase: Label
var lbl_codice: Label
var scheda: VBoxContainer
var registro: RichTextLabel
var azioni: PanelContainer
var box_azioni: VBoxContainer
var modale: PanelContainer
var box_modale: VBoxContainer
var tip: PanelContainer
var lbl_tip: RichTextLabel
var aiuto: PanelContainer
var avviso: Label

# pianificazione
var piano: Array = []
var fasi: Dictionary = {}
var modo_volo := false
var guida_pannello: PanelContainer
var guida_box: VBoxContainer
var guida_visti := {}
var guida_attiva := true
var guida_coda: Array = []
var marcatore: Node3D
const GUIDA_CFG := "user://guida_magicrealm.cfg"
const SCENARI := [1, 2, 3, 4, 5, 6]
var modo_mossa := false
var codice := ""
var scelte_menu := {"edizione": "super", "scenario": 3, "pg": "amazzone", "rivali": 2, "partita_libera": false, "durata_libera": 84, "incontro_classico": 4, "partenza": ""}
var mischia := {}
var edizione_portale := "" # "super" o "classico" per le build sul sito; vuoto in Godot locale

func _edizione_attuale() -> String:
	return ("classico" if g.e_classico() else "super") if g != null and not g.s.is_empty() else str(scelte_menu["edizione"])

func _percorso_salvataggio(edizione: String) -> String:
	return SALVATAGGIO_CLASSICO if edizione == "classico" else SALVATAGGIO_SUPER

func _torna_portale() -> void:
	if OS.has_feature("web") and edizione_portale != "":
		JavaScriptBridge.eval("window.location.href = '../';", true)


func _ready() -> void:
	Dati.carica()
	if OS.has_feature("web"):
		var url_path: String = str(JavaScriptBridge.eval("window.location.pathname", true))
		if url_path.ends_with("/classico/") or url_path.ends_with("/classico/index.html"):
			edizione_portale = "classico"
		elif url_path.ends_with("/super/") or url_path.ends_with("/super/index.html"):
			edizione_portale = "super"
		if edizione_portale != "":
			scelte_menu["edizione"] = edizione_portale
	f_tit = load("res://assets/font/Titoli.ttf")
	f_txt = load("res://assets/font/Testo.ttf")
	f_fell = load("res://assets/font/Fell.ttf")
	net = load("res://scripts/net.gd").new()
	if edizione_portale == "classico":
		net.root_partite = "magicrealm/classico/partite"
		net.sessione = "user://online_magicrealm_classico.cfg"
	add_child(net)
	_crea_mondo()
	_crea_ui()
	_mostra_menu()

func T(p: String) -> Texture2D:
	if not tex.has(p):
		tex[p] = load(p) if ResourceLoader.exists(p) else null
	return tex[p]

# ============================================================ 3D
func _crea_mondo() -> void:
	mondo = Node3D.new()
	add_child(mondo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.06, 0.05)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.95, 0.88, 0.75)
	e.ambient_light_energy = 0.32
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = e
	mondo.add_child(env)
	var luce := DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-58, 35, 0)
	luce.light_energy = 0.78
	luce.light_color = Color(1.0, 0.94, 0.82)
	luce.shadow_enabled = true
	luce.directional_shadow_max_distance = 40.0
	mondo.add_child(luce)
	cam = Camera3D.new()
	cam.fov = 45
	mondo.add_child(cam)
	# tavolo
	var tav := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	tav.mesh = pm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.20, 0.13, 0.08)
	mt.roughness = 0.9
	tav.material_override = mt
	tav.position.y = -0.02
	mondo.add_child(tav)
	nodo_tessere = Node3D.new()
	mondo.add_child(nodo_tessere)
	nodo_pezzi = Node3D.new()
	mondo.add_child(nodo_pezzi)
	nodo_evid = Node3D.new()
	mondo.add_child(nodo_evid)
	_aggiorna_camera()

func _aggiorna_camera() -> void:
	pitch = clampf(pitch, -1.45, -0.35)
	distanza = clampf(distanza, 2.0, 30.0)
	var dir := Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch))
	cam.position = bersaglio_cam + dir * distanza
	cam.look_at(bersaglio_cam, Vector3.UP)

func _v3(p: Vector2, h := 0.0) -> Vector3:
	return Vector3(p.x, ALTEZZA + h, p.y)

func _mesh_tessera(i: int) -> MeshInstance3D:
	var p: Dictionary = g.mappa.pezzi[i]
	var t: int = p["t"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := g.mappa.centro(i)
	var rot := deg_to_rad(60.0 * p["rot"])
	var punti := []
	for k in range(6):
		var a := deg_to_rad(60.0 * k)
		punti.append(Vector2(cos(a), sin(a)))
	for k in range(6):
		var a: Vector2 = punti[k]
		var b: Vector2 = punti[(k + 1) % 6]
		for v in [Vector2.ZERO, a, b]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(0.5 + v.x * 0.5 * 790.0 / 791.0, 0.5 + v.y * 0.5 * 790.0 / 791.0))
			var w: Vector2 = c + v.rotated(rot) * 0.995
			st.add_vertex(Vector3(w.x, ALTEZZA, w.y))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_texture = T("res://assets/tessere/t%02d.webp" % t)
	m.roughness = 0.85
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mi.material_override = m
	# bordo in rilievo (spessore della tessera)
	var sv := SurfaceTool.new()
	sv.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(6):
		var a: Vector2 = c + (punti[k] as Vector2).rotated(rot) * 0.995
		var b: Vector2 = c + (punti[(k + 1) % 6] as Vector2).rotated(rot) * 0.995
		var n := Vector3((a + b).x / 2 - c.x, 0, (a + b).y / 2 - c.y).normalized()
		for v in [Vector3(a.x, ALTEZZA, a.y), Vector3(b.x, ALTEZZA, b.y), Vector3(b.x, 0, b.y), Vector3(a.x, ALTEZZA, a.y), Vector3(b.x, 0, b.y), Vector3(a.x, 0, a.y)]:
			sv.set_normal(n)
			sv.add_vertex(v)
	var bordo := MeshInstance3D.new()
	bordo.mesh = sv.commit()
	var mb := StandardMaterial3D.new()
	mb.albedo_color = Color(0.30, 0.24, 0.14)
	mb.cull_mode = BaseMaterial3D.CULL_DISABLED
	bordo.material_override = mb
	mi.add_child(bordo)
	return mi

func _costruisci_mappa() -> void:
	for c in nodo_tessere.get_children():
		c.queue_free()
	var minimo := Vector2(INF, INF)
	var massimo := Vector2(-INF, -INF)
	for i in range(g.mappa.pezzi.size()):
		nodo_tessere.add_child(_mesh_tessera(i))
		var c := g.mappa.centro(i)
		minimo = minimo.min(c)
		massimo = massimo.max(c)
	var u := g.umano()
	if not u.is_empty() and g.mappa.radure.has(u["dove"]):
		var p: Vector2 = g.mappa.radure[u["dove"]]["pos"]
		bersaglio_cam = Vector3(p.x, 0, p.y)
	else:
		var m := (minimo + massimo) / 2
		bersaglio_cam = Vector3(m.x, 0, m.y)
	distanza = 8.0
	_aggiorna_camera()

func _gettone(img: String, lato: float, retro := "", spessore := 0.035, colore := Color(0.18, 0.12, 0.08)) -> Node3D:
	var n := Node3D.new()
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(lato, spessore, lato)
	base.mesh = bm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = colore
	base.material_override = mm
	base.position.y = spessore / 2
	n.add_child(base)
	var top := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(lato * 0.98, lato * 0.98)
	top.mesh = q
	top.rotation_degrees.x = -90
	top.position.y = spessore + 0.002
	var tm := StandardMaterial3D.new()
	tm.albedo_texture = T(img)
	tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	tm.roughness = 0.7
	top.material_override = tm
	n.add_child(top)
	return n

# Preferisce una miniatura GLB, mantenendo la pedina originale come fallback.
# Contratto asset 3D: soggetto centrato sull'asse Y, base a Y=0, larghezza 1 unita.
func _gettone_o_modello(id_modello: String, img: String, lato: float, spessore := 0.035, colore := Color(0.18, 0.12, 0.08)) -> Node3D:
	var path := "res://assets/3d/%s.glb" % id_modello
	if ResourceLoader.exists(path):
		var risorsa = load(path)
		if risorsa is PackedScene:
			var modello = risorsa.instantiate()
			if modello is Node3D:
				var contenitore := Node3D.new()
				modello.scale = Vector3.ONE * lato
				contenitore.add_child(modello)
				return contenitore
			modello.queue_free()
	return _gettone(img, lato, "", spessore, colore)

func _anello(pos: Vector2, colore: Color, r := 0.17, spessore := 0.025) -> void:
	var a := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r - spessore
	tm.outer_radius = r
	tm.rings = 24
	a.mesh = tm
	var m := StandardMaterial3D.new()
	m.albedo_color = colore
	m.emission_enabled = true
	m.emission = colore
	m.emission_energy_multiplier = 1.4
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	a.material_override = m
	a.position = _v3(pos, 0.01)
	nodo_evid.add_child(a)

func _img_mostro(m: Dictionary) -> String:
	var lato := "b" if m["lato"] == 1 else "a"
	if m.has("nativo"):
		return "res://assets/nativi/%s_%s.webp" % [m["img"], lato]
	var p := "res://assets/mostri/%s_%s.webp" % [m["img"], lato]
	if not ResourceLoader.exists(p):
		p = "res://assets/mostri/%s_a.webp" % m["img"]
	return p

func _aggiorna_pezzi() -> void:
	for c in nodo_pezzi.get_children():
		c.queue_free()
	if g == null or g.mappa == null:
		return
	var per_radura := {}
	var aggiungi := func(k: String, nodo: Node3D, lato: float):
		if not per_radura.has(k): per_radura[k] = []
		per_radura[k].append([nodo, lato])
	# abitazioni
	for a in g.s["abitazioni"]:
		aggiungi.call(g.s["abitazioni"][a], _gettone_o_modello("abitazioni/%s" % a, "res://assets/abitazioni/%s.webp" % a, 0.26, 0.05, Color(0.3, 0.25, 0.2)), 0.26)
	# mostri (dei nativi si mostra un solo segnalino per gruppo e radura)
	var gruppi_visti := {}
	for id in g.s["mostri"]:
		var m: Dictionary = g.s["mostri"][id]
		if m["morto"] or m["dove"] == "":
			continue
		if m.has("nativo"):
			var kg: String = m["dove"] + "|" + m["nativo"]
			if gruppi_visti.has(kg):
				continue
			gruppi_visti[kg] = true
		var peso: String = Dati.tipo_mostro(m["tipo"]).get("peso", "M")
		var lato := {"M": 0.19, "H": 0.23, "T": 0.29, "X": 0.31}.get(peso, 0.2) as float
		aggiungi.call(m["dove"], _gettone_o_modello("nativi/%s" % m["nativo"] if m.has("nativo") else "mostri/%s" % m["tipo"], _img_mostro(m), lato, 0.04), lato)
	# viaggiatori
	for id in g.s.get("viaggi", {}):
		var x: Dictionary = g.s["viaggi"][id]
		if x["dove"] == "" or x["chi"] != "":
			continue
		var img: String = "res://assets/" + Viaggi.v(id)["img"] if x["su"] else "res://assets/viaggiatori/retro.webp"
		aggiungi.call(x["dove"], _gettone_o_modello("viaggiatori/%s" % id, img, 0.17, 0.03), 0.17)
	# personaggi (la tua pedina sta al centro della radura, più grande, sotto il segnalino rosso)
	var mia: Node3D = null
	var mia_k := ""
	for p in g.s["pg"]:
		if p["morto"]:
			continue
		var d := Dati.personaggi[p["pg"]] as Dictionary
		var nasc: bool = p["nascosto"] and g.s["scenario"] >= 2
		var img := "res://assets/personaggi/%s_%s.webp" % [d["pedina"], "nascosto" if nasc else "pedina"]
		if p["umano"]:
			mia = _gettone_o_modello("personaggi/%s" % d["pedina"], img, 0.36, 0.09, Color(0.6, 0.08, 0.05))
			mia_k = p["dove"]
			continue
		var gt := _gettone_o_modello("personaggi/%s" % d["pedina"], img, 0.27, 0.06, Color(0.12, 0.1, 0.1))
		aggiungi.call(p["dove"], gt, 0.24)
	for k in per_radura:
		if not g.mappa.radure.has(k):
			continue
		var pos: Vector2 = g.mappa.radure[k]["pos"]
		var lista: Array = per_radura[k]
		var n := lista.size()
		for i in range(n):
			var nodo: Node3D = lista[i][0]
			var off := Vector2.ZERO
			if n > 1:
				var ang := TAU * i / n
				var rr := 0.10 + 0.012 * n
				off = Vector2(cos(ang), sin(ang)) * rr
			nodo.position = _v3(pos + off, 0.002 * i)
			nodo_pezzi.add_child(nodo)
	if mia != null and g.mappa.radure.has(mia_k):
		var pm: Vector2 = g.mappa.radure[mia_k]["pos"]
		mia.position = _v3(pm, 0.03)
		nodo_pezzi.add_child(mia)
		marcatore = MeshInstance3D.new()
		var cono := CylinderMesh.new()
		cono.top_radius = 0.09
		cono.bottom_radius = 0.0
		cono.height = 0.18
		cono.radial_segments = 4
		(marcatore as MeshInstance3D).mesh = cono
		var mc := StandardMaterial3D.new()
		mc.albedo_color = Color(0.9, 0.12, 0.08)
		mc.emission_enabled = true
		mc.emission = Color(0.9, 0.12, 0.08)
		mc.emission_energy_multiplier = 0.8
		(marcatore as MeshInstance3D).material_override = mc
		marcatore.position = _v3(pm, 0.62)
		nodo_pezzi.add_child(marcatore)
	# segnalini della mappa
	var u := g.umano()
	for i in range(g.mappa.pezzi.size()):
		var t: int = g.mappa.pezzi[i]["t"]
		var st: Dictionary = g.s["tessere"][str(t)]
		var visti: bool = st["scoperti"] or (not u.is_empty() and u["sbirciati"].has(str(t)))
		var lista := []
		var cat: String = Dati.tessere[t]["cat"]
		if st["avviso"] != "" and not (cat in ["V", "H"]):
			lista.append(st["avviso"])
		for r in st["rossi"]:
			lista.append(r)
		var c := g.mappa.centro(i)
		var j := 0
		for id in lista:
			var ch: Dictionary = Dati.segnalini[id]
			var img := "res://assets/segnalini/%s.webp" % id
			if not visti:
				img = "res://assets/segnalini/%s.webp" % ch.get("retro", "retro_rosso")
			var gtt := _gettone(img, 0.15, "", 0.025)
			var off := Vector2(-0.52 + 0.17 * (j % 4), 0.62 - 0.17 * (j / 4))
			gtt.position = _v3(c + off.rotated(0.0), 0.0)
			nodo_pezzi.add_child(gtt)
			j += 1

func _aggiorna_evidenze() -> void:
	for c in nodo_evid.get_children():
		c.queue_free()
	if g == null or g.mappa == null:
		return
	var u := g.umano()
	if u.is_empty() or u["morto"]:
		return
	if g.mappa.radure.has(u["dove"]):
		_anello(g.mappa.radure[u["dove"]]["pos"], Color(0.95, 0.2, 0.1), 0.28, 0.05)
	if modo_mossa and g.richiesta.get("tipo", "") == "piano" and modo_volo:
		var t0 := g.tessera(_ultima_posizione())
		for t1 in [t0] + g.mappa.tessere_adiacenti(t0):
			for k in g.mappa.radure_tessera(t1):
				_anello(g.mappa.radure[k]["pos"], Color(0.6, 0.75, 1.0), 0.13)
	elif modo_mossa and g.richiesta.get("tipo", "") == "piano":
		var da := _ultima_posizione()
		for k in g.vicini_di(u, da):
			_anello(g.mappa.radure[k]["pos"], Color(1.0, 0.85, 0.1), 0.24, 0.05)
	# percorso pianificato
	var prec: String = u["dove"]
	for a in piano:
		if a["a"] in ["M", "V"] and a["dest"] != prec and g.mappa.radure.has(a["dest"]):
			_anello(g.mappa.radure[a["dest"]]["pos"], Color(0.2, 0.9, 0.4), 0.2, 0.045)
			prec = a["dest"]
	if hover != "" and g.mappa.radure.has(hover):
		_anello(g.mappa.radure[hover]["pos"], Color(1, 1, 1), 0.21)

func _ultima_posizione() -> String:
	var u := g.umano()
	var k: String = u["dove"]
	for a in piano:
		if a["a"] in ["M", "V"]:
			k = a["dest"]
	return k

func _radura_sotto(pos: Vector2) -> String:
	if g == null or g.mappa == null:
		return ""
	var o := cam.project_ray_origin(pos)
	var d := cam.project_ray_normal(pos)
	if absf(d.y) < 0.0001:
		return ""
	var t := (ALTEZZA - o.y) / d.y
	if t < 0:
		return ""
	var p := o + d * t
	var best := ""
	var bd := 0.2
	for k in g.mappa.radure:
		var q: Vector2 = g.mappa.radure[k]["pos"]
		var dd := q.distance_to(Vector2(p.x, p.z))
		if dd < bd:
			bd = dd
			best = k
	return best

func _unhandled_input(ev: InputEvent) -> void:
	if menu.visible:
		return
	# tocco: un dito trascina (emulato come mouse), due dita pizzicano e ruotano
	if ev is InputEventScreenTouch:
		var st := ev as InputEventScreenTouch
		if st.pressed:
			tocchi[st.index] = st.position
		else:
			tocchi.erase(st.index)
		due_dita = tocchi.size() >= 2
		if due_dita:
			trascina = 0
		return
	if ev is InputEventScreenDrag:
		var sd := ev as InputEventScreenDrag
		if tocchi.size() >= 2 and tocchi.has(sd.index):
			var ids: Array = tocchi.keys()
			var altro: int = ids[1] if ids[0] == sd.index else ids[0]
			var a0: Vector2 = tocchi[sd.index]
			var b0: Vector2 = tocchi[altro]
			var a1: Vector2 = sd.position
			var d0 := a0.distance_to(b0)
			var d1 := a1.distance_to(b0)
			if d0 > 10 and d1 > 10:
				distanza = clampf(distanza * d0 / d1, 3.0, 40.0)
			var ang := (a1 - b0).angle() - (a0 - b0).angle()
			yaw -= wrapf(ang, -PI, PI)
			tocchi[sd.index] = a1
			_aggiorna_camera()
		elif tocchi.has(sd.index):
			tocchi[sd.index] = sd.position
		return
	if due_dita and (ev is InputEventMouseMotion or ev is InputEventMouseButton):
		if ev is InputEventMouseButton and not (ev as InputEventMouseButton).pressed:
			trascina = 0
		return
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			distanza *= 0.9
			_aggiorna_camera()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			distanza *= 1.1
			_aggiorna_camera()
		elif mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if mb.pressed:
				trascina = mb.button_index
				mouse_prec = mb.position
				mouse_giu = mb.position
			else:
				if mb.button_index == MOUSE_BUTTON_LEFT and mb.position.distance_to(mouse_giu) < 6:
					_clic(_radura_sotto(mb.position))
				trascina = 0
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if trascina == MOUSE_BUTTON_LEFT and mm.position.distance_to(mouse_giu) > 6:
			_sposta(mm.position - mouse_prec)
		elif trascina == MOUSE_BUTTON_RIGHT or trascina == MOUSE_BUTTON_MIDDLE:
			yaw -= (mm.position - mouse_prec).x * 0.006
			pitch -= (mm.position - mouse_prec).y * 0.004
			_aggiorna_camera()
		mouse_prec = mm.position
		var h := _radura_sotto(mm.position)
		if h != hover:
			hover = h
			_aggiorna_evidenze()
			_mostra_tip(h, mm.position)
		elif h != "":
			tip.position = mm.position + Vector2(18, 18)
	elif ev is InputEventMagnifyGesture:
		distanza /= (ev as InputEventMagnifyGesture).factor
		_aggiorna_camera()
	elif ev is InputEventPanGesture:
		_sposta(-(ev as InputEventPanGesture).delta * 8.0)

func _sposta(d: Vector2) -> void:
	var f := distanza * 0.0016
	var dx := Vector3(cos(yaw), 0, -sin(yaw))
	var dz := Vector3(sin(yaw), 0, cos(yaw))
	bersaglio_cam -= dx * d.x * f + dz * d.y * f
	_aggiorna_camera()

func _mostra_tip(k: String, pos: Vector2) -> void:
	if k == "" or g == null:
		tip.visible = false
		return
	var t := g.tessera(k)
	var testo := "[b]%s[/b] (%s)\n%s, radura di %s" % [g.nome_r(k), g.mappa.sigla_radura(k), Dati.CATEGORIE[Dati.tessere[t]["cat"]], Dati.TIPI_RADURA[g.tipo_radura(k)]]
	var ab := g.abitazione_in(k)
	if ab != "":
		testo += "\n" + Dati.ABITAZIONI[ab]
	for p in g.s["pg"]:
		if p["dove"] == k and not p["morto"]:
			testo += "\n%s%s" % [p["nome"], " (nascost%s)" % ("a" if Dati.personaggi[p["pg"]]["genere"] == "f" else "o") if p["nascosto"] else ""]
	var mostri := []
	for id in g.s["mostri"]:
		var m: Dictionary = g.s["mostri"][id]
		if m["dove"] == k and not m["morto"]:
			mostri.append(m)
	if not mostri.is_empty():
		testo += "\n[color=#8a1c10]" + g._elenco_mostri(mostri) + "[/color]"
	var u := g.umano()
	if not u.is_empty() and k in g.vicini_di(u, u["dove"]):
		testo += "\nMovimento: %d fas%s" % [g.costo_mossa(u, u["dove"], k), "e" if g.costo_mossa(u, u["dove"], k) == 1 else "i"]
	lbl_tip.text = testo
	tip.visible = true
	tip.position = pos + Vector2(18, 18)
	tip.reset_size()

func _clic(k: String) -> void:
	if k == "" or g == null:
		return
	if modo_mossa and g.richiesta.get("tipo", "") == "piano" and modo_volo:
		var u2 := g.umano()
		var t0 := g.tessera(_ultima_posizione())
		var t1 := g.tessera(k)
		if t1 != t0 and not (t1 in g.mappa.tessere_adiacenti(t0)):
			_avviso("Puoi volare solo verso una tessera vicina.")
			return
		if piano.size() >= _fasi_totali():
			return
		piano.append({"a": "V", "dest": k})
		modo_volo = false
		_pannello_piano()
		_aggiorna_evidenze()
		return
	if modo_mossa and g.richiesta.get("tipo", "") == "piano":
		var u := g.umano()
		var da := _ultima_posizione()
		if not (k in g.vicini_di(u, da)):
			_avviso("Da %s non c'è una strada conosciuta per %s." % [g.nome_r(da), g.nome_r(k)])
			return
		var costo := g.costo_mossa(u, da, k)
		if piano.size() + costo > _fasi_totali():
			_avviso("Non restano abbastanza fasi per muovere lì (servono %d fasi)." % costo)
			return
		for i in range(costo):
			piano.append({"a": "M", "dest": k})
		_pannello_piano()
		_aggiorna_evidenze()

# ============================================================ UI di base
func _stile(colore: Color, bordo := Color(0, 0, 0, 0), raggio := 6, spessore := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = colore
	s.corner_radius_top_left = raggio
	s.corner_radius_top_right = raggio
	s.corner_radius_bottom_left = raggio
	s.corner_radius_bottom_right = raggio
	if spessore > 0:
		s.border_color = bordo
		s.border_width_left = spessore
		s.border_width_right = spessore
		s.border_width_top = spessore
		s.border_width_bottom = spessore
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _lab(t: String, size := 18, font: Font = null, col := C_INCHIOSTRO) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font if font != null else f_txt)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _bott(t: String, cb: Callable, size := 18, primario := false) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_override("font", f_tit)
	b.add_theme_font_size_override("font_size", size)
	var base := Color(0.45, 0.10, 0.07) if primario else Color(0.30, 0.20, 0.12)
	b.add_theme_stylebox_override("normal", _stile(base, C_ORO, 5, 1))
	b.add_theme_stylebox_override("hover", _stile(base.lightened(0.15), C_ORO, 5, 2))
	b.add_theme_stylebox_override("pressed", _stile(base.darkened(0.2), C_ORO, 5, 2))
	b.add_theme_stylebox_override("disabled", _stile(Color(0.35, 0.32, 0.28), Color(0.5, 0.45, 0.4), 5, 1))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color(0.98, 0.92, 0.78))
	b.add_theme_color_override("font_hover_color", Color(1, 0.97, 0.85))
	b.add_theme_color_override("font_disabled_color", Color(0.75, 0.72, 0.66))
	b.pressed.connect(cb)
	return b

func _pannello(colore := C_PERG) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _stile(colore, Color(0.45, 0.30, 0.15), 8, 2))
	return p

func _crea_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	# barra in alto
	var barra := _pannello(Color(0.16, 0.10, 0.06, 0.95))
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.offset_bottom = 54
	hud.add_child(barra)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	barra.add_child(hb)
	var titolo := _lab("Magic Realm", 28, f_tit, C_ORO)
	titolo.autowrap_mode = TextServer.AUTOWRAP_OFF
	hb.add_child(titolo)
	lbl_giorno = _lab("", 20, f_tit, C_PERG)
	lbl_giorno.autowrap_mode = TextServer.AUTOWRAP_OFF
	hb.add_child(lbl_giorno)
	lbl_fase = _lab("", 18, f_txt, C_PERG)
	lbl_fase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_fase.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl_fase.clip_text = true
	hb.add_child(lbl_fase)
	lbl_codice = _lab("", 16, f_txt, C_PERG_SCURA)
	lbl_codice.autowrap_mode = TextServer.AUTOWRAP_OFF
	hb.add_child(lbl_codice)
	hb.add_child(_bott("Centra", _centra, 16))
	hb.add_child(_bott("Salva online", _salva_online, 16))
	hb.add_child(_bott("Guida", func(): _mostra_guida_classica() if g != null and g.e_classico() else _mostra_guida_scenario(true), 16))
	hb.add_child(_bott("Regole", func(): aiuto.visible = not aiuto.visible, 16))
	hb.add_child(_bott("Menu", _torna_menu, 16))
	# scheda personaggio a sinistra
	var ps := _pannello()
	ps.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	ps.offset_top = 62
	ps.offset_bottom = -8
	ps.offset_left = 8
	ps.offset_right = 330
	hud.add_child(ps)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ps.add_child(sc)
	scheda = VBoxContainer.new()
	scheda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scheda.add_theme_constant_override("separation", 6)
	sc.add_child(scheda)
	# registro a destra
	var pr := _pannello(Color(0.93, 0.86, 0.70, 0.94))
	pr.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	pr.offset_top = 62
	pr.offset_bottom = -8
	pr.offset_right = -8
	pr.offset_left = -350
	hud.add_child(pr)
	var vr := VBoxContainer.new()
	pr.add_child(vr)
	vr.add_child(_lab("Cronaca", 22, f_tit))
	registro = RichTextLabel.new()
	registro.bbcode_enabled = true
	registro.scroll_following = true
	registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	registro.add_theme_font_override("normal_font", f_txt)
	registro.add_theme_font_override("bold_font", f_tit)
	registro.add_theme_font_size_override("normal_font_size", 16)
	registro.add_theme_font_size_override("bold_font_size", 17)
	registro.add_theme_color_override("default_color", C_INCHIOSTRO)
	vr.add_child(registro)
	# pannello azioni in basso al centro
	azioni = _pannello(Color(0.93, 0.86, 0.70, 0.97))
	azioni.anchor_left = 0.5
	azioni.anchor_right = 0.5
	azioni.anchor_top = 1.0
	azioni.anchor_bottom = 1.0
	azioni.offset_left = -440
	azioni.offset_right = 440
	azioni.offset_top = -215
	azioni.offset_bottom = -10
	azioni.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hud.add_child(azioni)
	var sa := ScrollContainer.new()
	sa.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	azioni.add_child(sa)
	box_azioni = VBoxContainer.new()
	box_azioni.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_azioni.add_theme_constant_override("separation", 6)
	sa.add_child(box_azioni)
	# finestra modale (combattimento, ricerca)
	modale = _pannello(Color(0.93, 0.86, 0.70, 0.98))
	modale.set_anchors_preset(Control.PRESET_CENTER)
	modale.custom_minimum_size = Vector2(760, 0)
	modale.visible = false
	hud.add_child(modale)
	var sm := ScrollContainer.new()
	sm.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sm.name = "Scorri"
	modale.add_child(sm)
	box_modale = VBoxContainer.new()
	box_modale.add_theme_constant_override("separation", 8)
	box_modale.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sm.add_child(box_modale)
	# avvisi
	avviso = _lab("", 18, f_txt, Color(1, 0.95, 0.8))
	avviso.set_anchors_preset(Control.PRESET_CENTER_TOP)
	avviso.offset_top = 64
	avviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avviso.add_theme_stylebox_override("normal", _stile(Color(0.45, 0.1, 0.07, 0.92), C_ORO, 6, 1))
	avviso.visible = false
	hud.add_child(avviso)
	# suggerimento
	tip = _pannello(Color(0.98, 0.93, 0.80, 0.97))
	tip.visible = false
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(tip)
	lbl_tip = RichTextLabel.new()
	lbl_tip.bbcode_enabled = true
	lbl_tip.fit_content = true
	lbl_tip.custom_minimum_size = Vector2(280, 0)
	lbl_tip.add_theme_font_override("normal_font", f_txt)
	lbl_tip.add_theme_font_override("bold_font", f_tit)
	lbl_tip.add_theme_font_size_override("normal_font_size", 16)
	lbl_tip.add_theme_color_override("default_color", C_INCHIOSTRO)
	lbl_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_child(lbl_tip)
	_crea_aiuto()
	_crea_menu()

func _avviso(t: String) -> void:
	avviso.text = "  " + t + "  "
	avviso.visible = true
	avviso.reset_size()
	avviso.position.x = (hud.size.x - avviso.size.x) / 2
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func(): avviso.visible = false)

func _centra() -> void:
	if g == null:
		return
	var u := g.umano()
	if g.mappa.radure.has(u["dove"]):
		var p: Vector2 = g.mappa.radure[u["dove"]]["pos"]
		bersaglio_cam = Vector3(p.x, 0, p.y)
		_aggiorna_camera()

# ============================================================ menu
func _mostra_guida_classica() -> void:
	_apri_modale("Magic Realm Classico — guida")
	box_modale.add_child(_lab("Quattro incontri della seconda edizione: I — esplorazione e caccia al tesoro senza combattimenti; II — combattimento con i mostri; III — guerra tra personaggi, nativi e assoldamenti; IV — incantesimi ed incantamenti.", 17))
	box_modale.add_child(_lab("Ogni incontro dura 28 giorni, usa 20 tessere e assegna cinque punti tra grandi tesori, incantesimi (solo nel IV), fama, notorietà e oro. Alla fine si calcolano bonus e penalità: punteggio non negativo = requisiti raggiunti; il più alto è il vincitore assoluto.", 16))
	box_modale.add_child(_lab("Versione sperimentale: cavalli personali e combattimento montato presenti; restano da completare cavalli dei nativi, parte delle missioni e campagne classiche, comandi ai nativi e diversi incantesimi avanzati. Super Realm resta separato.", 15))
	_riga_bottoni().add_child(_bott("Chiudi", func(): modale.visible = false, 18, true))
	_ricentra()

func _crea_menu() -> void:
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(menu)
	var fondo := TextureRect.new()
	fondo.texture = T("res://assets/ui/copertina.webp")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.modulate = Color(0.55, 0.5, 0.45)
	menu.add_child(fondo)

func _mostra_menu() -> void:
	menu.visible = true
	hud.visible = false
	for c in menu.get_children():
		if c is TextureRect:
			continue
		c.queue_free()
	# Con quattro Encounter e scelta della dimora il menu supera l'altezza
	# disponibile su TV, notebook e dispositivi mobili: deve scorrere.
	var menu_scroll := ScrollContainer.new()
	menu_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	menu.add_child(menu_scroll)
	var cc := CenterContainer.new()
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.add_child(cc)
	var p := _pannello(Color(0.93, 0.86, 0.70, 0.97))
	p.custom_minimum_size = Vector2(1180, 0)
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var t := _lab("Magic Realm Classico" if scelte_menu["edizione"] == "classico" else "Super Magic Realm", 46, f_tit, C_ROSSO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var st := _lab("Magic Realm originale · 20 tessere · 28 giorni" if scelte_menu["edizione"] == "classico" else "Super Realm · esplorazione fantasy in versione digitale", 20, f_fell)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	# Selezione indipendente del regolamento, mantenendo Super come default.
	if edizione_portale == "":
		var edizione_bar := HBoxContainer.new()
		edizione_bar.add_theme_constant_override("separation", 10)
		v.add_child(edizione_bar)
		edizione_bar.add_child(_bott("Super Magic Realm", func(): _scegli_menu("edizione", "super"), 20, scelte_menu["edizione"] == "super"))
		edizione_bar.add_child(_bott("Magic Realm Classico (sperimentale)", func(): _scegli_menu("edizione", "classico"), 20, scelte_menu["edizione"] == "classico"))
	else:
		v.add_child(_bott("‹ Torna alla scelta dei giochi", _torna_portale, 17))
	# The six Super modes are progressive scenarios; free play uses full Scenario 6 rules.
	if scelte_menu["edizione"] == "super":
		v.add_child(_lab("Scegli come giocare", 24, f_tit))
		var modebar := HBoxContainer.new()
		modebar.add_theme_constant_override("separation", 12)
		v.add_child(modebar)
		modebar.add_child(_bott("Partita libera — tutte le regole", func(): _scegli_menu("partita_libera", true), 21, scelte_menu["partita_libera"]))
		modebar.add_child(_bott("Sei scenari progressivi", func(): _scegli_menu("partita_libera", false), 19, not scelte_menu["partita_libera"]))
	else:
		v.add_child(_lab("Modalità classica", 24, f_tit))
	var descr := {1: ["1 · Esplorare il Reame", "Muoviti e cerca: completa per primo le 4 spedizioni pubbliche."],
		2: ["2 · Duello tra personaggi", "Nasconditi, blocca e combatti: vince chi uccide 4 rivali o resta l'ultimo in piedi."],
		3: ["3 · I mostri si risvegliano", "Mostri, siti, Luoghi Perduti e missioni: il primo a 10 Punti Vittoria vince."],
		4: ["4 · Tesori e magia", "Saccheggia i siti, leggi le rune, incanta i segnalini e lancia incantesimi: il primo a 10 Punti Vittoria vince."],
		5: ["5 · I nativi si destano", "Nativi nelle abitazioni: commercia, ingaggia e attento a chi ti è ostile. Il primo a 10 Punti Vittoria vince."],
		6: ["6 · Arrivano i viaggiatori", "Il gioco completo: viaggiatori, visitatori e Punti Vittoria assegnati in segreto."]}
	if scelte_menu["edizione"] == "classico":
		var incontri := {1: "I · Caccia al tesoro", 2: "II · I mostri attaccano", 3: "III · Guerra e nativi", 4: "IV · Magia"}
		var he := GridContainer.new()
		he.columns = 2
		v.add_child(he)
		for n in [1, 2, 3, 4]:
			he.add_child(_bott(incontri[n], func(): _scegli_menu("incontro_classico", n), 18, int(scelte_menu["incontro_classico"]) == n))
		v.add_child(_lab("28 giorni · 5 punti vittoria", 17, f_tit, C_ROSSO))
	elif scelte_menu["partita_libera"]:
		v.add_child(_lab("Tutte le regole Super disponibili · 12 punti vittoria", 19, f_tit, C_ROSSO))
	else:
		var hs := GridContainer.new()
		hs.columns = 3
		hs.add_theme_constant_override("h_separation", 8)
		hs.add_theme_constant_override("v_separation", 6)
		v.add_child(hs)
		for n in SCENARI:
			var b := _bott(descr[n][0], func(): _scegli_menu("scenario", n), 18, scelte_menu["scenario"] == n)
			b.tooltip_text = descr[n][1]
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hs.add_child(b)
	var spiegazioni_classiche := {1: "Incontro I: esplora, nasconditi, cerca tesori e commercia. Mostri e nativi sono presenti ma non combattono.", 2: "Incontro II: i mostri diventano pericolosi e comincia il combattimento; i nativi non combattono.", 3: "Incontro III: si aggiungono la guerra tra personaggi, il combattimento con i nativi e gli ingaggi.", 4: "Incontro IV: si aggiungono incantesimi e incantamenti. Alcuni effetti avanzati restano in lavorazione."}
	v.add_child(_lab("Partita libera: scegli la durata e gioca il Super Realm completo, con mostri, magia, tesori, nativi e viaggiatori." if scelte_menu["edizione"] == "super" and scelte_menu["partita_libera"] else (descr[scelte_menu["scenario"]][1] if scelte_menu["edizione"] == "super" else spiegazioni_classiche[int(scelte_menu["incontro_classico"])]), 18))
	if scelte_menu["edizione"] == "super" and scelte_menu["partita_libera"]:
		var durata := HBoxContainer.new()
		v.add_child(durata)
		durata.add_child(_lab_riga("Durata:"))
		for giorni in [28, 56, 84]:
			durata.add_child(_bott("%d giorni" % giorni, func(): _scegli_menu("durata_libera", giorni), 18, int(scelte_menu["durata_libera"]) == giorni))
	# personaggio
	v.add_child(_lab("Personaggio", 24, f_tit))
	var grid := GridContainer.new()
	grid.columns = 12
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var validi := _personaggi_validi(6 if scelte_menu["edizione"] == "super" and scelte_menu["partita_libera"] else scelte_menu["scenario"])
	if not (scelte_menu["pg"] in validi):
		scelte_menu["pg"] = validi[0]
	for id in validi:
		var d: Dictionary = Dati.personaggi[id]
		var b := Button.new()
		b.custom_minimum_size = Vector2(90, 96)
		b.icon = T("res://assets/personaggi/%s_simbolo.webp" % d["pedina"])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.text = d["nome"]
		b.add_theme_font_override("font", f_tit)
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", C_INCHIOSTRO)
		b.add_theme_color_override("font_hover_color", C_ROSSO)
		var sel: bool = scelte_menu["pg"] == id
		b.add_theme_stylebox_override("normal", _stile(Color(0.98, 0.93, 0.80) if not sel else Color(0.95, 0.78, 0.45), C_ROSSO if sel else Color(0.6, 0.45, 0.25), 6, 3 if sel else 1))
		b.add_theme_stylebox_override("hover", _stile(Color(1, 0.96, 0.85), C_ORO, 6, 2))
		b.add_theme_stylebox_override("pressed", _stile(Color(0.95, 0.78, 0.45), C_ROSSO, 6, 3))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.tooltip_text = _descr_pg(d)
		b.pressed.connect(func(): _scegli_menu("pg", id))
		grid.add_child(b)
	var dsel: Dictionary = Dati.personaggi[scelte_menu["pg"]]
	v.add_child(_lab(_descr_pg(dsel), 16))
	if scelte_menu["edizione"] == "classico":
		v.add_child(_lab("Abitazione iniziale (come nel gioco originale)", 17, f_tit))
		var abitazioni := HBoxContainer.new()
		v.add_child(abitazioni)
		for nome in dsel["partenze"]:
			abitazioni.add_child(_bott(str(Dati.ABITAZIONI.get(nome, nome)), func(): _scegli_menu("partenza", nome), 15, scelte_menu["partenza"] == nome))
		if not (scelte_menu["partenza"] in dsel["partenze"]):
			scelte_menu["partenza"] = dsel["partenze"][0]
	# rivali
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 8)
	v.add_child(hr)
	hr.add_child(_lab_riga("Personaggi rivali (IA):"))
	var minimo := 1 if scelte_menu["scenario"] == 2 and scelte_menu["edizione"] == "super" and not scelte_menu["partita_libera"] else 0
	for n in range(minimo, 4):
		hr.add_child(_bott(str(n), func(): _scegli_menu("rivali", n), 18, scelte_menu["rivali"] == n))
	# avvio
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(hb)
	hb.add_child(_bott("Nuova partita", _nuova_partita, 22, true))
	var cont := _bott("Continua", _continua, 22)
	cont.disabled = not FileAccess.file_exists(_percorso_salvataggio(str(scelte_menu["edizione"])))
	hb.add_child(cont)
	var ed := LineEdit.new()
	ed.placeholder_text = "codice partita"
	ed.custom_minimum_size = Vector2(170, 0)
	ed.add_theme_font_override("font", f_txt)
	ed.add_theme_font_size_override("font_size", 18)
	hb.add_child(ed)
	hb.add_child(_bott("Carica online", func(): _carica_online(ed.text.strip_edges().to_upper()), 20))
	hb.add_child(_bott("Regole", func(): aiuto.visible = true, 20))
	var nota := _lab("Modalita classica sperimentale: obiettivi e punteggio originali; alcuni effetti e l’IA restano in verifica." if scelte_menu["edizione"] == "classico" else "Versione digitale per uso personale del modulo Super Magic Realm (espansione non ufficiale di Magic Realm, Avalon Hill).", 14, f_txt, Color(0.4, 0.3, 0.2))
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nota)

func _personaggi_validi(sc: int) -> Array:
	var r := []
	for id in Dati.ordine_pg:
		if scelte_menu["edizione"] == "classico":
			if ProfiliRegole.personaggio_classico(id):
				r.append(id)
			continue
		var d: Dictionary = Dati.personaggi[id]
		if sc == 1 and id in ["pescatore", "re_stregone", "stregone_bianco"]:
			continue
		if sc >= 2 and sc <= 3 and not d["combattente"]:
			continue
		if sc == 2 and (id == "barbaro" or id == "ragazza_boschi"):
			continue
		r.append(id)
	return r

func _descr_pg(d: Dictionary) -> String:
	var t := "%s — peso e vulnerabilità %s" % [d["nome"], Dati.NOMI_PESO[d["vuln"]]]
	for a in d["abilita"]:
		t += "\n%s: %s" % [a["nome"], a["testo"]]
	if not d["equip"].is_empty() and (scelte_menu["scenario"] >= 2 or scelte_menu["edizione"] == "classico"):
		t += "\nEquipaggiamento: " + ", ".join(d["equip"].map(func(x): return Dati.nome_arma(x)))
	return t

func _scegli_menu(k: String, v) -> void:
	scelte_menu[k] = v
	if k == "edizione":
		net.root_partite = "magicrealm/classico/partite" if v == "classico" else "magicrealm/partite"
		net.sessione = "user://online_magicrealm_classico.cfg" if v == "classico" else "user://online_magicrealm.cfg"
		net.id_token = ""
		net.refresh_token = ""
	if k == "scenario" and v == 2 and scelte_menu["edizione"] == "super" and not scelte_menu["partita_libera"] and scelte_menu["rivali"] < 1:
		scelte_menu["rivali"] = 1
	_mostra_menu()

func _nuova_partita() -> void:
	var libera: bool = scelte_menu["edizione"] == "super" and scelte_menu["partita_libera"]
	var sc: int = 6 if libera else scelte_menu["scenario"]
	var validi := _personaggi_validi(sc)
	validi.erase(scelte_menu["pg"])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var rivali := []
	for i in range(scelte_menu["rivali"]):
		var j := rng.randi_range(0, validi.size() - 1)
		rivali.append(validi[j])
		validi.remove_at(j)
	codice = _nuovo_codice(rng)
	if scelte_menu["edizione"] == "classico":
		_avvia(func(): return g.nuova_con_profilo(ProfiliRegole.classico_incontro(int(scelte_menu["incontro_classico"])), scelte_menu["pg"], rivali, rng.randi(), str(scelte_menu["partenza"])))
	else:
		_avvia(func():
			g.nuova(sc, scelte_menu["pg"], rivali, rng.randi())
			if libera:
				g.s["partita_libera"] = true
				g.s["giorni_max"] = int(scelte_menu["durata_libera"]))

func _nuovo_codice(rng: RandomNumberGenerator) -> String:
	var a := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var c := ""
	for i in range(6):
		c += a[rng.randi_range(0, a.length() - 1)]
	return c

func _avvia(prepara: Callable) -> void:
	if g != null:
		for conn in g.chiede.get_connections():
			g.chiede.disconnect(conn["callable"])
	g = Reame.new()
	g.pausa_cb = func(t): return get_tree().create_timer(t).timeout
	g.chiede.connect(_chiede)
	g.cambiato.connect(_aggiorna)
	g.messaggio.connect(_messaggio)
	prepara.call()
	if g.s.is_empty():
		_avviso("Impossibile creare la partita: verifica il generatore e riprova.")
		return
	menu.visible = false
	hud.visible = true
	registro.clear()
	for r in g.log_righe:
		_messaggio(r[0], r[1])
	_costruisci_mappa()
	distanza = 5.5
	_centra()
	_aggiorna()
	g.gioca()
	if not g.e_classico():
		_mostra_guida_scenario(false)

func _salvataggio_compatibile(d: Dictionary) -> bool:
	if not (d.get("s") is Dictionary):
		return false
	var famiglia: String = str(d["s"].get("profilo_regole", {}).get("famiglia", "super"))
	return famiglia == str(scelte_menu["edizione"])

func _continua() -> void:
	var f := FileAccess.open(_percorso_salvataggio(str(scelte_menu["edizione"])), FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary) or not _salvataggio_compatibile(d):
		_avviso("Salvataggio non leggibile o appartenente a un’altra edizione.")
		return
	codice = d.get("codice", "")
	_avvia(func(): g.importa(d))

func _carica_online(c: String) -> void:
	if c.length() != 6:
		_avviso("Il codice ha 6 caratteri.")
		return
	_avviso("Carico la partita %s..." % c)
	var d = await net.carica_partita(c)
	if not (d is Dictionary):
		_avviso("Partita %s non trovata (o rete non raggiungibile)." % c)
		return
	if not _salvataggio_compatibile(d):
		_avviso("Il codice appartiene a un’altra edizione di Magic Realm.")
		return
	codice = c
	_avvia(func(): g.importa(d))

func _salva_locale() -> void:
	if g == null or g.s.is_empty():
		return
	var d := g.esporta()
	d["codice"] = codice
	var f := FileAccess.open(_percorso_salvataggio(_edizione_attuale()), FileAccess.WRITE)
	f.store_string(JSON.stringify(d))

func _salva_online() -> void:
	if g == null or g.s.is_empty():
		return
	if g.s["fase"] != "alba":
		_avviso("Si salva all'alba, quando si registrano le attività.")
		return
	var d := g.esporta()
	d["codice"] = codice
	d["nome"] = "%s, giorno %d" % [g.umano()["nome"], g.s["giorno"]]
	d["turno"] = g.s["giorno"]
	d["aggiornata"] = int(Time.get_unix_time_from_system())
	_avviso("Salvo online la partita %s..." % codice)
	var ok = await net.salva_partita(codice, d)
	_avviso("Partita salvata online: codice %s." % codice if ok else "Salvataggio online non riuscito: %s" % net.ultimo_errore)

func _torna_menu() -> void:
	if g != null and g.s.get("fase", "") == "alba":
		_salva_locale()
	modale.visible = false
	_mostra_menu()

# ============================================================ aggiornamento
func _messaggio(t: String, tipo: String) -> void:
	var col := {"titolo": "#5a1a0a", "male": "#8a1c10", "bene": "#1f5a20", "mostri": "#6a2a7a", "segreto": "#1a4a7a", "round": "#7a5a2a", "turno": "#3a2a1a"}
	var c: String = col.get(tipo, "")
	var testo := t
	if tipo == "titolo" or tipo == "round":
		testo = "[b]%s[/b]" % t
	if c != "":
		testo = "[color=%s]%s[/color]" % [c, testo]
	registro.append_text(testo + "\n")

func _aggiorna() -> void:
	if g == null or g.s.is_empty():
		return
	var fasi_n := {"alba": "Alba: registra le attività", "giorno": "Giorno", "sera": "Sera: combattimenti", "mezzanotte": "Mezzanotte"}
	lbl_giorno.text = ("Classico · giorno %d/28" % g.s["giorno"]) if g.e_classico() else ("Giorno %d · %s" % [g.s["giorno"], g.settimana_mese()])
	var f: String = fasi_n.get(g.s["fase"], "")
	if g.s["scenario"] >= 3 and g.s["riga_mostri"] > 0:
		f += "   ·   mostri in agguato: riga %d" % g.s["riga_mostri"]
	if g.s.has("attivo"):
		f += "   ·   turno di " + g.P(g.s["attivo"])["nome"]
	lbl_fase.text = f
	lbl_codice.text = "Partita %s" % codice
	_aggiorna_scheda()
	_aggiorna_pezzi()
	_aggiorna_evidenze()
	if g.s["fine"] != "":
		_fine()
	elif g.combat.attivo() and modale.visible and g.richiesta.is_empty():
		_mostra_combattimento_attesa()

func _chit_ui(c: Dictionary, sel := false) -> PanelContainer:
	var col := C_MOVE if c["tipo"] in ["M", "D"] else (C_FIGHT if c["tipo"] in ["F", "B", "R"] else C_MAGIA)
	var st: String = c.get("stato", "a")
	if c.get("colore", false):
		col = {"I": Color(0.93, 0.92, 0.86), "II": Color(0.55, 0.55, 0.55), "III": Color(0.85, 0.66, 0.12), "IV": Color(0.45, 0.2, 0.6), "V": Color(0.12, 0.1, 0.1)}.get(c.get("magia", ""), col)
	if st == "f":
		col = col.darkened(0.45)
	elif st == "w":
		col = Color(0.32, 0.08, 0.06)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _stile(col, C_ORO if sel else Color(0.1, 0.05, 0.02), 4, 3 if sel else 1))
	p.custom_minimum_size = Vector2(74, 62)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	p.add_child(v)
	var nomi := {"M": "MOVIMENTO", "F": "COMBATTE", "G": "MAGIA", "B": "BERSERK", "R": "RIFLESSI", "D": "ABBASSARSI"}
	var tit: String = nomi.get(c["tipo"], "")
	if c.get("colore", false):
		tit = "COLORE"
	elif c.has("tes"):
		tit = "TESORO"
	var chiaro: bool = c.get("colore", false) and c.get("magia", "") == "I"
	var l1 := _lab(tit, 9, f_tit, Color(0.2, 0.1, 0.05) if chiaro else Color(1, 0.95, 0.85))
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(l1)
	var val := "%s%d" % [c.get("forza", c.get("magia", "")), c["vel"]]
	var l2 := _lab(val, 22, f_tit, Color(0.2, 0.1, 0.05) if chiaro else Color(1, 1, 1))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(l2)
	var l3 := _lab("*".repeat(c["sforzi"]) if st != "w" else "ferito", 14 if st != "w" else 11, f_tit, Color(1, 0.95, 0.85))
	if st == "f":
		l3.text = "affaticato"
		l3.add_theme_font_size_override("font_size", 10)
	elif st == "s":
		l3.text = "legato"
		l3.add_theme_font_size_override("font_size", 10)
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l3.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(l3)
	return p

func _aggiorna_scheda() -> void:
	for c in scheda.get_children():
		c.queue_free()
	var u := g.umano()
	if u.is_empty():
		return
	var d: Dictionary = Dati.personaggi[u["pg"]]
	var hb := HBoxContainer.new()
	scheda.add_child(hb)
	var im := TextureRect.new()
	im.texture = T("res://assets/personaggi/%s_simbolo.webp" % d["pedina"])
	im.custom_minimum_size = Vector2(84, 84)
	im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	hb.add_child(im)
	var vv := VBoxContainer.new()
	vv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vv)
	vv.add_child(_lab(d["nome"] + (" (mort%s)" % ("a" if d["genere"] == "f" else "o") if u["morto"] else ""), 26, f_tit, C_ROSSO))
	var stato_n := "allo scoperto"
	if u["nascosto"]:
		stato_n = "nascosta" if d["genere"] == "f" else "nascosto"
	vv.add_child(_lab("Peso %s · %s" % [Dati.NOMI_PESO[d["vuln"]], stato_n], 15))
	vv.add_child(_lab(g.nome_r(u["dove"]) if g.mappa.radure.has(u["dove"]) else "", 15, f_txt, C_VERDE))
	var punti := "Fama %d · Notorietà %d" % [u["fama"], u["noto"]]
	if g.s["scenario"] >= 5:
		punti += " · Oro %d" % u["oro"]
	if g.e_classico():
		punti += " · Classico: %d PV · giorno %d/28" % [g.pv(u), int(g.s["giorno"])]
	elif g.s["scenario"] >= 6:
		punti += " · punteggio %d" % g.viaggi.punteggio(u)
	elif g.s["scenario"] >= 3:
		punti += " · PV %d/%d" % [g.pv(u), g.obiettivo_pv()]
	elif g.s["scenario"] == 2:
		punti += " · uccisioni %d/4" % u["uccisi_pg"]
	scheda.add_child(_lab(punti, 17, f_tit))
	# Cavalli esclusivi del Classico: uno cavalcato, altri come animali da soma.
	if g.e_classico() and g.usa_regola("cavalli") and not u.get("cavalli", []).is_empty():
		scheda.add_child(_lab("Cavalli · uno attivo, gli altri da soma", 18, f_tit))
		var scuderia := HFlowContainer.new()
		scheda.add_child(scuderia)
		for cavallo in u["cavalli"]:
			var definizione: Dictionary = CavalliClassici.definizione(cavallo["id"])
			var cavalcato: bool = cavallo.get("attivo", false)
			scuderia.add_child(_bott(("%s: %s" % [definizione["nome"], "cavalcato" if cavalcato else "da soma"]),
				func(): _attiva_cavallo(cavallo["id"]), 14, cavalcato))
	# segnalini d'azione
	scheda.add_child(_lab("Segnalini d'azione", 18, f_tit))
	var gr := GridContainer.new()
	gr.columns = 4
	gr.add_theme_constant_override("h_separation", 3)
	gr.add_theme_constant_override("v_separation", 4)
	scheda.add_child(gr)
	for c in u["chits"]:
		var ch := _chit_ui(c)
		ch.tooltip_text = g.descr_chit(c) + {"a": "", "f": " (affaticato)", "w": " (ferito)", "s": " (legato a un incantesimo)"}.get(c["stato"], "")
		if c.get("colore", false):
			ch.tooltip_text += " · segnalino di colore " + Arcano.NOMI_COLORE.get(Arcano.TIPO_COLORE.get(c["magia"], ""), "")
		gr.add_child(ch)
	# oggetti
	if not u["oggetti"].is_empty():
		scheda.add_child(_lab("Equipaggiamento", 18, f_tit))
		var go := GridContainer.new()
		go.columns = 4
		scheda.add_child(go)
		for o in u["oggetti"]:
			var b := Button.new()
			var lato := "a"
			if (o.get("allerta", false) and Dati.oggetti["armi"].has(o["id"])) or (o.get("danno", 0) > 0):
				lato = "b"
			if Arcano.e_tesoro(o["id"]):
				b.icon = T("res://assets/" + Arcano.tesoro(o["id"])["img"])
				b.custom_minimum_size = Vector2(70, 95)
				b.expand_icon = true
				b.modulate = Color(1, 1, 1) if o["attivo"] else Color(0.6, 0.6, 0.6)
				b.tooltip_text = "%s%s\n%s\n(clic: vedi la carta)" % [Dati.nome_arma(o["id"]), "" if o["attivo"] else " · inattivo", Arcano.descrivi_tesoro(o["id"])]
				b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
				b.pressed.connect(func(): _carta_tesoro(o["id"]))
				go.add_child(b)
				continue
			b.icon = T("res://assets/oggetti/%s_%s.webp" % [o["id"], lato])
			b.expand_icon = true
			b.custom_minimum_size = Vector2(70, 70)
			b.modulate = Color(1, 1, 1) if o["attivo"] else Color(0.6, 0.6, 0.6)
			var stato := ""
			if Dati.oggetti["armi"].has(o["id"]):
				stato = " · in allerta" if o["allerta"] else " · a riposo"
			elif o.get("danno", 0) > 0:
				stato = " · danneggiato"
			b.tooltip_text = "%s%s%s\n(clic: attiva o disattiva all'alba)" % [Dati.nome_arma(o["id"]), stato, "" if o["attivo"] else " · inattivo"]
			b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			b.pressed.connect(func(): _attiva_oggetto(o["id"]))
			go.add_child(b)
	# missioni
	var miss: Array = g.s["missioni_pubbliche"] + u["missioni"]
	if not miss.is_empty():
		scheda.add_child(_lab("Missioni", 18, f_tit))
		for q in miss:
			var m: Dictionary = Dati.missioni[q]
			var fatta: bool = q in u["fatte"]
			var priv: bool = q in u["missioni"]
			var testo := "%s%s%s" % ["[fatta] " if fatta else "", m["nome"], " (privata)" if priv else ""]
			if m["pv"] > 0:
				testo += " · %d PV" % m["pv"]
			var l := _lab(testo, 16, f_tit, C_VERDE if fatta else C_INCHIOSTRO)
			l.tooltip_text = m["testo"]
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			scheda.add_child(l)
			scheda.add_child(_lab(m["testo"], 13, f_txt, Color(0.35, 0.25, 0.15)))
	if not u.get("incantesimi", []).is_empty():
		scheda.add_child(_lab("Incantesimi", 18, f_tit))
		var hi := HFlowContainer.new()
		hi.add_theme_constant_override("h_separation", 4)
		hi.add_theme_constant_override("v_separation", 4)
		scheda.add_child(hi)
		for id in u["incantesimi"]:
			var x := Arcano.inc(id)
			var bi := _bott("%s (%s)" % [x["nome"], x["tipo"]], func(): _carta_inc(id), 13)
			bi.tooltip_text = Arcano.descrivi_inc(id)
			if x["eff"] == "" or not g.arcano.lanciabile_in_teoria(u, id):
				bi.modulate = Color(0.7, 0.7, 0.7)
			hi.add_child(bi)
	if g.s["scenario"] >= 4 and g.mappa.radure.has(u["dove"]):
		var cols: Array = g.arcano.colori_radura(u["dove"])
		var tx := "Magia nella radura: " + (", ".join(cols.map(func(c): return Arcano.NOMI_COLORE[c])) if not cols.is_empty() else "nessun colore")
		if g.s["tessere"][str(g.tessera(u["dove"]))].get("incantata", false):
			tx += " (tessera incantata)"
		scheda.add_child(_lab(tx, 14, f_txt, C_VERDE))
	if (g.e_classico() or g.s["scenario"] >= 6) and u.has("vp"):
		scheda.add_child(_lab("Traguardi dei Punti Vittoria", 18, f_tit))
		if g.e_classico():
			var risultato: Dictionary = g.punteggio_classico(u)
			for cat in PunteggioClassico.CATEGORIE:
				var val: Dictionary = risultato.get("categorie", {}).get(cat, {})
				scheda.add_child(_lab("%s: %d / %d · punti %d" % [Viaggi.NOMI_CAT[cat], val.get("valore", 0), val.get("richiesti", 0), val.get("totale", 0)], 15, f_txt))

		for x in ([] if g.e_classico() else g.viaggi.requisiti(u)):
			if x["serve"] > 0 or x["ha"] > 0:
				scheda.add_child(_lab("%s: %d su %d%s" % [x["nome"], x["ha"], x["serve"], "" if x["ok"] else " (manca)"], 15, f_txt, C_VERDE if x["ok"] else C_ROSSO))
		var con := []
		if str(u.get("nomade", "")) != "":
			con.append("nomade " + Viaggi.v(u["nomade"])["nome"])
		for m in u.get("missioni_v", []):
			con.append("missione %s verso %s" % [Viaggi.v(m["id"])["nome"], g.nome_r(m["dest"])])
		if not u.get("compito", {}).is_empty():
			con.append("compito %s (%d/4)%s" % [Viaggi.v(u["compito"]["id"])["nome"], u["compito"]["visti"].size(), " completato" if u["compito"].get("fatto", false) else ""])
		if not con.is_empty():
			scheda.add_child(_lab("Con te: " + ", ".join(con), 14, f_txt, C_VERDE))
	if g.s["scenario"] >= 5:
		var rr := {2: [], 1: [], -1: [], -2: []}
		for gid in Dati.nativi["gruppi"]:
			if g.e_classico() and not (gid in Nativi.GRUPPI_CLASSICI):
				continue
			var v := g.nativi.rapporto(u, gid)
			if rr.has(v):
				rr[v].append(Dati.nativi["gruppi"][gid]["nome"])
		var tx := []
		for v in [2, 1, -1, -2]:
			if not rr[v].is_empty():
				tx.append("%s: %s" % [Nativi.NOMI_REL[v], ", ".join(rr[v])])
		scheda.add_child(_lab("Rapporti con i nativi", 18, f_tit))
		scheda.add_child(_lab("; ".join(tx) + ". Gli altri sono neutrali.", 14))
		var ing := []
		for gid in g.s["nativi"]:
			if g.s["nativi"][gid]["ingaggio"] == u["pid"]:
				ing.append("%s (fino al giorno %d)" % [Dati.nativi["gruppi"][gid]["nome"], int(g.s["nativi"][gid]["scadenza"])])
		if not ing.is_empty():
			scheda.add_child(_lab("Al tuo servizio: " + ", ".join(ing), 15, f_txt, C_VERDE))
	if not u["maledizioni"].is_empty():
		scheda.add_child(_lab("Maledizioni: " + ", ".join(u["maledizioni"]), 16, f_txt, C_ROSSO))
	if not u["siti"].is_empty():
		scheda.add_child(_lab("Siti scoperti: " + ", ".join(u["siti"].map(func(x): return Dati.segnalini[x]["nome"])), 15))
	# rivali
	var altri: Array = g.s["pg"].filter(func(p): return not p["umano"])
	if not altri.is_empty():
		scheda.add_child(_lab("Rivali", 18, f_tit))
		for p in altri:
			var testo := "%s%s · fama %d, notorietà %d" % [p["nome"], " (mort%s)" % ("a" if Dati.personaggi[p["pg"]]["genere"] == "f" else "o") if p["morto"] else "", p["fama"], p["noto"]]
			if g.s["scenario"] >= 3:
				testo += " · PV %d" % g.pv(p)
			elif g.s["scenario"] == 1:
				testo += " · spedizioni %d/4" % p["fatte"].size()
			scheda.add_child(_lab(testo, 15))

func _carta_tesoro(id: String) -> void:
	if g.richiesta.get("tipo", "") == "" or modale.visible:
		pass
	var d := Arcano.tesoro(id)
	var u := g.umano()
	_apri_modale(d["nome"])
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	box_modale.add_child(h)
	var im := TextureRect.new()
	im.texture = T("res://assets/" + d["img"])
	im.custom_minimum_size = Vector2(220, 300)
	im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	h.add_child(im)
	var t := _lab(Arcano.descrivi_tesoro(id), 16)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var hb := _riga_bottoni()
	var mono := str(d.get("eff", {}).get("monouso", ""))
	if mono in ["amuleto", "ripara"]:
		hb.add_child(_bott("Usa ora", func():
			if not g.arcano.usa(u, id): _avviso("Non c'è nulla su cui usarlo.")
			modale.visible = false
			_aggiorna_scheda(), 17, true))
	if g.richiesta.get("tipo", "") == "piano":
		hb.add_child(_bott("Attiva o disattiva", func():
			modale.visible = false
			_attiva_oggetto(id), 17))
	hb.add_child(_bott("Chiudi", func():
		modale.visible = false
		if not g.richiesta.is_empty() and g.richiesta["tipo"] != "piano": _chiede(g.richiesta), 17))
	_ricentra()

func _carta_inc(id: String) -> void:
	var d := Arcano.inc(id)
	_apri_modale(d["nome"])
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	box_modale.add_child(h)
	if d["img"] != "":
		var im := TextureRect.new()
		im.texture = T("res://assets/" + d["img"])
		im.custom_minimum_size = Vector2(220, 300)
		im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		h.add_child(im)
	var t := _lab(Arcano.descrivi_inc(id), 16)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var hb := _riga_bottoni()
	hb.add_child(_bott("Chiudi", func():
		modale.visible = false
		if not g.richiesta.is_empty() and g.richiesta["tipo"] != "piano": _chiede(g.richiesta), 17))
	_ricentra()

func _attiva_cavallo(id: String) -> void:
	if not g.e_classico() or not g.usa_regola("cavalli"):
		return
	if g.richiesta.get("tipo", "") != "piano":
		_avviso("Puoi cambiare cavallo prima di confermare il piano del giorno.")
		return
	var u: Dictionary = g.umano()
	if not CavalliClassici.attiva(u, id, g.carico_max(u), g.vulnerabilita(u), g.tipo_radura(u["dove"]) == "C"):
		_avviso("Non puoi cavalcare questo animale: grotta o carico troppo pesante.")
		return
	fasi = g.fasi_disponibili(u)
	piano = []
	_aggiorna_scheda()
	_pannello_piano()

func _attiva_oggetto(id: String) -> void:
	if g.richiesta.get("tipo", "") != "piano":
		_avviso("Gli oggetti si attivano all'alba (o come azione in combattimento).")
		return
	g.combat.C = {"uso": {}}
	var u := g.umano()
	g.combat._attiva(u, id)
	g.combat.C = {}
	if g.s["scenario"] >= 4:
		g.arcano.sincronizza(u)
	_aggiorna_scheda()

# ============================================================ richieste del motore
func _chiede(req: Dictionary) -> void:
	modale.visible = false
	var chiave_sugg: String = {"piano": "piano", "tabella": "tabella", "adesca": "combattimento", "azione": "combattimento", "mischia": "combattimento",
		"incanto": "incanto", "commercio": "commercio", "incantesimo_sera": "sera"}.get(req["tipo"], "")
	if req["tipo"] == "tabella" and not req["dati"].get("fonti", {}).get("saccheggia", []).is_empty():
		chiave_sugg = "saccheggio" if guida_visti.has("tabella") else "tabella"
	if chiave_sugg != "":
		_suggerimento(chiave_sugg)
	match req["tipo"]:
		"piano":
			_salva_locale()
			piano = []
			fasi = req["dati"]["fasi"]
			modo_mossa = true
			_pannello_piano()
			_aggiorna_evidenze()
		"tabella": _richiesta_tabella(req)
		"scelta": _richiesta_scelta(req)
		"riposo": _richiesta_riposo(req)
		"blocca": _richiesta_si_no("Bloccare %s? Vi affronterete stasera." % g.P(req["dati"]["bersaglio"])["nome"])
		"anticipa": _richiesta_si_no("Astuto: vuoi giocare ora il tuo turno? (Restano %d personaggi da estrarre)" % req["dati"]["restanti"])
		"combatti_pg": _richiesta_si_no("Vuoi combattere contro %s stasera?" % ", ".join(req["dati"]["altri"].map(func(x): return g.P(x)["nome"])))
		"adesca", "carica", "azione", "bersaglio", "mischia", "fatica", "ferita":
			_richiesta_combattimento(req)
		"incanto": _richiesta_incanto(req)
		"commercio": _richiesta_commercio(req)
		"viaggiatore": _richiesta_si_no(req["dati"]["testo"])
		"assegna_pv": _richiesta_pv(req)
		"ingaggio": _richiesta_ingaggio(req)
		"conferma":
			if req["dati"].get("puo", true):
				_richiesta_si_no(req["dati"]["testo"])
			else:
				_apri_modale("Commercio")
				box_modale.add_child(_lab(req["dati"]["testo"], 18))
				_riga_bottoni().add_child(_bott("Va bene", func(): _rispondi(false), 18, true))
				_ricentra()
		"incantesimo_sera": _richiesta_sera(req)
		_:
			g.rispondi(null)

func _rispondi(x) -> void:
	modale.visible = false
	modo_mossa = false
	for c in box_azioni.get_children():
		c.queue_free()
	azioni.visible = false
	_aggiorna_evidenze()
	g.rispondi(x)

func _svuota_azioni() -> void:
	for c in box_azioni.get_children():
		c.queue_free()

func _fasi_totali() -> int:
	return int(fasi["base"]) + int(fasi["luce"]) + fasi["extra"].size()

func _pannello_piano() -> void:
	_svuota_azioni()
	azioni.visible = true
	var u := g.umano()
	var tot := _fasi_totali()
	var testo := "Alba del giorno %d: registra le attività di %s (%d fasi" % [g.s["giorno"], u["nome"], tot]
	if not fasi["extra"].is_empty():
		var nomi := {"M": "movimento", "R": "riposo", "H": "nascondersi", "S": "ricerca", "A": "allerta", "*": "qualsiasi", "E": "incanto", "T": "commercio", "HR": "ingaggio", "V": "volo", "MP": "pony (movimento)", "MC": "cavallo da lavoro (movimento)"}
		testo += ", di cui extra: " + ", ".join(fasi["extra"].map(func(x): return nomi[x]))
	testo += ")."
	if fasi["grotta"]:
		testo += " Sei in una grotta: niente fasi di luce."
	if g.s["scenario"] >= 2:
		testo += " All'inizio del turno ti riveli: nasconditi per primo se vuoi passare accanto ai mostri, e per ultimo per non farti bloccare."
	box_azioni.add_child(_lab(testo, 17, f_tit))
	var hp := HFlowContainer.new()
	hp.add_theme_constant_override("h_separation", 4)
	box_azioni.add_child(hp)
	var prec: String = u["dove"]
	for i in range(tot):
		var t := "%d. " % (i + 1)
		if i < piano.size():
			var a: Dictionary = piano[i]
			if a["a"] == "M":
				t += "Muovi a %s" % g.mappa.sigla_radura(a["dest"])
			elif a["a"] == "V":
				t += "Vola a %s" % Dati.tessere[g.tessera(a["dest"])]["nome"]
			else:
				t += Reame.ATTIVITA[a["a"]]
		else:
			t += "—"
		var l := _lab(t, 16, f_txt, C_INCHIOSTRO if i < piano.size() else Color(0.55, 0.45, 0.35))
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.add_theme_stylebox_override("normal", _stile(Color(1, 0.97, 0.88) if i < piano.size() else Color(0.88, 0.8, 0.65), Color(0.6, 0.45, 0.25), 4, 1))
		hp.add_child(l)
	var hb := HFlowContainer.new()
	hb.add_theme_constant_override("h_separation", 6)
	hb.add_theme_constant_override("v_separation", 6)
	box_azioni.add_child(hb)
	var pieno := piano.size() >= tot
	var att := ["S", "H", "R"] if g.e_classico() or g.s["scenario"] >= 2 else ["S"]
	if (not g.e_classico() and g.s["scenario"] >= 2) or g.usa_regola("combattimento_mostri"):
		att.append("A")
	if g.usa_regola("commercio"):
		att.append("T")
	if g.usa_regola("ingaggio"):
		att.append("HR")
	if g.usa_regola("magia"):
		var magico: bool = "E" in fasi["extra"]
		for c in u["chits"]:
			if c["tipo"] == "G" and Arcano.TIPO_COLORE.has(c["magia"]):
				magico = true
		if magico:
			att.append("E")
	for a in att:
		var b := _bott(Reame.ATTIVITA[a], func(): _aggiungi(a), 17)
		b.disabled = pieno
		hb.add_child(b)
	if g.usa_regola("magia") and g.arcano.puo_volare(u):
		var bv := _bott("Vola" if not modo_volo else "Vola: clic su una radura di una tessera vicina", func():
			modo_volo = not modo_volo
			_pannello_piano(), 17)
		bv.disabled = pieno
		hb.add_child(bv)
	var lm := _lab("Muovi: tocca una radura con l'anello giallo", 15, f_txt, C_VERDE)
	lm.autowrap_mode = TextServer.AUTOWRAP_OFF
	hb.add_child(lm)
	var hb2 := HBoxContainer.new()
	hb2.add_theme_constant_override("separation", 8)
	box_azioni.add_child(hb2)
	hb2.add_child(_bott("Togli l'ultima", func():
		if not piano.is_empty():
			var ult: Dictionary = piano.pop_back()
			if ult["a"] == "M":
				while not piano.is_empty() and piano[piano.size() - 1]["a"] == "M" and piano[piano.size() - 1]["dest"] == ult["dest"]:
					piano.pop_back()
		_pannello_piano()
		_aggiorna_evidenze(), 16))
	hb2.add_child(_bott("Svuota", func():
		piano = []
		_pannello_piano()
		_aggiorna_evidenze(), 16))
	var conf := _bott("Conferma il giorno", func(): _rispondi(piano.duplicate(true)), 18, true)
	hb2.add_child(conf)
	if g.e_classico() and g.usa_regola("combattimento_pg"):
		for guida in g.vivi():
			if guida == u or guida["dove"] != u["dove"]:
				continue
			hb2.add_child(_bott("Segui %s (tutto il giorno)" % guida["nome"],
				func(): _rispondi([{"a": "F", "guida": guida["pid"]}]), 15))

func _aggiungi(a: String) -> void:
	if piano.size() >= _fasi_totali():
		return
	piano.append({"a": a})
	_pannello_piano()

func _apri_modale(titolo: String) -> void:
	for c in box_modale.get_children():
		c.queue_free()
	box_modale.add_child(_lab(titolo, 26, f_tit, C_ROSSO))
	modale.visible = true

func _lab_riga(t: String) -> Label:
	var l := _lab(t, 17, f_tit)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l

func _riga_bottoni() -> HFlowContainer:
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 8)
	h.add_theme_constant_override("v_separation", 8)
	box_modale.add_child(h)
	return h

func _richiesta_si_no(domanda: String) -> void:
	_apri_modale("Decisione")
	box_modale.add_child(_lab(domanda, 20))
	var h := _riga_bottoni()
	h.add_child(_bott("Sì", func(): _rispondi(true), 20, true))
	h.add_child(_bott("No", func(): _rispondi(false), 20))
	_ricentra()

func _ricentra() -> void:
	await get_tree().process_frame
	var sm: ScrollContainer = modale.get_node("Scorri")
	var alto: float = min(box_modale.get_combined_minimum_size().y + 4, hud.size.y - 110)
	sm.custom_minimum_size = Vector2(760, alto)
	modale.reset_size()
	modale.position = (hud.size - modale.size) / 2

func _richiesta_tabella(req: Dictionary) -> void:
	var u := g.umano()
	_apri_modale("Ricerca a %s" % g.nome_r(u["dove"]))
	var t := g.tessera(u["dove"])
	if u["indizi"].has(str(t)):
		box_modale.add_child(_lab("Oggi hai già trovato indizi in questa tessera: «Scopri indizi» sulla tabella Localizza vale come «Scopri segnalini».", 16, f_txt, C_VERDE))
	var radure: Array = req["dati"]["radure"]
	var dove := [u["dove"]]
	for nome in ["cerca", "scruta", "localizza"]:
		var v := HBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		box_modale.add_child(v)
		var b := _bott(Reame.NOMI_TABELLE[nome], func(): _rispondi({"tabella": nome, "radura": dove[0]}), 20, nome == "scruta")
		b.custom_minimum_size = Vector2(150, 0)
		v.add_child(b)
		var righe := []
		for i in range(6):
			righe.append("%d %s" % [i + 1, Reame.RISULTATI[Reame.TABELLE[nome][i]]])
		var lr := _lab(" · ".join(righe), 15)
		lr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(lr)
	var fo: Dictionary = req["dati"].get("fonti", {})
	if not fo.get("saccheggia", []).is_empty():
		box_modale.add_child(_lab("Saccheggio (1-6: prendi la carta corrispondente dalla cima della pila; se non c'è, nulla):", 16, f_tit))
		var hs := _riga_bottoni()
		for x in fo["saccheggia"]:
			hs.add_child(_bott("Saccheggia: " + x["nome"], func(): _rispondi({"tabella": "saccheggia", "fonte": x["id"]}), 17, true))
	if not fo.get("rune", []).is_empty():
		box_modale.add_child(_lab("Lettura delle rune (1-3 impari l'incantesimo, 4 lo risvegli, 5 maledizione, 6 niente):", 16, f_tit))
		var hr := _riga_bottoni()
		for x in fo["rune"]:
			hr.add_child(_bott("Rune: " + x["nome"], func(): _rispondi({"tabella": "rune", "fonte": x["id"]}), 17))
	if radure.size() > 1:
		box_modale.add_child(_lab("Sei su una montagna: con Scruta puoi guardare un'altra radura di questa tessera o di quelle vicine (non le grotte).", 15))
		var opt := OptionButton.new()
		opt.add_theme_font_override("font", f_txt)
		for k in radure:
			opt.add_item(g.nome_r(k))
		opt.item_selected.connect(func(i): dove[0] = radure[i])
		box_modale.add_child(opt)
	box_modale.add_child(_lab("Si tirano due dadi e si tiene il più alto. «Scopri segnalini» scopre i siti della radura e completa le spedizioni.", 14, f_txt, Color(0.4, 0.3, 0.2)))
	_ricentra()

func _richiesta_incanto(req: Dictionary) -> void:
	_apri_modale("Incanto")
	box_modale.add_child(_lab("Un segnalino Magia incantato diventa un segnalino di colore, che fornisce la magia di quel colore per lanciare gli incantesimi. Incantare la tessera la rende una fonte di magia per tutti.", 15))
	var h := _riga_bottoni()
	var opz: Array = req["dati"]["opzioni"]
	for i in range(opz.size()):
		h.add_child(_bott(opz[i]["testo"], func(): _rispondi(i), 16, i == 0))
	_ricentra()

func _richiesta_commercio(req: Dictionary) -> void:
	var d: Dictionary = req["dati"]
	_apri_modale("Commercio")
	box_modale.add_child(_lab("Hai %d oro. Per comprare tiri sulla Tabella degli incontri nella colonna del tuo rapporto con il gruppo: il risultato moltiplica il prezzo. Vendere non richiede tiri." % d["oro"], 15))
	for gx in d["gruppi"]:
		box_modale.add_child(_lab("%s (rapporto: %s)" % [gx["nome"], gx["rapporto"]], 19, f_tit, C_ROSSO))
		var h := _riga_bottoni()
		var merce: Array = gx["merce"]
		if gx.has("servizio"):
			h.add_child(_bott(gx["servizio"], func(): _rispondi({"gruppo": gx["gruppo"], "tipo": "servizio"}), 15, true))
			continue
		if merce.is_empty():
			h.add_child(_lab_riga("Non hanno nulla da vendere."))
		for i in range(merce.size()):
			var x: Dictionary = merce[i]
			var b := _bott("Compra %s (valore %d)" % [x["nome"], x["oro"]], func(): _rispondi({"gruppo": gx["gruppo"], "tipo": "compra", "merce": i}), 15)
			if x["k"] == "t":
				b.tooltip_text = Arcano.descrivi_tesoro(x["id"])
			elif x["k"] == "s":
				b.tooltip_text = Arcano.descrivi_inc(x["id"])
			h.add_child(b)
		if not d["vendibili"].is_empty():
			var sel := []
			var hv := _riga_bottoni()
			for v in d["vendibili"]:
				var cb := CheckBox.new()
				cb.text = "%s (%d)" % [v["nome"], v["oro"]]
				cb.add_theme_font_override("font", f_txt)
				cb.add_theme_color_override("font_color", C_INCHIOSTRO)
				cb.toggled.connect(func(on): (sel.append(v["id"]) if on else sel.erase(v["id"])))
				hv.add_child(cb)
			_riga_bottoni().add_child(_bott("Vendi a %s gli oggetti scelti" % gx["nome"], func():
				if sel.is_empty(): _avviso("Scegli prima cosa vendere.")
				else: _rispondi({"gruppo": gx["gruppo"], "tipo": "vendi", "oggetti": sel}), 16))
	_riga_bottoni().add_child(_bott("Nessun affare", func(): _rispondi({}), 17, true))
	_ricentra()

func _richiesta_pv(req: Dictionary) -> void:
	var vp: Dictionary = req["dati"]["vp"]
	var tot_pv := 5 if g.e_classico() else 12
	_apri_modale("Assegna i tuoi %d Punti Vittoria" % tot_pv)
	box_modale.add_child(_lab("Classico: assegna cinque punti tra tesori, magia, fama, notorietà e oro. I risultati sono calcolati dopo 28 giorni con penalità per gli obiettivi mancati." if g.e_classico() else "Ogni punto è un traguardo da raggiungere: 1 grande tesoro, 2 incantesimi imparati, 10 Fama, 20 Notorietà o 30 Oro. Ogni sito o luogo scoperto e ogni missione o compito completato toglie punti. A fine mese vince chi ha soddisfatto tutti i traguardi con il margine più ampio.", 15))
	var tot_l := _lab("", 18, f_tit, C_ROSSO)
	var righe := {}
	var aggiorna := func():
		var t := 0
		for c in Viaggi.CATEGORIE:
			t += int(vp[c])
			righe[c].text = "%s: %d (%d)" % [Viaggi.NOMI_CAT[c], int(vp[c]), int(vp[c]) * Viaggi.UNITA[c]]
		tot_l.text = "Totale: %d su %d" % [t, tot_pv]
	for c in Viaggi.CATEGORIE:
		var h := _riga_bottoni()
		var l := _lab_riga("")
		l.custom_minimum_size = Vector2(300, 0)
		righe[c] = l
		h.add_child(l)
		h.add_child(_bott("meno", func():
			vp[c] = max(0, int(vp[c]) - 1)
			aggiorna.call(), 15))
		var aumenta := _bott("più", func():
			vp[c] = int(vp[c]) + 1
			aggiorna.call(), 15)
		if g.e_classico() and c == "inc" and (not g.usa_regola("magia") or int(Dati.personaggi[g.umano()["pg"]].get("magia", 0)) == 0):
			aumenta.disabled = true
		h.add_child(aumenta)
	box_modale.add_child(tot_l)
	aggiorna.call()
	_riga_bottoni().add_child(_bott("Conferma", func():
		var t := 0
		for c in Viaggi.CATEGORIE: t += int(vp[c])
		if t != tot_pv: _avviso("Devi assegnare esattamente %d punti." % tot_pv)
		elif g.e_classico() and not PunteggioClassico.valida_assegnazione(vp, g.usa_regola("magia") and int(Dati.personaggi[g.umano()["pg"]].get("magia", 0)) > 0):
			_avviso("Assegnazione non valida: il personaggio non puo ricevere punti magia.")
		else: _rispondi(vp), 18, true))
	_ricentra()

func _richiesta_ingaggio(req: Dictionary) -> void:
	var d: Dictionary = req["dati"]
	_apri_modale("Ingaggio")
	box_modale.add_child(_lab("Hai %d oro. Il costo base è la somma delle paghe del gruppo; la Tabella degli incontri lo moltiplica. Gli ingaggiati ti seguono e combattono con te per 14 giorni." % d["oro"], 15))
	var h := _riga_bottoni()
	for gx in d["gruppi"]:
		h.add_child(_bott("%s: %d membri, paga %d (rapporto %s)" % [gx["nome"], gx["membri"], gx["oro"], gx["rapporto"]], func(): _rispondi({"gruppo": gx["gruppo"]}), 16))
	h.add_child(_bott("Nessuno", func(): _rispondi({}), 17, true))
	_ricentra()

func _richiesta_sera(req: Dictionary) -> void:
	_apri_modale("Sera: incantesimi")
	box_modale.add_child(_lab("Puoi lanciare un incantesimo su te stess%s. Il segnalino Magia resta legato finché l'incantesimo dura." % ("a" if Dati.personaggi[g.umano()["pg"]]["genere"] == "f" else "o"), 15))
	var h := _riga_bottoni()
	for x in req["dati"]["lista"]:
		var d := Arcano.inc(x["inc"])
		for j in range(x["mezzi"].size()):
			var b := _bott("%s con %s" % [d["nome"], x["mezzi"][j]["testo"]], func(): _rispondi({"inc": x["inc"], "mezzo": j}), 15)
			b.tooltip_text = Arcano.descrivi_inc(x["inc"])
			h.add_child(b)
	h.add_child(_bott("Nessuno", func(): _rispondi({}), 17, true))
	_ricentra()

func _richiesta_scelta(req: Dictionary) -> void:
	_apri_modale("Scelta: prendi il risultato che preferisci")
	var h := _riga_bottoni()
	for r in req["dati"]["opzioni"]:
		h.add_child(_bott(Reame.RISULTATI[r], func(): _rispondi(r), 18, r == "scopri"))
	_ricentra()

func _richiesta_riposo(req: Dictionary) -> void:
	var u := g.umano()
	_apri_modale("Riposo: quale segnalino recuperi?")
	var h := _riga_bottoni()
	var opz: Array = req["dati"]["opzioni"]
	for i in range(opz.size()):
		var o: Dictionary = opz[i]
		var c: Dictionary = u["chits"][o["i"]]
		var t := "%s: %s" % [g.descr_chit(c), "da ferito ad affaticato" if (o["da"] == "w" and o["a"] == "f") else "torna disponibile"]
		if o["resto"] >= 0:
			t += " (affatichi un segnalino a un asterisco come resto)"
		h.add_child(_bott(t, func(): _rispondi(i), 15))
	_ricentra()

# ============================================================ combattimento
func _intestazione_combattimento() -> void:
	var C: Dictionary = g.combat.C
	var u := g.umano()
	box_modale.add_child(_lab("Combattimento a %s · round %d%s" % [g.nome_r(C.get("k", u["dove"])), C.get("round", 1), " (primo round: colpisce prima l'arma più lunga)" if C.get("primo", false) else " (colpisce prima il più veloce)"], 16, f_tit))
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 10)
	box_modale.add_child(h)
	for id in g.s["mostri"]:
		var m: Dictionary = g.s["mostri"][id]
		if m["morto"] or m["dove"] != C.get("k", ""):
			continue
		h.add_child(_scheda_mostro(m, C.get("assegnati", {}).get(id, "")))
	for p in g.s["pg"]:
		if p != u and not p["morto"] and p["dove"] == C.get("k", ""):
			var v := VBoxContainer.new()
			var im := TextureRect.new()
			im.texture = T("res://assets/personaggi/%s_%s.webp" % [Dati.personaggi[p["pg"]]["pedina"], "nascosto" if p["nascosto"] else "pedina"])
			im.custom_minimum_size = Vector2(64, 64)
			im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			v.add_child(im)
			v.add_child(_lab(p["nome"], 13, f_tit))
			h.add_child(v)

func _scheda_mostro(m: Dictionary, assegnato: String) -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(96, 0)
	var im := TextureRect.new()
	im.texture = T(_img_mostro(m))
	im.custom_minimum_size = Vector2(80, 80)
	im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	v.add_child(im)
	var d := Dati.tipo_mostro(m["tipo"])
	var lato: Array = d["scuro"] if m["lato"] == 1 else d["chiaro"]
	var at := str(lato[0]) if str(lato[0]) != "" else "nessuno"
	if at.begins_with("V"):
		at = "incantesimo " + at.substr(1)
	var info := "%s\nattacco %s, mossa %d%s" % [g.nome_mostro(m), at, int(lato[1]), "\ncorazzato" if d.get("armato", false) else ""]
	if assegnato != "":
		info += "\ncontro " + g.P(assegnato)["nome"]
	var pos: Dictionary = g.combat.C.get("pos", {}).get(m["id"], {})
	if not pos.is_empty():
		info += "\n%s · %s" % [Combattimento.DIREZIONI[pos["riga"]], Combattimento.MANOVRE[pos["col"]]]
	v.add_child(_lab(info, 12))
	return v

func _mostra_combattimento_attesa() -> void:
	pass

func _scegli_chit(lista: Array, sel: Array, multi := false) -> HFlowContainer:
	var u := g.umano()
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 6)
	for i in lista:
		var c: Dictionary = u["chits"][i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(78, 66)
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var ch := _chit_ui(c, i in sel)
		ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ch)
		b.tooltip_text = g.descr_chit(c)
		b.pressed.connect(func():
			if multi:
				if i in sel: sel.erase(i)
				else: sel.append(i)
			else:
				sel.clear()
				sel.append(i)
			for x in h.get_children():
				x.queue_free()
			var nuovo := _scegli_chit(lista, sel, multi)
			for x in nuovo.get_children():
				nuovo.remove_child(x)
				h.add_child(x)
			nuovo.queue_free())
		h.add_child(b)
	return h

func _richiesta_combattimento(req: Dictionary) -> void:
	var u := g.umano()
	var d: Dictionary = req["dati"]
	var titoli := {"adesca": "Adescare i mostri", "carica": "Carica", "azione": "Azione", "bersaglio": "Bersaglio", "mischia": "Mischia: attacco, manovra e scudo",
		"fatica": "Fatica: affatica un segnalino", "ferita": "Ferita: scegli il segnalino ferito"}
	await _apri_modale(titoli[req["tipo"]])
	_intestazione_combattimento()
	match req["tipo"]:
		"adesca":
			box_modale.add_child(_lab("Puoi attirare su di te dei mostri (chi adesca si rivela). Serve a dividere i mostri tra i personaggi.", 15))
			var sel := []
			var h := _riga_bottoni()
			for mid in d["mostri"]:
				var cb := CheckBox.new()
				cb.text = g.nome_mostro(g.M(mid))
				cb.add_theme_font_override("font", f_txt)
				cb.add_theme_color_override("font_color", C_INCHIOSTRO)
				cb.toggled.connect(func(on): (sel.append(mid) if on else sel.erase(mid)))
				h.add_child(cb)
			var h2 := _riga_bottoni()
			h2.add_child(_bott("Conferma", func(): _rispondi(sel), 18, true))
			h2.add_child(_bott("Nessuno", func(): _rispondi([]), 18))
		"carica":
			box_modale.add_child(_lab("Caricare un personaggio con un segnalino Movimento ostacola la sua fuga e la sua allerta.", 15))
			var sel := []
			box_modale.add_child(_scegli_chit(d["chits"], sel))
			var h := _riga_bottoni()
			for pid in d["bersagli"]:
				h.add_child(_bott("Carica " + g.P(pid)["nome"], func():
					if sel.is_empty():
						_avviso("Scegli prima il segnalino Movimento.")
					else:
						_rispondi({"bersaglio": pid, "chit": sel[0]}), 17))
			h.add_child(_bott("Nessuna carica", func(): _rispondi({}), 17))
		"azione":
			var info := "Minaccia più rapida: velocità %d." % d["minaccia"] if d["minaccia"] < 99 else "Nessuno ti minaccia."
			box_modale.add_child(_lab(info + " Fuggire o allertare richiede un segnalino più veloce.", 15))
			var sel := []
			var tutti: Array = (d["fuga"] + d["allerta"]).duplicate()
			if d["berserk"] >= 0: tutti.append(d["berserk"])
			if d["riflessi"] >= 0: tutti.append(d["riflessi"])
			var unici := []
			for x in tutti:
				if not (x in unici): unici.append(x)
			if not unici.is_empty():
				box_modale.add_child(_scegli_chit(unici, sel))
			var h := _riga_bottoni()
			if d.get("fuga_cavallo", false):
				h.add_child(_bott("Fuggi a cavallo", func(): _rispondi({"tipo": "fuga_cavallo"}), 17))
			if not d["fuga"].is_empty():
				h.add_child(_bott("Fuggi", func():
					if sel.is_empty() or not (sel[0] in d["fuga"]): _avviso("Scegli un segnalino Movimento valido per fuggire.")
					else: _rispondi({"tipo": "fuga", "chit": sel[0]}), 17))
			if not d["allerta"].is_empty():
				h.add_child(_bott("Allerta l'arma", func():
					if sel.is_empty() or not (sel[0] in d["allerta"]): _avviso("Scegli un segnalino Combattimento valido.")
					else: _rispondi({"tipo": "allerta", "chit": sel[0]}), 17))
			if d["berserk"] >= 0:
				h.add_child(_bott("Berserk!", func(): _rispondi({"tipo": "berserk", "chit": d["berserk"]}), 17))
			if d["riflessi"] >= 0:
				h.add_child(_bott("Riflessi", func(): _rispondi({"tipo": "riflessi", "chit": d["riflessi"]}), 17))
			for o in d["oggetti"]:
				var nome := Dati.nome_arma(o)
				h.add_child(_bott("Attiva/disattiva " + nome, func(): _rispondi({"tipo": "attiva", "oggetto": o}), 14))
			for o in d.get("usabili", []):
				h.add_child(_bott("Usa " + Dati.nome_arma(o), func(): _rispondi({"tipo": "usa", "oggetto": o}), 15))
			if not d.get("incantesimi", []).is_empty():
				box_modale.add_child(_lab("Incantesimi: scegli bersaglio e incantesimo (ha effetto all'inizio della mischia).", 16, f_tit))
				var bsel := [u["pid"]]
				var opt := OptionButton.new()
				opt.add_theme_font_override("font", f_txt)
				for id in d["bersagli_inc"]:
					opt.add_item("Bersaglio: " + (g.P(id)["nome"] if id.begins_with("p") else g.nome_mostro(g.M(id))))
				opt.select(maxi(0, d["bersagli_inc"].find(u["pid"])))
				opt.item_selected.connect(func(i): bsel[0] = d["bersagli_inc"][i])
				box_modale.add_child(opt)
				var hi := _riga_bottoni()
				for x in d["incantesimi"]:
					var xi := Arcano.inc(x["inc"])
					for j in range(x["mezzi"].size()):
						var bb := _bott("%s (%s)" % [xi["nome"], x["mezzi"][j]["testo"]], func(): _rispondi({"tipo": "incantesimo", "inc": x["inc"], "mezzo": j, "bersaglio": bsel[0]}), 15)
						bb.tooltip_text = Arcano.descrivi_inc(x["inc"])
						hi.add_child(bb)
			h.add_child(_bott("Nessuna azione", func(): _rispondi({}), 17, true))
		"bersaglio":
			box_modale.add_child(_lab("Chi vuoi attaccare (o parare) in questo round? Chi attacca in mischia si rivela; con un'arma da tiro si tenta l'imboscata.", 15))
			var h := _riga_bottoni()
			for id in d["bersagli"]:
				var nome: String = g.P(id)["nome"] if id.begins_with("p") else g.nome_mostro(g.M(id))
				if not id.begins_with("p") and g.combat.C["assegnati"].get(id, "") == u["pid"]:
					nome += " (ti attacca)"
				h.add_child(_bott(nome, func(): _rispondi(id), 17))
			h.add_child(_bott("Nessuno", func(): _rispondi(""), 17, true))
		"mischia":
			_pannello_mischia(d)
		"fatica", "ferita":
			box_modale.add_child(_lab("Ancora %d da %s." % [d["quanti"], "affaticare (in asterischi)" if req["tipo"] == "fatica" else "ferire"], 16))
			var sel := []
			box_modale.add_child(_scegli_chit(d["opzioni"], sel))
			var h := _riga_bottoni()
			h.add_child(_bott("Conferma", func():
				if sel.is_empty(): _avviso("Scegli un segnalino.")
				else: _rispondi(sel[0]), 18, true))
	_ricentra()

# Plancia di combattimento: le tre direzioni e le tre manovre sono zone
# cliccabili. I comandi storici restano disponibili sotto la plancia.
# Non modifica i tiri ne la risoluzione: restituisce le stesse scelte al motore.
# Replica funzionale della MELEE SECTION di Magic Realm seconda edizione.
# La geometria segue l'originale: box rossi dei mostri sulla sinistra,
# cerchi di attacco a destra, ovali di difesa sotto, quadrati MOVE in basso,
# tabella di riposizionamento e box dei segnalini usati a lato.
# Il motore resta l'autorita per assegnazioni, risultati e lanci di dadi.
func _plancia_mischia(d: Dictionary) -> void:
	var pergamena := Color(0.94, 0.89, 0.76)
	var inchiostro := Color(0.18, 0.13, 0.09)
	var rosso := Color(0.79, 0.48, 0.47)
	var selezione := Color(0.99, 0.81, 0.43)
	var carta := _pannello(pergamena)
	carta.add_theme_stylebox_override("panel", _stile(pergamena, Color(0.24, 0.18, 0.12), 4, 3))
	box_modale.add_child(carta)
	var corpo := VBoxContainer.new()
	corpo.add_theme_constant_override("separation", 9)
	carta.add_child(corpo)
	var titolo := _lab("SCHEDA DI COMBATTIMENTO  ·  MAGIC REALM II EDIZIONE", 22, f_tit, inchiostro)
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	corpo.add_child(titolo)
	var sottotitolo := _lab("I tre cerchi ATTACCO intercettano le tre caselle rosse; i tre quadrati MANOVRA rappresentano le direzioni di difesa.", 14, f_txt, inchiostro)
	corpo.add_child(sottotitolo)
	var scelte := _lab("", 15, f_tit, inchiostro)
	var rifresca_scelte := func():
		var modo: String = "PARATA" if mischia["modo"] == "parata" else "ATTACCO"
		var attacco: String = str(Combattimento.DIREZIONI[mischia["cerchio"]])
		var manovra: String = str(Combattimento.MANOVRE[mischia["casella"]])
		var scudo: String = str(Combattimento.DIREZIONI[mischia["scudo"]]) if d.get("scudo", false) else "nessuno"
		scelte.text = "%s: %s    •    MANOVRA: %s    •    SCUDO: %s" % [modo, attacco, manovra, scudo]
	var direzioni := ["thrust", "swing", "smash"]
	var manovre := ["charge", "dodge", "duck"]
	var intercetta := ["Carica", "Schivata", "Abbassarsi"]
	var posizioni: Dictionary = g.combat.C.get("pos", {})
	var assegnati: Dictionary = g.combat.C.get("assegnati", {})
	var attacchi := []
	var difese := []
	var movimenti := []
	var aggiorna_stili := func():
		for b in attacchi:
			var on: bool = b.get_meta("direzione") == mischia["cerchio"]
			b.add_theme_stylebox_override("normal", _stile(selezione if on else Color(0.98, 0.96, 0.89), inchiostro, 40, 3 if on else 1))
			b.add_theme_color_override("font_color", inchiostro)
		for b in difese:
			var on: bool = b.get_meta("scudo") == mischia["scudo"]
			b.add_theme_stylebox_override("normal", _stile(selezione if on else Color(0.98, 0.96, 0.89), inchiostro, 40, 3 if on else 1))
			b.add_theme_color_override("font_color", inchiostro)
		for b in movimenti:
			var on: bool = b.get_meta("manovra") == mischia["casella"]
			b.add_theme_stylebox_override("normal", _stile(selezione if on else Color(0.95, 0.93, 0.85), inchiostro, 2, 3 if on else 1))
			b.add_theme_color_override("font_color", inchiostro)
		rifresca_scelte.call()
	# Colonna principale e colonna della tabella con la stessa gerarchia
	# della scheda fisica originale.
	var tavola := HBoxContainer.new()
	tavola.add_theme_constant_override("separation", 18)
	corpo.add_child(tavola)
	var sinistra := VBoxContainer.new()
	sinistra.custom_minimum_size.x = 750
	sinistra.add_theme_constant_override("separation", 8)
	sinistra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tavola.add_child(sinistra)
	var laterale := VBoxContainer.new()
	laterale.custom_minimum_size.x = 238
	laterale.add_theme_constant_override("separation", 10)
	tavola.add_child(laterale)
	var intestazione := HBoxContainer.new()
	sinistra.add_child(intestazione)
	var label_box := _lab("BOX ROSSI DEI MOSTRI", 16, f_tit, inchiostro)
	label_box.custom_minimum_size.x = 330
	intestazione.add_child(label_box)
	intestazione.add_child(_lab("← INTERCETTA ←", 13, f_tit, inchiostro))
	intestazione.add_child(_lab("ATTACCHI", 16, f_tit, inchiostro))
	for i in range(3):
		var dir: String = direzioni[i]
		var man: String = manovre[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 12)
		sinistra.add_child(fila)
		# Le caselle rosse sono sfalsate a gradini, come sulla stampa 2e.
		# Lo spazio assegnato rimane identico fra i tre attacchi.
		var area_nemici := Control.new()
		area_nemici.custom_minimum_size = Vector2(332, 90)
		fila.add_child(area_nemici)
		var nemici := _pannello(rosso)
		nemici.position = Vector2(float(i * 55), 0.0)
		nemici.custom_minimum_size = Vector2(212, 86)
		nemici.add_theme_stylebox_override("panel", _stile(rosso, inchiostro, 1, 2))
		area_nemici.add_child(nemici)
		var testo_box := VBoxContainer.new()
		nemici.add_child(testo_box)
		testo_box.add_child(_lab("%d   %s + %s" % [i + 1, intercetta[i].to_upper(), Combattimento.DIREZIONI[dir].to_upper()], 14, f_tit, inchiostro))
		var contenuto := []
		for id in assegnati:
			var m: Dictionary = g.M(id)
			if m.is_empty() or m["morto"]:
				continue
			# Le posizioni sono casuali e segrete finche il motore le rivela.
			if posizioni.has(id) and posizioni[id].get("riga", "") == dir:
				contenuto.append(g.nome_mostro(m))
		testo_box.add_child(_lab(", ".join(contenuto) if not contenuto.is_empty() else "Posizioni da rivelare", 12, f_txt, inchiostro))
		var freccia := _lab("←────", 22, f_tit, inchiostro)
		freccia.custom_minimum_size.x = 70
		freccia.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila.add_child(freccia)
		var att := _bott(Combattimento.DIREZIONI[dir], func():
			mischia["cerchio"] = dir
			aggiorna_stili.call(), 16)
		att.set_meta("direzione", dir)
		att.custom_minimum_size = Vector2(182, 84)
		fila.add_child(att)
		attacchi.append(att)
		var legenda := _lab("Colpisce:\n" + intercetta[i], 12, f_txt, inchiostro)
		legenda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila.add_child(legenda)
	# Ovali scudo e armature come nel pannello DEFENSES originale.
	sinistra.add_child(_lab("DIFESE  ·  ORIENTAMENTO DELLO SCUDO E ARMATURE INDOSSATE", 15, f_tit, inchiostro))
	var scudi := HBoxContainer.new()
	scudi.add_theme_constant_override("separation", 8)
	sinistra.add_child(scudi)
	for dir in direzioni:
		var testo_scudo: String = "Proteggi: " + str(Combattimento.DIREZIONI[dir])
		var difesa := _bott(testo_scudo, func():
			mischia["scudo"] = dir
			aggiorna_stili.call(), 13)
		difesa.set_meta("scudo", dir)
		difesa.custom_minimum_size = Vector2(182, 76)
		difesa.disabled = not d.get("scudo", false)
		difese.append(difesa)
		scudi.add_child(difesa)
	var armature := HBoxContainer.new()
	armature.add_theme_constant_override("separation", 9)
	sinistra.add_child(armature)
	var oggetti_attivi := []
	var p: Dictionary = g.umano()
	for o in p["oggetti"]:
		if o.get("attivo", false) and Dati.oggetti["armature"].has(o["id"]):
			oggetti_attivi.append(Dati.nome_arma(o["id"]))
	for testo in ["CORAZZA\nAffondo + Fendente", "ELMO\nColpo dall'alto", "ARMATURA COMPLETA\nTutte le direzioni"]:
		var ovale := _pannello(Color(0.98, 0.96, 0.89))
		ovale.add_theme_stylebox_override("panel", _stile(Color(0.98, 0.96, 0.89), inchiostro, 35, 1))
		ovale.custom_minimum_size = Vector2(182, 74)
		armature.add_child(ovale)
		var l := _lab(testo, 12, f_tit, inchiostro)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ovale.add_child(l)
	sinistra.add_child(_lab("Armature effettivamente attive: " + (", ".join(oggetti_attivi) if not oggetti_attivi.is_empty() else "nessuna"), 13, f_txt, inchiostro))
	sinistra.add_child(_lab("MANOVRE  ·  CASELLE MOVE", 16, f_tit, inchiostro))
	var fila_manovre := HBoxContainer.new()
	fila_manovre.add_theme_constant_override("separation", 8)
	sinistra.add_child(fila_manovre)
	for man in manovre:
		var b := _bott(str(Combattimento.MANOVRE[man]), func():
			mischia["casella"] = man
			aggiorna_stili.call(), 18)
		b.set_meta("manovra", man)
		b.custom_minimum_size = Vector2(182, 88)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		movimenti.append(b)
		fila_manovre.add_child(b)
	# Originale: tabella di riposizionamento dei mostri (un dado).
	laterale.add_child(_lab("RIPOSIZIONAMENTO\nDEI MOSTRI", 16, f_tit, inchiostro))
	var tabella := GridContainer.new()
	tabella.columns = 4
	tabella.add_theme_constant_override("h_separation", 4)
	tabella.add_theme_constant_override("v_separation", 6)
	laterale.add_child(tabella)
	var celle := [["Dado", "Box 1", "Box 2", "Box 3"],
		["1", "resta", "3", "2"], ["2", "3", "resta", "1"],
		["3", "2", "1", "resta"], ["4", "resta", "resta", "resta"],
		["5", "2", "3", "1"], ["6", "3", "1", "2"]]
	for riga in celle:
		for valore in riga:
			var l := _lab(str(valore), 12, f_tit, inchiostro)
			l.custom_minimum_size.x = 53
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tabella.add_child(l)
	laterale.add_child(_lab("USATI IN QUESTO ROUND", 15, f_tit, inchiostro))
	var usati := _pannello(Color(0.98, 0.96, 0.89))
	usati.add_theme_stylebox_override("panel", _stile(Color(0.98, 0.96, 0.89), inchiostro, 2, 2))
	usati.custom_minimum_size.y = 152
	laterale.add_child(usati)
	var usati_testo := []
	var uso: Dictionary = g.combat.C.get("uso", {}).get(p["pid"], {})
	for ci in uso.get("usati", []):
		if int(ci) >= 0 and int(ci) < p["chits"].size():
			usati_testo.append(g.descr_chit(p["chits"][int(ci)]))
	usati.add_child(_lab("\n".join(usati_testo) if not usati_testo.is_empty() else "Nessun segnalino ancora usato", 13, f_txt, inchiostro))
	laterale.add_child(_lab("Le frecce mostrano le intercettazioni; il motore gestisce tiri, velocità, fatica e cambio tattica.", 13, f_txt, inchiostro))
	# Con le armi da tiro non e consentita la parata.
	if not d.get("missile", false):
		var modo := _bott("Usa FIGHT per: ATTACCO", func():
			mischia["modo"] = "parata" if mischia["modo"] == "attacco" else "attacco"
			rifresca_scelte.call(), 15)
		corpo.add_child(modo)
		modo.pressed.connect(func():
			modo.text = "Usa FIGHT per: " + ("PARATA" if mischia["modo"] == "parata" else "ATTACCO"))
	corpo.add_child(scelte)
	corpo.add_child(_lab("Metti sotto la scheda i segnalini FIGHT e MOVE (o il cavallo), poi premi RIVELA LE GIOCATE.", 14, f_txt, inchiostro))
	aggiorna_stili.call()

func _pannello_mischia(d: Dictionary) -> void:
	var u := g.umano()
	mischia = {"modo": "attacco", "cerchio": "thrust", "f": [], "m": [], "casella": "dodge", "scudo": "thrust"}
	var sug: Dictionary = g.ia.mischia(u, d)
	if sug.has("attacco"):
		mischia["f"] = [sug["attacco"]["chit"]]
		mischia["cerchio"] = sug["attacco"]["cerchio"]
	if sug.has("manovra"):
		mischia["casella"] = sug["manovra"]["casella"]
		if sug["manovra"].get("cavallo", false):
			mischia["cavallo"] = true
		else:
			mischia["m"] = [sug["manovra"]["chit"]]
	mischia["scudo"] = sug.get("scudo", "thrust")
	var bers: String = d["bersaglio"]
	box_modale.add_child(_lab("Bersaglio: %s · arma: %s%s · sforzo già usato: %d asterischi (massimo 2)" % [
		(g.P(bers)["nome"] if bers.begins_with("p") else g.nome_mostro(g.M(bers))) if bers != "" else "nessuno", Dati.nome_arma(d["arma"]),
		" (da tiro: niente parate)" if d["missile"] else "", d["sforzo"]], 15))
	box_modale.add_child(_lab("Affondo colpisce chi fa Carica, Fendente chi Schiva, Colpo dall'alto chi si Abbassa; un attacco più veloce della manovra colpisce comunque.", 14, f_txt, Color(0.4, 0.3, 0.2)))
	_plancia_mischia(d)
	if bers != "" and not d["fight"].is_empty():
		box_modale.add_child(_lab("SEGNALINO FIGHT  ·  Forza e velocità del tuo attacco o della parata", 15, f_tit))
		box_modale.add_child(_scegli_chit(d["fight"], mischia["f"]))
	elif bers != "":
		box_modale.add_child(_lab("Nessun segnalino FIGHT valido: questo round puoi soltanto manovrare.", 14))
	if d.get("cavallo", false):
		mischia["cavallo"] = true
		box_modale.add_child(_lab("MANOVRA A CAVALLO  ·  Galoppo a velocità %d. Il cavallo può assorbire il colpo." % d["tempo_cavallo"], 15, f_tit))
	elif not d["move"].is_empty():
		box_modale.add_child(_lab("SEGNALINO MOVE  ·  Scegli una manovra che regga il tuo equipaggiamento", 15, f_tit))
		box_modale.add_child(_scegli_chit(d["move"], mischia["m"]))
	else:
		box_modale.add_child(_lab("Nessun segnalino MOVE valido: non puoi eseguire una manovra.", 14))
	var hb := _riga_bottoni()
	hb.add_child(_bott("Rivela le giocate", func():
		var r := {"scudo": mischia["scudo"]}
		if not mischia["f"].is_empty():
			r[mischia["modo"]] = {"cerchio": mischia["cerchio"], "chit": mischia["f"][0]}
		if mischia.get("cavallo", false):
			r["manovra"] = {"casella": mischia["casella"], "cavallo": true}
		elif not mischia["m"].is_empty():
			r["manovra"] = {"casella": mischia["casella"], "chit": mischia["m"][0]}
		_rispondi(r), 20, true))
	hb.add_child(_bott("Non giocare nulla", func(): _rispondi({"scudo": mischia["scudo"]}), 16))

func _evidenzia(gruppo: Array, testo: String) -> void:
	for b in gruppo:
		var sel: bool = (b as Button).text == testo or ((b as Button).text + " (attacco)") == testo
		(b as Button).add_theme_stylebox_override("normal", _stile(Color(0.55, 0.12, 0.08) if sel else Color(0.30, 0.20, 0.12), C_ORO, 5, 3 if sel else 1))

# ============================================================ fine partita
func _fine() -> void:
	_svuota_azioni()
	azioni.visible = true
	var vinto: bool = g.s["fine"] == "vittoria"
	box_azioni.add_child(_lab("Vittoria!" if vinto else "La partita è finita.", 30, f_tit, C_VERDE if vinto else C_ROSSO))
	var nomi: Array = g.s["vincitori"].map(func(x): return g.P(x)["nome"])
	if not nomi.is_empty():
		box_azioni.add_child(_lab("Vince: " + ", ".join(nomi), 20))
	var h := HBoxContainer.new()
	box_azioni.add_child(h)
	h.add_child(_bott("Nuova partita", _torna_menu, 18, true))
	var finito_path := _percorso_salvataggio(_edizione_attuale())
	if FileAccess.file_exists(finito_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(finito_path))

# ============================================================ regole
func _crea_aiuto() -> void:
	aiuto = _pannello(Color(0.95, 0.89, 0.74, 0.99))
	aiuto.set_anchors_preset(Control.PRESET_FULL_RECT)
	aiuto.offset_left = 120
	aiuto.offset_right = -120
	aiuto.offset_top = 70
	aiuto.offset_bottom = -40
	aiuto.visible = false
	ui.add_child(aiuto)
	var v := VBoxContainer.new()
	aiuto.add_child(v)
	var hb := HBoxContainer.new()
	v.add_child(hb)
	var t := _lab("Regole in breve", 30, f_tit, C_ROSSO)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(t)
	hb.add_child(_bott("Chiudi", func(): aiuto.visible = false, 18))
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_override("normal_font", f_txt)
	rt.add_theme_font_override("bold_font", f_tit)
	rt.add_theme_font_size_override("normal_font_size", 18)
	rt.add_theme_font_size_override("bold_font_size", 20)
	rt.add_theme_color_override("default_color", C_INCHIOSTRO)
	rt.text = load("res://scripts/regole.gd").TESTO
	v.add_child(rt)

# ============================================================ guida
func _carica_guida() -> void:
	var cf := ConfigFile.new()
	if cf.load(GUIDA_CFG) == OK:
		guida_visti = cf.get_value("guida", "visti", {})
		guida_attiva = cf.get_value("guida", "attiva", true)

func _salva_guida() -> void:
	var cf := ConfigFile.new()
	cf.set_value("guida", "visti", guida_visti)
	cf.set_value("guida", "attiva", guida_attiva)
	cf.save(GUIDA_CFG)

func _crea_guida() -> void:
	guida_pannello = _pannello(Color(1, 0.96, 0.84))
	guida_pannello.add_theme_stylebox_override("panel", _stile(Color(1, 0.96, 0.84), C_ROSSO, 8, 3))
	guida_pannello.custom_minimum_size = Vector2(620, 0)
	guida_pannello.visible = false
	hud.add_child(guida_pannello)
	var m := MarginContainer.new()
	for lato in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + lato, 12)
	guida_pannello.add_child(m)
	guida_box = VBoxContainer.new()
	guida_box.add_theme_constant_override("separation", 8)
	m.add_child(guida_box)

func _apri_guida(titolo: String, righe: Array) -> void:
	if guida_pannello == null:
		_crea_guida()
	for c in guida_box.get_children():
		c.queue_free()
	guida_box.add_child(_lab(titolo, 22, f_tit, C_ROSSO))
	for t in righe:
		var l := _lab(t, 16)
		l.custom_minimum_size = Vector2(596, 0)
		guida_box.add_child(l)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	guida_box.add_child(h)
	h.add_child(_bott("Ho capito", func():
		guida_pannello.visible = false
		if not guida_coda.is_empty():
			var k: String = guida_coda.pop_front()
			_apri_guida("Suggerimento", [Guida.SUGGERIMENTI[k]]), 17, true))
	var cb := CheckBox.new()
	cb.text = "Mostra i suggerimenti"
	cb.button_pressed = guida_attiva
	cb.add_theme_font_override("font", f_txt)
	for nome in ["font_color", "font_pressed_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		cb.add_theme_color_override(nome, C_INCHIOSTRO)
	cb.toggled.connect(func(on):
		guida_attiva = on
		_salva_guida())
	h.add_child(cb)
	guida_pannello.visible = true
	guida_pannello.size = Vector2.ZERO
	guida_pannello.reset_size()
	await get_tree().process_frame
	guida_pannello.size = Vector2.ZERO
	guida_pannello.reset_size()
	guida_pannello.position = Vector2(hud.size.x - guida_pannello.size.x - 10, 64)

func _mostra_guida_scenario(sempre: bool) -> void:
	if g == null:
		return
	if guida_visti.is_empty():
		_carica_guida()
	var sc: int = g.s["scenario"]
	var k := "scenario_%d" % sc
	if not sempre and (not guida_attiva or guida_visti.has(k)):
		return
	var t: Array = Guida.SCENARI[sc]
	_apri_guida(t[0], t.slice(1))
	guida_visti[k] = true
	_salva_guida()

func _suggerimento(k: String) -> void:
	if guida_visti.is_empty():
		_carica_guida()
	if not guida_attiva or guida_visti.has(k):
		return
	guida_visti[k] = true
	_salva_guida()
	if guida_pannello != null and guida_pannello.visible:
		guida_coda.append(k)
		return
	_apri_guida("Suggerimento", [Guida.SUGGERIMENTI[k]])

func _process(delta: float) -> void:
	if marcatore != null and is_instance_valid(marcatore):
		marcatore.position.y = 0.62 + 0.06 * sin(Time.get_ticks_msec() / 300.0)
		marcatore.rotation.y += delta * 1.5
