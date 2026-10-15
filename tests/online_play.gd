extends SceneTree
## Prova del gioco online: due istanze (chi crea la stanza e un amico) giocano una partita intera sul
## finto Firebase (tests/firebase_mock.py); Germania e Stati Uniti li gioca l'IA. Le persone sono simulate
## dall'IA. WW_ROLE=host|guest, WW_CODEFILE=file per il codice della stanza, WW_PHASE=drop: l'ospite esce a
## metà (per provare il rientro con WW_PHASE=back). Alla fine ognuno stampa l'impronta della partita.

var main
var t0 := 0
var ai := WWAI.new()
var answered := -1

func _init() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	t0 = Time.get_ticks_msec()
	_run()

func _wait(s: float) -> void:
	await create_timer(s).timeout

func _run() -> void:
	await _wait(0.5)
	var role := OS.get_environment("WW_ROLE")
	var cf := OS.get_environment("WW_CODEFILE")
	var phase := OS.get_environment("WW_PHASE")
	var menu = main.current
	menu.fac_mode = [1, 0, 1, 0]
	menu.speed = 3
	menu._online_panel()
	menu.on_name.text = "Host" if role == "host" else "Ospite"
	if role == "host":
		await menu._online_create()
		var code: String = main.lobby.get("code", "")
		print("WWTEST stanza ", code)
		var f := FileAccess.open(cf, FileAccess.WRITE)
		f.store_string(code)
		f.close()
		while true:
			var room: Dictionary = await main.net.room(code)
			if Net._as_dict(room.get("seats", {})).size() >= 2:
				break
			await _wait(0.5)
		await menu._online_start()
	else:
		var code := ""
		while code == "":
			if FileAccess.file_exists(cf):
				code = FileAccess.get_file_as_string(cf).strip_edges()
			await _wait(0.3)
		menu.on_code.text = code
		await menu._online_join()
	while true:
		await process_frame
		if Time.get_ticks_msec() - t0 > 1200000:
			print("WWTEST tempo scaduto")
			quit(2)
			return
		var view = main.current
		if view == null or not ("eng" in view) or view.eng == null or view.online == null:
			continue
		var e: WWEngine = view.eng
		var req: Dictionary = view.req
		if not req.is_empty() and view.online._mine_pending and answered != view.online.n:
			answered = view.online.n
			var r = ai.decide(e, int(req["fac"]), req)
			view._send(r)
		if phase == "drop" and int(e.S["part"]) == 1 and int(e.S["round"]) >= 3:
			print("WWTEST esco a metà partita, mossa ", view.online.n)
			quit(0)
			return
		if e.S.get("over", false):
			await _wait(0.5)
			print("WWTEST impronta ", view.online.n, " | ", e.fingerprint())
			quit(0)
			return
