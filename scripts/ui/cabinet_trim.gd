class_name CabinetTrim
extends Control
## Original front cabinet construction: upright glass, sloped deck, bumper and base.
var accent := Color("ffc848")
var primary := Color("a52e19")
func _draw() -> void:
	draw_rect(Rect2(0,0,720,1440),Color("101012"))
	for i in 12:
		draw_rect(Rect2(24-i,75-i,672+i*2,1340+i),Color(0,0,0,0.022))
	# Cabinet shell and shaped side mouldings.
	_poly([Vector2(69,82),Vector2(651,82),Vector2(675,828),Vector2(710,1120),Vector2(682,1230),Vector2(660,1416),Vector2(60,1416),Vector2(38,1230),Vector2(10,1120),Vector2(45,828)],Color("080b0d"))
	_poly([Vector2(77,99),Vector2(643,99),Vector2(655,816),Vector2(65,816)],primary.darkened(0.24))
	_poly([Vector2(65,821),Vector2(655,821),Vector2(696,1135),Vector2(24,1135)],primary.darkened(0.10))
	# Deep red/purple moulded side cheeks with ribs and chrome reveal.
	for left in [true,false]:
		var points := [Vector2(53,114),Vector2(74,100),Vector2(63,818),Vector2(23,1130),Vector2(9,1112)]
		if not left:
			for i in points.size(): points[i].x = 720-points[i].x
		_poly(points,primary.lightened(0.18))
		for i in 9:
			var x: float = 54+i*2 if left else 666-i*2
			draw_line(Vector2(x,117),Vector2(x-7 if left else x+7,805),Color(1,0.8,0.7,0.12*(1.0-float(i)/9)),2,true)
		for y in range(160,800,14):
			var x: float = 55-(y-160)*0.01
			if not left: x = 720-x-13
			draw_line(Vector2(x,y),Vector2(x+13,y),primary.darkened(0.60),3)
		for i in 5:
			var x: float = 73+i if left else 647-i
			draw_line(Vector2(x,110),Vector2(x-10 if left else x+10,816),Color(0.25+i*0.13,0.26+i*0.13,0.27+i*0.13),1)
	# Printed marbling/foil lightning, deliberately unlike the reference artwork.
	for i in 34:
		var x := 88.0+fmod(i*93.0,540.0)
		var y := 125.0+fmod(i*127.0,660.0)
		draw_polyline(PackedVector2Array([Vector2(x,y),Vector2(x+20,y+28),Vector2(x-8,y+41),Vector2(x+9,y+67)]),Color(accent,0.13),2,true)
	for y in [102,163,778,818]:
		draw_line(Vector2(77,y),Vector2(643,y),Color("ead9a4"),2)
	for x in range(95,630,13):
		for y in [92,98]: draw_circle(Vector2(x,y),1.6,Color("69675b"))
	# Perspective stripes on the sloping console.
	for i in 16:
		draw_line(Vector2(77+i*37,827),Vector2(32+i*43,1130),Color(accent,0.14),1,true)
	for i in 8:
		draw_line(Vector2(28,1133+i),Vector2(692,1133+i),Color(0.16+i*0.07,0.17+i*0.07,0.17+i*0.07),1)
	# Raised physical button shelf and rounded rubber palm rest.
	_plate(Rect2(24,1140,672,83),Color("171b1a"),Color("686a61"),8)
	_plate(Rect2(17,1220,686,28),Color("22292a"),Color("686e6a"),12)
	# Recessed return tray: decorative, fictional credits have no physical payout.
	_plate(Rect2(61,1253,598,83),Color("0b0d0e"),Color("2b3434"),3)
	_plate(Rect2(161,1267,398,40),Color("030405"),Color("3a4242"),6)
	draw_line(Vector2(170,1308),Vector2(550,1308),Color("70746b"),3)
	_plate(Rect2(73,1342,574,62),primary.darkened(0.23),accent,2)
	for x in [84,636]:
		for y in [115,808,1352]:
			draw_circle(Vector2(x,y),3,Color("c8c7b8"))
			draw_line(Vector2(x-2,y),Vector2(x+2,y),Color("353a3c"),1)
func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points),color)
func _plate(rect: Rect2,color: Color,border: Color,radius: int) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color=color
	box.border_color=border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	draw_style_box(box,rect)
