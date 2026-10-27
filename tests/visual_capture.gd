extends SceneTree
## Run under an X11/Wayland renderer, never exported to Android.
var app: Control
func _initialize() -> void:
	call_deferred("_run")
func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/screenshots/"+name+".png")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/screenshots")
	app = load("res://scenes/arcade/main.tscn").instantiate()
	root.add_child(app)
	app.preferences.mute = true
	app._apply_preferences()
	OS.low_processor_usage_mode = false
	await create_timer(0.3).timeout
	await _capture("arcade")
	for id: String in ["last_orders","empire_estates","time_shift"]:
		app._open_machine(id)
		app.engine.configure(MachineLibrary.get_machine(id),4702)
		app._sync()
		await _capture(id)
		app.engine.state = "FEATURE_ENTRY"
		app.engine.feature = {"id":"board","pot":60}
		app.engine.act("feature_start")
		app._sync()
		await _capture(id+"_board")
	app.engine._launch_bonus("temporal_hi_lo",40)
	app._sync()
	await _capture("temporal_hilo")
	app._open_machine("last_orders")
	app.engine._launch_bonus("darts_dash")
	app._sync()
	await create_timer(0.5).timeout
	await _capture("darts_dash")
	app.engine = null
	app.sounds.shutdown()
	await create_timer(0.1).timeout
	app.queue_free()
	await process_frame
	print("VISUAL CAPTURE PASS")
	quit()
