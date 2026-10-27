class_name SkillLamps
extends Control
var cursor := 0:
	set(value):
		cursor = value
		queue_redraw()
var reduced_flashing := false
var font: Font = ThemeDB.fallback_font
func _draw() -> void:
	var step := size.x / 12.0
	for i in 12:
		var center := Vector2(step*(i+0.5),size.y*0.5)
		var target := i in [5,6]
		var fill := Color("23674d") if target else Color("283239")
		if i == cursor: fill = Color("ffe09c")
		draw_circle(center,17,fill)
		draw_arc(center,18,0,TAU,24,Color("e9c66d") if target or i==cursor else Color("86918b"),2,true)
		draw_string(font,center+Vector2(-16,6),str(i+1),HORIZONTAL_ALIGNMENT_CENTER,32,16,Color("322b20") if i==cursor else Color("ece4c8"))
		if i == cursor:
			draw_line(center+Vector2(-11,24),center+Vector2(11,24),Color("fff0be"),3,true)
