extends SceneTree
## Headless integration tests exercise the production engine, not a second model.
## godot --headless --path . --script res://tests/test_runner.gd

const EngineScript = preload("res://scripts/gameplay/reel_engine.gd")
const Library = preload("res://scripts/machines/machine_library.gd")
const Persistence = preload("res://scripts/core/save_store.gd")
const RngScript = preload("res://scripts/core/sim_rng.gd")

var assertions: int = 0
var failures: Array[String] = []
var groups: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_configurations()
	_test_alignment()
	_test_controls_and_accounting()
	_test_hold()
	_test_nudge()
	_test_save_store()
	_test_interruption()
	_test_reproducibility()
	_test_paytable()
	_test_feature_trails()
	_test_features()
	_test_retro_bonuses()
	_test_hilo()
	_test_collect_exchange()
	var report := {
		"engine_version": Engine.get_version_info().string,
		"assertions": assertions,
		"groups": groups,
		"failures": failures,
		"passed": failures.is_empty()
	}
	DirAccess.make_dir_recursive_absolute("res://builds")
	var file := FileAccess.open("res://builds/test-results.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	if failures.is_empty():
		print("TEST PASS: %d assertions across %d groups" % [assertions, groups.size()])
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: " + failure)
		printerr("TEST FAILED: %d failures / %d assertions" % [failures.size(), assertions])
		quit(1)

func _check(condition: bool, detail: String) -> void:
	assertions += 1
	if not condition:
		failures.append(detail)

func _new_game(id: String = "last_orders", seed_value: int = 42):
	var game = EngineScript.new()
	game.configure(Library.get_machine(id), seed_value)
	return game

func _quiet_config(id: String = "last_orders") -> Dictionary:
	var config: Dictionary = Library.get_machine(id).duplicate(true)
	for symbol in config.symbols:
		config.symbols[symbol].number = 0
	return config

func _test_configurations() -> void:
	groups.append("all machine configurations and validation")
	var machines: Array = Library.all()
	_check(machines.size() >= 3, "Three complete machines load")
	for id in ["last_orders", "empire_estates", "time_shift"]:
		var machine: Dictionary = Library.get_machine(id)
		_check(not machine.is_empty(), id + " is registered")
		_check(Library.validate(machine).is_empty(), id + " validates")
		_check(machine.trail.size() == int(machine.trail_length), id + " board matches declared length")
		for strip in machine.strips:
			for symbol in strip:
				_check(machine.symbols.has(symbol), id + " has artwork/rules for each reel symbol")
	var invalid: Dictionary = Library.get_machine("last_orders").duplicate(true)
	invalid.strips = [["missing"], [], []]
	_check(not Library.validate(invalid).is_empty(), "Malformed strips are rejected")

func _test_alignment() -> void:
	groups.append("reel centre and wrap-around alignment")
	for id in ["last_orders", "empire_estates", "time_shift"]:
		var game = _new_game(id)
		for reel in range(3):
			var strip: Array = game.config.strips[reel]
			for position in range(strip.size()):
				game.positions[reel] = position
				var visible: Array = game.visible_symbols(reel)
				_check(visible.size() == 3, id + " reel shows three physical stops")
				for row in range(3):
					var expected: String = strip[posmod(position + row - 1, strip.size())]
					_check(str(visible[row].id) == expected, "%s reel %d stop %d row %d aligned" % [id, reel, position, row])

func _test_controls_and_accounting() -> void:
	groups.append("invalid inputs, rapid repeated input and credit boundaries")
	var game = _new_game()
	var before: String = JSON.stringify(game.snapshot())
	_check(not game.act("invented_button"), "Unknown action rejected")
	_check(not game.act("hi"), "HI rejected outside gamble")
	_check(not game.act("nudge_up_0"), "Nudge rejected without offer")
	_check(JSON.stringify(game.snapshot()) == before, "Invalid input leaves complete engine state unchanged")
	var initial_credits: int = game.credits
	_check(game.act("start"), "START accepted in idle")
	for repeat in range(30):
		_check(not game.act("start"), "Repeated START during spin rejected")
	_check(game.credits == initial_credits - int(game.config.stake), "Rapid START only charges one stake")
	_check(game.state == "SPINNING", "Spin retains committed state while animating")
	game.finish_spin()
	var finished: String = JSON.stringify(game.snapshot())
	game.finish_spin()
	_check(JSON.stringify(game.snapshot()) == finished, "Repeated animation-complete cannot evaluate twice")
	var poor = _new_game()
	poor.credits = 0
	_check(not poor.act("start"), "Cannot spend unavailable credits")
	_check(poor.credits == 0, "Credit balance never becomes negative")
	_check(poor.act("refill"), "Free refill works")
	_check(poor.credits > 0, "Free refill supplies fictional credits")

func _test_hold() -> void:
	groups.append("actual hold preservation")
	var game = _new_game()
	game.state = "HOLD_OFFER"
	game.positions = [9, 3, 16]
	_check(game.act("hold_0"), "Offered HOLD 1 toggles")
	_check(bool(game.held[0]), "HOLD lights selected reel")
	_check(game.act("start"), "START accepts held spin")
	_check(int(game.positions[0]) == 9, "Held physical stop is preserved")
	game.finish_spin()
	var idle = _new_game()
	_check(not idle.act("hold_0"), "HOLD cannot be forced outside offer")

func _test_nudge() -> void:
	groups.append("physical nudge direction and allowance")
	for direction in ["up", "down"]:
		var game = _new_game()
		game.state = "NUDGE_OFFER"
		game.nudges = 2
		game.positions = [0, 1, 2]
		_check(game.act("nudge_%s_0" % direction), "Offered nudge %s works" % direction)
		var expected: int = game.config.strips[0].size() - 1 if direction == "up" else 1
		_check(int(game.positions[0]) == expected, "Nudge %s moves one configured strip stop" % direction)
		_check(game.nudges == 1, "Nudge consumes exactly one allowance")
		_check(int(game.positions[1]) == 1 and int(game.positions[2]) == 2, "Nudge changes only selected reel")

func _test_save_store() -> void:
	groups.append("atomic persistence and corruption recovery")
	var path := "user://reelworks_test_save.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(path + suffix)
	var data: Dictionary = {"credits": 123, "bank": 456, "preferences": {"mute": true}, "machine": "last_orders"}
	_check(Persistence.save(data, path), "Save succeeds")
	_check(_json_equivalent(Persistence.load_save(path), data), "All persistence fields round-trip")
	data.credits = 99
	_check(Persistence.save(data, path), "Atomic replacement succeeds")
	_check(int(Persistence.load_save(path).credits) == 99, "Latest committed save is loaded")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{truncated")
	file.close()
	_check(int(Persistence.load_save(path).credits) == 123, "Corrupt current file falls back to previous complete snapshot")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(path + suffix)

func _test_interruption() -> void:
	groups.append("spin interruption and exactly-once restoration")
	for id in ["last_orders", "empire_estates", "time_shift"]:
		var game = _new_game(id, 1701)
		_check(game.act("start"), id + " interruption test spin starts")
		var raw_snapshot: Dictionary = game.snapshot()
		var serialized: Dictionary = JSON.parse_string(JSON.stringify(raw_snapshot))
		var resumed = _new_game(id, 999)
		_check(resumed.restore(serialized), id + " pending spin JSON restore succeeds")
		_check(_json_equivalent(resumed.positions, game.positions), id + " committed stops survive interruption")
		_check(resumed.credits == game.credits, id + " committed stake survives interruption")
		game.finish_spin()
		resumed.finish_spin()
		_check(_json_equivalent(resumed.snapshot(), game.snapshot()), id + " resumed evaluation matches uninterrupted evaluation")
		var after: String = JSON.stringify(resumed.snapshot())
		resumed.finish_spin()
		_check(JSON.stringify(resumed.snapshot()) == after, id + " resumed spin cannot award twice")

func _test_reproducibility() -> void:
	groups.append("deterministic random stream and snapshot continuation")
	var first = _new_game("last_orders", 7832)
	var second = _new_game("last_orders", 7832)
	for index in range(100):
		_check(first.act("start") and second.act("start"), "Seeded engines accept same start")
		_check(first.positions == second.positions, "Equal seeds produce equal independent stops")
		first.finish_spin()
		second.finish_spin()
		_drain(first)
		_drain(second)
		_check(JSON.stringify(first.snapshot()) == JSON.stringify(second.snapshot()), "Same inputs and seed preserve complete state")

func _test_paytable() -> void:
	groups.append("complete advertised paytables")
	for id in ["last_orders", "empire_estates", "time_shift"]:
		var game = _new_game(id)
		for symbol in game.config.paytable:
			for reel in range(3):
				game.positions[reel] = game.config.strips[reel].find(symbol)
			_check(game.evaluate_prize() == int(game.config.paytable[symbol]), "%s triple %s pays exact advertised prize" % [id, symbol])
			var other: String = "lemon" if symbol == "cherry" else "cherry"
			game.positions[2] = game.config.strips[2].find(other)
			_check(game.evaluate_prize() == 0, "%s two %s cannot pay triple" % [id, symbol])
		game.positions = [0, 0, 0]
		for reel in range(3):
			game.positions[reel] = game.config.strips[reel].find("cherry")
		game.state = "SPINNING"
		game.finish_spin()
		_check(game.state == "AWARD_COLLECTION", id + " real triple enters award collection")
		_check(int(game.feature.pot) == int(game.config.paytable.cherry), id + " real evaluation sets exact pot")

func _test_feature_trails() -> void:
	groups.append("number trails and board movement")
	for id in ["last_orders", "empire_estates", "time_shift"]:
		var game = _new_game(id)
		game.trail_progress = int(game.config.trail_length) - 1
		game.trail_pos = int(game.config.trail_length) - 1
		for reel in range(3):
			game.positions[reel] = game.config.strips[reel].find("lemon")
		game.state = "SPINNING"
		game.finish_spin()
		_check(game.state == "FEATURE_ENTRY", id + " numbered centre symbols trigger trail threshold")
		_check(game.trail_progress == 2, id + " trail retains remainder beyond threshold")
		_check(game.trail_pos == 2, id + " trail wraps physical board")
		_check(game.act("feature_start"), id + " FEATURE START enters board")
		_check(game.feature.id == "board", id + " normal number entry starts board")
		var expected_rng = RngScript.new(1)
		expected_rng.restore(game.rng.snapshot())
		var expected_roll: int = expected_rng.range_int(1, 6)
		var start_position: int = game.trail_pos
		var old_turns: int = int(game.feature.turns)
		# Replace only landing content for this movement test; production move rule stays unchanged.
		for square in game.config.trail:
			square.kind = "cash"
			square.value = 10
		var old_pot: int = int(game.feature.pot)
		var action := "choice_1" if id == "empire_estates" else "continue"
		_check(game.act(action), id + " board movement accepts valid control")
		var route_offset: int = 1 if id == "empire_estates" else 0
		_check(game.trail_pos == posmod(start_position + expected_roll + route_offset, int(game.config.trail_length)), id + " board moves by declared random die and route")
		_check(int(game.feature.turns) == old_turns - 1, id + " one move consumes one board turn")
		_check(int(game.feature.pot) == old_pot + 10, id + " landing cash is added exactly once")
		if id == "empire_estates":
			_check(int(game.districts[1]) == expected_roll, "District choice accumulates selected branch")
		_check(game.act("collect"), id + " board pot can be collected")
		_check(game.bank == old_pot + 10, id + " board collection credits exact pot")

func _test_features() -> void:
	groups.append("all reusable and themed bonuses complete")
	var unique_features: Dictionary = {}
	for machine in Library.all():
		for id in machine.features:
			if not unique_features.has(id):
				unique_features[id] = machine.id
	for id in Library.FEATURE_IDS:
		var machine_id: String = str(unique_features.get(id, "last_orders"))
		for seed_value in [11, 42, 150]:
			var game = _new_game(machine_id, seed_value)
			game._launch_bonus(id)
			_check(not game.available_actions().is_empty(), id + " has implemented legal controls")
			_check(_exercise_bonus(game), id + " completes without deadlock")
			_check(game.bank >= 0 and game.credits >= 0, id + " preserves nonnegative balances")
			_check(int(game.stats.feature_counts.get(id, 0)) == 1, id + " entry counted once")
	# Exact skill payout depends on visible lamp rather than a later random draw.
	for cursor in range(12):
		var skill = _new_game()
		skill._launch_bonus("darts_dash")
		var draws: int = skill.rng.draws
		_check(skill.act("stop", cursor), "Darts STOP accepts displayed lamp")
		var expected: int = 120 if cursor in [5, 6] else (60 if cursor in [4, 7] else 20)
		_check(int(skill.feature.pot) == expected, "Darts lamp %d follows published table" % (cursor + 1))
		_check(skill.rng.draws == draws, "Darts timing award uses no hidden random event")
		_check(skill.act("stop",cursor),"Second dart accepted")
		var resumed = _new_game()
		_check(resumed.restore(JSON.parse_string(JSON.stringify(skill.snapshot()))),"Darts restore between throws")
		_check(resumed.act("stop",cursor),"Third dart completes")
		_check(int(resumed.feature.pot) == expected*3,"Three dart score accumulated exactly")
		_check(not resumed.act("stop",cursor),"Fourth dart rejected")
	# A WIN SPIN must produce an actual configured centre-line triple.
	var winning = _new_game()
	winning._launch_bonus("win_spin")
	winning.act("continue")
	_check(winning.evaluate_prize() > 0, "Win Spin aligns actual matching strip symbols")
	_check(winning.evaluate_prize() == int(winning.feature.pot), "Win Spin pays the matching symbol's real prize")
	# Property route, era jump and rewind retain meaningful machine-specific state.
	var property_game = _new_game("empire_estates")
	property_game._launch_bonus("property_pick")
	property_game.act("choice_2")
	_check(bool(property_game.unlocked_buildings[2]), "Property Pick unlocks selected original property")
	_check(property_game.building_icons == 1, "Property Pick adds construction progress")
	var time_game = _new_game("time_shift")
	time_game._launch_bonus("time_jump")
	time_game.act("choice_2")
	_check(time_game.era == 2 and time_game.trail_pos == 16, "Time Jump relocates to selected era")
	_check(str(time_game.feature.id) == "temporal_surge", "Future selects its declared temporal feature")
	var rewind = _new_game("time_shift")
	rewind.prior_positions = [2, 7, 18]
	rewind.rewind_available = true
	_check(rewind.act("rewind"), "Earned REWIND accepted")
	_check(rewind.positions == [2, 7, 18], "REWIND restores actual preceding stops")
	_check(not rewind.act("rewind"), "REWIND token consumed exactly once")
	# Board modifiers survive nested features and change later resolution.
	var board = _new_game()
	board._start_board()
	board._launch_bonus("extra_life")
	board.act("continue")
	_check(int(board.feature.lives) == 1, "Extra Life persists on board")
	board._launch_bonus("no_lose")
	board.act("continue")
	_check(bool(board.feature.no_lose), "No Lose persists on board")
	board._launch_bonus("feature_upgrade")
	board.act("continue")
	_check(int(board.feature.upgrade) == 2, "Feature Upgrade increments board multiplier")
	var pot: int = int(board.feature.pot)
	board._launch_bonus("add_again")
	board.act("continue")
	_check(int(board.feature.pot) == pot * 3, "Add Again uses current pot and declared board multiplier")
	# Save during a partially revealed streak continues once from the recorded stage.
	var streak = _new_game()
	streak._launch_bonus("last_call_streak")
	streak.act("continue")
	var resumed = _new_game()
	_check(resumed.restore(JSON.parse_string(JSON.stringify(streak.snapshot()))), "Partially revealed bonus restores")
	_check(_exercise_bonus(streak) and _exercise_bonus(resumed), "Restored streak completes")
	_check(streak.bank == resumed.bank and streak.award_serial == resumed.award_serial, "Restored streak grants exactly the uninterrupted award")

func _test_hilo() -> void:
	groups.append("hi-lo strict comparison, equals and protection")
	for high in [true, false]:
		for outcome in [3, 6, 9]:
			var game = _new_game()
			game._launch_bonus("cash_climb", 40)
			game.feature.number = 6
			game.rng = RngScript.new(_seed_for_number(outcome))
			var action := "hi" if high else "lo"
			_check(game.act(action), "Valid %s prediction accepted" % action)
			var expected_win: bool = outcome > 6 if high else outcome < 6
			if expected_win:
				_check(game.state == "GAMBLE" and int(game.feature.pot) == 80, "%s 6 to %d doubles exact pot" % [action, outcome])
			else:
				_check(game.state == "IDLE" and game.bank == 0, "%s 6 to %d loses unprotected pot, including equality" % [action, outcome])
	var protected = _new_game()
	protected._launch_bonus("cash_climb", 40)
	protected.feature.number = 6
	protected.feature.no_lose = true
	protected.rng = RngScript.new(_seed_for_number(6))
	protected.act("hi")
	_check(protected.state == "GAMBLE" and int(protected.feature.pot) == 40, "No Lose protects an equal result")
	_check(not bool(protected.feature.no_lose), "No Lose consumed once")
	protected.act("collect")
	_check(protected.state == "IDLE" and protected.bank == 40, "Protected standalone gamble collects without phantom board")
	var extra = _new_game()
	extra._launch_bonus("cash_climb", 40)
	extra.feature.number = 6
	extra.feature.lives = 1
	extra.rng = RngScript.new(_seed_for_number(3))
	extra.act("hi")
	_check(extra.state == "GAMBLE" and int(extra.feature.lives) == 0, "Extra Life absorbs one wrong prediction")
	var boundary = _new_game()
	boundary._launch_bonus("cash_climb", 40)
	boundary.feature.number = 1
	_check(not boundary.available_actions().has("lo"), "Impossible LO at 1 is unlit and rejected")
	boundary.feature.number = 12
	_check(not boundary.available_actions().has("hi"), "Impossible HI at 12 is unlit and rejected")

func _test_collect_exchange() -> void:
	groups.append("collect, exchange and prize pots")
	var game = _new_game()
	game._set_award(80, "Test triple")
	_check(game.act("collect"), "COLLECT accepts pending award")
	_check(game.bank == 80 and game.award_serial == 1, "COLLECT banks exact amount once")
	for repeat in range(30):
		_check(not game.act("collect"), "Repeated COLLECT rejected after award consumed")
	_check(game.bank == 80, "Repeated collection never duplicates award")
	var before: int = game.credits
	_check(game.act("transfer"), "Transfer-to-play consumes bank")
	_check(game.credits == before + 80 and game.bank == 0, "Transfer preserves total fictional value")
	_check(not game.act("transfer"), "Empty bank cannot transfer twice")
	game._set_award(80, "Test triple")
	_check(game.act("exchange"), "Award EXCHANGE enters ladder")
	_check(game.state == "GAMBLE" and int(game.feature.pot) == 80, "Exchange carries exact award to cash ladder")
	_check(game.bank == 0, "Exchanged award is not also banked")
	_check(game.act("exchange"), "Ladder EXCHANGE accepts secure half alternative")
	_check(game.state == "AWARD_COLLECTION" and int(game.feature.pot) == 40, "Ladder exchange pays exact published half")
	game.act("collect")
	_check(game.bank == 40, "Exchanged cash can be collected once")
	var cash = _new_game()
	cash._launch_bonus("cash_pot")
	cash.act("continue")
	_check(int(cash.feature.pot) >= 20 and int(cash.feature.pot) <= 100 and int(cash.feature.pot) % 10 == 0, "Cash Pot awards only its published set")
	var invalid: Dictionary = cash.snapshot()
	invalid.credits = -1
	var untouched: String = JSON.stringify(cash.snapshot())
	_check(not cash.restore(invalid), "Negative-balance snapshot rejected")
	_check(JSON.stringify(cash.snapshot()) == untouched, "Rejected restore is atomic")

func _seed_for_number(number: int) -> int:
	for seed_value in range(10000):
		var candidate = RngScript.new(seed_value)
		if candidate.range_int(1, 12) == number:
			return seed_value
	return 0

func _exercise_bonus(game) -> bool:
	var attempts: Dictionary = {}
	for step in range(300):
		if game.state == "SPINNING":
			game.finish_spin()
			continue
		var actions: Array = game.available_actions()
		var id: String = str(game.feature.get("id", ""))
		var action: String = ""
		var value: int = 0
		if actions.has("feature_start"):
			action = "feature_start"
		elif game.state == "AWARD_COLLECTION":
			action = "collect"
		elif game.state == "GAMBLE":
			action = "collect"
		elif id == "board":
			if int(game.feature.get("turns", 0)) > 0:
				action = "choice_1" if actions.has("choice_1") else "continue"
			else:
				action = "collect"
		elif actions.has("stop"):
			action = "stop"
			value = 6
		elif actions.has("choice_0"):
			action = "choice_0"
		elif actions.has("nudge_up_0"):
			action = "nudge_up_%d" % (step % 3)
		elif actions.has("continue"):
			action = "continue"
		elif actions.has("start"):
			return true
		elif actions.has("cancel"):
			action = "cancel"
		elif actions.has("collect"):
			action = "collect"
		else:
			return false
		attempts[id] = int(attempts.get(id, 0)) + 1
		if not game.act(action, value):
			return false
	return false

func _drain(game, max_steps: int = 200) -> bool:
	for step in range(max_steps):
		if game.state == "SPINNING":
			game.finish_spin()
			continue
		var actions: Array = game.available_actions()
		if actions.has("feature_start"):
			game.act("feature_start")
		elif actions.has("collect"):
			game.act("collect")
		elif actions.has("choice_0"):
			game.act("choice_0")
		elif actions.has("stop"):
			game.act("stop", 6)
		elif actions.has("continue"):
			game.act("continue")
		elif actions.has("start"):
			return true
		elif actions.has("cancel"):
			game.act("cancel")
		elif actions.has("hi"):
			game.act("hi")
		elif actions.has("lo"):
			game.act("lo")
		else:
			return false
	return false

func _json_equivalent(left: Variant, right: Variant) -> bool:
	return JSON.stringify(JSON.parse_string(JSON.stringify(left))) == JSON.stringify(JSON.parse_string(JSON.stringify(right)))

func _test_retro_bonuses() -> void:
	groups.append("independent cellar, property and phase-lock decisions")
	var barrel = _new_game()
	barrel._launch_bonus("mystery_barrel")
	barrel.feature.barrels = [40,0,80]
	_check(barrel.act("choice_0") and int(barrel.feature.pot)==60,"Barrel adds its saved hidden award")
	_check(not barrel.act("choice_0"),"Opened barrel cannot be picked twice")
	var resumed = _new_game()
	_check(resumed.restore(JSON.parse_string(JSON.stringify(barrel.snapshot()))),"Cellar hidden order restores")
	resumed.act("choice_1")
	_check(int(resumed.feature.pot)==60 and resumed.state=="AWARD_COLLECTION","Empty barrel retains accumulated pot and ends")
	var phase = _new_game("time_shift")
	phase._launch_bonus("paradox_mystery")
	for i in 3: _check(phase.act("choice_0"),"Stable phase accepts one lock")
	_check(phase.state=="AWARD_COLLECTION" and int(phase.feature.pot)==30,"Three stable phase locks pay exactly thirty")
	_check(not phase.act("choice_0"),"Fourth phase lock rejected")
	var estate = _new_game("empire_estates")
	estate._launch_bonus("property_pick")
	estate.act("choice_2")
	_check(int(estate.feature.pot)==80 and estate.state=="FEATURE_ACTIVE","Property requires a separate development decision")
	estate.act("choice_2")
	_check(int(estate.feature.pot)==40 and estate.building_icons==3,"Building floor trades half rent for two construction icons")
