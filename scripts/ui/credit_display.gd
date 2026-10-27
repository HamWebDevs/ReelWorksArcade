class_name CreditDisplay
extends Control
var value := 0:
	set(v):
		value = maxi(0, v)
		queue_redraw()
var caption := "PLAY CREDITS"
var ink := Color("ffb444")
var font: Font = ThemeDB.fallback_font
const SEGMENTS := [0b1111110,0b0110000,0b1101101,0b1111001,0b0110011,0b1011011,0b1011111,0b1110000,0b1111111,0b1111011]
func _draw() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("080e0c")
	s.border_color = Color("79715c")
	s.set_border_width_all(2)
	s.set_corner_radius_all(5)
	draw_style_box(s, Rect2(Vector2.ZERO,size))
	draw_string(font, Vector2(12,18), caption, HORIZONTAL_ALIGNMENT_LEFT,size.x-24,13,Color("b9b89e"))
	var text_value := "%06d" % mini(value,999999)
	var digit_width := 23.0
	var x0 := (size.x - digit_width * 6) / 2.0
	for i in 6:
		var bits: int = SEGMENTS[int(text_value[i])]
		var start := Vector2(x0 + i*digit_width,27)
		var lines := [Vector4(4,0,16,0),Vector4(18,3,18,14),Vector4(18,19,18,30),Vector4(4,33,16,33),Vector4(2,19,2,30),Vector4(2,3,2,14),Vector4(4,16,16,16)]
		for j in 7:
			var c := ink if bits & (1 << (6-j)) else Color(ink,0.08)
			var l: Vector4 = lines[j]
			draw_line(start+Vector2(l.x,l.y),start+Vector2(l.z,l.w),c,3,true)
