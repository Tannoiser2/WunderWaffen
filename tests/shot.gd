extends SceneTree
## Screenshot di prova: xvfb-run godot --path . -s res://tests/shot.gd -- <cosa> <secondi> <file.png> [fazione umana]
## cosa: menu | game | rules

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var what := a[0] if a.size() > 0 else "menu"
	var secs := float(a[1]) if a.size() > 1 else 2.0
	var out := a[2] if a.size() > 2 else "/tmp/shot.png"
	var human := int(a[3]) if a.size() > 3 else 3
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	if what == "game":
		var seats := []
		for f in 4:
			seats.append({"name": WWData.FAC_NAME[f], "ai": f != human, "level": 1, "facs": [f]})
		main.start_game({"seats": seats, "ai_delay": 0.0, "seed": int(a[4]) if a.size() > 4 else 7, "opts": {"hist": true}})
	elif what == "rules":
		main.show_rules()
	await create_timer(secs).timeout
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("salvato ", out)
	quit()
