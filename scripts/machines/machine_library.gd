class_name MachineLibrary
extends RefCounted
## Loads inert machine definitions. Optional user modules never execute code.
## Invalid modules and duplicate identifiers are ignored, leaving built-ins intact.

const BUILT_INS: Array[String] = [
	"res://data/machines/last_orders.json",
	"res://data/machines/empire_estates.json",
	"res://data/machines/time_shift.json",
]
const MODULE_DIRECTORY := "user://machines"
const MAX_MODULE_BYTES := 262144
const FEATURE_IDS: Array[String] = [
	"reel_skill", "win_spin", "super_hold", "super_nudges", "cash_climb",
	"mystery_bonus", "cash_repeater", "feature_shot", "add_again", "extra_life",
	"no_lose", "lucky_seven", "streak_feature", "cash_pot", "feature_upgrade",
	"bonus_selector", "darts_dash", "lucky_bells", "last_call_streak", "mystery_barrel",
	"property_pick", "auction_offer", "building_bonus", "rent_rush", "tycoon_trail",
	"empire_streak", "bonus_exchange", "temporal_hi_lo", "rewind", "time_jump",
	"temporal_surge", "super_shift", "paradox_mystery",
]
const TRAIL_KINDS: Array[String] = ["cash", "nudges", "feature", "mystery", "life", "upgrade", "repeat"]


static func all() -> Array[Dictionary]:
	var machines: Array[Dictionary] = []
	var seen: Dictionary = {}
	for path: String in BUILT_INS:
		_add_file(path, machines, seen)
	var directory := DirAccess.open(MODULE_DIRECTORY)
	if directory != null:
		var filenames := directory.get_files()
		filenames.sort()
		for filename: String in filenames:
			if filename.ends_with(".json"):
				_add_file(MODULE_DIRECTORY.path_join(filename), machines, seen)
	return machines


static func get_machine(id: String) -> Dictionary:
	for machine: Dictionary in all():
		if machine.get("id", "") == id:
			return machine
	return {}


static func _add_file(path: String, machines: Array[Dictionary], seen: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Machine file unavailable: " + path)
		return
	if file.get_length() > MAX_MODULE_BYTES:
		push_warning("Machine module exceeds 256 KiB: " + path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Machine module is not a JSON object: " + path)
		return
	var errors := validate(parsed)
	if not errors.is_empty():
		push_warning("Invalid machine module %s: %s" % [path, "; ".join(errors)])
		return
	var machine_id := str(parsed["id"])
	if seen.has(machine_id):
		push_warning("Duplicate machine identifier ignored: " + machine_id)
		return
	seen[machine_id] = true
	machines.append(parsed)


static func validate(config: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key: String in ["id", "name", "subtitle", "description", "trail_name", "special_symbol"]:
		if not config.get(key) is String or str(config.get(key, "")).is_empty():
			errors.append("%s must be a non-empty string" % key)
	var machine_id := str(config.get("id", ""))
	if not machine_id.is_valid_identifier() or machine_id != machine_id.to_lower():
		errors.append("id must be a lowercase identifier")
	for key: String in ["stake", "jackpot", "trail_length", "board_turns"]:
		if not _whole_number(config.get(key), 1, 1000000):
			errors.append("%s must be a positive integer" % key)
	if _whole_number(config.get("trail_length"), 1, 1000000) and int(config["trail_length"]) > 64:
		errors.append("trail_length must be at most 64")
	if _whole_number(config.get("board_turns"), 1, 1000000) and int(config["board_turns"]) > 20:
		errors.append("board_turns must be at most 20")
	var colors: Variant = config.get("colors")
	if not colors is Dictionary:
		errors.append("colors must be an object")
	else:
		for key: String in ["bg", "primary", "secondary", "accent"]:
			if not colors.get(key) is String or not Color.html_is_valid(str(colors.get(key, ""))):
				errors.append("colors.%s must be an HTML color" % key)
	var symbols: Variant = config.get("symbols")
	var paytable: Variant = config.get("paytable")
	if not symbols is Dictionary or symbols.is_empty():
		errors.append("symbols must be a non-empty object")
		symbols = {}
	if not paytable is Dictionary or paytable.is_empty():
		errors.append("paytable must be a non-empty object")
		paytable = {}
	for raw_symbol: Variant in symbols:
		var symbol_id := str(raw_symbol)
		var symbol: Variant = symbols[raw_symbol]
		if not symbol is Dictionary:
			errors.append("symbol %s must be an object" % symbol_id)
			continue
		if not symbol.get("label") is String or str(symbol.get("label", "")).is_empty():
			errors.append("symbol %s requires a label" % symbol_id)
		if not _whole_number(symbol.get("number"), 0, 12):
			errors.append("symbol %s number must be 0..12" % symbol_id)
		if not _whole_number(symbol.get("prize"), 0, 1000000):
			errors.append("symbol %s requires a non-negative prize" % symbol_id)
		if not symbol.get("icon") is String or not _asset_path(str(symbol.get("icon", ""))):
			errors.append("symbol %s icon must be a res:// or user:// asset path" % symbol_id)
		if not paytable.has(symbol_id):
			errors.append("symbol %s is missing from the paytable" % symbol_id)
		elif _whole_number(symbol.get("prize"), 0, 1000000) and _whole_number(paytable[symbol_id], 0, 1000000):
			if int(symbol["prize"]) != int(paytable[symbol_id]):
				errors.append("symbol %s prize differs from paytable" % symbol_id)
	if not symbols.has(config.get("special_symbol", "")):
		errors.append("special_symbol must exist in symbols")
	for symbol: Variant in paytable:
		if not symbols.has(symbol) or not _whole_number(paytable[symbol], 0, 1000000):
			errors.append("paytable contains unknown symbol or invalid prize: " + str(symbol))
	var strips: Variant = config.get("strips")
	if not strips is Array or strips.size() != 3:
		errors.append("strips must contain exactly three arrays")
	else:
		for reel: int in range(3):
			var strip: Variant = strips[reel]
			if not strip is Array or strip.size() < 3 or strip.size() > 256:
				errors.append("reel %d must contain 3..256 stops" % reel)
				continue
			for symbol: Variant in strip:
				if not symbol is String or not symbols.has(symbol):
					errors.append("reel %d contains an unknown symbol" % reel)
					break
			for symbol: Variant in paytable:
				if not strip.has(symbol) and _whole_number(paytable[symbol], 1, 1000000):
					errors.append("advertised triple %s is impossible on reel %d" % [symbol, reel])
	var trail: Variant = config.get("trail")
	if not trail is Array:
		errors.append("trail must be an array")
	elif not _whole_number(config.get("trail_length"), 1, 64) or trail.size() != int(config["trail_length"]):
		errors.append("trail size must equal trail_length")
	else:
		for raw_square: Variant in trail:
			if not raw_square is Dictionary:
				errors.append("trail squares must be objects")
				continue
			var square: Dictionary = raw_square
			if not square.get("label") is String or str(square.get("label", "")).is_empty():
				errors.append("trail square label is required")
			var kind := str(square.get("kind", ""))
			if not TRAIL_KINDS.has(kind):
				errors.append("unknown trail square kind: " + kind)
			elif kind == "feature":
				if not FEATURE_IDS.has(str(square.get("value", ""))):
					errors.append("unknown trail feature: " + str(square.get("value")))
			elif not _whole_number(square.get("value"), 0, 1000000):
				errors.append("trail square value must be a non-negative integer")
	var features: Variant = config.get("features")
	if not features is Array or features.is_empty():
		errors.append("features must be a non-empty array")
	else:
		for feature_id: Variant in features:
			if not feature_id is String or not FEATURE_IDS.has(feature_id):
				errors.append("unknown feature id: " + str(feature_id))
	if not FEATURE_IDS.has(str(config.get("special_feature", ""))):
		errors.append("special_feature must name an implemented feature")
	for chance_key: String in ["hold_chance", "nudge_chance"]:
		var chance: Variant = config.get(chance_key)
		if not chance is Array or chance.size() != 2:
			errors.append(chance_key + " must be [numerator, denominator]")
		elif not _whole_number(chance[0], 0, 1000000) or not _whole_number(chance[1], 1, 1000000):
			errors.append(chance_key + " must contain integers with positive denominator")
		elif int(chance[0]) > int(chance[1]):
			errors.append(chance_key + " numerator exceeds denominator")
	var rules: Variant = config.get("rules")
	if not rules is Array or rules.is_empty():
		errors.append("rules must contain player-facing rule strings")
	else:
		for rule: Variant in rules:
			if not rule is String or str(rule).is_empty():
				errors.append("rules contains an invalid string")
	return errors


static func _whole_number(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float):
		return false
	var numeric := float(value)
	return is_finite(numeric) and numeric == floor(numeric) and numeric >= minimum and numeric <= maximum


static func _asset_path(path: String) -> bool:
	return (path.begins_with("res://") or path.begins_with("user://")) and not path.contains("..") and (path.ends_with(".svg") or path.ends_with(".png") or path.ends_with(".webp"))
