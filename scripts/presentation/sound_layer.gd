class_name SoundLayer
extends Node

var muted: bool = false
var volume: float = 0.75
var voices: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var voice_index: int = 0
const GAINS := {"cast": -20.0, "shield": -21.0, "dash": -22.0, "frost": -22.0, "hit": -25.0, "loot": -20.0, "capture": -22.0, "denied": -24.0, "death": -19.0}

func _ready() -> void:
	for kind in ["cast", "shield", "dash", "frost", "hit", "loot", "capture", "denied", "death"]:
		streams[kind] = load("res://assets/audio/%s.wav" % kind)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -20.0
		add_child(voice)
		voices.append(voice)

func play(kind: String) -> void:
	if muted or volume <= 0.0 or voices.is_empty() or not streams.has(kind):
		return
	var voice := voices[voice_index % voices.size()]
	voice_index += 1
	voice.set_meta("kind", kind)
	voice.volume_db = float(GAINS.get(kind, -22.0)) + linear_to_db(maxf(0.001, volume))
	voice.stream = streams[kind]
	voice.play()

func receive(event: Dictionary) -> void:
	match str(event["kind"]):
		"cast_moon": play("cast")
		"cast_frost": play("frost")
		"shield": play("shield")
		"dash": play("dash")
		"hit", "player_hit":
			if int(event.get("amount", 0)) > 0:
				play("hit")
		"loot", "level_up", "quest_complete", "farm_harvest", "animal_harvest", "npc_quest_complete", "gu_upgrade", "gu_fusion", "realm_unlocked", "item_crafted": play("loot")
		"capture_success", "capture_start", "discovery", "waygate", "region_changed", "farm_plant", "farm_water", "farm_supply", "npc_talk", "quest_accepted": play("capture")
		"player_death": play("death")

func toggle() -> bool:
	muted = not muted
	if muted:
		for voice in voices:
			voice.stop()
	return muted

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	for voice in voices:
		if volume <= 0.0:
			voice.stop()
		if voice.playing:
			voice.volume_db = float(GAINS.get(str(voice.get_meta("kind", "")), -22.0)) + linear_to_db(maxf(0.001, volume))

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()
