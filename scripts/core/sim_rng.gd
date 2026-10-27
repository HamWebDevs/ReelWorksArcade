class_name SimRng
extends RefCounted
## Park–Miller 48271. Fully reproducible, platform independent, non-cryptographic.
## Rejection sampling makes every integer in the requested range equally likely.
const MODULUS: int = 2147483647
const MULTIPLIER: int = 48271
var state: int = 1
var draws: int = 0

func _init(seed_value: int = -1) -> void:
	set_seed(seed_value)

func set_seed(seed_value: int) -> void:
	if seed_value < 0:
		seed_value = int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_usec()
	state = posmod(seed_value, MODULUS - 1) + 1
	draws = 0

func next_int() -> int:
	state = (state * MULTIPLIER) % MODULUS
	draws += 1
	return state - 1

func range_int(low: int, high: int) -> int:
	assert(high >= low)
	var width: int = high - low + 1
	var population: int = MODULUS - 1
	var limit: int = population - population % width
	var result: int = next_int()
	while result >= limit:
		result = next_int()
	return low + result % width

func chance(numerator: int, denominator: int) -> bool:
	return range_int(1, denominator) <= numerator

func snapshot() -> Dictionary:
	return {"state": str(state), "draws": draws}

func restore(data: Dictionary) -> bool:
	var candidate: int = int(data.get("state", "0"))
	if candidate < 1 or candidate >= MODULUS:
		return false
	state = candidate
	draws = maxi(0, int(data.get("draws", 0)))
	return true
