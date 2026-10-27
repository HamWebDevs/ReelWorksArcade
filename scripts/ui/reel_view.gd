class_name ReelView
extends Control
## Visual reel motion only. Engine owns the preselected center stops.
signal settled
signal reel_stopped(index: int)
var config: Dictionary = {}
var display_positions: Array[float] = [0.0, 0.0, 0.0]
var textures: Dictionary = {}
var spinning := false
var reduced_motion := false
var win := false
var held: Array = [false, false, false]
var tween: Tween
var font: Font = ThemeDB.fallback_font

func setup(machine: Dictionary, positions: Array) -> void:
	config = machine
	for key: String in config.get("symbols", {}):
		var path := "res://assets/symbols/" + key + ".svg"
		if key == "special":
			path = "res://assets/symbols/" + str(config.id) + "_special.svg"
		if ResourceLoader.exists(path):
			textures[key] = load(path)
	for i in 3:
		display_positions[i] = float(positions[i])
	queue_redraw()

func animate_to(positions: Array, hold_flags: Array) -> void:
	if tween and tween.is_running():
		tween.kill()
	spinning = true
	win = false
	tween = create_tween().set_parallel(true)
	for i in 3:
		var length: int = config.strips[i].size()
		var current := display_positions[i]
		var target := float(positions[i])
		if not hold_flags[i]:
			target += float(length * (2 + i))
			while target < current + float(length):
				target += length
		else:
			target = current
		var duration := 0.18 if reduced_motion else 0.9 + i * 0.3
		tween.tween_method(_set_reel_position.bind(i), current, target, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if not hold_flags[i]: tween.tween_callback(_notify_stop.bind(i)).set_delay(duration)
	tween.chain().tween_callback(func() -> void:
		for i in 3:
			display_positions[i] = float(positions[i])
		spinning = false
		queue_redraw()
		settled.emit()
	)

func _notify_stop(index: int) -> void:
	reel_stopped.emit(index)

func _set_reel_position(value: float, reel: int) -> void:
	display_positions[reel] = value
	queue_redraw()

func _draw() -> void:
	if config.is_empty():
		return
	var width := (size.x - 20.0) / 3.0
	for i in 3:
		var x := i * (width + 10.0)
		draw_style_box(_box(Color("151b1a"), Color("d8b76f"), 3, 12), Rect2(x, 0, width, size.y))
		draw_style_box(_box(Color("f3ebce"), Color("9c8c69"), 2, 8), Rect2(x + 6, 6, width - 12, size.y - 12))
		var strip: Array = config.strips[i]
		var p := display_positions[i]
		var base := int(floor(p))
		var fraction: float = p - floorf(p)
		var row_h := (size.y - 16.0) / 3.0
		for row in range(-2, 3):
			if not spinning and absi(row)>1: continue
			var index := posmod(base + row, strip.size())
			var raw: Variant = strip[index]
			var id: String = str(raw.get("symbol", raw.get("id", "cherry"))) if raw is Dictionary else str(raw)
			var center_y: float = size.y / 2.0 + (float(row) - fraction) * row_h
			if center_y < -row_h / 2.0 or center_y > size.y + row_h / 2.0:
				continue
			var icon_size := Vector2(row_h * 0.92, row_h * 0.92)
			var rect := Rect2(Vector2(x + (width - icon_size.x) / 2.0, center_y - icon_size.y / 2.0), icon_size)
			if textures.has(id):
				draw_texture_rect(textures[id], rect, false)
			else:
				draw_string(font, Vector2(x + 20, center_y + 10), id.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, width - 30, 25, Color("432d22"))
			var def: Dictionary = config.symbols.get(id, {})
			var number := int(raw.get("number", def.get("number", 0))) if raw is Dictionary else int(def.get("number", 0))
			if number > 0:
				draw_circle(Vector2(x + width - 28, center_y - 17), 13, Color("c53d2f"))
				draw_string(font, Vector2(x + width - 37, center_y - 10), str(number), HORIZONTAL_ALIGNMENT_CENTER, 18, 18, Color.WHITE)
		# Curved glass shadow and strip boundaries.
		for shade in 10:
			var alpha := float(10 - shade) / 24.0
			draw_rect(Rect2(x + 7, 7 + shade * 3, width - 14, 3), Color(0.08, 0.07, 0.04, alpha))
			draw_rect(Rect2(x + 7, size.y - 10 - shade * 3, width - 14, 3), Color(0.08, 0.07, 0.04, alpha))
		if held[i]:
			draw_style_box(_box(Color(1, 0.8, 0.2, 0.08), Color("ffe28c"), 4, 10), Rect2(x + 2, 2, width - 4, size.y - 4))
	var line_y := size.y / 2.0
	draw_line(Vector2(0, line_y - 36), Vector2(size.x, line_y - 36), Color(0.65, 0.12, 0.08, 0.55), 2)
	draw_line(Vector2(0, line_y + 36), Vector2(size.x, line_y + 36), Color(0.65, 0.12, 0.08, 0.55), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(0, line_y-12),Vector2(16,line_y),Vector2(0,line_y+12)]), Color("c64230"))
	draw_colored_polygon(PackedVector2Array([Vector2(size.x, line_y-12),Vector2(size.x-16,line_y),Vector2(size.x,line_y+12)]), Color("c64230"))
	if win:
		draw_style_box(_box(Color(1, 0.8, 0.1, 0.04), Color("ffd56a"), 4, 8), Rect2(0, line_y - 38, size.x, 76))

func _box(bg: Color, border: Color, thickness: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(thickness)
	style.set_corner_radius_all(radius)
	return style
