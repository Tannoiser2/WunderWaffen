class_name WWBoard
extends Control
## Il tabellone: mappa ricomposta dalle scansioni, con sopra pedine, tessere, segnalini e le caselle
## evidenziate quando bisogna scegliere dove giocare. Rotella = zoom, trascinamento = spostamento,
## doppio clic = vista intera.

signal target_clicked(t: Dictionary)

const D = preload("res://scripts/data/ww_data.gd")

var eng: WWEngine
var B := 1056.0                  # lato del tabellone a zoom 1
var zoom := 1.0
var off := Vector2.ZERO
var targets: Array = []          # {r: Rect2 normalizzato, c: Color, data: Dictionary, label}
var hover := -1
var flashes: Array = []          # {r, c, t}
var _press_pos := Vector2.ZERO
var _pressing := false
var _dragged := false
var _t := 0.0
var tex_board: Texture2D


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	tex_board = UI.tex("res://assets/board/tabellone.jpg")
	B = size.x


func set_targets(list: Array) -> void:
	targets = list
	hover = -1
	queue_redraw()


func clear_targets() -> void:
	set_targets([])


func flash(r: Rect2, c: Color) -> void:
	flashes.append({"r": r, "c": c, "t": 1.6})
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if not flashes.is_empty():
		for f in flashes:
			f["t"] = float(f["t"]) - delta
		flashes = flashes.filter(func(f): return float(f["t"]) > 0.0)
		queue_redraw()
	elif not targets.is_empty():
		queue_redraw()


func _px(r: Rect2) -> Rect2:
	return Rect2(r.position * B, r.size * B)


func _to_board(p: Vector2) -> Vector2:
	return (p - off) / zoom / B


func _clamp_off() -> void:
	var lim := B * zoom - size.x
	off.x = clampf(off.x, -lim, 0.0)
	off.y = clampf(off.y, -(B * zoom - size.y), 0.0)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var old := zoom
			zoom = clampf(zoom * (1.15 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), 1.0, 3.2)
			off = mb.position - (mb.position - off) * (zoom / old)
			_clamp_off()
			queue_redraw()
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				if mb.double_click:
					zoom = 1.0
					off = Vector2.ZERO
					queue_redraw()
					return
				_pressing = true
				_dragged = false
				_press_pos = mb.position
			else:
				_pressing = false
				if not _dragged and mb.button_index == MOUSE_BUTTON_LEFT:
					var i := _hit(mb.position)
					if i >= 0:
						target_clicked.emit(targets[i]["data"])
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if _pressing and (mm.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT)) != 0:
			if _dragged or mm.position.distance_to(_press_pos) > 8.0:
				_dragged = true
				off += mm.relative
				_clamp_off()
				queue_redraw()
		var h := _hit(mm.position)
		if h != hover:
			hover = h
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if h >= 0 else Control.CURSOR_ARROW
			queue_redraw()


func _hit(p: Vector2) -> int:
	var q := _to_board(p)
	for i in range(targets.size() - 1, -1, -1):
		var r: Rect2 = targets[i]["r"]
		if r.grow(0.004).has_point(q):
			return i
	return -1


## Descrizione del territorio sotto il mouse.
func _get_tooltip(at: Vector2) -> String:
	if eng == null:
		return ""
	var i := _hit(at)
	if i >= 0 and str(targets[i].get("tip", "")) != "":
		return str(targets[i]["tip"])
	var q := _to_board(at)
	var best := -1
	var bd := 1e9
	for t in D.T_KEY.size():
		var d: float = (D.T_CENTER[t] as Vector2).distance_to(q)
		if d < bd:
			bd = d
			best = t
	if best < 0 or bd > 0.09:
		return ""
	return terr_text(best)


func terr_text(t: int) -> String:
	var T: Dictionary = eng.S["terr"][t]
	var lines := [D.T_NAME[t].to_upper()]
	if t == D.BERLIN:
		lines.append("Si entra quando almeno 4 territori confinanti sono degli Alleati (ora %d)." % eng.allied_around_berlin())
		lines.append("Solo Corazzati, Simbolo Fazione e Politica, e non le pedine ricevute.")
		return "\n".join(lines)
	if T["al"]:
		lines.append("Conquistato da: %s" % D.FAC_NAME[int(T["ctrl"])])
	elif T["fort"]:
		lines.append("Fortezza tedesca (pedina di controllo: %s, forza %d)" % [D.TYPE_NAME[int(T["cp"]["t"])], int(T["cp"]["s"])])
	else:
		lines.append("Controllato dalla Germania")
	var tile := int(T["tile"])
	if tile >= 0:
		var b := []
		if int(D.TILE_PV[tile]) > 0:
			b.append("%d PV" % int(D.TILE_PV[tile]))
		for x in D.TILE_BONUS[tile]:
			b.append({"ric": "Ricerca", "pol": "Politica", "mor": "Morale", "eve": "Eventi", "card": "carta Ricerca"}[x])
		lines.append("Tessera: " + " + ".join(b))
	var sl := []
	for i in 3:
		var x = T["sl"][i]
		var need: int = D.T_SLOTS[t][i]
		if x == null:
			sl.append("libera" if need == 0 else "serve %s" % D.TYPE_NAME[need])
		else:
			sl.append("%s %s" % [D.TYPE_NAME[int(x["t"])], D.FAC_SHORT[int(x["f"])]])
	lines.append("Caselle: " + " · ".join(sl))
	var nb := []
	for a in D.T_ADJ[t]:
		nb.append(D.T_NAME[a])
	lines.append("Confina con: " + ", ".join(nb))
	return "\n".join(lines)


# ------------------------------------------------------------------ disegno

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UI.NAVY_DARK)
	draw_set_transform(off, 0.0, Vector2(zoom, zoom))
	draw_texture_rect(tex_board, Rect2(0, 0, B, B), false)
	if eng == null or eng.S.is_empty():
		return
	var S := eng.S
	for t in D.T_KEY.size():
		var T: Dictionary = S["terr"][t]
		if t == D.BERLIN:
			continue
		if int(T["tile"]) >= 0:
			var tr := _px(D.T_TILE_POS[t]).grow(-1.0)
			draw_texture_rect(UI.tile(int(T["tile"])), tr, false)
		for i in 3:
			var x = T["sl"][i]
			if x != null:
				_pawn(int(x["p"]), int(x["f"]), _px(D.T_SLOT_POS[t][i]))
		if T["cp"] != null:
			var cr := _px(D.T_CTRL_POS[t])
			_pawn(int(T["cp"]["p"]), int(T["cp"]["f"]), cr)
			_cube(cr, int(T["ctrl"]) if T["al"] else 0, T["fort"])
		var k := 0
		for sh in T["share"]:
			var base := _px(D.T_TILE_POS[t])
			var r := Rect2(base.position + Vector2(base.size.x + 3 + k * 22, base.size.y * 0.15), Vector2(base.size.y * 0.7, base.size.y * 0.7))
			_pawn(int(sh["p"]), int(sh["f"]), r)
			k += 1
	# Berlino
	for i in 6:
		var b = S["ber"][i]
		if b != null:
			_pawn(int(b["p"]), int(b["f"]), _px(D.BER_POS[i]))
	if S["berx"].size() > 0:
		var r := _px(D.BER_POS[5])
		_badge(r.position + Vector2(r.size.x - 4, 4), "+%d" % S["berx"].size(), UI.RED)
	# Conferenza
	for i in 3:
		var c = S["conf"][i]
		if c != null:
			_pawn(int(c["p"]), int(c["f"]), _px(D.CONF_POS[i]))
	if S["conf_closed"]:
		var a := _px(D.CONF_POS[0])
		var z := _px(D.CONF_POS[2])
		draw_line(a.position + Vector2(0, a.size.y + 4), z.end + Vector2(0, 4), UI.RED, 3.0)
	# aree di partenza alleate (si vede il fronte)
	for f in [D.USSR, D.USA, D.UK]:
		var k := 0
		for p in S["start"][f]:
			if k < 3:
				_pawn(int(p), f, _px(D.START_POS[f][k]), false)
			k += 1
	# tracciati
	_track(S["pol"], S["pst"], D.POL_POS, "politica")
	_track(S["mor"], S["mst"], D.MOR_POS, "morale")
	_pv_track()
	# caselle selezionabili
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	for i in targets.size():
		var tg: Dictionary = targets[i]
		var r := _px(tg["r"]).grow(3.0)
		var c: Color = tg.get("c", UI.GREEN)
		var on := i == hover
		draw_rect(r, Color(c, 0.18 + (0.25 if on else 0.1 * pulse)), true)
		draw_rect(r, Color(c, 0.95), false, 4.0 if on else 2.5 + pulse)
	for f in flashes:
		var r := _px(f["r"]).grow(4.0)
		var a := clampf(float(f["t"]) / 1.6, 0.0, 1.0)
		draw_rect(r, Color(f["c"], 0.35 * a), true)
		draw_rect(r, Color(f["c"], a), false, 4.0)


func _is_back(p: int, f: int) -> bool:
	return D.owner(p) != f


func _pawn(p: int, f: int, r: Rect2, auto_back := true) -> void:
	var back := _is_back(p, f) if auto_back else false
	var rr := r.grow(-1.5)
	draw_rect(Rect2(rr.position + Vector2(2, 3), rr.size), Color(0, 0, 0, 0.35), true)
	draw_texture_rect(UI.pawn(p, back), rr, false)


func _cube(r: Rect2, f: int, fort: bool) -> void:
	var s := r.size.x * 0.32
	var c := Rect2(r.end - Vector2(s, s) * 0.85, Vector2(s, s))
	draw_rect(Rect2(c.position + Vector2(1, 2), c.size), Color(0, 0, 0, 0.4), true)
	draw_rect(c, D.FAC_COLOR[f] if not fort else Color("#4b4d4a"), true)
	draw_rect(c, Color(1, 1, 1, 0.8), false, 1.5)


func _badge(pos: Vector2, text: String, col: Color) -> void:
	var f := UI.font_title
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 10
	var r := Rect2(pos - Vector2(w * 0.5, 0), Vector2(w, 20))
	draw_rect(r, col, true)
	draw_string(f, r.position + Vector2(5, 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)


func _track(vals: Array, stamps: Array, pos: Array, kind: String) -> void:
	var order := [0, 1, 2, 3]
	order.sort_custom(func(a, b): return int(stamps[a]) < int(stamps[b]))
	var count := {}
	for f in order:
		var v := int(vals[f])
		var k := int(count.get(v, 0))
		count[v] = k + 1
		var r := _px(pos[v])
		var s := r.size * 0.62
		var p := r.position + Vector2(r.size.x * 0.08 + k * 5.0, r.size.y * 0.30 - k * 5.0)
		draw_rect(Rect2(p + Vector2(1, 2), s), Color(0, 0, 0, 0.35), true)
		draw_texture_rect(UI.marker(f, kind), Rect2(p, s), false)


func _pv_track() -> void:
	var count := {}
	for f in [0, 1, 2, 3]:
		var v := int(eng.S["pv"][f]) % 76
		var k := int(count.get(v, 0))
		count[v] = k + 1
		var c: Vector2 = D.PV_POS[v] * B
		var s := D.PV_CELL * B * 0.66
		var p := c - Vector2(s, s) * 0.5 + Vector2(k * 4.0, -k * 4.0)
		draw_rect(Rect2(p + Vector2(1, 2), Vector2(s, s)), Color(0, 0, 0, 0.35), true)
		draw_texture_rect(UI.marker(f, "pv"), Rect2(p, Vector2(s, s)), false)
