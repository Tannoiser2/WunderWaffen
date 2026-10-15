extends Control
## Menu principale: copertina, le quattro fazioni (Umano / IA), opzioni e gioco online.

const D = preload("res://scripts/data/ww_data.gd")
## pedina Simbolo Fazione di ogni fazione (per lo stemma)
const EMBLEM := [4, 8, 8, 6]
const FAC_ORDER := [0, 1, 2, 3]

var main
var fac_mode := [1, 0, 1, 1]          # 0 umano, 1 IA (per fazione)
var team_mode := [0, 1]               # partita a due: giocatore A (UK+URSS), B (USA+Germania)
var two := false
var hist := false
var start_cards := true
var level := 1
var speed := 1
var tiles_box: HBoxContainer
var msg: Label
var two_chk: CheckBox


func _ready() -> void:
	size = Vector2(1920, 1080)
	if main.menu_state.has("fac_mode"):
		fac_mode = main.menu_state["fac_mode"].duplicate()
		team_mode = main.menu_state["team_mode"].duplicate()
		two = main.menu_state["two"]
		hist = main.menu_state["hist"]
		start_cards = main.menu_state["start_cards"]
		level = main.menu_state["level"]
		speed = main.menu_state["speed"]
	var bg := ColorRect.new()
	bg.color = UI.NAVY
	bg.size = size
	add_child(bg)
	var art := TextureRect.new()
	art.texture = UI.tex("res://assets/ui/cover_art.jpg")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.position = Vector2(1180, 0)
	art.size = Vector2(740, 1080)
	add_child(art)
	var fade := TextureRect.new()
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(UI.NAVY, 1.0))
	g.set_color(1, Color(UI.NAVY, 0.0))
	grad.gradient = g
	grad.fill_from = Vector2(0, 0)
	grad.fill_to = Vector2(1, 0)
	fade.texture = grad
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.position = Vector2(1180, 0)
	fade.size = Vector2(380, 1080)
	add_child(fade)

	var logo := UI.icon_rect(UI.tex("res://assets/ui/logo.png"), Vector2(900, 192))
	logo.position = Vector2(60, 34)
	add_child(logo)
	var sub := UI.label("UN GIOCO STRATEGICO SUGLI ULTIMI GIORNI DELLA SECONDA GUERRA MONDIALE · DI WALTER OBERT", 19, UI.CREAM, UI.font_title)
	sub.position = Vector2(64, 236)
	add_child(sub)

	var head := UI.banner("Nuova partita", 30, UI.RED)
	head.position = Vector2(60, 290)
	add_child(head)
	var note := UI.label("Scegli chi guida ogni fazione: gli Alleati corrono verso Berlino, la Germania cerca le armi miracolose.", 21, UI.CREAM)
	note.position = Vector2(64, 350)
	add_child(note)
	tiles_box = HBoxContainer.new()
	tiles_box.position = Vector2(60, 392)
	tiles_box.add_theme_constant_override("separation", 18)
	add_child(tiles_box)

	var box := PanelContainer.new()
	box.position = Vector2(60, 700)
	box.custom_minimum_size = Vector2(1090, 0)
	box.add_theme_stylebox_override("panel", UI.flat(Color(UI.NAVY_DARK, 0.85), Color("#4a4680"), 2, 12, 16))
	add_child(box)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 10)
	box.add_child(ov)
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 30)
	two_chk = _check("Partita a due (variante)", two, func(on):
		two = on
		_build_tiles())
	r1.add_child(two_chk)
	r1.add_child(_check("Preparazione storica", hist, func(on): hist = on))
	r1.add_child(_check("Carte Ricerca iniziali del tedesco", start_cards, func(on): start_cards = on))
	ov.add_child(r1)
	ov.add_child(_segmented("Livello IA", ["Facile", "Normale", "Difficile"], level, func(k): level = k))
	ov.add_child(_segmented("Velocità IA", ["Lenta", "Normale", "Veloce", "Istantanea"], speed, func(k): speed = k))

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 18)
	btns.position = Vector2(60, 920)
	add_child(btns)
	var b_start := UI.primary(UI.button("INIZIA PARTITA", 380, 78, 32))
	b_start.pressed.connect(_on_start)
	btns.add_child(b_start)
	var b_rules := UI.light(UI.button("REGOLE", 220, 78, 30))
	b_rules.pressed.connect(func():
		_store()
		main.show_rules())
	btns.add_child(b_rules)
	var b_online := UI.button("GIOCA ONLINE", 320, 78, 30)
	b_online.pressed.connect(_online_panel)
	btns.add_child(b_online)
	if not OS.has_feature("web"):
		var b_quit := UI.button("ESCI", 150, 78, 30)
		b_quit.pressed.connect(func(): get_tree().quit())
		btns.add_child(b_quit)
	msg = UI.label("", 24, UI.GOLD, UI.font_title)
	msg.position = Vector2(64, 1008)
	add_child(msg)
	var credits := UI.label("Adattamento digitale non ufficiale per uso personale · WunderWaffen © Oliphante / Ares Games · F11 schermo intero", 16, Color("#a9a5c8"))
	credits.position = Vector2(64, 1046)
	add_child(credits)
	_build_tiles()
	if not main.lobby.is_empty():
		_online_panel.call_deferred()


func _check(text: String, on: bool, cb: Callable) -> CheckBox:
	var c := CheckBox.new()
	c.text = text
	c.button_pressed = on
	c.toggled.connect(func(v): cb.call(v))
	return c


func _store() -> void:
	main.menu_state = {"fac_mode": fac_mode.duplicate(), "team_mode": team_mode.duplicate(), "two": two, "hist": hist,
		"start_cards": start_cards, "level": level, "speed": speed}


func _build_tiles() -> void:
	for c in tiles_box.get_children():
		c.queue_free()
	if two:
		_tile("GIOCATORE A", "Regno Unito e Unione Sovietica", [3, 1], team_mode, 0)
		_tile("GIOCATORE B", "Stati Uniti e Germania", [2, 0], team_mode, 1)
	else:
		for f in FAC_ORDER:
			_tile(D.FAC_NAME[f].to_upper(), ["Asse", "Alleati", "Alleati", "Alleati"][f], [f], fac_mode, f)


func _tile(title: String, sub: String, facs: Array, modes: Array, idx: int) -> void:
	var w := 255.0 if not two else 530.0
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(w, 290)
	var col: Color = D.FAC_COLOR[facs[0]]
	p.add_theme_stylebox_override("panel", UI.flat(Color(UI.NAVY_DARK, 0.92), col, 3, 12, 12))
	tiles_box.add_child(p)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	p.add_child(vb)
	var em := HBoxContainer.new()
	em.alignment = BoxContainer.ALIGNMENT_CENTER
	em.add_theme_constant_override("separation", 10)
	for f in facs:
		em.add_child(UI.icon_rect(UI.pawn(int(f) * 18 + EMBLEM[f]), Vector2(110, 110)))
	vb.add_child(em)
	var t := UI.label(title, 24 if not two else 28, Color.WHITE, UI.font_title)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var s := UI.label(sub, 18, Color("#c9c5e0"))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(s)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 6)
	vb.add_child(bar)
	var bs := []
	for k in 2:
		var b := UI.button(["UMANO", "IA"][k], 110 if not two else 160, 48, 20)
		bar.add_child(b)
		bs.append(b)
	var paint := func():
		for k in 2:
			if modes[idx] == k:
				UI.primary(bs[k])
			else:
				UI.light(bs[k])
	for k in 2:
		bs[k].pressed.connect(func():
			modes[idx] = k
			msg.text = ""
			paint.call())
	paint.call()


func _segmented(label_text: String, items: Array, cur: int, cb: Callable) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	var l := UI.label(label_text, 24, UI.CREAM, UI.font_title)
	l.custom_minimum_size = Vector2(200, 0)
	hb.add_child(l)
	var btns := []
	for k in items.size():
		var b := UI.button(items[k], 190, 46, 20)
		hb.add_child(b)
		btns.append(b)
	var paint := func(sel: int):
		for k in btns.size():
			if k == sel:
				UI.primary(btns[k])
			else:
				UI.light(btns[k])
	for k in btns.size():
		btns[k].pressed.connect(func():
			cb.call(k)
			paint.call(k))
	paint.call(cur)
	return hb


## Configurazione scelta nel menu (anche quella che, online, viaggia agli altri).
func _config() -> Dictionary:
	var seats := []
	if two:
		seats.append({"name": "Giocatore A", "ai": team_mode[0] == 1, "level": level, "facs": [3, 1]})
		seats.append({"name": "Giocatore B", "ai": team_mode[1] == 1, "level": level, "facs": [2, 0]})
	else:
		for f in FAC_ORDER:
			seats.append({"name": D.FAC_NAME[f], "ai": fac_mode[f] == 1, "level": level, "facs": [f]})
	var speeds := [1.4, 0.7, 0.25, 0.0]
	return {"seats": seats, "ai_delay": speeds[speed],
		"opts": {"two": two, "hist": hist, "nocards": not start_cards}}


func _on_start() -> void:
	_store()
	main.start_game(_config())


# =================================================================== online

var on_panel: Control
var on_name: LineEdit
var on_code: LineEdit
var on_lbl: Label
var on_start: Button


func _online_panel() -> void:
	if is_instance_valid(on_panel):
		on_panel.queue_free()
	on_panel = Control.new()
	on_panel.size = Vector2(1920, 1080)
	on_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(on_panel)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.size = on_panel.size
	on_panel.add_child(shade)
	var box := PanelContainer.new()
	box.position = Vector2(540, 120)
	box.custom_minimum_size = Vector2(840, 0)
	box.add_theme_stylebox_override("panel", UI.paper(26))
	on_panel.add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	box.add_child(vb)
	vb.add_child(UI.banner("Gioca online", 34))
	vb.add_child(UI.para("Chi crea la stanza sceglie prima nel menu le fazioni e il livello dell'IA: le fazioni su UMANO diventano i posti per gli amici (la prima è la sua). Gli amici entrano con il codice di 4 lettere; i posti rimasti liberi li gioca l'IA.", 780, 20))
	var ses: Dictionary = main.get_net().load_session()
	on_name = _line("Il tuo nome", 20)
	on_name.text = str(ses.get("name", ""))
	vb.add_child(on_name)
	var b_create := UI.primary(UI.button("CREA UNA STANZA", 0, 60, 26))
	b_create.pressed.connect(_online_create)
	vb.add_child(b_create)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	on_code = _line("Codice", 4)
	on_code.custom_minimum_size.x = 220
	on_code.text_changed.connect(func(t):
		on_code.text = t.to_upper()
		on_code.caret_column = t.length())
	row.add_child(on_code)
	var b_join := UI.button("ENTRA", 200, 60, 26)
	b_join.pressed.connect(_online_join)
	row.add_child(b_join)
	vb.add_child(row)
	on_lbl = UI.para("", 780, 22)
	on_lbl.custom_minimum_size.y = 120
	vb.add_child(on_lbl)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	on_start = UI.primary(UI.button("INIZIA ONLINE", 380, 70, 28))
	on_start.pressed.connect(_online_start)
	on_start.visible = main.lobby.get("role", "") == "host"
	row2.add_child(on_start)
	var b_close := UI.button("INDIETRO", 260, 70, 28)
	b_close.pressed.connect(func(): on_panel.queue_free())
	row2.add_child(b_close)
	vb.add_child(row2)
	if not main.lobby.is_empty():
		on_code.text = main.lobby["code"]
		on_lbl.text = "Stanza %s…" % main.lobby["code"]
	elif str(ses.get("room", "")) != "":
		on_code.text = str(ses["room"])
		on_lbl.text = "Eri nella stanza %s: premi ENTRA per rientrare." % ses["room"]


func _line(ph: String, maxlen: int) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = ph
	le.max_length = maxlen
	le.custom_minimum_size = Vector2(0, 58)
	return le


func _say(t: String) -> void:
	if is_instance_valid(on_lbl):
		on_lbl.text = t


func _seats_text(room: Dictionary) -> String:
	var seats := Net._as_dict(room.get("seats", {}))
	var list: Array = _config()["seats"]
	var parts := []
	for idx in room.get("open", []):
		var k := str(int(idx))
		var who := str(seats[k].get("name", "?")) if seats.has(k) and seats[k] is Dictionary else "libero"
		var cname: String = list[int(idx)]["name"] if int(idx) < list.size() else "posto %d" % (int(idx) + 1)
		parts.append("%s: %s" % [cname, who])
	return ", ".join(parts)


func _online_create() -> void:
	var nm := on_name.text.strip_edges()
	if nm == "":
		_say("Scrivi il tuo nome.")
		return
	var list: Array = _config()["seats"]
	var seats := []
	for i in list.size():
		if not list[i]["ai"]:
			seats.append(i)
	if seats.size() < 2:
		_say("Metti su UMANO almeno due fazioni: la prima è la tua, le altre sono i posti per gli amici.")
		return
	_store()
	_say("Creo la stanza…")
	var net: Net = main.get_net()
	var code := await net.create_room(nm, seats)
	if code == "":
		_say("Non riesco a creare la stanza.\n%s" % net.last_error)
		return
	main.lobby = {"role": "host", "code": code, "seat": seats[0]}
	net.remember_room(code, seats[0])
	net._save({"name": nm})
	if is_instance_valid(on_code):
		on_code.text = code
	if is_instance_valid(on_start):
		on_start.visible = true
	_lobby_poll(code)


func _online_join() -> void:
	var code := on_code.text.strip_edges().to_upper()
	var nm := on_name.text.strip_edges()
	if nm == "" or code.length() != 4:
		_say("Scrivi il tuo nome e il codice di 4 lettere.")
		return
	_say("Entro nella stanza %s…" % code)
	var net: Net = main.get_net()
	var seat := await net.join_room(code, nm)
	if seat == -2:
		_say("Stanza %s non trovata, oppure la partita è già iniziata.%s" % [code, ("\n" + net.last_error) if net.last_error != "" else ""])
		return
	if seat == -1:
		_say("Nella stanza %s non ci sono posti liberi." % code)
		return
	var room: Dictionary = net.last_room
	main.lobby = {"role": "host" if room.get("host", "") == net.uid else "guest", "code": code, "seat": seat}
	net.remember_room(code, seat)
	net._save({"name": nm})
	if room.get("status", "") in ["playing", "over"] and room.has("game"):
		_say("Rientro nella partita della stanza %s…" % code)
		_begin(room["game"], true)
		return
	if is_instance_valid(on_start):
		on_start.visible = main.lobby["role"] == "host"
	_lobby_poll(code)


func _lobby_poll(code: String) -> void:
	var net: Net = main.get_net()
	while is_inside_tree() and main.lobby.get("code", "") == code:
		var room := await net.room(code)
		if not is_inside_tree() or main.lobby.get("code", "") != code:
			return
		if room.is_empty():
			_say("La stanza %s non esiste più." % code)
			main.lobby = {}
			return
		if main.lobby["role"] == "host":
			_say("Stanza [ %s ]: dai il codice ai tuoi amici.\nPosti: %s.\nQuando ci siete tutti premi INIZIA ONLINE: i posti liberi li gioca l'IA." % [code, _seats_text(room)])
		else:
			if room.get("status", "") == "playing" and room.has("game"):
				_begin(room["game"], false)
				return
			_say("Sei nella stanza [ %s ] (posto %d).\nPosti: %s.\nAspetta che chi l'ha creata avvii la partita." % [code, int(main.lobby["seat"]) + 1, _seats_text(room)])
		await get_tree().create_timer(2.0).timeout


## Chi ha creato la stanza avvia: fazioni, opzioni e seme valgono per tutti.
func _online_start() -> void:
	var code: String = main.lobby["code"]
	var net: Net = main.get_net()
	var room := await net.room(code)
	if room.is_empty():
		_say("La stanza %s non esiste più." % code)
		main.lobby = {}
		return
	var seats_db := Net._as_dict(room.get("seats", {}))
	var cfg := _config()
	var my_seat := int(main.lobby["seat"])
	if my_seat >= cfg["seats"].size() or not seats_db.has(str(my_seat)) or cfg["seats"][my_seat]["ai"]:
		_say("Hai cambiato le fazioni dopo aver creato la stanza: creane una nuova.")
		return
	for i in cfg["seats"].size():
		var k := str(i)
		if seats_db.has(k) and seats_db[k] is Dictionary and not cfg["seats"][i]["ai"]:
			cfg["seats"][i]["name"] = str(seats_db[k].get("name", cfg["seats"][i]["name"]))
		else:
			cfg["seats"][i]["ai"] = true
	cfg["seed"] = 1 + randi() % 2000000000
	var g := {"cfg": var_to_str(cfg)}
	if not await net.start_room(code, g):
		_say("Non riesco ad avviare la partita (%s)." % net.last_error)
		return
	_begin(g, false)


## Avvio (o rientro) della partita online.
func _begin(g: Dictionary, rejoin: bool) -> void:
	var net: Net = main.get_net()
	var lob: Dictionary = main.lobby
	var backlog: Array = []
	if rejoin:
		backlog = await net.get_acts(lob["code"])
		net.set_away(lob["code"], int(lob["seat"]), false)
	var cfg = str_to_var(str(g.get("cfg", "")))
	if not (cfg is Dictionary):
		_say("Configurazione della partita non valida.")
		return
	var ses := OnlineSession.new()
	ses.setup(net, lob["code"], int(lob["seat"]), lob["role"], backlog)
	cfg["online"] = ses
	main.lobby = {}
	main.start_game(cfg)
