extends SceneTree
## Controllo di compilazione di tutti gli script: godot --headless --path . -s res://tests/check.gd
func _init() -> void:
	var dirs := ["res://scripts/data", "res://scripts/core", "res://scripts/net", "res://scripts/ui"]
	for d in dirs:
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				var s = load(d + "/" + f)
				if s == null:
					print("FALLITO ", d + "/" + f)
	print("controllo finito")
	quit()
