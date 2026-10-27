extends SceneTree
## Exercises real UI scene and checks every legal engine action is touch reachable.
var errors: Array[String] = []
var assertions := 0
var app: Control
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, detail: String) -> void:
	assertions += 1
	if not ok: errors.append(detail)
func _run() -> void:
	app = load("res://scenes/arcade/main.tscn").instantiate()
	root.add_child(app)
	app.preferences.mute = true
	app._apply_preferences()
	await process_frame
	_check(app.on_arcade,"Starts in arcade")
	for id: String in ["last_orders","empire_estates","time_shift"]:
		app._open_machine(id)
		await process_frame
		app.engine.configure(MachineLibrary.get_machine(id),4702)
		app._sync()
		_check(app.glass.art != null,id+" has glass")
		_check(app.reels.textures.size() >= 6,id+" has reel assets")
		app.engine.state = "HOLD_OFFER"
		app.engine.act("hold_0")
		var before: float = app.reels.display_positions[0]
		app.last_input_ms = -1000
		app._act("start")
		_check(app.reels.spinning,"Starts real spin animation")
		await create_timer(0.35).timeout
		_check(app.reels.display_positions[0] == before,"Held reel stays visually stationary")
		await create_timer(1.3).timeout
		_check(app.engine.state != "SPINNING","Reel animation completes evaluation")
		for bonus: String in ReelEngine.SUPPORTED_BONUSES:
			app.engine.configure(MachineLibrary.get_machine(id),33)
			app.engine._launch_bonus(bonus,40)
			app._sync()
			_check_actions(id+"/"+bonus)
		app.engine.configure(MachineLibrary.get_machine(id),55)
		app.engine.rewind_available = true
		app._sync()
		_check_actions(id+"/rewind idle")
		app.engine.state = "FEATURE_ENTRY"
		app.engine.feature = {"id":"board","pot":0}
		app.engine.act("feature_start")
		app._sync()
		_check_actions(id+"/board")
		app._show_zoom()
		_check(is_instance_valid(app.overlay),"Board zoom opens")
		app._show_reel_zoom()
		app._close_overlay()
		app._show_rules()
		app._close_overlay()
		app._show_settings()
		app._close_overlay()
		await process_frame
	if errors.is_empty():
		print("UI PASS: %d assertions; 3 cabinets, all 33 feature action sets, holds, zoom and settings" % assertions)
	else:
		for error in errors: printerr("FAIL "+error)
	app.engine = null # Test fixtures must not replace the player's saved game on exit.
	app.sounds.shutdown()
	await create_timer(0.1).timeout
	app.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
func _check_actions(context: String) -> void:
	for action: String in app.engine.available_actions():
		_check(app.buttons.has(action),context+": button for "+action)
		if app.buttons.has(action):
			var button: Button = app.buttons[action]
			_check(button.is_visible_in_tree(),context+": visible "+action)
			_check(not button.disabled,context+": enabled "+action)
