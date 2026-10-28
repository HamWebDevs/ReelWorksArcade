extends Control
## Native portrait cabinet and arcade. All gameplay decisions live in ReelEngine.
const DESIGN := Vector2(720,1440)
const REEL_SCENE := preload("res://scenes/reels/reel_window.tscn")
const GLASS_SCENE := preload("res://scenes/cabinet/feature_glass.tscn")
const BONUS_SCENE := preload("res://scenes/features/bonus_props.tscn")
var stage: Control
var screen: Control
var overlay: Control
var machines: Array[Dictionary] = []
var engine: ReelEngine
var current_id := "last_orders"
var snapshots: Dictionary = {}
var preferences := {"sound":0.7,"music":0.25,"mute":false,"vibration":false,"reduced_motion":false,"reduced_flashing":false,"contrast":false,"reminders":false}
var sounds: SoundRack
var display_font: Font
var body_font: Font
var bold_font: Font
var buttons: Dictionary = {}
var glass: FeatureGlass
var reels: ReelView
var credits_display: CreditDisplay
var bank_display: CreditDisplay
var status_label: Label
var feature_title: Label
var feature_prompt: Label
var feature_pot: Label
var feature_panel: Control
var bonus_face: BonusFace
var paytable_panel: Control
var choice_buttons: Array[Button] = []
var skill_bar: SkillLamps
var on_arcade := true
var zoomed := false
var session_elapsed := 0.0
var skill_elapsed := 0.0
var cursor := 0
var last_input_ms := 0
var last_feature_id := ""
var lamp_elapsed := 0.0
var save_ok := true

func _ready() -> void:
	get_tree().auto_accept_quit = false
	Engine.max_fps = 60
	OS.low_processor_usage_mode = true
	display_font = _font("display.ttf")
	body_font = _font("body.ttf")
	bold_font = _font("bold.ttf")
	var theme := Theme.new()
	theme.default_font = body_font
	theme.default_font_size = 21
	self.theme = theme
	machines = MachineLibrary.all()
	var saved := SaveStore.load_save()
	preferences.merge(saved.get("preferences", {}),true)
	snapshots = saved.get("machines", {})
	current_id = str(saved.get("current_machine", "last_orders"))
	sounds = SoundRack.new()
	add_child(sounds)
	_apply_preferences()
	stage = Control.new()
	stage.size = DESIGN
	add_child(stage)
	resized.connect(_resize)
	_resize()
	_show_arcade()

func _font(filename: String) -> Font:
	var path := "res://assets/fonts/" + filename
	return load(path) as Font if ResourceLoader.exists(path) else ThemeDB.fallback_font

func _resize() -> void:
	if stage:
		stage.position = (size-DESIGN)/2.0

func _process(delta: float) -> void:
	session_elapsed += delta
	if preferences.reminders and session_elapsed >= 1200:
		session_elapsed = 0.0
		_show_text("A MOMENT BETWEEN SPINS", "You have been playing for 20 minutes. This is a free-play simulation with no real money or prizes. Your progress is saved whenever you leave.")
	if not on_arcade and is_instance_valid(glass) and is_instance_valid(reels) and reels.spinning and not preferences.reduced_flashing:
		lamp_elapsed += delta
		if lamp_elapsed >= 0.12:
			lamp_elapsed = 0
			glass.phase += 1
			glass.queue_redraw()
	if not on_arcade and engine and engine.available_actions().has("stop") and is_instance_valid(skill_bar):
		skill_elapsed += delta if not preferences.reduced_motion else 0.0
		cursor = int(skill_elapsed / 0.1) % 12
		skill_bar.cursor = cursor
		if is_instance_valid(bonus_face):
			bonus_face.cursor = cursor
			bonus_face.queue_redraw()
		skill_bar.tooltip_text = "Stop at 5 or 6 for the top skill award. Current: %d" % cursor

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_save()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_safely()

func _quit_safely() -> void:
	_save()
	sounds.shutdown()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()
	elif event is InputEventKey and event.pressed and not event.echo and not on_arcade and not is_instance_valid(overlay):
		match event.keycode:
			KEY_SPACE: _act("start")
			KEY_1: _act("hold_0")
			KEY_2: _act("hold_1")
			KEY_3: _act("hold_2")
			KEY_C: _act("collect")
			KEY_H: _act("hi")
			KEY_L: _act("lo")

func _back() -> void:
	if is_instance_valid(overlay):
		_close_overlay()
	elif not on_arcade:
		if reels and reels.spinning:
			return
		_save()
		_show_arcade()
	else:
		_quit_safely()

func _clear_screen() -> void:
	_close_overlay()
	if is_instance_valid(screen):
		screen.queue_free()
		screen.hide()
	screen = Control.new()
	screen.size = DESIGN
	stage.add_child(screen)
	buttons.clear()
	choice_buttons.clear()

func _show_arcade() -> void:
	on_arcade = true
	_clear_screen()
	sounds.ambience.stop()
	_panel(screen, Rect2(0,0,720,1440),Color("101c20"),Color("101c20"),0)
	for x in range(0,720,48):
		_panel(screen,Rect2(x,0,2,1440),Color("203032"),Color.TRANSPARENT,0)
	_label(screen,"R E E L W O R K S",Rect2(36,47,648,51),39,Color("f2cf88"),true)
	_label(screen,"A R C A D E",Rect2(36,100,648,36),23,Color("d4ded3"),true)
	_label(screen,"THREE CABINETS.  A POCKETFUL OF NOSTALGIA.",Rect2(36,153,648,30),16,Color("9eafa9"),true)
	_panel(screen,Rect2(36,200,648,54),Color("253b38"),Color("546151"),1,8)
	_label(screen,"18+  ·  FREE PLAY  ·  FICTIONAL CREDITS ONLY",Rect2(40,211,640,30),17,Color("eadbb7"),true)
	var cabinet_scroll := ScrollContainer.new()
	cabinet_scroll.position = Vector2(0,274)
	cabinet_scroll.size = Vector2(720,962)
	cabinet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen.add_child(cabinet_scroll)
	var cards := Control.new()
	cards.custom_minimum_size = Vector2(708,machines.size()*315+12)
	cabinet_scroll.add_child(cards)
	for i in machines.size():
		_arcade_card(machines[i],12+i*315,cards)
	_button(screen,"SOUND & ACCESSIBILITY",Rect2(36,1260,318,62),_show_settings,Color("29433e"))
	_button(screen,"ABOUT THIS ARCADE",Rect2(366,1260,318,62),func() -> void: _show_text("WELCOME TO REELWORKS", "An original, offline collection inspired by the craft of British pub fruit machines.\n\n18+ simulated gambling. All play uses unlimited fictional, non-transferable credits. There are no payments, adverts, accounts or redeemable prizes.\n\nOutcomes use an independent, seeded random generator. The rules and paytables of every machine are available from its cabinet. No compensated payout or near-miss adjustment is used.\n\nCreated with original vector artwork and synthesized sound."),Color("29433e"))
	_label(screen,"NO CASH VALUE.  NO PURCHASES.  ALWAYS OFFLINE.",Rect2(36,1360,648,30),15,Color("9eafa9"),true)

func _arcade_card(machine: Dictionary, y: float, parent: Control) -> void:
	var accent := Color(machine.colors.accent)
	_panel(parent,Rect2(36,y,648,292),Color(machine.colors.bg),accent.darkened(0.35),2,14)
	_panel(parent,Rect2(49,y+13,211,266),Color("090f11"),accent,2,10)
	var texture := TextureRect.new()
	texture.texture = load("res://assets/cabinets/"+str(machine.id)+".svg") if ResourceLoader.exists("res://assets/cabinets/"+str(machine.id)+".svg") else null
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.position = Vector2(57,y+21)
	texture.size = Vector2(195,170)
	texture.clip_contents = true
	parent.add_child(texture)
	for r in 3:
		_panel(parent,Rect2(64+r*61,y+199,55,55),Color("f4e9cb"),accent,1,4)
		var symbol := TextureRect.new()
		var path := "res://assets/symbols/"+str(machine.id)+"_special.svg"
		if ResourceLoader.exists(path): symbol.texture = load(path)
		symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		symbol.position = Vector2(68+r*61,y+202)
		symbol.size = Vector2(48,48)
		parent.add_child(symbol)
	_label(parent,str(machine.name).to_upper(),Rect2(284,y+21,370,43),27,accent,false,true)
	_label(parent,str(machine.get("subtitle","ORIGINAL FRUIT MACHINE")).to_upper(),Rect2(284,y+69,365,26),13,Color("d6dacb"))
	var description := _label(parent,str(machine.description),Rect2(284,y+105,363,70),18,Color("c0c9c0"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(parent,"TOP PRIZE  %d CR" % int(machine.jackpot),Rect2(284,y+186,350,27),16,accent)
	_button(parent,"PLAY CABINET   →",Rect2(284,y+225,367,48),func() -> void: _open_machine(str(machine.id)),Color(machine.colors.primary),accent)

func _open_machine(id: String) -> void:
	current_id = id
	engine = ReelEngine.new()
	engine.configure(MachineLibrary.get_machine(id))
	if snapshots.has(id):
		engine.restore(snapshots[id])
	engine.changed.connect(_engine_event)
	on_arcade = false
	_build_cabinet()
	sounds.set_ambience(id)
	if engine.state == "SPINNING":
		engine.finish_spin()
	_sync()
	_save()

func _build_cabinet() -> void:
	_clear_screen()
	var machine := engine.config
	var accent := Color(machine.colors.accent)
	_panel(screen,Rect2(12,12,696,1416),Color("090e10"),Color("71716a"),3,28)
	_panel(screen,Rect2(22,22,676,1396),Color(machine.colors.bg),accent.darkened(0.4),2,22)
	var trim := CabinetTrim.new()
	trim.size = DESIGN
	trim.accent = accent
	trim.primary = Color(machine.colors.primary)
	trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(trim)
	_panel(screen,Rect2(34,27,652,44),Color("101b1b"),Color("45524b"),1,12)
	_button(screen,"‹ ARCADE",Rect2(42,28,141,43),_back,Color("233a35"))
	_button(screen,"RULES",Rect2(482,28,91,43),_show_rules,Color("233a35"))
	_button(screen,"⚙",Rect2(584,28,90,43),_show_settings,Color("233a35"))
	_label(screen,"REELWORKS  /  ORIGINAL SERIES",Rect2(185,38,291,26),12,Color("c6cbbd"),true)
	var marquee := _label(screen,str(machine.name).to_upper(),Rect2(40,86,640,58),44,Color("fff1a0"),true,true)
	marquee.add_theme_color_override("font_shadow_color",Color("5d0f08"))
	marquee.add_theme_constant_override("shadow_offset_x",4)
	marquee.add_theme_constant_override("shadow_offset_y",5)
	marquee.add_theme_color_override("font_outline_color",Color("431c16"))
	marquee.add_theme_constant_override("outline_size",9)
	_label(screen,str(machine.get("subtitle", "THE ORIGINAL PUB FRUIT MACHINE")).to_upper(),Rect2(42,145,636,26),14,Color("e4d6b9"),true)
	glass = GLASS_SCENE.instantiate() as FeatureGlass
	glass.position = Vector2(34,181)
	glass.size = Vector2(652,469)
	glass.font = bold_font
	glass.number_font = body_font
	glass.setup(machine)
	screen.add_child(glass)
	_button(screen,"⤢  ENLARGE BOARD",Rect2(226,654,268,37),_show_zoom,Color("263b32"),accent)
	credits_display = CreditDisplay.new()
	credits_display.position = Vector2(43,701)
	credits_display.size = Vector2(215,72)
	credits_display.font = bold_font
	screen.add_child(credits_display)
	bank_display = CreditDisplay.new()
	bank_display.position = Vector2(270,701)
	bank_display.size = Vector2(215,72)
	bank_display.caption = "PRIZE BANK · CREDITS"
	bank_display.font = bold_font
	bank_display.ink = Color("c5f1a7")
	screen.add_child(bank_display)
	_panel(screen,Rect2(497,701,179,72),Color("25372d"),accent,1,6)
	_label(screen,"TOP PRIZE",Rect2(504,709,164,22),13,Color("e7d4a8"),true)
	_label(screen,"%d CR" % int(machine.jackpot),Rect2(504,732,164,33),28,accent,true,true)
	paytable_panel = Control.new()
	paytable_panel.position = Vector2(40,781)
	paytable_panel.size = Vector2(640,34)
	screen.add_child(paytable_panel)
	_label(paytable_panel,"3×",Rect2(0,0,54,32),22,accent,true)
	var ids := ["cherry","lemon","bell","bar","seven","special"]
	for i in ids.size():
		var symbol := TextureRect.new()
		var path: String = "res://assets/symbols/"+(str(machine.id)+"_special" if ids[i]=="special" else ids[i])+".svg"
		if ResourceLoader.exists(path): symbol.texture = load(path)
		symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		symbol.position = Vector2(55+i*97,1)
		symbol.size = Vector2(30,30)
		paytable_panel.add_child(symbol)
		_label(paytable_panel,str(int(machine.paytable.get(ids[i],0))),Rect2(89+i*97,0,58,32),17,Color("f0dba6"))
	reels = REEL_SCENE.instantiate() as ReelView
	reels.position = Vector2(43,820)
	reels.size = Vector2(633,224)
	reels.clip_contents = true
	reels.font = bold_font
	reels.reduced_motion = preferences.reduced_motion
	reels.setup(machine,engine.positions)
	reels.settled.connect(_spin_finished)
	reels.reel_stopped.connect(func(_index: int) -> void: sounds.play_event("stop"))
	screen.add_child(reels)
	for i in 3:
		buttons["hold_"+str(i)] = _button(screen,"HOLD "+str(i+1),Rect2(44+i*214,1054,204,53),_act.bind("hold_"+str(i)),Color("8c452b"),Color("f7d18a"))
	status_label = _label(screen,"",Rect2(49,1118,624,53),19,Color("fee4a7"),true)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buttons.start = _button(screen,"START  ·  %d CR" % int(machine.stake),Rect2(446,1180,228,76),_act.bind("start"),Color("c0a54b"),Color("fff1bb"))
	buttons.collect = _button(screen,"COLLECT",Rect2(44,1180,190,76),_act.bind("collect"),Color("346b4b"),Color("c8edb0"))
	buttons.cancel = _button(screen,"CANCEL",Rect2(246,1180,188,76),_act.bind("cancel"),Color("73302a"),Color("efbf91"))
	buttons.exchange = _button(screen,"EXCHANGE",Rect2(44,1269,190,54),_act.bind("exchange"),Color("314b69"))
	buttons.feature_start = _button(screen,"FEATURE START",Rect2(246,1269,428,54),_act.bind("feature_start"),Color("8b6633"))
	buttons.refill = _button(screen,"+ FREE CREDITS",Rect2(44,1341,206,43),_act.bind("refill"),Color("223b32"))
	buttons.transfer = _button(screen,"BANK → PLAY",Rect2(264,1341,198,43),_act.bind("transfer"),Color("223b32"))
	_button(screen,"STATS",Rect2(476,1341,198,43),_show_stats,Color("223b32"))
	_label(screen,"18+  ·  FREE-PLAY SIMULATION  ·  NO REAL MONEY",Rect2(38,1390,644,25),12,Color("bcbca7"),true)
	_build_feature_panel()

func _build_feature_panel() -> void:
	feature_panel = Control.new()
	feature_panel.position = Vector2(49,790)
	feature_panel.size = Vector2(622,375)
	screen.add_child(feature_panel)
	_panel(feature_panel,Rect2(0,0,622,375),Color("111f20"),Color("e9bd6c"),3,16)
	feature_title = _label(feature_panel,"",Rect2(19,15,584,39),26,Color("f6d695"),true,true)
	feature_prompt = _label(feature_panel,"",Rect2(22,65,578,85),18,Color("e2e5d7"),true)
	feature_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feature_pot = _label(feature_panel,"",Rect2(24,148,574,37),24,Color("a7e9cd"),true,true)
	bonus_face = BONUS_SCENE.instantiate() as BonusFace
	bonus_face.position = Vector2(20,171)
	bonus_face.size = Vector2(582,111)
	bonus_face.font = bold_font
	feature_panel.add_child(bonus_face)
	skill_bar = SkillLamps.new()
	skill_bar.position = Vector2(28,179)
	skill_bar.size = Vector2(566,50)
	skill_bar.font = bold_font
	feature_panel.add_child(skill_bar)
	for i in 3:
		var b := _button(feature_panel,"",Rect2(20+i*196,231,187,54),_act.bind("choice_"+str(i)),Color("36554a"))
		choice_buttons.append(b)
		buttons["choice_"+str(i)] = b
	var actions := ["hi","lo","continue","stop","rewind"]
	var titles := ["HI ↑","LO ↓","CONTINUE","STOP","REWIND"]
	for i in actions.size():
		buttons[actions[i]] = _button(feature_panel,titles[i],Rect2(19+i*118,301,112,52),_act.bind(actions[i]),Color("70523c"))
	for i in 3:
		buttons["nudge_up_"+str(i)] = _button(screen,"↑ NUDGE "+str(i+1),Rect2(44+i*214,1054,204,53),_act.bind("nudge_up_"+str(i)),Color("4a5b86"))
		buttons["nudge_down_"+str(i)] = _button(screen,"↓ NUDGE "+str(i+1),Rect2(44+i*214,1114,204,53),_act.bind("nudge_down_"+str(i)),Color("4a5b86"))

func _act(action: String) -> void:
	if engine == null or on_arcade or (is_instance_valid(reels) and reels.spinning):
		return
	# Human input is edge-triggered and debounced; core independently validates state.
	var now := Time.get_ticks_msec()
	if now-last_input_ms < 110:
		return
	last_input_ms = now
	var before := engine.state
	var held_before := engine.held.duplicate()
	var bonus_reel_spin := action == "continue" and str(engine.feature.get("id","")) in ["super_hold","win_spin"]
	if engine.act(action,cursor if action == "stop" else 0):
		_save()
		if preferences.vibration:
			Input.vibrate_handheld(18)
		if (engine.state == "SPINNING" and before != "SPINNING") or bonus_reel_spin:
			reels.animate_to(engine.positions,held_before)
		else:
			for i in 3: reels.display_positions[i] = float(engine.positions[i])
		_sync()

func _spin_finished() -> void:
	if engine:
		engine.finish_spin()
		_save()
		_sync()

func _engine_event(event: String) -> void:
	sounds.play_event(event)

func _sync() -> void:
	if on_arcade or not is_instance_valid(status_label):
		return
	var actions := engine.available_actions()
	for key: String in buttons:
		var b: Button = buttons[key]
		b.disabled = not actions.has(key) or reels.spinning
		if key.begins_with("nudge_") or key in ["hi","lo","continue","stop","rewind","choice_0","choice_1","choice_2"]:
			b.visible = actions.has(key)
		if key.begins_with("hold_"):
			b.visible = not actions.has("nudge_up_0")
			var idx := int(key[-1])
			b.text = ("HELD " if engine.held[idx] else "HOLD ")+str(idx+1)
	credits_display.value = engine.credits
	bank_display.value = engine.bank
	status_label.text = engine.message if save_ok else "Storage unavailable — progress cannot be saved."
	status_label.visible = not actions.has("nudge_down_0")
	reels.held = engine.held
	reels.win = engine.state == "AWARD_COLLECTION"
	reels.queue_redraw()
	glass.chasing = reels.spinning
	glass.update_state(engine.trail_pos,engine.trail_progress,engine.state.begins_with("FEATURE"),engine.feature)
	glass.reduced_flashing = preferences.reduced_flashing
	var f: Dictionary = engine.feature
	var needs_panel := engine.state in ["FEATURE_ACTIVE","GAMBLE","FEATURE_ENTRY"] and not f.is_empty()
	feature_panel.visible = needs_panel
	feature_panel.position = Vector2(49,257) if str(f.get("id","")) in ["super_hold","super_nudges","super_shift"] else Vector2(49,790)
	if buttons.rewind.get_parent() != screen:
		buttons.rewind.reparent(screen)
	buttons.rewind.position = Vector2(246,1269)
	buttons.rewind.size = Vector2(428,54)
	buttons.feature_start.visible = not actions.has("rewind")
	var covers_reels: bool = needs_panel and feature_panel.position.y > 700
	reels.visible = not covers_reels
	paytable_panel.visible = not covers_reels
	if covers_reels:
		status_label.visible = false
		for i in 3: buttons["hold_"+str(i)].visible = false
	if needs_panel:
		bonus_face.kind = str(f.get("id",""))
		bonus_face.number = int(f.get("number",1))
		bonus_face.stage = int(f.get("stage",0))
		bonus_face.opened = f.get("opened",[])
		bonus_face.queue_redraw()
		feature_title.text = str(f.get("title",str(f.get("id","FEATURE")).replace("_"," ").to_upper()))
		feature_prompt.text = str(f.get("prompt",engine.message))
		var number_text := "NUMBER %d  /  " % int(f.number) if int(f.get("number",0))>0 else ""
		feature_pot.text = number_text+"FEATURE POT  %d CR" % int(f.get("pot",0))
		if f.has("lives") and int(f.lives)>0: feature_pot.text += "  ·  ♥ %d" % int(f.lives)
		skill_bar.visible = actions.has("stop")
		skill_bar.position = Vector2(145,193) if bonus_face.kind == "darts_dash" else Vector2(28,179)
		skill_bar.size.x = 447 if bonus_face.kind == "darts_dash" else 566
		var visible_actions: Array[String] = []
		for action: String in ["hi","lo","continue","stop"]:
			if actions.has(action): visible_actions.append(action)
		for i in visible_actions.size():
			var b: Button = buttons[visible_actions[i]]
			b.position = Vector2(20 + i*584.0/visible_actions.size(),301)
			b.size = Vector2(574.0/visible_actions.size(),52)
		var choices: Array = f.get("choices",[])
		for i in 3:
			choice_buttons[i].text = str(choices[i]) if i<choices.size() else "PICK "+str(i+1)
			choice_buttons[i].add_theme_font_size_override("font_size",16)
		if last_feature_id != str(f.get("id","")):
			skill_elapsed = 0.0
			last_feature_id = str(f.get("id",""))
	_save()

func _save() -> void:
	if engine and not on_arcade:
		snapshots[current_id] = engine.snapshot()
	save_ok = SaveStore.save({"current_machine":current_id,"machines":snapshots,"preferences":preferences,"unlocked":["last_orders","empire_estates","time_shift"]})

func _show_rules() -> void:
	var config := engine.config
	var body := "Stake: %d fictional credits. Top decorative prize: %d credits.\n\n" % [int(config.stake),int(config.jackpot)]
	body += "PAYTABLE — Three matching symbols on the center line\n"
	for id: String in config.paytable:
		body += "%s: %d credits\n" % [str(config.symbols[id].get("label",id)),int(config.paytable[id])]
	body += "\n"+"\n\n".join(config.get("rules",[]))
	body += "\n\nCONTROL GUIDE\nSTART spins. Lit HOLD buttons preserve their reel on your next paid spin. NUDGE moves a reel exactly one strip stop. COLLECT moves the available award into the prize bank. BANK → PLAY transfers bank credits into playable credits. FREE CREDITS is unlimited. EXCHANGE uses the current offer under the feature's printed rules. CANCEL declines the current hold/nudge opportunity.\n\nNumbers overprinted on symbols advance the trail. Feature decisions and probabilities are explained in the panel. HI/LO uses independent numbers 1–12; equality loses unless protected. STOP uses lamps 1–12 changing every 100ms; lamps 6 or 7 score the top award. Reduced motion freezes the cursor at lamp 1 (20-credit skill award).\n\nAll results are independent PRNG events. No guaranteed return percentage is advertised. No real money, payments or redeemable value."
	_show_text(str(config.name).to_upper()+" / RULES",body)

func _show_stats() -> void:
	var body := "THIS CABINET\n\n"
	for key: String in engine.stats:
		body += key.replace("_"," ").capitalize()+": "+str(engine.stats[key])+"\n"
	body += "\nPlay credits: %d\nBank credits: %d\n\nAll figures refer to fictional credits. Free refills and bank transfers are not prize awards." % [engine.credits,engine.bank]
	_show_text(str(engine.config.name).to_upper()+" / STATISTICS",body)

func _show_zoom() -> void:
	_new_overlay("FEATURE GLASS / CLOSE INSPECTION")
	var enlarged := GLASS_SCENE.instantiate() as FeatureGlass
	enlarged.position = Vector2(32,231)
	enlarged.size = Vector2(656,810)
	enlarged.font = bold_font
	enlarged.number_font = body_font
	enlarged.setup(engine.config)
	enlarged.update_state(engine.trail_pos,engine.trail_progress,false,engine.feature)
	overlay.add_child(enlarged)
	_label(overlay,str(engine.config.trail_name).to_upper(),Rect2(44,1082,632,38),25,Color("f0d191"),true,true)
	_label(overlay,"Current position %d  ·  Trail progress %d" % [engine.trail_pos+1,engine.trail_progress],Rect2(44,1140,632,36),21,Color("d8e0cf"),true)
	var zoom_reels := _button(overlay,"INSPECT REELS",Rect2(146,1201,428,64),_show_reel_zoom,Color("36574b"))
	zoom_reels.tooltip_text = "Enlarge the three visible reel positions."

func _show_reel_zoom() -> void:
	_new_overlay("REEL GLASS / CENTER WINLINE")
	var large := REEL_SCENE.instantiate() as ReelView
	large.position = Vector2(38,380)
	large.size = Vector2(644,470)
	large.clip_contents = true
	large.font = bold_font
	large.setup(engine.config,engine.positions)
	large.held = engine.held
	overlay.add_child(large)
	_label(overlay,"Three matching center symbols pay the printed prize.",Rect2(45,920,630,80),22,Color("ead8ad"),true)

func _show_settings() -> void:
	_new_overlay("SOUND & ACCESSIBILITY")
	var y := 235
	for item: Array in [["mute","Mute all sound"],["vibration","Gentle button vibration"],["reduced_motion","Reduced reel motion"],["reduced_flashing","Reduced lamp flashing"],["contrast","Improved contrast"],["reminders","Optional 20-minute session reminder"]]:
		var toggle := CheckButton.new()
		toggle.text = item[1]
		toggle.position = Vector2(52,y)
		toggle.size = Vector2(616,60)
		toggle.button_pressed = preferences[item[0]]
		toggle.add_theme_font_size_override("font_size",22)
		toggle.toggled.connect(func(value: bool) -> void:
			preferences[item[0]] = value
			_apply_preferences()
			_save()
		)
		overlay.add_child(toggle)
		y += 84
	for item: Array in [["sound","EFFECTS VOLUME"],["music","AMBIENCE VOLUME"]]:
		_label(overlay,item[1],Rect2(54,y,610,32),17,Color("e8cc92"))
		var slider := HSlider.new()
		slider.position = Vector2(54,y+41)
		slider.size = Vector2(610,48)
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = preferences[item[0]]
		slider.value_changed.connect(func(value: float) -> void:
			preferences[item[0]] = value
			_apply_preferences()
			_save()
		)
		overlay.add_child(slider)
		y += 130
	_label(overlay,"Settings save automatically. All game cues are also visual.",Rect2(54,1125,610,74),19,Color("bdcabe"),true)

func _apply_preferences() -> void:
	if sounds:
		sounds.sound_volume = preferences.sound
		sounds.music_volume = preferences.music
		sounds.muted = preferences.mute
		sounds.apply_volume()
	if is_instance_valid(reels): reels.reduced_motion = preferences.reduced_motion
	if is_instance_valid(glass):
		glass.high_contrast = preferences.contrast
		glass.reduced_flashing = preferences.reduced_flashing
		glass.queue_redraw()
	if is_instance_valid(status_label):
		status_label.add_theme_color_override("font_color",Color.WHITE if preferences.contrast else Color("fee4a7"))

func _show_text(title: String, body: String) -> void:
	_new_overlay(title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(46,225)
	scroll.size = Vector2(628,1038)
	overlay.add_child(scroll)
	var label := Label.new()
	label.text = body
	label.custom_minimum_size.x = 597
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",23)
	label.add_theme_color_override("font_color",Color("e1e4d7"))
	scroll.add_child(label)

func _new_overlay(title: String) -> void:
	_close_overlay()
	overlay = Control.new()
	overlay.size = DESIGN
	stage.add_child(overlay)
	var shield := ColorRect.new()
	shield.color = Color(0,0,0,0.88)
	shield.size = DESIGN
	overlay.add_child(shield)
	_panel(overlay,Rect2(22,117,676,1259),Color("132a29"),Color("b59e6a"),2,18)
	_label(overlay,title,Rect2(45,155,630,53),25,Color("f0d49c"),true,true)
	_button(overlay,"RETURN TO ARCADE" if on_arcade else "RETURN TO CABINET",Rect2(140,1290,440,60),_close_overlay,Color("41604a"))

func _close_overlay() -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
		overlay.hide()
	overlay = null

func _panel(parent: Control, rect: Rect2, color: Color, edge: Color, border: int=1, radius: int=0) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	return panel

func _label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color, centered: bool=false, display: bool=false) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_override("font",display_font if display else body_font)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	return label

func _button(parent: Control, text: String, rect: Rect2, callback: Callable, fill: Color, edge: Color=Color("c3b683")) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.add_theme_font_override("font",bold_font)
	button.add_theme_font_size_override("font_size",17 if rect.size.y<65 else 22)
	button.add_theme_color_override("font_color",Color("fff1cd"))
	button.add_theme_color_override("font_disabled_color",Color("959a8e"))
	for state: String in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = fill.darkened(0.68) if state == "disabled" else fill
		if state == "hover": style.bg_color = fill.lightened(0.15)
		if state == "pressed": style.bg_color = fill.darkened(0.15)
		style.border_color = edge.darkened(0.6) if state == "disabled" else edge
		style.set_border_width_all(1 if state == "disabled" else 2)
		style.border_width_bottom = 5 if state != "pressed" else 1
		style.set_corner_radius_all(8)
		style.content_margin_left = 6
		style.content_margin_right = 6
		button.add_theme_stylebox_override(state,style)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
