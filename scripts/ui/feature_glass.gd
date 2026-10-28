class_name FeatureGlass
extends Control
## Dense original printed glass. Every highlighted meter reflects engine state.
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
	config=machine
	var path := str(machine.get("artwork","res://assets/cabinets/"+str(machine.id)+".svg"))
	if ResourceLoader.exists(path): art=load(path)
	queue_redraw()
func update_state(index: int, amount: int, is_active: bool, data: Dictionary) -> void:
	position_index=index
	progress=amount
	active=is_active
	feature=data
	queue_redraw()
func _draw() -> void:
	if config.is_empty(): return
	draw_set_transform(Vector2.ZERO,0,Vector2(size.x/680.0,size.y/760.0))
	var theme_color := Color("a6171a") if config.id=="last_orders" else (Color("135a43") if config.id=="empire_estates" else Color("342583"))
	_panel(Rect2(0,0,680,760),theme_color,Color("f4d085"),2)
	for i in 30:
		var x := float(i*29%680)
		draw_polyline(PackedVector2Array([Vector2(x,0),Vector2(x-90,370),Vector2(x+60,760)]),Color(1,0.78,0.2,0.09),3,true)
	# Left cash ladder, central route and right feature ladder are separate printed modules.
	_text("CASH",Rect2(8,7,116,27),20)
	_text(str(config.trail_name).to_upper(),Rect2(132,7,414,30),24)
	_text("FEATURES",Rect2(555,7,116,27),17)
	var amounts: Array = [20,40,80,160,320]
	if int(config.jackpot)>640: amounts.append(640)
	amounts.append(int(config.jackpot))
	var pot := int(feature.get("pot",0))
	for i in amounts.size():
		var amount: int=amounts[amounts.size()-1-i]
		var step: float = 282.0/amounts.size()
		_cell(Rect2(10,42+i*step,112,step-6),str(amount)+" CR",Color("17612b"),active and pot>=amount,21)
	_text("COLLECT OR\nGO HIGHER",Rect2(10,329,112,43),15)
	var names: Array = config.get("features",[])
	for i in mini(10,names.size()):
		var id := str(names[i])
		_cell(Rect2(551,42+i*37,119,32),id.replace("_"," ").to_upper(),Color("194b78") if i%2==0 else Color("772b27"),str(feature.get("id",""))==id,11)
	# Original illustration is printed behind the central route, as a small motif.
	if art: draw_texture_rect(art,Rect2(137,45,406,345),false,Color(1,1,1,0.52))
	var trail: Array = config.trail
	var n: int=trail.size()
	var columns := 4
	var rows := int(ceil(float(n)/columns))
	var step_y := 343.0/rows
	var route := PackedVector2Array()
	for i in n:
		var row := i/columns
		var col := i%columns if row%2==0 else columns-1-i%columns
		route.append(Vector2(189+col*99,48+row*step_y+(step_y-7)/2))
	draw_polyline(route,Color("ffe594"),5,true)
	for i in n:
		var row := i/columns
		var col := i%columns if row%2==0 else columns-1-i%columns
		var rect := Rect2(143+col*99,48+row*step_y,93,step_y-7)
		var entry: Dictionary=trail[i]
		var label := str(entry.label).to_upper()
		label={"UPGRADE":"BOOST","LAST CALL":"STREAK","EXCHANGE":"EXCH"}.get(label,label)
		var kind := str(entry.kind)
		var colors := {"cash":"176335","feature":"9f2423","nudges":"254e88","mystery":"743183","life":"185966","upgrade":"94501a","repeat":"185966"}
		var lit := i==posmod(int(phase) if chasing and not reduced_flashing else position_index,n)
		_cell(rect,label,Color(colors.get(kind,"176335")),lit,14)
		_text("%02d"%(i+1),Rect2(rect.position+Vector2(0,rect.size.y-18),Vector2(rect.size.x,17)),10,Color("ffe9a0") if not lit else Color("39230c"))
	# Genuine persistent trail accumulator, one lamp per earned step.
	_text("BONUS NUMBERS  •  FILL THE TRAIL",Rect2(139,402,402,23),14)
	for i in n:
		var col:=i%12
		var row:=i/12
		_cell(Rect2(143+col*33,430+row*27,29,23),str(i+1),Color("17332e"),i<progress,11)
	# Number / board-pot displays and protective lives reflect the active model.
	_panel(Rect2(10,390,112,86),Color("090d0e"),Color("cdba73"),2)
	_text("HI • LO",Rect2(10,393,112,20),15)
	_text(str(int(feature.get("number",0))) if int(feature.get("number",0))>0 else "1–12",Rect2(12,414,108,53),35,Color("ff5035"))
	_panel(Rect2(550,428,120,55),Color("0a1010"),Color("d4b567"),2)
	_text("FEATURE POT",Rect2(552,430,116,19),12)
	_text(str(pot),Rect2(552,447,116,31),25,Color("ff4f32"))
	# Prize matrix uses the real paytable, not invented awards.
	_text("THREE ON THE CENTRE LINE",Rect2(12,493,657,28),20)
	var keys := ["cherry","lemon","bell","bar","seven","special"]
	for i in 6:
		var rect := Rect2(12+i*110,526,105,66)
		_panel(rect,Color("172e43"),Color("e4d8ab"),2)
		_text(str(config.symbols[keys[i]].label).to_upper(),Rect2(rect.position+Vector2(2,3),Vector2(101,23)),11)
		_text(str(int(config.paytable[keys[i]])),Rect2(rect.position+Vector2(2,27),Vector2(101,34)),27,Color("ffe487"))
	# Printed hardware instructions; lower bays become touch controls during board play.
	var captions: Array = ["THREE DARTS","CELLAR RAID","LUCKY BELLS"] if config.id=="last_orders" else (["PROPERTY PICK","AUCTION OFFER","RENT RUSH"] if config.id=="empire_estates" else ["REWIND","TIME JUMP","SURGE"])
	for i in 3:
		var rect := Rect2(12+i*221,610,211,91)
		_panel(rect,Color("211e28"),Color("e6c477"),2)
		var center := rect.position+Vector2(39,39)
		if config.id=="last_orders" and i==0:
			for sector in 12:
				var points := PackedVector2Array([center])
				for j in 5: points.append(center+Vector2.from_angle(TAU*(sector+j/4.0)/12)*29)
				draw_colored_polygon(points,Color("c84432") if sector%2==0 else Color("f4dea1"))
			draw_circle(center,7,Color("1e7557"))
		elif config.id=="empire_estates":
			for j in 3:
				var h := float(28+j*9)
				_panel(Rect2(center+Vector2(-30+j*20,20-h),Vector2(17,h)),Color("c7b77a"),Color("dfd8a3"))
				for w in 3: draw_rect(Rect2(center+Vector2(-26+j*20,23-h+w*9),Vector2(7,5)),Color("ffe788"))
		elif config.id=="time_shift":
			draw_circle(center,29,Color("183657"))
			draw_arc(center,30,0,TAU,32,Color("7af2ee"),2,true)
			draw_line(center,center+Vector2.from_angle(-PI/2+i)*24,Color("ffcb5d"),3,true)
			draw_line(center,center+Vector2(14,6),Color("ffcb5d"),3,true)
		else:
			_panel(Rect2(center-Vector2(24,29),Vector2(48,58)),Color("9f5c2c"),Color("dec87e"),2)
			draw_line(center+Vector2(-24,-17),center+Vector2(24,-17),Color("edcf78"),5)
			draw_line(center+Vector2(-24,18),center+Vector2(24,18),Color("edcf78"),5)
			_text("?" if i==1 else "3×",Rect2(center-Vector2(20,18),Vector2(40,36)),26)
		_text(captions[i],Rect2(rect.position+Vector2(74,10),Vector2(133,53)),14)
		_text("ORIGINAL BONUS",Rect2(rect.position+Vector2(4,70),Vector2(203,18)),10,Color("a7d2ce"))
	_text("ORIGINAL REELWORKS MACHINE  /  FICTIONAL CREDITS",Rect2(14,715,650,24),13)
	draw_set_transform(Vector2.ZERO)
func _panel(rect: Rect2, color: Color, edge: Color, thickness: int=1) -> void:
	var box:=StyleBoxFlat.new()
	box.bg_color=Color.BLACK if high_contrast else color
	box.border_color=edge
	box.set_border_width_all(thickness)
	box.set_corner_radius_all(2)
	draw_style_box(box,rect)
func _cell(rect: Rect2, label: String, color: Color, lit: bool, font_size: int) -> void:
	_panel(rect,Color("ffe892") if lit else color,Color("fff3c7") if lit else Color("c1c0a0"),2)
	draw_line(rect.position+Vector2(4,4),Vector2(rect.end.x-4,rect.position.y+4),Color(1,1,1,0.25),2)
	_text(label,Rect2(rect.position+Vector2(3,0),rect.size-Vector2(6,0)),font_size,Color("3d230c") if lit else Color("fff0bd"))
func _text(value: String,rect: Rect2,font_size: int,color: Color=Color("ffeab1")) -> void:
	draw_string(font,rect.position+Vector2(0,(rect.size.y+font_size)/2-3),value,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,font_size,color)
