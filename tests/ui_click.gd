extends SceneTree
## Prova dei percorsi di clic: per ogni turno umano usa i pulsanti e le caselle del tabellone come farebbe
## una persona (prima scelta disponibile). godot --headless --path . -s res://tests/ui_click.gd -- <seme> <fazione>

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var seed := int(a[0]) if a.size() > 0 else 2
	var human := int(a[1]) if a.size() > 1 else 1
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var seats := []
	for f in 4:
		seats.append({"name": "Umano" if f == human else WWData.FAC_NAME[f], "ai": f != human, "level": 0, "facs": [f]})
	main.start_game({"seats": seats, "ai_delay": 0.0, "seed": seed, "opts": {}})
	var gv = main.current
	var eng: WWEngine = gv.eng
	var ai := WWAI.new()
	var counts := {}
	eng.decision_requested.connect(func(r): _act(gv, eng, ai, r, counts))
	var t0 := Time.get_ticks_msec()
	while not eng.S.get("over", false) and Time.get_ticks_msec() - t0 < 240000:
		await create_timer(0.2).timeout
	print("percorsi usati: ", counts, " fine: ", eng.S.get("over", false), " vincitori ", eng.results.get("winners"))
	quit()


func _press_first(node: Node, kinds: Array) -> bool:
	for c in node.get_children():
		if c is BaseButton and not c.disabled and c.visible:
			var txt: String = c.text if c is Button else ""
			var ok := kinds.is_empty()
			for k in kinds:
				if txt.begins_with(k):
					ok = true
			if ok:
				c.pressed.emit()
				return true
		if _press_first(c, kinds):
			return true
	return false


func _act(gv, eng, ai, r, counts) -> void:
	await process_frame
	await process_frame
	var t := str(r["type"])
	var how := "ia"
	if t == "turn":
		# prima prova un DAI se serve, altrimenti USA + casella del tabellone o pulsante
		if int(r["self_left"]) > 0:
			_press_first(gv.act_body, ["USA"])
			await process_frame
			if not gv.board.targets.is_empty():
				gv.board.target_clicked.emit(gv.board.targets[0]["data"])
				how = "tabellone"
			elif _press_first(gv.act_body, []):
				how = "pulsante"
		elif _press_first(gv.act_body, ["DAI"]):
			await process_frame
			if not gv.req.is_empty():
				_press_first(gv.act_body, [])
			how = "dai"
		elif _press_first(gv.act_body, ["SCARTA"]):
			how = "scarta"
	elif t == "use_gift":
		if not gv.board.targets.is_empty():
			gv.board.target_clicked.emit(gv.board.targets[0]["data"])
			how = "tabellone"
		elif _press_first(gv.act_body, []):
			how = "pulsante"
	elif t == "pick":
		_press_first(gv.act_body, ["SCEGLI TU"])
		how = "auto"
	elif t in ["event_opt", "target", "conf_bonus", "yesno"]:
		if _press_first(gv.act_body, []):
			how = "pulsante"
	if how == "ia":
		eng.provide_decision(ai.decide(eng, int(r["fac"]), r))
	var k := t + ":" + how
	counts[k] = int(counts.get(k, 0)) + 1
