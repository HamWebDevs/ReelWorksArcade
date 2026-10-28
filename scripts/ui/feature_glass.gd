class_name FeatureGlass
extends Control
var config: Dictionary = {}
var position_index := 0
var progress := 0
var active := false
var chasing := false
var phase := 0.0
var reduced_flashing := false
var high_contrast := false
var art: Texture2D
var font: Font = ThemeDB.fallback_font
var number_font: Font = ThemeDB.fallback_font
var feature: Dictionary = {}

func setup(machine: Dictionary) -> void:
	config = machine
	var path := "res://assets/cabinets/" + str(config.id) + ".svg"
	if ResourceLoader.exists(path):
		art = load(path)
	queue_redraw()

func update_state(index: int, amount: int, is_active: bool, data: Dictionary) -> void:
	position_index = index
	progress = amount
	active = is_active
	feature = data
	queue_redraw()

func _draw() -> void:
	if config.is_empty():
		return
	var sx := size.x / 680.0
	var sy := size.y / 580.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(sx, sy))
	if art:
		draw_texture_rect(art, Rect2(0, 0, 680, 580), false)
	var trail: Array = config.get("trail", [])
	var count := int(config.get("trail_length", 24))
	var points: Array[Vector2] = []
	for i in count:
		var p: Vector2
		if config.id == "last_orders":
			if i < 8:
				p = Vector2(70+i*77,53)
			elif i < 12:
				p = Vector2(626,157+(i-8)*90)
			elif i < 20:
				p = Vector2(609-(i-12)*77,523)
			else:
				p = Vector2(53,427-(i-20)*90)
		elif config.id == "empire_estates":
			var a := TAU * float(i) / count - PI / 2
			p = Vector2(340 + sin(a) * 270, 282 + cos(a) * 225)
		else:
			var a := TAU * float(i) / count - PI / 2
			p = Vector2(340 + cos(a) * 270, 290 + sin(a) * 220)
		points.append(p)
	for i in count - 1:
		draw_line(points[i], points[i+1], Color("ad8752"), 5, true)
		draw_line(points[i], points[i+1], Color("382d23"), 2, true)
	if config.id != "last_orders":
		draw_line(points[-1], points[0], Color("ad8752"), 4, true)
	if config.id == "empire_estates":
		for i in [2, 7, 12, 17]:
			draw_line(points[i], points[posmod(i+3, count)], Color(0.8,0.7,0.3,0.45), 3,true)
	for i in count:
		var lit := i == posmod(int(phase) if chasing and not reduced_flashing else position_index, count)
		var panel_width := 68.0 if config.id == "time_shift" else (78.0 if config.id == "empire_estates" else 70.0)
		var panel_height := 42.0 if config.id == "time_shift" else (44.0 if config.id == "empire_estates" else 50.0)
		var panel := Rect2(points[i] - Vector2(panel_width/2,panel_height/2), Vector2(panel_width,panel_height))
		var entry: Dictionary = trail[i] if i < trail.size() else {}
		var style := StyleBoxFlat.new()
		var print_colors := {"cash":"f4c65c","feature":"a52b26","nudges":"315a9a","mystery":"773c83","life":"28724e","upgrade":"a34422","repeat":"28724e"}
		style.bg_color = Color("ffe19a") if lit else Color(print_colors.get(str(entry.get("kind","cash")),"f4c65c"))
		if high_contrast: style.bg_color = Color("fff5c9") if lit else Color("070e0b")
		if config.id == "time_shift" and not lit and not high_contrast:
			style.bg_color = Color("644fa2")
		style.border_color = Color("fff5c9") if lit else Color("ad8752")
		style.set_border_width_all(3 if lit else 2)
		style.set_corner_radius_all(8)
		style.shadow_color = Color(1.0, 0.65, 0.15, 0.35 if lit else 0.0)
		style.shadow_size = 12 if lit else 0
		draw_style_box(style, panel)
		draw_line(panel.position+Vector2(5,4),Vector2(panel.end.x-5,panel.position.y+4),Color(1,1,1,0.35),2)
		var label := str(entry.get("label", str(i+1))).to_upper()
		label = {"UPGRADE":"BOOST","LAST CALL":"STREAK","EXCHANGE":"EXCH"}.get(label,label)
		if label.length() > 11:
			label = label.substr(0, 10)
		var ink := Color("3b281a") if lit else (Color("fff1c5") if config.id == "time_shift" or str(entry.get("kind","cash")) != "cash" else Color("3d2114"))
		draw_string(font, points[i] + Vector2(-(panel_width-6)/2, 1), label, HORIZONTAL_ALIGNMENT_CENTER, panel_width-6, 11 if label.length()>8 else 13, ink)
		draw_string(number_font, points[i] + Vector2(-30, 18), "%02d" % (i+1), HORIZONTAL_ALIGNMENT_CENTER, 60, 12, ink.darkened(0.18))
		for bulb_x in [-panel_width/2+5, panel_width/2-5]:
			draw_circle(points[i] + Vector2(bulb_x, -panel_height/2+4), 3, Color("fff8da") if lit else Color("94753d"))
	if config.id == "last_orders":
		draw_string(font,Vector2(120,143),"PUB CRAWL",HORIZONTAL_ALIGNMENT_CENTER,440,33,Color("fff1a0"))
		for j in 5:
			var box := Rect2(143+j*79,445,74,39)
			var plate := StyleBoxFlat.new()
			plate.bg_color = Color("a32d20")
			plate.border_color = Color("ffdd7a")
			plate.set_border_width_all(2)
			draw_style_box(plate,box)
			draw_string(font,box.position+Vector2(0,25),["20","40","80","160","320"][j],HORIZONTAL_ALIGNMENT_CENTER,74,22,Color("fff0bb"))
	if config.id != "last_orders":
		var title := "DISTRICT CIRCUIT" if config.id == "empire_estates" else "TIME CIRCUIT"
		draw_string(font, Vector2(180, 261), title, HORIZONTAL_ALIGNMENT_CENTER, 320, 21, Color("ffe6a6"))
		var detail := str(feature.get("zone", "PAST · PRESENT · FUTURE")) if config.id == "time_shift" else "BUILD YOUR EMPIRE"
		draw_string(font, Vector2(170, 289), detail.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 340, 15, Color("dcdfcf"))
	draw_set_transform(Vector2.ZERO)
