extends SceneTree
## Development-only Monte Carlo runner. Uses the real engine and legal inputs.
## godot --headless --path . --script res://tests/simulation.gd -- --spins=100000

const EngineScript = preload("res://scripts/gameplay/reel_engine.gd")
const Library = preload("res://scripts/machines/machine_library.gd")

var event_counts: Dictionary = {}
var feature_counts: Dictionary = {}
var policy_rng := RandomNumberGenerator.new()
var total_transitions: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var spins: int = 100000
	var seed_value: int = 470200
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--spins="):
			spins = maxi(1, int(argument.get_slice("=", 1)))
		if argument.begins_with("--seed="):
			seed_value = int(argument.get_slice("=", 1))
	var results: Dictionary = {
		"engine_version": Engine.get_version_info().string,
		"seed": seed_value,
		"spins_per_machine": spins,
		"policy": "Use offered nudges; independently choose up to one hold before paid spins. Enter offered features. Play all board turns and free reel-control bonuses. Choose uniformly between offered choices; in the barrel raid make one pick then collect with probability 1/3 or pick again; attempt one hi-lo per paid spin using the more likely direction then collect; play repeat and reveal features to completion. Collect completed prizes. Skill stops are uniform over 12 positions. No bank transfers.",
		"note": "Observed virtual return for this explicit simulation policy, not an advertised RTP. Features and player choices affect return. Includes feature awards funded by each paid spin.",
		"machines": []
	}
	var index: int = 0
	for machine in Library.all():
		var result: Dictionary = _simulate(machine, spins, seed_value + index)
		if result.has("error"):
			printerr(JSON.stringify(result))
			quit(1)
			return
		results.machines.append(result)
		index += 1
		print("SIMULATION %s: %d spins, %.3f%% observed return, %d feature entries" % [machine.id, spins, result.virtual_return_percent, result.feature_entries])
	DirAccess.make_dir_recursive_absolute("res://builds")
	var output := FileAccess.open("res://builds/simulation-results.json", FileAccess.WRITE)
	if output == null:
		printerr("Cannot write simulation report")
		quit(1)
		return
	output.store_string(JSON.stringify(results, "\t", true, true))
	output.close()
	print("SIMULATION PASS: %d paid spins; report builds/simulation-results.json" % (spins * results.machines.size()))
	quit(0)

func _simulate(machine: Dictionary, spins: int, seed_value: int) -> Dictionary:
	var game = EngineScript.new()
	game.configure(machine, seed_value)
	game.credits = maxi(1000, int(machine.stake) * spins + 1000)
	policy_rng.seed = seed_value + 10000000
	event_counts = {}
	feature_counts = {}
	total_transitions = 0
	game.changed.connect(_count_event)
	var histogram: Dictionary = {}
	var win_count: int = 0
	var awards: int = 0
	var last_feature: String = ""
	for spin_index in range(spins):
		var actions: Array = game.available_actions()
		if not actions.has("start"):
			return {"error": "Cannot start paid spin", "machine": machine.id, "spin": spin_index, "state": game.state, "actions": actions}
		# Hold policy is independent of the engine RNG and does not inspect hidden stops.
		var possible_holds: Array = []
		for reel in range(3):
			if actions.has("hold_%d" % reel):
				possible_holds.append("hold_%d" % reel)
		if not possible_holds.is_empty() and policy_rng.randf() < 0.5:
			game.act(possible_holds[policy_rng.randi_range(0, possible_holds.size() - 1)])
		var before_bank: int = game.bank
		if not game.act("start"):
			return {"error": "Legal start rejected", "machine": machine.id, "spin": spin_index}
		game.finish_spin()
		var gambled: bool = false
		last_feature = ""
		var settled: bool = false
		for transition in range(300):
			total_transitions += 1
			actions = game.available_actions()
			if game.state == "SPINNING":
				game.finish_spin()
				continue
			var current_feature: String = str(game.feature.get("id", ""))
			if not current_feature.is_empty() and current_feature != last_feature:
				feature_counts[current_feature] = int(feature_counts.get(current_feature, 0)) + 1
				last_feature = current_feature
			var action: String = ""
			var value: int = 0
			if actions.has("feature_start"):
				action = "feature_start"
			elif current_feature == "board":
				if int(game.feature.get("turns", 0)) > 0:
					action = "choice_%d" % policy_rng.randi_range(0, 2) if actions.has("choice_0") else "continue"
				else:
					action = "collect"
			elif current_feature == "mystery_barrel" and game.feature.has("opened"):
				var picks: Array = []
				for i in 3:
					if actions.has("choice_%d" % i): picks.append("choice_%d" % i)
				action = "collect" if game.feature.opened.size()>0 and policy_rng.randi_range(0,2)==0 else str(picks[policy_rng.randi_range(0,picks.size()-1)])
			elif current_feature == "super_hold":
				action = "continue"
			elif current_feature in ["super_nudges", "super_shift"]:
				action = "nudge_%s_%d" % ["up" if policy_rng.randi_range(0, 1) == 0 else "down", policy_rng.randi_range(0, 2)]
			elif current_feature in ["cash_repeater", "auction_offer"]:
				action = "continue"
			elif actions.has("hi") or actions.has("lo"):
				if gambled and actions.has("collect"):
					action = "collect"
				else:
					action = "hi" if int(game.feature.get("number", 6)) <= 6 else "lo"
					if not actions.has(action):
						action = "lo" if action == "hi" else "hi"
					gambled = true
			elif actions.has("collect"):
				action = "collect"
			elif actions.has("stop"):
				action = "stop"
				value = policy_rng.randi_range(0, 11)
			elif actions.has("choice_0"):
				var choices: Array = []
				for choice in range(3):
					if actions.has("choice_%d" % choice):
						choices.append("choice_%d" % choice)
				action = choices[policy_rng.randi_range(0, choices.size() - 1)]
			elif actions.has("continue"):
				action = "continue"
			elif actions.has("nudge_up_0"):
				action = "nudge_%s_%d" % ["up" if policy_rng.randi_range(0, 1) == 0 else "down", policy_rng.randi_range(0, 2)]
			elif actions.has("start"):
				settled = true
				break
			elif actions.has("cancel"):
				action = "cancel"
			else:
				return {"error": "No simulation action", "machine": machine.id, "spin": spin_index, "state": game.state, "feature": game.feature, "actions": actions}
			if not game.act(action, value):
				return {"error": "Legal action rejected", "machine": machine.id, "spin": spin_index, "action": action, "state": game.state}
		if not settled:
			return {"error": "Transition budget exceeded", "machine": machine.id, "spin": spin_index, "state": game.state}
		var won: int = game.bank - before_bank
		if won < 0 or game.credits < 0:
			return {"error": "Negative accounting", "machine": machine.id, "spin": spin_index}
		awards += won
		if won > 0:
			win_count += 1
		var key := str(won)
		histogram[key] = int(histogram.get(key, 0)) + 1
	feature_counts = game.stats.feature_counts.duplicate(true)
	var feature_entries: int = 0
	for count in feature_counts.values():
		feature_entries += int(count)
	return {
		"machine": machine.id, "seed": seed_value, "paid_spins": spins,
		"wager_credits": spins * int(machine.stake), "awarded_credits": awards,
		"virtual_return_percent": 100.0 * float(awards) / float(spins * int(machine.stake)),
		"winning_spins": win_count, "win_frequency": float(win_count) / float(spins),
		"win_distribution": histogram, "event_frequencies": event_counts.duplicate(),
		"feature_frequencies": feature_counts.duplicate(), "feature_entries": feature_entries,
		"feature_transitions": total_transitions, "final_state": game.state
	}

func _count_event(event: String) -> void:
	event_counts[event] = int(event_counts.get(event, 0)) + 1
