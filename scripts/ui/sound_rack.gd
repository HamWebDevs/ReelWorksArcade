class_name SoundRack
extends Node
var sound_volume := 0.7
var music_volume := 0.25
var muted := false
var voices: Array[AudioStreamPlayer] = []
var ambience: AudioStreamPlayer
var next_voice := 0
func _ready() -> void:
	for i in 8:
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	ambience.finished.connect(_loop_ambience)
func _loop_ambience() -> void:
	if not muted and music_volume > 0 and ambience.stream != null:
		ambience.play()

func play_event(event: String) -> void:
	if muted or sound_volume <= 0 or voices.is_empty():
		return
	var path := "res://assets/audio/" + event + ".wav"
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/click.wav"
	if not ResourceLoader.exists(path):
		return
	var voice := voices[next_voice % voices.size()]
	next_voice += 1
	voice.stream = load(path)
	voice.volume_db = linear_to_db(sound_volume)
	voice.play()
func set_ambience(machine_id: String) -> void:
	var path := "res://assets/audio/ambient_" + machine_id + ".wav"
	ambience.stop()
	if ResourceLoader.exists(path):
		ambience.stream = load(path)
	apply_volume()
func apply_volume() -> void:
	if muted:
		for voice: AudioStreamPlayer in voices: voice.stop()
	if ambience:
		if muted or music_volume <= 0.0:
			ambience.stop()
		else:
			ambience.volume_db = linear_to_db(maxf(0.001,music_volume))
			if ambience.stream != null and not ambience.playing: ambience.play()

func shutdown() -> void:
	# Release active WAV playback before the audio server's final mix/teardown.
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
	for voice: AudioStreamPlayer in voices:
		voice.stop()
		voice.stream = null

func _exit_tree() -> void:
	shutdown()
