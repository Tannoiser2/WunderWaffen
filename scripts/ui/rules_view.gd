extends Control
## Regole in breve, dal menu.

var main


func _ready() -> void:
	size = Vector2(1920, 1080)
	var bg := ColorRect.new()
	bg.color = UI.NAVY
	bg.size = size
	add_child(bg)
	var head := UI.banner("Regole in breve", 34, UI.RED)
	head.position = Vector2(60, 30)
	add_child(head)
	var back := UI.primary(UI.button("MENU", 200, 56, 24))
	back.position = Vector2(1660, 26)
	back.pressed.connect(func(): main.show_menu())
	add_child(back)
	var p := PanelContainer.new()
	p.position = Vector2(60, 110)
	p.custom_minimum_size = Vector2(1800, 940)
	p.size = Vector2(1800, 940)
	p.add_theme_stylebox_override("panel", UI.paper(28))
	add_child(p)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1740, 880)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(1700, 0)
	rt.add_theme_font_size_override("normal_font_size", 22)
	rt.add_theme_font_size_override("bold_font_size", 23)
	rt.add_theme_font_size_override("italics_font_size", 22)
	rt.append_text(RulesText.TEXT)
	sc.add_child(rt)
