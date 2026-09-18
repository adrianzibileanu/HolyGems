class_name HGSave
extends Node

const SAVE_PATH := "user://holy_gems.cfg"
const MAX_LEVEL := 5

static var music_volume: float = 0.8
static var sfx_volume: float = 0.8
static var locale: String = "ro"
static var last_level_id: int = 1
static var highest_unlocked: int = 1
static var has_started: bool = false
static var level_stars: Dictionary = {}
static var pending_level_id: int = 1
static var flash_from_title: bool = false
static var pending_intro: bool = false


func _ready() -> void:
	load_save()
	apply_audio()


static func can_continue() -> bool:
	return has_started


static func start_level(level_id: int, play_intro: bool = false) -> void:
	pending_level_id = clampi(level_id, 1, MAX_LEVEL)
	last_level_id = pending_level_id
	pending_intro = play_intro and pending_level_id == 1
	has_started = true
	save_progress()
	var tree := Engine.get_main_loop() as SceneTree
	tree.change_scene_to_file("res://scenes/game.tscn")


static func continue_game() -> void:
	start_level(last_level_id)


static func mark_level_complete(level_id: int, stars: int) -> void:
	var previous: int = int(level_stars.get(str(level_id), 0))
	level_stars[str(level_id)] = maxi(previous, stars)
	highest_unlocked = clampi(maxi(highest_unlocked, level_id + 1), 1, MAX_LEVEL)
	last_level_id = mini(level_id + 1, MAX_LEVEL)
	has_started = true
	save_progress()


static func is_unlocked(level_id: int) -> bool:
	return level_id <= highest_unlocked


static func apply_audio() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		var linear := clampf(music_volume, 0.0, 1.0)
		AudioServer.set_bus_mute(master, linear <= 0.001)
		AudioServer.set_bus_volume_db(master, linear_to_db(maxf(linear, 0.0001)))


static func _default_locale() -> String:
	return "ro"


static func set_locale(new_locale: String) -> void:
	if new_locale != "en" and new_locale != "ro":
		return
	locale = new_locale
	save_progress()


static func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		locale = _default_locale()
		return
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	locale = String(cfg.get_value("audio", "locale", _default_locale()))
	if locale != "en" and locale != "ro":
		locale = _default_locale()
	last_level_id = int(cfg.get_value("progress", "last_level", 1))
	highest_unlocked = int(cfg.get_value("progress", "highest_unlocked", 1))
	has_started = bool(cfg.get_value("progress", "has_started", false))
	level_stars = cfg.get_value("progress", "stars", {})


static func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "locale", locale)
	cfg.set_value("progress", "last_level", last_level_id)
	cfg.set_value("progress", "highest_unlocked", highest_unlocked)
	cfg.set_value("progress", "has_started", has_started)
	cfg.set_value("progress", "stars", level_stars)
	cfg.save(SAVE_PATH)
