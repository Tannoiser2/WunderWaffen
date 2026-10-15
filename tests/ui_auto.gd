extends SceneTree
## Prova dell'interfaccia: una fazione "umana" le cui scelte le fa l'IA dopo aver mostrato il pannello.
## xvfb-run godot --path . -s res://tests/ui_auto.gd -- <seme> <fazione umana> [cartella screenshot]

var shots := {}
var dir := ""

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var seed := int(a[0]) if a.size() > 0 else 3
	var human := int(a[1]) if a.size() > 1 else 3
	dir = a[2] if a.size() > 2 else ""
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var seats := []
	for f in 4:
		seats.append({"name": WWData.FAC_NAME[f], "ai": f != human, "level": 1, "facs": [f]})
	main.start_game({"seats": seats, "ai_delay": 0.0, "seed": seed, "opts": {"hist": seed % 2 == 0}})
	var gv = main.current
	var eng: WWEngine = gv.eng
	var ai := WWAI.new()
	ai.level = 1
	var n := 0
	eng.decision_requested.connect(func(r):
		n += 1
		_answer(gv, eng, ai, r))
	while not eng.S.get("over", false):
		await create_timer(0.5).timeout
	await create_timer(0.5).timeout
	if dir != "":
		_shot(gv, "fine")
	print("decisioni umane: %d, tipi visti: %s" % [n, str(shots.keys())])
	print("risultato: ", eng.results.get("winners"))
	quit()


func _answer(gv, eng, ai, r) -> void:
	# lascia costruire il pannello, poi risponde come l'IA
	await process_frame
	await process_frame
	var t := str(r["type"])
	print("richiesta ", t, " parte ", eng.S["part"], " giro ", eng.S["round"])
	if dir != "" and not shots.has(t):
		shots[t] = true
		_shot(gv, t)
	else:
		shots[t] = true
	var v = ai.decide(eng, int(r["fac"]), r)
	eng.provide_decision(v)


func _shot(gv, name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])
