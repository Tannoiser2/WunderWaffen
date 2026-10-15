extends Control
## Schermata di gioco: tabellone a sinistra, a destra fazioni, azioni, carte Ricerca e cronaca.

const D = preload("res://scripts/data/ww_data.gd")
const EMBLEM := [4, 8, 8, 6]
const USE_COL := {"place": Color("#3fa34d"), "kill": Color("#e0402f"), "berlin": Color("#e0b046"), "conf": Color("#e0b046"), "share": Color("#4f8fe0")}

var main
var config: Dictionary
var eng: WWEngine
var online: OnlineSession
var board: WWBoard
var req := {}
var last_private_seat := -1

var status_lbl: Label
var turn_pill: PanelContainer
var turn_lbl: Label
var net_lbl: Label
var rows := []
var act_title: Label
var act_text: Label
var act_body: VBoxContainer
var ric_box: VBoxContainer
var log_lbl: RichTextLabel
var overlay: Control
var log_all: Array = []


func _ready() -> void:
	size = Vector2(1920, 1080)
	var bg := ColorRect.new()
	bg.color = UI.NAVY
	bg.size = size
	add_child(bg)
	board = WWBoard.new()
	board.position = Vector2(12, 12)
	board.size = Vector2(1056, 1056)
	add_child(board)
	board.target_clicked.connect(_on_target)
	_build_right()
	eng = WWEngine.new()
	eng.host = self
	eng.setup(config)
	board.eng = eng
	eng.changed.connect(_refresh)
	eng.log_added.connect(_on_log)
	eng.decision_requested.connect(_on_request)
	eng.game_ended.connect(_on_end)
	eng.fx.connect(_on_fx)
	if config.has("online"):
		online = config["online"]
		online.view = self
		add_child(online)
		eng.online = online
		if online.role != "host":
			online.heartbeat_loop()
	_refresh()
	_idle("La partita sta per cominciare…")
	_run.call_deferred()


func _run() -> void:
	await eng.run()


func _exit_tree() -> void:
	if eng != null:
		eng.abort = true


# ------------------------------------------------------------------ costruzione

func _build_right() -> void:
	var x0 := 1080.0
	var w := 828.0
	# barra in alto
	status_lbl = UI.label("", 22, UI.CREAM, UI.font_title)
	status_lbl.position = Vector2(x0, 18)
	add_child(status_lbl)
	turn_pill = PanelContainer.new()
	turn_pill.position = Vector2(x0 + 228, 14)
	add_child(turn_pill)
	turn_lbl = UI.label("", 17, Color.WHITE, UI.font_title)
	turn_pill.add_child(turn_lbl)
	var bb := HBoxContainer.new()
	bb.position = Vector2(x0 + w - 372, 10)
	bb.add_theme_constant_override("separation", 8)
	add_child(bb)
	for it in [["CARTE", _cards_popup], ["DIARIO", _log_popup], ["REGOLE", _rules_popup], ["MENU", _menu_confirm]]:
		var b := UI.button(it[0], 87, 40, 15)
		b.pressed.connect(it[1])
		bb.add_child(b)
	net_lbl = UI.label("", 16, UI.GOLD)
	net_lbl.position = Vector2(x0, 50)
	add_child(net_lbl)
	# fazioni
	var fb := VBoxContainer.new()
	fb.position = Vector2(x0, 70)
	fb.add_theme_constant_override("separation", 6)
	add_child(fb)
	for f in D.ORDER:
		rows.append(null)
	for f in D.ORDER:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(w, 74)
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_faction_popup(f))
		p.tooltip_text = "Clic per la scheda della fazione"
		fb.add_child(p)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(hb)
		hb.add_child(UI.icon_rect(UI.pawn(f * 18 + EMBLEM[f]), Vector2(54, 54)))
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 0)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.custom_minimum_size = Vector2(236, 0)
		hb.add_child(vb)
		var nm := UI.label("", 21, Color.WHITE, UI.font_title)
		vb.add_child(nm)
		var who := UI.label("", 16, Color("#d0cce6"))
		vb.add_child(who)
		var pv := UI.label("", 34, UI.GOLD, UI.font_cond_bold)
		pv.custom_minimum_size = Vector2(70, 0)
		pv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hb.add_child(pv)
		var st := UI.label("", 16, UI.CREAM, UI.font_cond)
		st.custom_minimum_size = Vector2(380, 0)
		hb.add_child(st)
		rows[f] = {"panel": p, "name": nm, "who": who, "pv": pv, "st": st}
	# area delle azioni
	var ap := PanelContainer.new()
	ap.position = Vector2(x0, 404)
	ap.custom_minimum_size = Vector2(w, 470)
	ap.size = Vector2(w, 470)
	ap.add_theme_stylebox_override("panel", UI.paper(16))
	add_child(ap)
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 8)
	ap.add_child(av)
	act_title = UI.label("", 26, UI.INK, UI.font_title)
	av.add_child(act_title)
	act_text = UI.para("", w - 40, 19, UI.INK)
	av.add_child(act_text)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(w - 32, 330)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	av.add_child(sc)
	act_body = VBoxContainer.new()
	act_body.add_theme_constant_override("separation", 8)
	act_body.custom_minimum_size = Vector2(w - 40, 0)
	sc.add_child(act_body)
	# Ricerca tedesca e cronaca
	var rp := PanelContainer.new()
	rp.position = Vector2(x0, 884)
	rp.custom_minimum_size = Vector2(388, 184)
	rp.add_theme_stylebox_override("panel", UI.flat(UI.NAVY_DARK, Color("#4a4680"), 2, 10, 10))
	add_child(rp)
	ric_box = VBoxContainer.new()
	ric_box.add_theme_constant_override("separation", 4)
	rp.add_child(ric_box)
	var lp := PanelContainer.new()
	lp.position = Vector2(x0 + 398, 884)
	lp.custom_minimum_size = Vector2(430, 184)
	lp.size = Vector2(430, 184)
	lp.add_theme_stylebox_override("panel", UI.paper(10))
	add_child(lp)
	log_lbl = RichTextLabel.new()
	log_lbl.custom_minimum_size = Vector2(410, 164)
	log_lbl.scroll_following = true
	log_lbl.add_theme_font_override("normal_font", UI.font_type)
	log_lbl.add_theme_font_size_override("normal_font_size", 15)
	log_lbl.add_theme_color_override("default_color", UI.INK)
	lp.add_child(log_lbl)


# ------------------------------------------------------------------ aggiornamento

func _refresh() -> void:
	if eng == null or eng.S.is_empty():
		return
	var S := eng.S
	board.queue_redraw()
	status_lbl.text = "PARTE %d · GIRO %d/%d" % [int(S["part"]), maxi(1, int(S["round"])), 6 if int(S["part"]) == 1 else 4]
	var cur := int(S["cur"])
	if cur >= 0:
		turn_pill.add_theme_stylebox_override("panel", UI.flat(D.FAC_COLOR[cur].darkened(0.1), Color.WHITE, 2, 14, 6))
		turn_lbl.text = " %s " % D.FAC_NAME[cur].to_upper()
		turn_pill.visible = true
	else:
		turn_pill.visible = false
	for f in 4:
		var r: Dictionary = rows[f]
		var col: Color = D.FAC_COLOR[f]
		var on := f == cur
		r["panel"].add_theme_stylebox_override("panel", UI.flat(col.darkened(0.55) if not on else col.darkened(0.25), Color.WHITE if on else col.darkened(0.2), 3 if on else 2, 10, 8))
		r["name"].text = D.FAC_NAME[f].to_upper()
		var s: Dictionary = eng.seats[eng.seat_of[f]]
		r["who"].text = ("IA · %s" % ["facile", "normale", "difficile"][int(s["level"])]) if s["ai"] else str(s["name"])
		if eng.two():
			r["who"].text += " · " + ("giocatore A" if eng.team_of(f) == 0 else "giocatore B")
		r["pv"].text = "%d" % int(S["pv"][f])
		var line := "PV · Morale %d · Politica %d" % [int(S["mor"][f]), int(S["pol"][f])]
		if f == 0:
			line += " · Ricerca %d (punti %d)" % [int(S["ric"]), int(D.RIC_POINTS[int(S["ric"])])]
		else:
			line += " · Eventi %d/6" % int(S["eve"][f])
		line += "\nPedine: %d in gioco · %d in riserva · %d scarti · tessere %d" % [S["start"][f].size(), eng.reserve(f).size(), eng.discards(f).size(), S["tiles"][f].size()]
		if f == 0:
			line += " · carte %d" % S["cards"].size()
		r["st"].text = line
	_refresh_ric()


func _refresh_ric() -> void:
	for c in ric_box.get_children():
		c.queue_free()
	var S := eng.S
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.add_child(UI.label("RICERCA TEDESCA", 17, UI.CREAM, UI.font_title))
	ric_box.add_child(hb)
	var tr := HBoxContainer.new()
	tr.add_theme_constant_override("separation", 4)
	for i in 6:
		var p := PanelContainer.new()
		var on := i == int(S["ric"])
		p.add_theme_stylebox_override("panel", UI.flat(UI.RED if on else Color("#3a3868"), Color.WHITE if on else Color("#5a5690"), 2, 6, 4))
		var t: String = ["→", "·", "1", "2", "3", "3+5"][i]
		var l := UI.label(t, 16, Color.WHITE, UI.font_cond_bold)
		l.custom_minimum_size = Vector2(44, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		tr.add_child(p)
	ric_box.add_child(tr)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 4)
	if S["cards"].is_empty():
		cards.add_child(UI.label("Nessuna carta Ricerca acquisita.", 15, Color("#bdb9d8")))
	for c in S["cards"]:
		var b := TextureButton.new()
		b.texture_normal = UI.card(int(c))
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
		b.custom_minimum_size = Vector2(70, 50)
		b.tooltip_text = "%s\n%s" % [D.CARDS[c]["name"], D.CARDS[c]["text"]]
		b.pressed.connect(func(): _card_zoom(int(c)))
		cards.add_child(b)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(366, 70)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(cards)
	ric_box.add_child(sc)
	var b2 := UI.button("CARTE RICERCA DISPONIBILI", 366, 34, 15)
	b2.pressed.connect(_cards_popup)
	ric_box.add_child(b2)


func _on_log(t: String) -> void:
	log_all.append(t)
	var col := "#26244a"
	if t.begins_with("—"):
		col = "#c8372b"
	log_lbl.append_text("[color=%s]%s[/color]\n" % [col, t])


func _on_fx(kind: String, data: Dictionary) -> void:
	match kind:
		"place":
			board.flash(D.T_SLOT_POS[int(data["t"])][int(data["i"])], D.FAC_COLOR[int(data["f"])])
		"conquest":
			var t := int(data["t"])
			board.flash(D.T_CTRL_POS[t], D.FAC_COLOR[int(data["f"])])
			board.flash(D.T_TILE_POS[t], D.FAC_COLOR[int(data["f"])])
		"fortress":
			board.flash(D.T_CTRL_POS[int(data["t"])], D.FAC_COLOR[0])
		"fail":
			board.flash(D.T_CTRL_POS[int(data["t"])], UI.RED)
		"berlin":
			board.flash(D.BER_POS[int(data["i"])], D.FAC_COLOR[int(data["f"])])
		"turn":
			var f := int(data["f"])
			if not _human_seat(eng.seat_of[f]):
				_idle("%s sta giocando…" % eng.pname(f))
		"part2":
			_toast("SECONDA PARTE")
		"part1":
			_toast("FINE DELLA PRIMA PARTE")


# ------------------------------------------------------------------ area azioni

func _human_seat(seat: int) -> bool:
	if eng.seats[seat]["ai"]:
		return false
	if online != null:
		return seat == online.seat
	return true


func _local_humans() -> int:
	var n := 0
	for s in eng.seats.size():
		if _human_seat(s):
			n += 1
	return n


func _idle(text: String) -> void:
	act_title.text = "IN ATTESA"
	act_text.text = text
	for c in act_body.get_children():
		c.queue_free()
	board.clear_targets()


func _act(title: String, text: String) -> VBoxContainer:
	act_title.text = title.to_upper()
	act_text.text = text
	for c in act_body.get_children():
		c.queue_free()
	board.clear_targets()
	return act_body


func _send(r) -> void:
	board.clear_targets()
	req = {}
	_idle("…")
	eng.provide_decision(r)


func _row() -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	act_body.add_child(hb)
	return hb


func _pawn_btn(pid: int, back: bool, sz: float, cb: Callable, tip := "") -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = UI.pawn(pid, back)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(sz, sz)
	b.tooltip_text = tip
	if cb.is_valid():
		b.pressed.connect(cb)
	else:
		b.disabled = true
	return b


func _fac_name(f: int) -> String:
	return D.FAC_NAME[f]


func _on_request(r: Dictionary) -> void:
	req = r
	var seat := int(r.get("seat", 0))
	var private := str(r.get("type", "")) in ["turn", "use_gift", "spy_pick", "spy_use", "swap"]
	if private and online == null and _local_humans() > 1 and seat != last_private_seat:
		_cover(seat, func():
			last_private_seat = seat
			_show_request(r))
		return
	if private:
		last_private_seat = seat
	_show_request(r)


func _cover(seat: int, then: Callable) -> void:
	var layer := Control.new()
	layer.size = size
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)
	var sh := ColorRect.new()
	sh.color = Color(UI.NAVY_DARK, 0.97)
	sh.size = size
	layer.add_child(sh)
	var vb := VBoxContainer.new()
	vb.position = Vector2(560, 380)
	vb.custom_minimum_size = Vector2(800, 0)
	vb.add_theme_constant_override("separation", 24)
	layer.add_child(vb)
	var facs := []
	for f in eng.seats[seat]["facs"]:
		facs.append(D.FAC_NAME[int(f)])
	var t := UI.label("TOCCA A %s" % str(eng.seats[seat]["name"]).to_upper(), 48, Color.WHITE, UI.font_title)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var s := UI.label("(%s) · gli altri non guardino: si vedono i retri delle pedine." % " e ".join(facs), 22, UI.CREAM)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(s)
	var b := UI.primary(UI.button("SONO PRONTO", 380, 76, 30))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func():
		layer.queue_free()
		then.call())
	vb.add_child(b)


func _show_request(r: Dictionary) -> void:
	var f := int(r["fac"])
	match str(r["type"]):
		"turn":
			_ui_turn(r)
		"use_gift":
			_ui_uses(f, int(r["p"]), true, r["options"], "PEDINA RICEVUTA", "%s ti dà questa pedina girata sul retro: devi giocarla subito come pedina %s." % [_fac_name(int(r["from"])), D.FAC_SHORT[f]], false, func(u): _send(u))
		"spy_use":
			_ui_uses(int(r["to"]), int(r["p"]), true, r["options"], "RETE DI SPIE", "Decidi come %s gioca questa pedina." % _fac_name(int(r["to"])), false, func(u): _send(u))
		"pick":
			_ui_pick(r)
		"start_cards":
			_ui_start_cards(r)
		"buy":
			_ui_cards(r["options"], "CARTA RICERCA", "Hai %d punti Ricerca: puoi acquisire una carta (il segnalino torna alla prima casella). Puoi anche aspettare." % int(D.RIC_POINTS[int(eng.S["ric"])]), "NON ORA", -1)
		"free_card":
			_ui_cards(r["options"], "CARTA RICERCA GRATIS", "La tessera ti regala una carta Ricerca di valore 1: scegli quale.", "", -1)
		"deny_card":
			_ui_cards(r["options"], "SABOTAGGIO", "La tessera ti fa scegliere una carta Ricerca di valore 1 che il tedesco deve scartare.", "", -1)
		"event_opt":
			_ui_event(r)
		"target":
			var opts := []
			for g in r["options"]:
				opts.append([D.FAC_NAME[int(g)], int(g), int(g)])
			_ui_buttons("SCEGLI UNA FAZIONE", str(r.get("why", "")), opts)
		"conf_bonus":
			var opts := []
			for i in r["options"]:
				opts.append([["Avanza in Politica", "2 PV", "Avanza nel Morale"][int(i)], int(i), -1])
			_ui_buttons("CONFERENZA", "Hai una pedina nella Conferenza: scegli il bonus di una casella ancora libera.", opts)
		"yesno":
			_ui_buttons("SCELTA", str(r.get("text", "")), [["SÌ", true, -1], ["NO", false, -1]])
		"visita":
			var opts := []
			for m in range(3, -1, -1):
				opts.append(["%d Morale + %d Politica" % [m, 3 - m], m, -1])
			_ui_buttons("VISITA DEI GENERALI", "Dividi 3 punti fra Morale e Politica.", opts)
		"ctrl_pick":
			_ui_pawns(r["options"], "CASELLA DI CONTROLLO", "Hai conquistato %s: scegli la pedina che resta sulla casella di controllo (le altre vanno negli scarti e torneranno nella seconda parte)." % D.T_NAME[int(r["t"])], f)
		"discard_start":
			_ui_pawns(r["options"], "SCARTA UNA PEDINA", str(r.get("why", "")), f)
		"spy_pick":
			_ui_pawns(r["options"], "RETE DI SPIE", "Scegli quale pedina di %s girare (vedi anche il retro)." % _fac_name(int(r["ally"])), int(r["ally"]), true)
		"swap":
			_ui_swap(r)
		"fortress":
			_ui_fortress(r)
		_:
			_send(null)


# ---------- turno

func _ui_turn(r: Dictionary) -> void:
	var f := int(r["fac"])
	var sl := int(r["self_left"])
	var gl := int(r["gift_left"])
	var parts := []
	if sl > 0:
		parts.append("%d per te" % sl)
	if gl > 0:
		parts.append("%d da dare girata a un'altra fazione" % gl)
	_act("Tocca a te · %s" % _fac_name(f), "Pedine ancora da giocare: %s. Sotto ogni pedina c'è il suo retro: chi lo riceve e cosa diventa." % " e ".join(parts))
	var hb := _row()
	hb.add_theme_constant_override("separation", 18)
	for p in r["pawns"]:
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		vb.custom_minimum_size = Vector2(240, 0)
		hb.add_child(vb)
		vb.add_child(_pawn_btn(int(p), false, 112, Callable(), D.TYPE_NAME[int(D.P_FRONT[p])]))
		var nm := UI.label(D.TYPE_NAME[int(D.P_FRONT[p])].to_upper(), 18, UI.INK, UI.font_title)
		vb.add_child(nm)
		var bk := HBoxContainer.new()
		bk.add_theme_constant_override("separation", 6)
		bk.add_child(UI.icon_rect(UI.pawn(int(p), true), Vector2(46, 46)))
		var tg := eng.gift_targets(f, int(p))
		var who := []
		for x in D.P_BACK_TO[p]:
			who.append("un Alleato a scelta" if int(x) == -1 else D.FAC_SHORT[int(x)])
		bk.add_child(UI.para("retro: %s → %s" % [D.TYPE_NAME[int(D.P_BACK[p])], " o ".join(who)], 180, 15, UI.INK2))
		vb.add_child(bk)
		var bb := HBoxContainer.new()
		bb.add_theme_constant_override("separation", 6)
		vb.add_child(bb)
		var b1 := UI.primary(UI.button("USA", 110, 44, 19))
		b1.disabled = sl <= 0
		b1.pressed.connect(func(): _ui_self(r, int(p)))
		bb.add_child(b1)
		var b2 := UI.light(UI.button("DAI", 110, 44, 19))
		b2.disabled = gl <= 0 or tg.is_empty()
		b2.pressed.connect(func(): _ui_gift(r, int(p), tg))
		bb.add_child(b2)
		if gl > 0 and not r["can_gift"]:
			var b3 := UI.button("SCARTA", 110, 40, 16)
			b3.pressed.connect(func(): _send({"k": "gdisc", "p": int(p)}))
			vb.add_child(b3)
	if r.has("rfin"):
		var rb := _row()
		rb.add_child(UI.label("Ricerca finalizzata:", 18, UI.INK, UI.font_bold))
		for c in r["rfin"]:
			var b := UI.button("SCARTA «%s» (+1 Ricerca)" % D.CARDS[c]["name"], 0, 40, 15)
			b.pressed.connect(func(): _send({"k": "rfin", "c": int(c)}))
			rb.add_child(b)
	_hint(r)


## Consiglio dell'IA (in piccolo), utile per imparare.
func _hint(r: Dictionary) -> void:
	var a := WWAI.new()
	a.level = 0
	var m = a._quick(eng, int(r["fac"]), r)
	if m is Dictionary and m.has("k"):
		var t := ""
		match str(m["k"]):
			"self":
				t = "usare %s: %s" % [D.TYPE_NAME[int(D.P_FRONT[m["p"]])], _use_text(int(r["fac"]), int(m["p"]), false, m["use"])]
			"gift":
				t = "dare %s a %s" % [D.TYPE_NAME[int(D.P_FRONT[m["p"]])], D.FAC_NAME[int(m["to"])]]
		if t != "":
			act_body.add_child(UI.para("Suggerimento: " + t + ".", 760, 16, UI.INK2, UI.font_bold))


func _ui_self(r: Dictionary, p: int) -> void:
	var f := int(r["fac"])
	_ui_uses(f, p, false, eng.legal_uses(f, p, false), "Usa %s" % D.TYPE_NAME[int(D.P_FRONT[p])], "Scegli una casella evidenziata sul tabellone oppure un'azione qui sotto.", true,
		func(u): _send({"k": "self", "p": p, "use": u}))


func _ui_gift(r: Dictionary, p: int, tg: Array) -> void:
	if tg.size() == 1:
		_send({"k": "gift", "p": p, "to": int(tg[0])})
		return
	var b := _act("Dai la pedina", "A chi la dai? Chi la riceve la gioca subito come %s." % D.TYPE_NAME[int(D.P_BACK[p])])
	var hb := _row()
	for g in tg:
		var x := UI.faction(UI.button(D.FAC_NAME[int(g)].to_upper(), 240, 56, 20), int(g))
		x.pressed.connect(func(): _send({"k": "gift", "p": p, "to": int(g)}))
		hb.add_child(x)
	var back := UI.button("INDIETRO", 180, 48, 18)
	back.pressed.connect(func(): _ui_turn(r))
	b.add_child(back)


func _use_text(f: int, p: int, back: bool, u: Dictionary) -> String:
	var t := eng.ptype(p, back)
	match str(u.get("a")):
		"place":
			var x = eng.S["terr"][int(u["t"])]["sl"][int(u["i"])]
			if x != null:
				return "%s, elimina %s %s" % [D.T_NAME[int(u["t"])], D.TYPE_NAME[int(x["t"])], D.FAC_SHORT[int(x["f"])]]
			return D.T_NAME[int(u["t"])]
		"berlin":
			return "Berlino, casella %d PV" % int(D.BER_PV[int(u["i"])])
		"share":
			return "condividi %s" % D.T_NAME[int(u["t"])]
		"conf":
			return "Conferenza (%s)" % ["Politica", "2 PV", "Morale"][int(u["i"])]
		"mor":
			return "Morale +%d" % (2 if t == D.MOR2 else 1)
		"pol":
			return "Politica +1"
		"ric":
			return "Ricerca +%d" % (2 if t == D.RIC2 else 1)
		"ricback":
			return "Ricerca tedesca −1"
		"eve":
			return "Evento «%s»" % D.EVENTS[f][eng.next_event_box(f) - 1]["name"]
	return "scartala"


func _ui_uses(f: int, p: int, back: bool, uses: Array, title: String, text: String, cancel: bool, done: Callable) -> void:
	_act(title, text)
	var top := _row()
	top.add_child(_pawn_btn(p, back, 84, Callable()))
	top.add_child(UI.para("Giocata da %s come %s." % [D.FAC_NAME[f], D.TYPE_NAME[eng.ptype(p, back)]], 560, 18, UI.INK, UI.font_bold))
	var tg := []
	var btns := HFlowContainer.new()
	btns.add_theme_constant_override("h_separation", 8)
	btns.add_theme_constant_override("v_separation", 8)
	act_body.add_child(btns)
	for u in uses:
		var a := str(u["a"])
		match a:
			"place":
				var occ = eng.S["terr"][int(u["t"])]["sl"][int(u["i"])]
				tg.append({"r": D.T_SLOT_POS[int(u["t"])][int(u["i"])], "c": USE_COL["kill" if occ != null else "place"], "data": u, "tip": _use_text(f, p, back, u)})
			"berlin":
				tg.append({"r": D.BER_POS[int(u["i"])], "c": USE_COL["berlin"], "data": u, "tip": _use_text(f, p, back, u)})
			"conf":
				tg.append({"r": D.CONF_POS[int(u["i"])], "c": USE_COL["conf"], "data": u, "tip": _use_text(f, p, back, u)})
			"share":
				tg.append({"r": D.T_TILE_POS[int(u["t"])], "c": USE_COL["share"], "data": u, "tip": _use_text(f, p, back, u)})
			_:
				var b := UI.primary(UI.button(_use_text(f, p, back, u).to_upper(), 0, 48, 17)) if a != "discard" else UI.button("SCARTA (NESSUN USO POSSIBILE)", 0, 48, 17)
				b.pressed.connect(func(): done.call(u))
				btns.add_child(b)
				if a == "eve":
					var box := eng.next_event_box(f)
					b.tooltip_text = "%s\nA: %s\nB: %s" % [D.EVENTS[f][box - 1]["name"], _eff_list(f, D.EVENTS[f][box - 1]["opt"][0]), _eff_list(f, D.EVENTS[f][box - 1]["opt"][1])]
	if not tg.is_empty():
		act_body.add_child(UI.para("Sul tabellone: verde = casella libera, rosso = elimini una pedina, oro = Berlino o Conferenza, blu = territorio da condividere. Passa il mouse per i dettagli.", 760, 16, UI.INK2))
	board.set_targets(tg)
	_on_board_pick = done
	if cancel:
		var b := UI.button("INDIETRO", 180, 46, 18)
		b.pressed.connect(func():
			_on_board_pick = Callable()
			_ui_turn(req))
		act_body.add_child(b)


var _on_board_pick: Callable


func _on_target(data: Dictionary) -> void:
	if _on_board_pick.is_valid():
		var cb := _on_board_pick
		_on_board_pick = Callable()
		cb.call(data)


func _eff_list(f: int, effs: Array) -> String:
	var out := []
	for e in effs:
		out.append(eng.event_effect_text(f, e))
	return ", ".join(out)


# ---------- scelte semplici

func _ui_buttons(title: String, text: String, opts: Array) -> void:
	_act(title, text)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 10)
	fl.add_theme_constant_override("v_separation", 10)
	act_body.add_child(fl)
	for o in opts:
		var b := UI.button(str(o[0]).to_upper(), 230, 56, 19)
		if int(o[2]) >= 0:
			UI.faction(b, int(o[2]))
		else:
			UI.primary(b)
		b.pressed.connect(func(): _send(o[1]))
		fl.add_child(b)


func _ui_pawns(opts: Array, title: String, text: String, f: int, show_back := false) -> void:
	_act(title, text)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 12)
	act_body.add_child(fl)
	for p in opts:
		var vb := VBoxContainer.new()
		# sul tabellone una pedina ricevuta mostra il retro
		var bk := D.owner(int(p)) != f and not show_back
		var tname: String = D.TYPE_NAME[eng.ptype(int(p), bk)]
		vb.add_child(_pawn_btn(int(p), bk, 92, func(): _send(int(p)), tname))
		if show_back:
			vb.add_child(UI.icon_rect(UI.pawn(int(p), true), Vector2(56, 56)))
		vb.add_child(UI.label(tname, 15, UI.INK, UI.font_bold))
		fl.add_child(vb)


func _ui_event(r: Dictionary) -> void:
	var f := int(r["fac"])
	var box := int(r["box"])
	var ev: Dictionary = D.EVENTS[f][box - 1]
	_act("Evento: %s" % ev["name"], "Scegli quale dei due effetti applicare.")
	var hb := _row()
	hb.add_child(UI.icon_rect(UI.event_box(f, box), Vector2(330, 223)))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	hb.add_child(vb)
	for o in 2:
		var b := UI.primary(UI.button(("A: " if o == 0 else "B: ") + _eff_list(f, ev["opt"][o]), 400, 64, 18))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func(): _send(o))
		vb.add_child(b)
	vb.add_child(UI.para("A è la colonna di sinistra della casella, B quella di destra. «a scelta»: decidi tu chi colpire.", 400, 15, UI.INK2))


func _ui_cards(opts: Array, title: String, text: String, no_label: String, _x) -> void:
	_act(title, text)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 10)
	fl.add_theme_constant_override("v_separation", 10)
	act_body.add_child(fl)
	for c in opts:
		var b := TextureButton.new()
		b.texture_normal = UI.card(int(c))
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
		b.custom_minimum_size = Vector2(240, 173)
		b.tooltip_text = "%s (valore %d, costo %d)\n%s" % [D.CARDS[c]["name"], int(D.CARDS[c]["lvl"]), eng.card_cost(int(c)), D.CARDS[c]["text"]]
		b.pressed.connect(func(): _send(int(c)))
		fl.add_child(b)
	if no_label != "":
		var n := UI.button(no_label, 220, 50, 19)
		n.pressed.connect(func(): _send(-1))
		act_body.add_child(n)


func _ui_start_cards(r: Dictionary) -> void:
	var chosen := []
	_act("Carte Ricerca iniziali", "Scegli due carte di valore 1 oppure una di valore 2: i loro effetti valgono subito.")
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	act_body.add_child(fl)
	var ok := UI.primary(UI.button("CONFERMA", 220, 50, 20))
	var btns := {}
	var paint := func():
		for c in btns:
			btns[c].modulate = Color(1, 1, 1) if c in chosen else Color(0.72, 0.72, 0.72)
		var l1 := 0
		var l2 := 0
		for c in chosen:
			if int(D.CARDS[c]["lvl"]) == 1:
				l1 += 1
			else:
				l2 += 1
		ok.disabled = not ((l1 == 2 and l2 == 0) or (l1 == 0 and l2 == 1))
	for c in r["l1"] + r["l2"]:
		var b := TextureButton.new()
		b.texture_normal = UI.card(int(c))
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
		b.custom_minimum_size = Vector2(182, 131)
		b.tooltip_text = "%s (valore %d)\n%s" % [D.CARDS[c]["name"], int(D.CARDS[c]["lvl"]), D.CARDS[c]["text"]]
		b.pressed.connect(func():
			if c in chosen:
				chosen.erase(c)
			else:
				chosen.append(c)
			paint.call())
		btns[c] = b
		fl.add_child(b)
	ok.pressed.connect(func(): _send(chosen.duplicate()))
	act_body.add_child(ok)
	paint.call()


func _ui_pick(r: Dictionary) -> void:
	var f := int(r["fac"])
	var n := int(r["n"])
	var types: Dictionary = r["types"]
	var keep: bool = r.get("keep", false)
	var chosen := []
	var title := "Prepara il prossimo turno" if not keep else "Seconda parte: 12 pedine"
	var text := ("Scegli %d pedine dalla riserva per la tua area di partenza. Vedi solo il fronte: il retro si scopre dopo." % n) if not keep else "Hai più di 12 pedine: scegli le 12 da tenere (alla cieca, guardando solo il fronte)."
	_act(title, text)
	var sample := {}
	for p in eng.reserve(f):
		var t := int(D.P_FRONT[p])
		if not sample.has(t):
			sample[t] = p
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	act_body.add_child(fl)
	var sel_row := HBoxContainer.new()
	sel_row.add_theme_constant_override("separation", 6)
	var ok := UI.primary(UI.button("CONFERMA", 200, 50, 20))
	var count_lbls := {}
	var redraw_sel := func(): pass
	redraw_sel = func():
		for c in sel_row.get_children():
			c.queue_free()
		for i in chosen.size():
			var t: int = chosen[i]
			var idx := i
			sel_row.add_child(_pawn_btn(int(sample[t]), false, 54, func():
				chosen.remove_at(idx)
				redraw_sel.call(), "Togli"))
		for t in count_lbls:
			count_lbls[t].text = "×%d" % (int(types[t]) - chosen.count(int(t)))
		ok.disabled = chosen.size() != n
	for t in types:
		var vb := VBoxContainer.new()
		var tt := int(t)
		vb.add_child(_pawn_btn(int(sample[tt]), false, 72, func():
			if chosen.size() < n and chosen.count(tt) < int(types[t]):
				chosen.append(tt)
				redraw_sel.call(), D.TYPE_NAME[tt]))
		var l := UI.label("", 17, UI.INK, UI.font_cond_bold)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbls[t] = l
		vb.add_child(l)
		fl.add_child(vb)
	act_body.add_child(UI.label("Scelte:", 18, UI.INK, UI.font_bold))
	act_body.add_child(sel_row)
	var hb := _row()
	ok.pressed.connect(func(): _send(chosen.duplicate()))
	hb.add_child(ok)
	var auto := UI.button("SCEGLI TU PER ME", 240, 50, 17)
	auto.pressed.connect(func():
		var a := WWAI.new()
		_send(a._pick_types(eng, f, r)))
	hb.add_child(auto)
	redraw_sel.call()


func _ui_swap(r: Dictionary) -> void:
	var n := int(r["n"])
	var take := []
	var give := []
	_act("Sostituzione dei generali", "Scegli %d pedine dai tuoi scarti da riportare nella riserva e %d tipi di pedina della riserva da scartare al loro posto." % [n, n])
	act_body.add_child(UI.label("Dagli scarti:", 18, UI.INK, UI.font_bold))
	var a := HFlowContainer.new()
	act_body.add_child(a)
	act_body.add_child(UI.label("Dalla riserva:", 18, UI.INK, UI.font_bold))
	var b := HFlowContainer.new()
	act_body.add_child(b)
	var ok := UI.primary(UI.button("CONFERMA", 200, 50, 20))
	var upd := func():
		ok.disabled = take.size() != n or give.size() != n
	for p in r["disc"]:
		var btn := _pawn_btn(int(p), false, 60, Callable())
		btn.disabled = false
		btn.pressed.connect(func():
			if p in take:
				take.erase(p)
				btn.modulate = Color.WHITE
			elif take.size() < n:
				take.append(p)
				btn.modulate = Color(0.6, 1.0, 0.6)
			upd.call())
		a.add_child(btn)
	var sample := {}
	for p in eng.reserve(0):
		sample[int(D.P_FRONT[p])] = p
	for t in r["res_types"]:
		var btn := _pawn_btn(int(sample[int(t)]), false, 60, Callable())
		btn.disabled = false
		btn.pressed.connect(func():
			if int(t) in give:
				give.erase(int(t))
				btn.modulate = Color.WHITE
			elif give.size() < n:
				give.append(int(t))
				btn.modulate = Color(1.0, 0.6, 0.6)
			upd.call())
		b.add_child(btn)
	ok.pressed.connect(func(): _send({"disc": take.duplicate(), "res": give.duplicate()}))
	act_body.add_child(ok)
	upd.call()


func _ui_fortress(r: Dictionary) -> void:
	var pawn := [-1]
	_act("Nuova Fortezza", "Scegli la pedina scartata da mettere sulla casella di controllo, poi il territorio sul tabellone.")
	var fl := HFlowContainer.new()
	act_body.add_child(fl)
	var tg := []
	for t in r["terr"]:
		tg.append({"r": D.T_CTRL_POS[int(t)], "c": UI.RED, "data": {"t": int(t)}, "tip": D.T_NAME[int(t)]})
	for p in r["pawns"]:
		var btn := _pawn_btn(int(p), false, 64, Callable(), D.TYPE_NAME[int(D.P_FRONT[p])])
		btn.disabled = false
		btn.pressed.connect(func():
			pawn[0] = int(p)
			for c in fl.get_children():
				c.modulate = Color(0.6, 0.6, 0.6)
			btn.modulate = Color.WHITE
			board.set_targets(tg)
			_on_board_pick = func(d): _send({"t": int(d["t"]), "p": pawn[0]}))
		fl.add_child(btn)


# ------------------------------------------------------------------ finestre

func _popup(title: String, w := 1200.0, h := 860.0) -> VBoxContainer:
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = Control.new()
	overlay.size = size
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var sh := ColorRect.new()
	sh.color = Color(0, 0, 0, 0.7)
	sh.size = size
	sh.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			overlay.queue_free())
	overlay.add_child(sh)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.paper(20))
	p.position = (size - Vector2(w, h)) * 0.5
	p.custom_minimum_size = Vector2(w, h)
	p.size = Vector2(w, h)
	overlay.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	var top := HBoxContainer.new()
	top.add_child(UI.banner(title, 26))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var x := UI.button("CHIUDI", 140, 44, 18)
	x.pressed.connect(func(): overlay.queue_free())
	top.add_child(x)
	vb.add_child(top)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(w - 40, h - 100)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.custom_minimum_size = Vector2(w - 60, 0)
	sc.add_child(body)
	return body


func _card_zoom(c: int) -> void:
	var b := _popup(D.CARDS[c]["name"], 760, 700)
	b.add_child(UI.icon_rect(UI.card(c), Vector2(700, 505)))
	b.add_child(UI.para("Valore %d · costo attuale %d. %s" % [int(D.CARDS[c]["lvl"]), eng.card_cost(c), D.CARDS[c]["text"]], 690, 19))


func _cards_popup() -> void:
	var b := _popup("Carte Ricerca", 1500, 960)
	b.add_child(UI.para("Il tedesco compra una carta di valore pari o inferiore ai suoi punti Ricerca (una per turno); poi il segnalino torna alla prima casella. Passa il mouse su una carta per leggerla, clic per ingrandirla.", 1420, 18))
	for l in 3:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var bk := UI.icon_rect(UI.card_back(l + 1), Vector2(190, 137))
		bk.tooltip_text = "Mazzo di valore %d: %d carte" % [l + 1, eng.S["cdeck"][l].size()]
		bk.mouse_filter = Control.MOUSE_FILTER_PASS
		hb.add_child(bk)
		for c in eng.S["cdisp"][l]:
			var t := TextureButton.new()
			t.texture_normal = UI.card(int(c))
			t.ignore_texture_size = true
			t.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
			t.custom_minimum_size = Vector2(290, 209)
			t.tooltip_text = "%s (costo %d)\n%s" % [D.CARDS[c]["name"], eng.card_cost(int(c)), D.CARDS[c]["text"]]
			t.pressed.connect(func(): _card_zoom(int(c)))
			hb.add_child(t)
		b.add_child(hb)
	if not eng.S["cards"].is_empty():
		b.add_child(UI.banner("Carte del tedesco", 20, UI.RED))
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 8)
		for c in eng.S["cards"]:
			var t := TextureButton.new()
			t.texture_normal = UI.card(int(c))
			t.ignore_texture_size = true
			t.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
			t.custom_minimum_size = Vector2(230, 166)
			t.tooltip_text = "%s\n%s" % [D.CARDS[c]["name"], D.CARDS[c]["text"]]
			t.pressed.connect(func(): _card_zoom(int(c)))
			fl.add_child(t)
		b.add_child(fl)


func _faction_popup(f: int) -> void:
	var S := eng.S
	var b := _popup("%s" % D.FAC_NAME[f], 1240, 900)
	var line := "PV %d · Morale %d (vale %d PV a conquista) · Politica %d" % [int(S["pv"][f]), int(S["mor"][f]), int(D.MOR_PV[int(S["mor"][f])]), int(S["pol"][f])]
	if f == 0:
		line += " · Ricerca %d (punti %d)" % [int(S["ric"]), int(D.RIC_POINTS[int(S["ric"])])]
	b.add_child(UI.label(line, 22, UI.INK, UI.font_title))
	if f != 0:
		b.add_child(UI.banner("Tracciato Eventi (posizione %d di 6)" % int(S["eve"][f]), 20, D.FAC_COLOR[f].darkened(0.2)))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		for k in 6:
			var box := k + 1
			var vb := VBoxContainer.new()
			var im := UI.icon_rect(UI.event_box(f, box), Vector2(330, 223))
			if box <= int(S["eve"][f]):
				im.modulate = Color(0.55, 0.55, 0.55)
			vb.add_child(im)
			var ev: Dictionary = D.EVENTS[f][k]
			var reqs := []
			for t in ev["req"]:
				reqs.append(D.TYPE_NAME[int(t)])
			vb.add_child(UI.para("%d. %s · si scarta: %s o Simbolo\nA: %s\nB: %s" % [box, ev["name"], " o ".join(reqs), _eff_list(f, ev["opt"][0]), _eff_list(f, ev["opt"][1])], 360, 15))
			grid.add_child(vb)
		b.add_child(grid)
	else:
		b.add_child(UI.banner("Tracciato Ricerca", 20, UI.NAVY))
		b.add_child(UI.para("Casella di partenza → prima casella (nessun punto) → 1 → 2 → 3 punti → ultima casella (3 punti e 5 PV quando si compra). Scartando una pedina Ricerca (o Simbolo Fazione) si avanza; gli Alleati la fanno arretrare con le pedine Aviazione e con alcuni Eventi e tessere.", 1160, 18))
		if not S["start"][0].is_empty():
			b.add_child(UI.banner("Pedine sulla scheda Fazione (fronte)", 20, UI.NAVY))
			var hb0 := HBoxContainer.new()
			for p in S["start"][0]:
				hb0.add_child(UI.icon_rect(UI.pawn(int(p)), Vector2(80, 80)))
			b.add_child(hb0)
	b.add_child(UI.banner("Riserva", 20, UI.NAVY))
	var rt := eng.reserve_types(f)
	var hb := HFlowContainer.new()
	hb.add_theme_constant_override("h_separation", 12)
	var sample := {}
	for p in eng.reserve(f):
		sample[int(D.P_FRONT[p])] = p
	for t in rt:
		var vb := VBoxContainer.new()
		vb.add_child(UI.icon_rect(UI.pawn(int(sample[t])), Vector2(64, 64)))
		var l := UI.label("×%d" % int(rt[t]), 17, UI.INK, UI.font_cond_bold)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(l)
		hb.add_child(vb)
	if rt.is_empty():
		hb.add_child(UI.label("vuota", 18))
	b.add_child(hb)
	b.add_child(UI.banner("Scarti (%d)" % eng.discards(f).size(), 20, UI.NAVY))
	var dh := HFlowContainer.new()
	for p in eng.discards(f):
		dh.add_child(UI.icon_rect(UI.pawn(int(p)), Vector2(48, 48)))
	b.add_child(dh)
	if not S["tiles"][f].is_empty():
		b.add_child(UI.banner("Tessere Territorio", 20, UI.NAVY))
		var th := HFlowContainer.new()
		th.add_theme_constant_override("h_separation", 8)
		for t in S["tiles"][f]:
			th.add_child(UI.icon_rect(UI.tile(int(t)), Vector2(120, 80)))
		b.add_child(th)


func _log_popup() -> void:
	var b := _popup("Diario della partita", 1100, 900)
	var rt := RichTextLabel.new()
	rt.custom_minimum_size = Vector2(1040, 760)
	rt.add_theme_font_override("normal_font", UI.font_type)
	rt.add_theme_font_size_override("normal_font_size", 18)
	rt.scroll_following = true
	for t in log_all:
		rt.append_text(("[color=#c8372b]%s[/color]\n" if t.begins_with("—") else "%s\n") % t)
	b.add_child(rt)


func _rules_popup() -> void:
	var b := _popup("Regole in breve", 1300, 960)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(1240, 0)
	rt.append_text(RulesText.TEXT)
	b.add_child(rt)


func _menu_confirm() -> void:
	var b := _popup("Tornare al menu?", 700, 300)
	b.add_child(UI.para("La partita in corso andrà persa." if online == null else "Esci dalla partita online (potrai rientrare con lo stesso codice).", 640, 20))
	var ok := UI.primary(UI.button("SÌ, AL MENU", 260, 56, 20))
	ok.pressed.connect(func():
		eng.abort = true
		main.show_menu())
	b.add_child(ok)


func _toast(text: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.flat(UI.RED, Color.WHITE, 3, 14, 20))
	var l := UI.label(text, 40, Color.WHITE, UI.font_title)
	p.add_child(l)
	p.position = Vector2(300, 470)
	add_child(p)
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


func _on_end(res: Dictionary) -> void:
	if online != null:
		online.finish()
	_idle("Partita finita.")
	var b := _popup("Fine della guerra", 1180, 560)
	var names := []
	for w in res["winners"]:
		names.append(D.FAC_NAME[int(w)])
	b.add_child(UI.label("VINCE: %s" % " E ".join(names).to_upper(), 34, UI.RED, UI.font_title))
	if eng.two():
		b.add_child(UI.para("Partita a due: conta la fazione più debole di ogni giocatore. Giocatore A (Regno Unito e URSS): %d · Giocatore B (Stati Uniti e Germania): %d." % [int(res["teams"][0]), int(res["teams"][1])], 1100, 20))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 8)
	for h in ["FAZIONE", "PV IN PARTITA", "TERRITORI", "POLITICA", "BERLINO", "CARTE", "TOTALE"]:
		grid.add_child(UI.label(h, 18, UI.INK2, UI.font_title))
	var br: Dictionary = res["breakdown"]
	var order := [0, 1, 2, 3]
	order.sort_custom(func(a, c): return int(br[a]["total"]) > int(br[c]["total"]))
	for f in order:
		var x: Dictionary = br[f]
		grid.add_child(UI.label(D.FAC_NAME[f], 22, D.FAC_COLOR[f].darkened(0.3), UI.font_title))
		for k in ["base", "terr", "pol", "berlin", "cards"]:
			grid.add_child(UI.label(str(int(x[k])), 22, UI.INK, UI.font_cond_bold))
		grid.add_child(UI.label(str(int(x["total"])), 26, UI.RED, UI.font_cond_bold))
	b.add_child(grid)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	var m := UI.primary(UI.button("MENU", 220, 56, 22))
	m.pressed.connect(func(): main.show_menu())
	hb.add_child(m)
	var v := UI.button("GUARDA IL TABELLONE", 300, 56, 20)
	v.pressed.connect(func(): overlay.queue_free())
	hb.add_child(v)
	b.add_child(hb)


# ------------------------------------------------------------------ online

func online_caught_up() -> void:
	net_lbl.text = "Partita ripresa."


func online_cancel_decision(text: String) -> void:
	_idle(text)
	net_lbl.text = text


func online_status(text: String) -> void:
	net_lbl.text = text


func online_waiting(seat: int, slow: bool) -> void:
	if seat < 0:
		net_lbl.text = ""
		return
	net_lbl.text = "Online: aspetto %s%s" % [eng.seats[seat]["name"], " (risponde lentamente…)" if slow else "…"]
