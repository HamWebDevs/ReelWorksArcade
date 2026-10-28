class_name CabinetTrim
extends Control
var accent := Color("ffc848")
var primary := Color("a52e19")
func _draw() -> void:
	# Layered moulded fascia, reflective metal rails and printed sunburst glass.
	for x in [23,681]:
		for i in 11:
			var shade := 0.18 + 0.65*sin(PI*i/11.0)
			draw_line(Vector2(x+i,78),Vector2(x+i,1390),Color(shade,shade*0.98,shade*0.9),1)
	for region: Rect2 in [Rect2(35,80,650,97),Rect2(35,778,650,35),Rect2(35,1049,650,342)]:
		draw_rect(region,primary.darkened(0.25))
		for y in range(int(region.position.y),int(region.end.y),5):
			draw_line(Vector2(region.position.x,y),Vector2(region.end.x,y),Color(1,0.7,0.2,0.055),1)
		draw_rect(region,accent,false,2)
	for i in 38:
		var a := TAU*i/38.0
		var center := Vector2(360,128)
		var ray := PackedVector2Array([center,center+Vector2(cos(a)*310,sin(a)*46),center+Vector2(cos(a+0.07)*310,sin(a+0.07)*46)])
		draw_colored_polygon(ray,Color(accent,0.17))
	for i in 25:
		for y in [84,172]:
			var p := Vector2(47+i*26,y)
			draw_circle(p,4,Color("5c321b"))
			draw_circle(p,2.5,Color("ffe9a0") if i%3!=1 else Color("e98935"))
	for y in [695,815,1047,1333,1392]:
		for j in 5:
			draw_line(Vector2(35,y+j),Vector2(685,y+j),Color(0.25+j*0.13,0.24+j*0.12,0.2+j*0.1),1)
	for p: Vector2 in [Vector2(27,90),Vector2(693,90),Vector2(27,1388),Vector2(693,1388)]:
		draw_circle(p,5,Color("c3beb0"))
		draw_line(p-Vector2(3,0),p+Vector2(3,0),Color("35332b"),1)
