class_name BonusFace
extends Control
## Original miniature physical props for the live bonus panel.
var kind := ""
var cursor := 0
var number := 1
var stage := 0
var opened: Array = []
var font: Font = ThemeDB.fallback_font
func _draw() -> void:
	if kind == "darts_dash":
		var center := Vector2(61,58)
		for i in 12:
			var a := TAU*i/12.0-PI/2
			var points := PackedVector2Array([center])
			for j in 7:
				points.append(center+Vector2.from_angle(a+TAU/12.0*j/6.0)*53)
			draw_colored_polygon(points,Color("f5e2b0") if i%2==0 else Color("304b39"))
			draw_arc(center,38,a,a+TAU/12.0,6,Color("b84d37") if i%2==0 else Color("327a5a"),6,true)
		draw_arc(center,55,0,TAU,64,Color("d2b46e"),3,true)
		draw_circle(center,9,Color("aa3a2d"))
		var target := center+Vector2.from_angle(TAU*(cursor+0.5)/12.0-PI/2)*41
		draw_line(target+Vector2(12,-17),target,Color("efcb6b"),4,true)
		draw_circle(target,4,Color.WHITE)
		for i in 3:
			var p := Vector2(210+i*118,93)
			draw_circle(p,8,Color("ffd260") if i<stage else Color("665541"))
			draw_string(font,p+Vector2(13,6),"DART %d" % (i+1),HORIZONTAL_ALIGNMENT_LEFT,95,15,Color("f5daa1"))
	elif kind == "temporal_hi_lo":
		var center := Vector2(61,58)
		draw_circle(center,53,Color("10192b"))
		draw_arc(center,54,0,TAU,64,Color("6edce9"),3,true)
		for i in 12:
			var a := TAU*i/12.0-PI/2
			draw_line(center+Vector2.from_angle(a)*43,center+Vector2.from_angle(a)*48,Color("e8d4ad"),2,true)
		var angle := TAU*number/12.0-PI/2
		draw_line(center,center+Vector2.from_angle(angle)*36,Color("ffb067"),4,true)
		draw_string(font,Vector2(40,67),str(number),HORIZONTAL_ALIGNMENT_CENTER,44,26,Color("d8fafa"))
	elif kind == "paradox_mystery":
		for i in 3:
			var c := Vector2(101+i*196,28)
			draw_circle(c,26,Color("172444"))
			draw_arc(c,27,0,TAU,36,[Color("7ef5b4"),Color("f5cb53"),Color("ed77f0")][i],3,true)
			draw_string(font,c+Vector2(-25,7),["1/1","2/3","1/3"][i],HORIZONTAL_ALIGNMENT_CENTER,50,18,Color.WHITE)
	elif kind in ["mystery_barrel","mystery_bonus","property_pick"]:
		for i in 3:
			var x := 20+i*196.0
			var style := StyleBoxFlat.new()
			style.bg_color = Color("84572f") if kind in ["mystery_barrel","mystery_bonus"] else Color("254e53")
			style.border_color = Color("e3c58b")
			style.set_border_width_all(2)
			style.set_corner_radius_all(13 if kind.begins_with("mystery") else 3)
			draw_style_box(style,Rect2(x+39,5,84,52))
			if kind.begins_with("mystery"):
				draw_line(Vector2(x+40,15),Vector2(x+122,15),Color("c2a466"),5)
				draw_line(Vector2(x+40,47),Vector2(x+122,47),Color("c2a466"),5)
			draw_string(font,Vector2(x+40,39),("OPEN" if i in opened else "?") if kind != "property_pick" else ["40","60","80"][i],HORIZONTAL_ALIGNMENT_CENTER,82,29,Color("fff0c5"))
