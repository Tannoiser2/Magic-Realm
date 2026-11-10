extends SceneTree
func _init() -> void:
	for f in ["res://scripts/dati.gd", "res://scripts/arcano.gd", "res://scripts/nativi.gd", "res://scripts/viaggi.gd", "res://scripts/guida.gd", "res://scripts/tutorial.gd", "res://scripts/mappa.gd", "res://scripts/reame.gd", "res://scripts/combattimento.gd", "res://scripts/ia.gd", "res://scripts/main.gd", "res://scripts/net.gd", "res://scripts/regole.gd"]:
		var sc = load(f)
		print(f, " ", sc != null)
	quit()
