extends SceneTree
const EngineClass = preload("res://scripts/gameplay/reel_engine.gd")
func _initialize() -> void:
	var engine = EngineClass.new()
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/machines/last_orders.json"))
	engine.configure(data, 1234)
	for i in range(100):
		if engine.state == "SPINNING":
			engine.finish_spin()
		var actions: Array = engine.available_actions()
		if "start" in actions:
			engine.act("start")
		elif "feature_start" in actions:
			engine.act("feature_start")
		elif "continue" in actions:
			engine.act("continue")
		elif "choice_0" in actions:
			engine.act("choice_0")
		elif "stop" in actions:
			engine.act("stop", 5)
		elif "collect" in actions:
			engine.act("collect")
		elif "cancel" in actions:
			engine.act("cancel")
	print(engine.stats)
	quit()
