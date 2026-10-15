class_name UI
extends RefCounted
## Stile grafico di WunderWaffen, ripreso dal regolamento: pagine blu notte, schede di carta
## grezza color crema, titoli in maiuscolo pieno e rotondo (Nunito Black), numeri e didascalie
## condensati come i manifesti di guerra (Oswald), diario scritto a macchina (Special Elite).

const NAVY := Color("#26244a")
const NAVY2 := Color("#33305e")
const NAVY_DARK := Color("#17162e")
const PAPER := Color("#ebe2cf")
const PAPER2 := Color("#d9ceb6")
const INK := Color("#26244a")
const INK2 := Color("#5a5670")
const RED := Color("#c8372b")
const RED_DARK := Color("#8f2219")
const OLIVE := Color("#6f7a3a")
const GREEN := Color("#3f8f3a")
const GOLD := Color("#e0b046")
const CREAM := Color("#f4ecd9")

static var _tex := {}
static var font_title: Font
static var font_body: Font
static var font_bold: Font
static var font_cond: Font
static var font_cond_bold: Font
static var font_type: Font
static var font_stencil: Font


static func init_fonts() -> void:
	if font_title != null:
		return
	font_title = load("res://assets/fonts/Nunito-Black.ttf")
	font_body = load("res://assets/fonts/Nunito-Medium.ttf")
	font_bold = load("res://assets/fonts/Nunito-Bold.ttf")
	font_cond = load("res://assets/fonts/Oswald-SemiBold.ttf")
	font_cond_bold = load("res://assets/fonts/Oswald-Bold.ttf")
	font_type = load("res://assets/fonts/SpecialElite-Regular.ttf")
	font_stencil = load("res://assets/fonts/BlackOpsOne-Regular.ttf")


static func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path)
	return _tex[path]


static func pawn(pid: int, back := false) -> Texture2D:
	return tex(WWData.pawn_tex_path(pid, back))


static func marker(fac: int, kind: String) -> Texture2D:
	return tex("res://assets/markers/%s_%s.png" % [WWData.FAC_KEY[fac], kind])


static func tile(i: int) -> Texture2D:
	return tex("res://assets/tiles/t%02d.png" % i)


static func card(c: int) -> Texture2D:
	return tex("res://assets/cards/c%02d.jpg" % c)


static func card_back(lvl: int) -> Texture2D:
	return tex("res://assets/cards/back%d.jpg" % lvl)


static func event_box(fac: int, box: int) -> Texture2D:
	return tex("res://assets/sheets/ev_%s_%d.jpg" % [WWData.FAC_KEY[fac], box])


## Riquadro piatto.
static func flat(bg: Color, border := Color(0, 0, 0, 0), bw := 0, radius := 8, margin := 10.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


## Scheda di carta grezza (come le pagine del regolamento).
static func paper(margin := 16.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex("res://assets/ui/paper.jpg")
	sb.set_texture_margin_all(2)
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.set_content_margin_all(margin)
	return sb


static func label(text: String, size := 20, col := INK, font: Font = null) -> Label:
	init_fonts()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if font != null:
		l.add_theme_font_override("font", font)
	return l


static func title(text: String, size := 34, col := INK) -> Label:
	return label(text.to_upper(), size, col, font_title)


## Testo che va a capo da solo, largo w.
static func para(text: String, w: float, size := 19, col := INK, font: Font = null) -> Label:
	var l := label(text, size, col, font)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(w, 0)
	return l


## Intestazione bianca su striscia blu, come i capitoli del regolamento.
static func banner(text: String, size := 26, bg := NAVY) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := flat(bg, Color(1, 1, 1, 0.25), 2, 10, 6)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	p.add_theme_stylebox_override("panel", sb)
	var l := label(text.to_upper(), size, CREAM, font_title)
	p.add_child(l)
	return p


static func icon_rect(t: Texture2D, sz: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = sz
	r.size = sz
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func button(text: String, w := 200.0, h := 52.0, size := 22) -> Button:
	init_fonts()
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, h)
	b.add_theme_font_size_override("font_size", size)
	return b


static func _skin(b: Button, bg: Color, hover: Color, fg: Color) -> Button:
	b.add_theme_stylebox_override("normal", flat(bg, bg.darkened(0.35), 2, 10, 8))
	b.add_theme_stylebox_override("hover", flat(hover, hover.darkened(0.35), 2, 10, 8))
	b.add_theme_stylebox_override("pressed", flat(bg.darkened(0.2), bg.darkened(0.4), 2, 10, 8))
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	return b


## Pulsante principale (rosso del manifesto).
static func primary(b: Button) -> Button:
	return _skin(b, RED, Color("#de4a3b"), CREAM)


## Pulsante chiaro (carta).
static func light(b: Button) -> Button:
	return _skin(b, PAPER, Color("#fff6e2"), INK)


## Pulsante colorato di fazione.
static func faction(b: Button, f: int) -> Button:
	var c: Color = WWData.FAC_COLOR[f]
	return _skin(b, c.darkened(0.15), c, Color.WHITE)


static func make_theme() -> Theme:
	init_fonts()
	var th := Theme.new()
	th.default_font = font_body
	th.default_font_size = 20
	th.set_stylebox("normal", "Button", flat(NAVY2, Color("#5a5690"), 2, 10, 8))
	th.set_stylebox("hover", "Button", flat(Color("#45417a"), Color("#8a86c0"), 2, 10, 8))
	th.set_stylebox("pressed", "Button", flat(NAVY_DARK, Color("#5a5690"), 2, 10, 8))
	th.set_stylebox("disabled", "Button", flat(Color("#2a2944"), Color("#3a3858"), 2, 10, 8))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", CREAM)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", GOLD)
	th.set_color("font_disabled_color", "Button", Color("#77748f"))
	th.set_font("font", "Button", font_title)
	th.set_font_size("font_size", "Button", 21)
	th.set_color("font_color", "Label", INK)
	th.set_stylebox("panel", "Panel", paper())
	th.set_stylebox("panel", "PanelContainer", paper())
	th.set_font("normal_font", "RichTextLabel", font_body)
	th.set_font("bold_font", "RichTextLabel", font_title)
	th.set_font("italics_font", "RichTextLabel", font_bold)
	th.set_font_size("normal_font_size", "RichTextLabel", 20)
	th.set_font_size("bold_font_size", "RichTextLabel", 20)
	th.set_font_size("italics_font_size", "RichTextLabel", 20)
	th.set_color("default_color", "RichTextLabel", INK)
	th.set_font("font", "LineEdit", font_bold)
	th.set_font_size("font_size", "LineEdit", 24)
	th.set_color("font_color", "LineEdit", INK)
	th.set_color("font_placeholder_color", "LineEdit", Color(0.15, 0.14, 0.29, 0.5))
	th.set_color("caret_color", "LineEdit", INK)
	th.set_stylebox("normal", "LineEdit", flat(Color("#fbf6ea"), INK2, 2, 8))
	th.set_stylebox("focus", "LineEdit", flat(Color.WHITE, RED, 3, 8))
	th.set_font("font", "TooltipLabel", font_body)
	th.set_font_size("font_size", "TooltipLabel", 18)
	th.set_color("font_color", "TooltipLabel", INK)
	th.set_stylebox("panel", "TooltipPanel", paper(10))
	th.set_font("font", "CheckBox", font_bold)
	th.set_font_size("font_size", "CheckBox", 21)
	th.set_color("font_color", "CheckBox", CREAM)
	th.set_color("font_hover_color", "CheckBox", Color.WHITE)
	th.set_color("font_pressed_color", "CheckBox", CREAM)
	th.set_color("font_hover_pressed_color", "CheckBox", Color.WHITE)
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		th.set_stylebox(st, "CheckBox", StyleBoxEmpty.new())
	th.set_icon("checked", "CheckBox", tex("res://assets/ui/check_on.png"))
	th.set_icon("unchecked", "CheckBox", tex("res://assets/ui/check_off.png"))
	th.set_constant("h_separation", "CheckBox", 10)
	var sep := StyleBoxLine.new()
	sep.color = Color(0.15, 0.14, 0.29, 0.35)
	sep.thickness = 2
	th.set_stylebox("separator", "HSeparator", sep)
	th.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	return th
