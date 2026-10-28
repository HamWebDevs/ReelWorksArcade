class_name ReelEngine
extends RefCounted
## All outcomes and ledger changes live here, never in animation callbacks.
signal changed(event: String)

const SUPPORTED_BONUSES: Array[String] = ["reel_skill", "win_spin", "super_hold", "super_nudges", "cash_climb", "mystery_bonus", "cash_repeater", "feature_shot", "add_again", "extra_life", "no_lose", "lucky_seven", "streak_feature", "cash_pot", "feature_upgrade", "bonus_selector", "darts_dash", "lucky_bells", "last_call_streak", "mystery_barrel", "property_pick", "auction_offer", "building_bonus", "rent_rush", "tycoon_trail", "empire_streak", "bonus_exchange", "temporal_hi_lo", "rewind", "time_jump", "temporal_surge", "super_shift", "paradox_mystery"]
const VALID_STATES: Array[String] = ["IDLE", "SPINNING", "EVALUATING", "HOLD_OFFER", "NUDGE_OFFER", "FEATURE_ENTRY", "FEATURE_ACTIVE", "GAMBLE", "AWARD_COLLECTION", "RECOVERY"]
const SKILL_IDS: Array[String] = ["reel_skill", "darts_dash", "feature_shot"]
const LADDER_IDS: Array[String] = ["cash_climb", "temporal_hi_lo", "tycoon_trail"]
const REVEAL_IDS: Array[String] = ["streak_feature", "last_call_streak", "rent_rush", "empire_streak", "temporal_surge"]
const PICK_IDS: Array[String] = ["mystery_bonus", "mystery_barrel", "property_pick", "paradox_mystery", "bonus_selector", "lucky_bells"]
var config: Dictionary = {}
var state: String = "IDLE"
var credits: int = 1000
var bank: int = 0
var positions: Array = [0, 0, 0]
var held: Array = [false, false, false]
var trail_pos: int = 0
var trail_progress: int = 0
var nudges: int = 0
var feature: Dictionary = {}
var message: String = "Choose START. All credits are fictional."
var stats: Dictionary = {}
var rng: SimRng = SimRng.new()
var board_context: Dictionary = {}
var prior_positions: Array = [0, 0, 0]
var rewind_available: bool = false
var extra_hold_spins: int = 0
var pending_trail: int = 0
var pending_special: bool = false
var pending_paid: bool = true
var award_serial: int = 0
var building_icons: int = 0
var districts: Array = [0, 0, 0]
var unlocked_buildings: Array = [false, false, false]
var era: int = 0
var _busy: bool = false

func configure(machine: Dictionary, seed_value: int = -1) -> void:
	config = machine.duplicate(true)
	state = "IDLE"
	credits = 1000
	bank = 0
	positions = [0, 0, 0]
	held = [false, false, false]
	trail_pos = 0
	trail_progress = 0
	nudges = 0
	feature = {}
	board_context = {}
	prior_positions = [0, 0, 0]
	rewind_available = false
	extra_hold_spins = 0
	pending_trail = 0
	pending_special = false
	pending_paid = true
	award_serial = 0
	building_icons = 0
	districts = [0, 0, 0]
	unlocked_buildings = [false, false, false]
	era = 0
	_busy = false
	rng = SimRng.new(seed_value)
	stats = {"spins": 0, "staked": 0, "won": 0, "wins": 0, "features": 0, "nudges": 0, "holds": 0, "gambles": 0, "gamble_wins": 0, "refills": 0, "feature_counts": {}, "win_distribution": {}}
	message = "10 fictional credits per spin. START to play."

func visible_symbols(reel: int) -> Array:
	if reel < 0 or reel >= 3 or config.is_empty():
		return []
	var strip: Array = config.strips[reel]
	var result: Array = []
	for offset: int in [-1, 0, 1]:
		var symbol_id: String = str(strip[posmod(int(positions[reel]) + offset, strip.size())])
		var item: Dictionary = config.symbols[symbol_id].duplicate(true)
		item["id"] = symbol_id
		result.append(item)
	return result

func center_ids() -> Array:
	var result: Array = []
	for reel: int in range(3):
		result.append(visible_symbols(reel)[1].id)
	return result

func evaluate_prize() -> int:
	var ids: Array = center_ids()
	if ids[0] == ids[1] and ids[1] == ids[2]:
		return int(config.paytable.get(ids[0], 0))
	return 0

func available_actions() -> Array:
	var actions: Array = []
	if config.is_empty():
		return actions
	match state:
		"IDLE", "HOLD_OFFER":
			if credits >= int(config.stake):
				actions.append("start")
			if state == "HOLD_OFFER":
				for i: int in range(3):
					actions.append("hold_%d" % i)
				actions.append("cancel")
			if rewind_available:
				actions.append("rewind")
			actions.append("refill")
			if bank > 0:
				actions.append("transfer")
		"NUDGE_OFFER":
			for i: int in range(3):
				actions.append("nudge_up_%d" % i)
				actions.append("nudge_down_%d" % i)
			actions.append("cancel")
		"FEATURE_ENTRY":
			actions.append("feature_start")
		"AWARD_COLLECTION":
			actions.append_array(["collect", "exchange"])
		"GAMBLE":
			actions.append("collect")
			if int(feature.get("number", 1)) < 12:
				actions.append("hi")
			if int(feature.get("number", 12)) > 1:
				actions.append("lo")
			actions.append("exchange")
		"FEATURE_ACTIVE":
			var id: String = str(feature.get("id", ""))
			if id == "board":
				actions.append("collect")
				if int(feature.get("turns", 0)) > 0:
					if config.id == "empire_estates":
						actions.append_array(["choice_0", "choice_1", "choice_2"])
					else:
						actions.append("continue")
			elif id in SKILL_IDS:
				actions.append("stop")
			elif id == "mystery_barrel" and feature.has("barrels"):
				actions.append("collect")
				for i in 3:
					if not i in feature.get("opened",[]): actions.append("choice_%d" % i)
			elif id in PICK_IDS or id == "time_jump":
				actions.append_array(["choice_0", "choice_1", "choice_2"])
			elif id == "auction_offer":
				actions.append_array(["collect", "continue"])
			elif id == "cash_repeater":
				actions.append_array(["collect", "continue"])
			elif id in ["super_hold", "super_nudges", "super_shift"]:
				actions.append("collect")
				if id == "super_hold":
					actions.append_array(["hold_0", "hold_1", "hold_2", "continue"])
				else:
					for i: int in range(3):
						actions.append("nudge_up_%d" % i)
						actions.append("nudge_down_%d" % i)
			else:
				actions.append("continue")
	return actions

func act(action: String, value: int = 0) -> bool:
	if _busy or not action in available_actions():
		return false
	_busy = true
	var event: String = "click"
	if action == "start":
		_start_spin()
		event = "spin"
	elif action.begins_with("hold_"):
		var index: int = int(action.get_slice("_", 1))
		held[index] = not bool(held[index])
		message = "Reel %d %s." % [index + 1, "held" if held[index] else "released"]
	elif action.begins_with("nudge_"):
		var index: int = int(action.get_slice("_", 2))
		var direction: int = -1 if action.get_slice("_", 1) == "up" else 1
		_nudge(index, direction)
		event = "move"
	elif action == "refill":
		credits += 1000
		stats.refills += 1
		message = "1,000 free fictional credits added."
	elif action == "transfer":
		credits += bank
		bank = 0
		message = "Fictional bank transferred to play credits."
		event = "collect"
	elif action == "cancel":
		if state == "NUDGE_OFFER":
			_end_base_offer()
		else:
			held = [false, false, false]
			state = "IDLE"
			message = "Holds cancelled."
	elif action == "feature_start":
		_start_board()
		event = "feature"
	elif action == "collect":
		_collect()
		event = "collect"
	elif action == "exchange":
		_exchange()
		event = "feature"
	elif action == "hi" or action == "lo":
		_gamble(action == "hi")
		event = "move" if state == "GAMBLE" else "lose"
	elif action == "rewind":
		rewind_available = false
		positions = prior_positions.duplicate()
		var award: int = evaluate_prize()
		if award > 0:
			_set_award(award, "Rewind restored a winning centre line.")
		else:
			message = "Reels rewound one recorded spin. No centre-line match."
	elif action == "stop":
		_skill_stop(clampi(value, 0, 11))
		event = "win"
	elif action.begins_with("choice_"):
		_choice(int(action.get_slice("_", 1)))
		event = "feature"
	elif action == "continue":
		_continue_feature()
		event = "move"
	_busy = false
	changed.emit(event)
	return true

func _start_spin() -> void:
	credits -= int(config.stake)
	stats.spins += 1
	stats.staked += int(config.stake)
	prior_positions = positions.duplicate()
	for i: int in range(3):
		if not held[i]:
			positions[i] = rng.range_int(0, config.strips[i].size() - 1)
		else:
			stats.holds += 1
	held = [false, false, false]
	feature = {}
	board_context = {}
	nudges = 0
	pending_paid = true
	state = "SPINNING"
	message = "Reels running…"

func finish_spin() -> void:
	if state != "SPINNING" or _busy:
		return
	state = "EVALUATING"
	pending_trail = 0
	for i: int in range(3):
		pending_trail += int(visible_symbols(i)[1].get("number", 0))
	var ids: Array = center_ids()
	pending_special = ids[0] == config.special_symbol and ids[1] == ids[0] and ids[2] == ids[0]
	if config.id == "empire_estates":
		for symbol: String in ids:
			if symbol == config.special_symbol:
				building_icons += 1
	var prize: int = evaluate_prize()
	_advance_base_trail()
	if pending_special or trail_progress >= int(config.trail_length):
		trail_progress %= int(config.trail_length)
		state = "FEATURE_ENTRY"
		feature = {"id": "board", "title": str(config.trail_name), "pot": prize, "prompt": "Feature ready. Press FEATURE START.", "special_entry": pending_special}
		message = "BONUS READY — " + str(config.trail_name)
	elif prize > 0:
		_set_award(prize, "Three %s on the centre line!" % str(config.symbols[ids[0]].label))
	else:
		_offer_controls()
	changed.emit("win" if prize > 0 else "stop")

func _advance_base_trail() -> void:
	trail_progress += pending_trail
	trail_pos = posmod(trail_pos + pending_trail, int(config.trail_length))
	era = mini(2, int(trail_pos / 8)) if config.id == "time_shift" else 0

func _offer_controls() -> void:
	if extra_hold_spins > 0:
		extra_hold_spins -= 1
		state = "HOLD_OFFER"
		message = "SUPER HOLD — preserve any reels for the next paid spin."
	elif rng.chance(int(config.get("hold_chance", [1, 4])[0]), int(config.get("hold_chance", [1, 4])[1])):
		state = "HOLD_OFFER"
		message = "HOLD offered — choose reels, then START."
	elif rng.chance(int(config.get("nudge_chance", [1, 5])[0]), int(config.get("nudge_chance", [1, 5])[1])):
		nudges = rng.range_int(1, 3)
		state = "NUDGE_OFFER"
		message = "%d nudges. Move a reel one stop up or down." % nudges
	else:
		state = "IDLE"
		message = "Trail +%d · %d/%d to feature. START again." % [pending_trail, trail_progress, int(config.trail_length)]

func _nudge(index: int, direction: int) -> void:
	positions[index] = posmod(int(positions[index]) + direction, config.strips[index].size())
	nudges = maxi(0, nudges - 1)
	stats.nudges += 1
	var prize: int = evaluate_prize()
	if state == "FEATURE_ACTIVE":
		if prize > 0:
			_finish_bonus(int(feature.get("pot", 0)) + prize, "Nudge match! +%d credits." % prize)
		elif nudges == 0:
			_finish_bonus(int(feature.get("pot", 0)), "Nudges complete.")
		else:
			feature.prompt = "%d nudges remaining. Match the centre line or collect." % nudges
	else:
		var ids: Array = center_ids()
		if ids[0] == config.special_symbol and ids[1] == ids[0] and ids[2] == ids[0]:
			nudges = 0
			state = "FEATURE_ENTRY"
			feature = {"id": "board", "title": str(config.trail_name), "pot": prize, "prompt": "Special symbols aligned. FEATURE START.", "special_entry": true}
			message = "Special symbols nudged onto the centre line!"
		elif prize > 0:
			_set_award(prize, "Nudged onto a winning centre line!")
		elif nudges == 0:
			_end_base_offer()
		else:
			message = "%d nudges remaining." % nudges

func _end_base_offer() -> void:
	nudges = 0
	state = "IDLE"
	message = "Nudges ended. START to spin."

func _set_award(amount: int, reason: String) -> void:
	state = "AWARD_COLLECTION"
	feature = {"id": "award", "title": "PRIZE READY", "pot": maxi(0, amount), "prompt": "COLLECT to bank or EXCHANGE for the cash ladder."}
	message = reason

func _credit_bank(amount: int) -> void:
	if amount <= 0:
		return
	bank += amount
	stats.won += amount
	stats.wins += 1
	award_serial += 1
	var distribution: Dictionary = stats.win_distribution
	var key: String = str(amount)
	distribution[key] = int(distribution.get(key, 0)) + 1

func _collect() -> void:
	var amount: int = int(feature.get("pot", 0))
	if not board_context.is_empty():
		_finish_bonus(amount, "Bonus collected: %d credits added to board pot." % amount)
		return
	_credit_bank(amount)
	state = "IDLE"
	feature = {}
	held = [false, false, false]
	nudges = 0
	message = "%d fictional credits banked. START to play." % amount

func _exchange() -> void:
	var amount: int = int(feature.get("pot", 0))
	if state == "AWARD_COLLECTION":
		_launch_bonus("cash_climb", amount)
	elif state == "GAMBLE":
		# Secure half of the current ladder as the explicit alternative.
		_finish_bonus(maxi(1, int(amount / 2)), "Exchanged for half the ladder value, rounded down.")

func _start_board() -> void:
	var initial: int = int(feature.get("pot", 0))
	var special: bool = bool(feature.get("special_entry", false))
	stats.features += 1
	feature = {"id": "board", "title": str(config.trail_name), "pot": initial, "turns": int(config.get("board_turns", 6)), "stage": 0, "lives": 0, "no_lose": false, "upgrade": 1, "number": 0, "zone": ["Past", "Present", "Future"][era]}
	state = "FEATURE_ACTIVE"
	_update_board_prompt()
	if special:
		_launch_bonus(str(config.get("special_feature", "bonus_selector")))

func _update_board_prompt() -> void:
	if config.id == "empire_estates":
		feature.choices = config.get("districts", ["Quayside", "Foundry", "Skyline"]).duplicate()
		feature.prompt = "%d moves · Choose a district route, or COLLECT %d." % [int(feature.get("turns", 0)), int(feature.get("pot", 0))]
	else:
		feature.erase("choices")
		feature.prompt = "%d moves · CONTINUE rolls 1–6. COLLECT banks %d." % [int(feature.get("turns", 0)), int(feature.get("pot", 0))]
	message = feature.prompt

func _board_move(route: int = 0) -> void:
	var roll: int = rng.range_int(1, 6)
	feature.turns = int(feature.turns) - 1
	feature.stage = int(feature.stage) + 1
	feature.number = roll
	if config.id == "empire_estates":
		districts[route] = int(districts[route]) + roll
		if districts[route] >= 7:
			unlocked_buildings[route] = true
			feature.pot = int(feature.pot) + 20 * (route + 1)
			districts[route] -= 7
		trail_pos = posmod(trail_pos + roll + route, int(config.trail_length))
	else:
		trail_pos = posmod(trail_pos + roll, int(config.trail_length))
	if config.id == "time_shift":
		era = mini(2, int(trail_pos / 8))
		feature.zone = ["Past", "Present", "Future"][era]
	var square: Dictionary = config.trail[trail_pos]
	var kind: String = str(square.get("kind", "cash"))
	var multiplier: int = int(feature.get("upgrade", 1))
	var note: String = "Rolled %d · %s." % [roll, str(square.label)]
	match kind:
		"cash":
			feature.pot = int(feature.pot) + int(square.value) * multiplier
		"life":
			feature.lives = int(feature.get("lives", 0)) + 1
		"upgrade":
			feature.upgrade = mini(4, multiplier + 1)
		"repeat":
			feature.turns = mini(12, int(feature.turns) + 1)
		"nudges":
			_launch_bonus("super_nudges")
			nudges = clampi(int(square.value), 1, 9)
			feature.prompt = "%d nudges. Match the centre line or collect." % nudges
			return
		"mystery":
			var pool: Array = config.get("features", ["mystery_bonus"])
			_launch_bonus(str(pool[rng.range_int(0, pool.size() - 1)]))
			return
		"feature":
			var chosen: String = str(square.value)
			if config.id == "time_shift" and chosen == "zone_bonus":
				chosen = ["rewind", "temporal_hi_lo", "temporal_surge"][era]
			_launch_bonus(chosen)
			return
	_update_board_prompt()
	message = note + " " + str(feature.prompt)
	if int(feature.turns) <= 0:
		feature.prompt = "Circuit complete. COLLECT your %d-credit pot." % int(feature.pot)
		message = feature.prompt

func _launch_bonus(id: String, initial: int = 0) -> void:
	if str(feature.get("id", "")) == "board":
		board_context = feature.duplicate(true)
	var counts: Dictionary = stats.feature_counts
	counts[id] = int(counts.get(id, 0)) + 1
	feature = {"id": id, "title": id.replace("_", " ").to_upper(), "pot": initial, "stage": 0, "lives": int(board_context.get("lives", 0)), "no_lose": bool(board_context.get("no_lose", false)), "zone": ["Past", "Present", "Future"][era]}
	state = "FEATURE_ACTIVE"
	if id in LADDER_IDS:
		state = "GAMBLE"
		feature.pot = maxi(initial, 20)
		feature.number = rng.range_int(1, 12)
		feature.prompt = "Predict the next uniform 1–12. Equal loses. COLLECT keeps all; EXCHANGE keeps half."
	elif id in SKILL_IDS:
		feature.cursor = 0
		feature.prompt = "STOP the 100 ms lamp on 6 or 7 for 120, adjacent for 60; otherwise 20."
	elif id in PICK_IDS:
		feature.choices = ["Barrel A", "Barrel B", "Barrel C"] if id in ["mystery_bonus", "mystery_barrel"] else ["Choice A", "Choice B", "Choice C"]
		if id == "property_pick":
			feature.choices = ["Copper Mill", "Lantern Yard", "Glasshouse"]
		elif id == "paradox_mystery":
			feature.choices = ["Echo", "Loop", "Rift"]
		elif id in ["bonus_selector", "lucky_bells"]:
			feature.choices = ["REEL SKILL", "CASH CLIMB", "CASH POT"]
		feature.prompt = "Choose once. Hidden rewards are independently sampled when selected."
	elif id in REVEAL_IDS:
		feature.total = rng.range_int(3, 6)
		feature.prompt = "CONTINUE reveals %d rising awards; every reveal is kept." % int(feature.total)
	elif id == "auction_offer":
		feature.pot = maxi(40, initial)
		feature.prompt = "COLLECT %d, or CONTINUE: 2/3 chance to add 40; 1/3 loses the offer. Up to 4 raises." % int(feature.pot)
	elif id == "cash_repeater":
		feature.pot = maxi(40, initial)
		feature.prompt = "COLLECT, or CONTINUE: 1/2 chance of +40, otherwise the feature ends keeping the pot. Max 5 repeats."
	elif id == "super_hold":
		feature.turns = 3
		feature.prompt = "Choose held reels, then CONTINUE for a free spin (3). First match ends the feature."
		held = [false, false, false]
	elif id in ["super_nudges", "super_shift"]:
		nudges = 6 if id == "super_nudges" else 9
		feature.prompt = "%d nudges. First match awards the paytable; COLLECT ends early." % nudges
	elif id == "time_jump":
		feature.choices = ["PAST · REWIND", "PRESENT · HI-LO", "FUTURE · SURGE"]
		feature.prompt = "Choose an era. Jump to its first square and launch its feature."
	else:
		feature.prompt = "CONTINUE to reveal the feature result."
	if id == "property_pick":
		feature.prompt = "Choose a property: Copper Mill rents for 40, Lantern Yard 60, Glasshouse 80. Then choose rent, a double chance or construction. Each unlocks its building."
	elif id == "darts_dash":
		feature["darts_left"] = 3
		feature.prompt = "THREE DARTS! STOP each throw: lamps 6/7 = 120, 5/8 = 60, others = 20. All three scores count."
	elif id == "mystery_barrel":
		var barrels: Array = [40,80,0]
		for i in range(2,0,-1):
			var j: int = rng.range_int(0,i)
			var swap: int = barrels[i]
			barrels[i] = barrels[j]
			barrels[j] = swap
		feature["barrels"] = barrels
		feature["opened"] = []
		feature.pot = 20
		feature.prompt = "CELLAR RAID: two barrels hold +40/+80; one is empty. Pick another or COLLECT. Empty ends the raid, keeping your pot."
	elif id == "paradox_mystery":
		feature["locks_left"] = 3
		feature.choices = ["STABLE +10", "SURGE +50", "RIFT +120"]
		feature.prompt = "THREE PHASE LOCKS. Stable always pays 10; Surge pays 50 at 2/3; Rift pays 120 at 1/3. Failure ends, keeping your pot."
	message = str(feature.title) + " · " + str(feature.prompt)

func _finish_bonus(amount: int, note: String) -> void:
	if str(feature.get("id", "")) == "super_shift" and not board_context.is_empty():
		board_context.upgrade = mini(4, int(board_context.get("upgrade", 1)) + 1)
		note += " Feature multiplier upgraded."
	if not board_context.is_empty():
		var old: Dictionary = board_context
		board_context = {}
		old.pot = int(old.get("pot", 0)) + maxi(0, amount) * int(old.get("upgrade", 1))
		feature = old
		state = "FEATURE_ACTIVE"
		_update_board_prompt()
		message = note + " " + str(feature.prompt)
	else:
		_set_award(maxi(0, amount), note)
		# A zero award has nothing to duplicate or gamble.
		if amount <= 0:
			state = "IDLE"
			feature = {}

func _gamble(high: bool) -> void:
	var old: int = int(feature.number)
	var next: int = rng.range_int(1, 12)
	var won: bool = next > old if high else next < old
	stats.gambles += 1
	feature.number = next
	if won:
		stats.gamble_wins += 1
		feature.pot = maxi(int(feature.pot), mini(int(config.jackpot), int(feature.pot) * 2))
		feature.stage = int(feature.stage) + 1
		message = "%d → %d. Correct! Pot %d." % [old, next, int(feature.pot)]
		if int(feature.pot) >= int(config.jackpot) or int(feature.stage) >= 6:
			_finish_bonus(int(feature.pot), "Cash ladder complete!")
	elif bool(feature.get("no_lose", false)):
		feature.no_lose = false
		if not board_context.is_empty():
			board_context["no_lose"] = false
		message = "%d → %d. NO LOSE protection used; pot kept." % [old, next]
	elif int(feature.get("lives", 0)) > 0:
		feature.lives = int(feature.lives) - 1
		if not board_context.is_empty():
			board_context.lives = feature.lives
		message = "%d → %d. Extra life used; pot kept." % [old, next]
	else:
		_finish_bonus(0, "%d → %d. %s Ladder lost." % [old, next, "Equal number." if old == next else "Wrong prediction."])

func _skill_stop(cursor: int) -> void:
	var award: int = 120 if cursor in [5, 6] else (60 if cursor in [4, 7] else 20)
	var id: String = str(feature.id)
	if id == "darts_dash" and feature.has("darts_left"):
		feature.pot = int(feature.pot) + award
		feature.darts_left = int(feature.darts_left) - 1
		feature.stage = int(feature.stage) + 1
		if int(feature.darts_left) == 0:
			_finish_bonus(int(feature.pot), "Three darts complete! Total %d." % int(feature.pot))
		else:
			feature.prompt = "DART %d scored %d. %d throws left. Lamps 6/7 = 120, 5/8 = 60, others = 20." % [int(feature.stage),award,int(feature.darts_left)]
		return
	if id == "feature_shot":
		if cursor in [5, 6]:
			_launch_bonus("streak_feature")
			return
		award = 40 if cursor in [4, 7] else 10
	elif id == "reel_skill":
		# The stopped lamp selects a real strip index on reel 3, not a fake win.
		positions[2] = cursor % config.strips[2].size()
		award += evaluate_prize()
	_finish_bonus(award, "Stopped lamp %d · %d-credit award." % [cursor + 1, award])

func _choice(index: int) -> void:
	var id: String = str(feature.id)
	if id == "board":
		_board_move(index)
	elif id in ["bonus_selector", "lucky_bells"]:
		_launch_bonus(["reel_skill", "cash_climb", "cash_pot"][index])
	elif id == "time_jump":
		era = index
		trail_pos = index * 8
		if not board_context.is_empty():
			board_context.zone = ["Past", "Present", "Future"][index]
		_launch_bonus(["rewind", "temporal_hi_lo", "temporal_surge"][index])
	elif id == "property_pick":
		if int(feature.stage) == 0:
			building_icons += 1
			unlocked_buildings[index] = true
			feature.stage = 1
			feature.pot = 40 + index*20
			feature.choices = ["BANK RENT", "DOUBLE RENT", "BUILD FLOOR"]
			feature.prompt = "Property secured: %d rent. BANK keeps it; DOUBLE has 1/2 chance of twice rent (otherwise base rent); BUILD gives half rent and 2 icons." % int(feature.pot)
		else:
			var amount: int = int(feature.pot)
			if index == 1 and rng.chance(1,2): amount *= 2
			if index == 2:
				amount = int(amount/2)
				building_icons += 2
			_finish_bonus(amount,"Property deal completed: %d rent credits." % amount)
	elif id == "mystery_barrel" and feature.has("barrels"):
		feature.opened.append(index)
		var amount: int = int(feature.barrels[index])
		feature.pot = int(feature.pot) + amount
		if amount == 0 or feature.opened.size() >= 2:
			_finish_bonus(int(feature.pot), "Cellar raid complete: %d credits kept." % int(feature.pot))
		else:
			feature.prompt = "+%d in the barrel! COLLECT %d or risk the remaining barrels. One is empty." % [amount,int(feature.pot)]
	elif id == "paradox_mystery" and feature.has("locks_left"):
		var success: bool = index == 0 or rng.chance(2 if index == 1 else 1,3)
		feature.locks_left = int(feature.locks_left) - 1
		feature.stage = int(feature.stage) + 1
		if success: feature.pot = int(feature.pot) + [10,50,120][index]
		if not success or int(feature.locks_left) == 0:
			_finish_bonus(int(feature.pot), "Phase sequence ended. All %d credits kept." % int(feature.pot))
		else:
			feature.prompt = "LOCK %d secured! %d locks remain. Stable: 10 guaranteed; Surge: 50 at 2/3; Rift: 120 at 1/3." % [int(feature.stage),int(feature.locks_left)]
	elif id == "paradox_mystery":
		var roll: int = rng.range_int(0, 3)
		if roll == 0:
			rewind_available = true
			_finish_bonus(20, "Paradox grants REWIND and 20 credits.")
		elif roll == 1:
			_launch_bonus("time_jump")
		elif roll == 2:
			_launch_bonus("super_shift")
		else:
			_finish_bonus(160, "Paradox resolved: 160 credits.")
	else:
		var rewards: Array = [20, 40, 80, 120]
		var amount: int = int(rewards[rng.range_int(0, rewards.size() - 1)])
		_finish_bonus(amount, "Opened choice %d · %d credits." % [index + 1, amount])

func _continue_feature() -> void:
	var id: String = str(feature.id)
	if id == "board":
		_board_move()
	elif id in REVEAL_IDS:
		feature.stage = int(feature.stage) + 1
		var stage: int = int(feature.stage)
		var award: int = rng.range_int(1, 3) * 10 * stage
		if id == "rent_rush":
			award += 10 * unlocked_buildings.count(true)
		elif id == "empire_streak":
			award += building_icons * 5
		elif id == "temporal_surge":
			award += era * 10
		feature.pot = int(feature.pot) + award
		feature.prompt = "Reveal %d/%d · +%d credits. CONTINUE." % [stage, int(feature.total), award]
		message = feature.prompt
		if stage >= int(feature.total):
			_finish_bonus(int(feature.pot), "Streak complete: %d credits." % int(feature.pot))
	elif id == "auction_offer":
		if rng.chance(2, 3):
			feature.pot = int(feature.pot) + 40
			feature.stage = int(feature.stage) + 1
			feature.prompt = "Offer %d. COLLECT or risk a 2/3 raise of 40." % int(feature.pot)
			if int(feature.stage) >= 4:
				_finish_bonus(int(feature.pot), "Auction sold at the final offer.")
		else:
			_finish_bonus(0, "Auction offer withdrawn (1/3 outcome).")
	elif id == "cash_repeater":
		feature.stage = int(feature.stage) + 1
		if rng.chance(1, 2):
			feature.pot = int(feature.pot) + 40
			feature.prompt = "REPEAT! Pot %d. COLLECT or continue (1/2)." % int(feature.pot)
			if int(feature.stage) >= 5:
				_finish_bonus(int(feature.pot), "Maximum five repeats complete.")
		else:
			_finish_bonus(int(feature.pot), "No repeat. All accumulated credits kept.")
	elif id == "super_hold":
		for reel: int in range(3):
			if not held[reel]:
				positions[reel] = rng.range_int(0, config.strips[reel].size() - 1)
		feature.turns = int(feature.turns) - 1
		var award: int = evaluate_prize()
		if award > 0 or int(feature.turns) <= 0:
			held = [false, false, false]
			extra_hold_spins = 2
			_finish_bonus(award, "Super Hold complete. Two further HOLD offers earned.")
		else:
			feature.prompt = "%d free spins left. Choose held reels, then CONTINUE." % int(feature.turns)
	elif id == "win_spin":
		# Explicitly select an available three-symbol match. This is a declared bonus,
		# never used to manipulate paid spin or near-miss outcomes.
		var candidates: Array = []
		for symbol_id: String in config.paytable:
			if config.strips[0].has(symbol_id) and config.strips[1].has(symbol_id) and config.strips[2].has(symbol_id):
				candidates.append(symbol_id)
		var selected: String = str(candidates[rng.range_int(0, candidates.size() - 1)])
		for reel: int in range(3):
			positions[reel] = config.strips[reel].find(selected)
		_finish_bonus(evaluate_prize(), "WIN SPIN selected %s on all three reels." % selected)
	elif id == "add_again":
		var amount: int = maxi(20, int(board_context.get("pot", 20)))
		_finish_bonus(amount, "ADD AGAIN duplicates the current board pot once.")
	elif id == "extra_life":
		if not board_context.is_empty():
			board_context.lives = int(board_context.get("lives", 0)) + 1
		_finish_bonus(20, "One extra life protects a later hi-lo loss, plus 20 credits.")
	elif id == "no_lose":
		if not board_context.is_empty():
			board_context.no_lose = true
		_finish_bonus(20, "NO LOSE protects the next hi-lo loss, plus 20 credits.")
	elif id == "lucky_seven":
		var number: int = rng.range_int(1, 12)
		_finish_bonus(200 if number == 7 else 20, "Lucky Seven drew %d: 7 pays 200, other numbers 20." % number)
	elif id == "cash_pot":
		var amount: int = rng.range_int(2, 10) * 10
		_finish_bonus(amount, "CASH POT: uniform 20–100 in tens. Award %d." % amount)
	elif id in ["feature_upgrade", "building_bonus"]:
		if not board_context.is_empty():
			var increase: int = 1 + int(building_icons / 3) if id == "building_bonus" else 1
			board_context.upgrade = mini(4, int(board_context.get("upgrade", 1)) + increase)
			if id == "building_bonus":
				building_icons = 0
		_finish_bonus(20, "Feature multiplier upgraded (maximum ×4), plus 20 base credits.")
	elif id == "bonus_exchange":
		# Defined deterministic exchange: bank board value as a ladder entry.
		var amount: int = maxi(40, int(board_context.get("pot", 0)))
		if not board_context.is_empty():
			board_context.pot = 0
		_launch_bonus("cash_climb", amount)
	elif id == "rewind":
		rewind_available = true
		_finish_bonus(20, "REWIND earned: restore the preceding paid spin once, plus 20 credits.")
	else:
		# Configuration validation rejects unknown IDs; defensive recovery preserves ledger.
		_finish_bonus(0, "Unknown feature ended safely.")

func snapshot() -> Dictionary:
	return {"schema": 1, "machine_id": str(config.get("id", "")), "state": state, "credits": credits, "bank": bank, "positions": positions.duplicate(), "held": held.duplicate(), "trail_pos": trail_pos, "trail_progress": trail_progress, "nudges": nudges, "feature": feature.duplicate(true), "message": message, "stats": stats.duplicate(true), "rng": rng.snapshot(), "board_context": board_context.duplicate(true), "prior_positions": prior_positions.duplicate(), "rewind_available": rewind_available, "extra_hold_spins": extra_hold_spins, "pending_trail": pending_trail, "pending_special": pending_special, "pending_paid": pending_paid, "award_serial": award_serial, "building_icons": building_icons, "districts": districts.duplicate(), "unlocked_buildings": unlocked_buildings.duplicate(), "era": era}

func restore(data: Dictionary) -> bool:
	if int(data.get("schema", 0)) != 1 or str(data.get("machine_id", "")) != str(config.get("id", "")):
		return false
	var restored_state: String = str(data.get("state", ""))
	if not restored_state in VALID_STATES or int(data.get("credits", -1)) < 0 or int(data.get("bank", -1)) < 0:
		return false
	var restored_positions: Array = data.get("positions", [])
	var restored_held: Array = data.get("held", [])
	if restored_positions.size() != 3 or restored_held.size() != 3:
		return false
	for reel: int in range(3):
		if int(restored_positions[reel]) < 0 or int(restored_positions[reel]) >= config.strips[reel].size():
			return false
	var restored_feature: Dictionary = data.get("feature", {})
	if int(restored_feature.get("pot", 0)) < 0:
		return false
	if restored_state in ["EVALUATING", "RECOVERY"]:
		return false
	var restored_id: String = str(restored_feature.get("id", ""))
	if restored_state == "GAMBLE" and (not restored_id in LADDER_IDS or int(restored_feature.get("number", 0)) < 1 or int(restored_feature.get("number", 0)) > 12):
		return false
	if restored_state == "FEATURE_ENTRY" and restored_id != "board":
		return false
	if restored_state == "AWARD_COLLECTION" and restored_id != "award":
		return false
	if restored_state == "FEATURE_ACTIVE":
		if restored_id != "board" and not restored_id in SUPPORTED_BONUSES:
			return false
		if restored_id == "board" and not restored_feature.has("turns"):
			return false
		if restored_id in REVEAL_IDS and (int(restored_feature.get("total", 0)) < 3 or int(restored_feature.get("total", 0)) > 6):
			return false
	var restored_board: Dictionary = data.get("board_context", {})
	if not restored_board.is_empty() and (str(restored_board.get("id", "")) != "board" or not restored_board.has("turns") or int(restored_board.get("pot", -1)) < 0):
		return false
	var restored_previous: Array = data.get("prior_positions", [])
	var restored_districts: Array = data.get("districts", [])
	var restored_buildings: Array = data.get("unlocked_buildings", [])
	if restored_previous.size() != 3 or restored_districts.size() != 3 or restored_buildings.size() != 3:
		return false
	for reel: int in range(3):
		if int(restored_previous[reel]) < 0 or int(restored_previous[reel]) >= config.strips[reel].size():
			return false
	var restored_rng: SimRng = SimRng.new(1)
	if not restored_rng.restore(data.get("rng", {})):
		return false
	state = restored_state
	credits = int(data.credits)
	bank = int(data.bank)
	positions = restored_positions.duplicate()
	held = restored_held.duplicate()
	trail_pos = posmod(int(data.get("trail_pos", 0)), int(config.trail_length))
	trail_progress = clampi(int(data.get("trail_progress", 0)), 0, int(config.trail_length) - 1)
	nudges = clampi(int(data.get("nudges", 0)), 0, 12)
	feature = restored_feature.duplicate(true)
	message = str(data.get("message", "Game restored."))
	var restored_stats: Dictionary = data.get("stats", {})
	for key: String in stats:
		if restored_stats.has(key):
			stats[key] = restored_stats[key]
	rng = restored_rng
	board_context = data.get("board_context", {}).duplicate(true)
	prior_positions = data.get("prior_positions", [0, 0, 0]).duplicate()
	rewind_available = bool(data.get("rewind_available", false))
	extra_hold_spins = maxi(0, int(data.get("extra_hold_spins", 0)))
	pending_trail = int(data.get("pending_trail", 0))
	pending_special = bool(data.get("pending_special", false))
	pending_paid = bool(data.get("pending_paid", true))
	award_serial = maxi(0, int(data.get("award_serial", 0)))
	building_icons = maxi(0, int(data.get("building_icons", 0)))
	districts = data.get("districts", [0, 0, 0]).duplicate()
	unlocked_buildings = data.get("unlocked_buildings", [false, false, false]).duplicate()
	era = clampi(int(data.get("era", 0)), 0, 2)
	_busy = false
	return true
