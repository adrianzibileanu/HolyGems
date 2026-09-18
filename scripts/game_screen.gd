extends Control

const PIECE_TEXTURES := {
	"sun": preload("res://assets/pieces/genesis/sun.png"),
	"moon": preload("res://assets/pieces/genesis/moon.png"),
	"earth": preload("res://assets/pieces/genesis/earth.png"),
	"time": preload("res://assets/pieces/genesis/time.png"),
	"stars": preload("res://assets/pieces/genesis/stars.png"),
}

var level: Dictionary = {}
var moves_left: int = 0
var goals: Dictionary = {}
var board: GemBoard
var ended: bool = false
var _intro_done: bool = false

@onready var title_label: Label = %TitleLabel
@onready var verse_label: Label = %VerseLabel
@onready var moves_label: Label = %MovesLabel
@onready var goals_row: HBoxContainer = %GoalsRow
@onready var board_slot: Control = %BoardSlot
@onready var result_overlay: Control = %ResultOverlay
@onready var result_title: Label = %ResultTitle
@onready var result_detail: Label = %ResultDetail
@onready var pause_overlay: Control = %PauseOverlay


func _ready() -> void:
	if HGSave.pending_intro:
		%IntroOverlay.visible = true
	level = LevelCatalog.get_level(HGSave.pending_level_id)
	if level.is_empty():
		level = LevelCatalog.get_level(1)
	title_label.text = "%s  ·  %s" % [HGLoc.t(String(level.get("book_key", "book_genesis"))), HGLoc.t(String(level.get("name_key", "level_creation")))]
	var verse := HGLoc.t(String(level.get("verse_key", "verse_genesis_1_1")))
	var reference := HGLoc.t(String(level.get("reference_key", "ref_genesis_1_1")))
	if HGLoc.is_ro():
		verse_label.text = "„%s”  — %s" % [verse, reference]
	else:
		verse_label.text = "\"%s\"  — %s" % [verse, reference]
	moves_left = int(level.get("moves", 25))
	goals = (level.get("goals", {}) as Dictionary).duplicate(true)
	moves_label.text = str(moves_left)
	_build_goals()
	_apply_locale()
	result_overlay.visible = false
	pause_overlay.visible = false
	%BackButton.pressed.connect(_show_pause)
	%PauseButton.pressed.connect(_show_pause)
	%ResumeButton.pressed.connect(func() -> void: pause_overlay.visible = false)
	%PauseSettingsButton.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/settings.tscn"))
	%PauseMenuButton.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	%RetryButton.pressed.connect(func() -> void: HGSave.start_level(int(level.id), false))
	%LevelsButton.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/level_select.tscn"))
	%SkipIntroButton.pressed.connect(_skip_intro)
	%SkipIntroLabel.text = HGLoc.t("skip")
	await _maybe_play_intro()
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	board = GemBoard.new()
	board_slot.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.matched.connect(_on_matched)
	board.move_spent.connect(_on_move_spent)
	board.settled.connect(_on_settled)
	board.setup(level)


func _maybe_play_intro() -> void:
	var overlay := %IntroOverlay
	var player := %IntroVideo
	if not HGSave.pending_intro:
		overlay.visible = false
		_intro_done = true
		return
	HGSave.pending_intro = false
	var path := "res://assets/ui/lvl1.ogv"
	if not ResourceLoader.exists(path):
		overlay.visible = false
		_intro_done = true
		return
	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	player.volume_db = -80.0
	player.volume = 0.0
	player.loop = false
	player.expand = true
	player.stream = load(path)
	_fit_intro_video()
	if not resized.is_connected(_fit_intro_video):
		resized.connect(_fit_intro_video)
	player.visible = true
	player.play()
	var length := 7.04
	var started := false
	for _i in 30:
		if _intro_done or not is_inside_tree():
			_finish_intro()
			return
		await get_tree().process_frame
		if not is_instance_valid(player):
			return
		if player.get_stream_length() > 0.1:
			length = player.get_stream_length()
		if player.is_playing() or player.get_stream_position() > 0.01:
			started = true
			break
	while not _intro_done and is_inside_tree():
		await get_tree().process_frame
		if not is_inside_tree() or not is_instance_valid(player):
			return
		if player.get_stream_length() > 0.1:
			length = player.get_stream_length()
		var pos: float = player.get_stream_position()
		if pos >= length - 0.04:
			break
		if started and not player.is_playing() and not player.paused and pos > 0.2:
			break
	if is_inside_tree():
		_finish_intro()


func _fit_intro_video() -> void:
	var player := %IntroVideo
	var vs := size
	if vs.x <= 1.0:
		vs = get_viewport_rect().size
	var native := Vector2(720, 1280)
	var cover := maxf(vs.x / native.x, vs.y / native.y)
	var fitted := native * cover
	player.size = fitted
	player.position = (vs - fitted) * 0.5


func _skip_intro() -> void:
	_finish_intro()


func _finish_intro() -> void:
	_intro_done = true
	if not is_inside_tree():
		return
	var overlay := %IntroOverlay
	var player := %IntroVideo
	if is_instance_valid(player) and player.is_playing():
		player.stop()
	overlay.visible = false
	if is_instance_valid(player):
		player.visible = false


func _apply_locale() -> void:
	%MovesCaption.text = HGLoc.t("moves")
	%PauseTitle.text = HGLoc.t("paused")
	%ResumeLabel.text = HGLoc.t("resume")
	%PauseSettingsLabel.text = HGLoc.t("settings")
	%PauseMenuLabel.text = HGLoc.t("main_menu")
	%RetryLabel.text = HGLoc.t("try_again")
	%LevelsLabel.text = HGLoc.t("levels")


func _build_goals() -> void:
	for child in goals_row.get_children():
		child.queue_free()
	for piece_id in goals.keys():
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		var icon := TextureRect.new()
		icon.texture = PIECE_TEXTURES.get(String(piece_id), null)
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var count := Label.new()
		count.name = "Count_%s" % String(piece_id)
		count.text = str(int(goals[piece_id]))
		count.add_theme_font_size_override("font_size", 26)
		count.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
		count.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.05))
		count.add_theme_constant_override("outline_size", 6)
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(icon)
		box.add_child(count)
		goals_row.add_child(box)


func _on_matched(piece_id: String, amount: int) -> void:
	if not goals.has(piece_id):
		return
	goals[piece_id] = maxi(0, int(goals[piece_id]) - amount)
	var count := goals_row.find_child("Count_%s" % piece_id, true, false)
	if count is Label:
		(count as Label).text = str(int(goals[piece_id]))
		if int(goals[piece_id]) == 0:
			(count as Label).modulate = Color(0.55, 1.0, 0.55)


func _on_move_spent() -> void:
	moves_left = maxi(0, moves_left - 1)
	moves_label.text = str(moves_left)


func _on_settled() -> void:
	if ended:
		return
	if _goals_complete():
		_finish(true)
	elif moves_left <= 0:
		_finish(false)


func _goals_complete() -> bool:
	for piece_id in goals.keys():
		if int(goals[piece_id]) > 0:
			return false
	return true


func _finish(won: bool) -> void:
	ended = true
	result_overlay.visible = true
	if won:
		var stars := 1
		if moves_left >= 10:
			stars = 3
		elif moves_left >= 5:
			stars = 2
		HGSave.mark_level_complete(int(level.id), stars)
		result_title.text = HGLoc.t("win_title")
		result_detail.text = "%s\n%s" % [HGLoc.t("win_detail"), "★".repeat(stars)]
	else:
		result_title.text = HGLoc.t("lose_title")
		result_detail.text = HGLoc.t("lose_detail")


func _show_pause() -> void:
	if ended:
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
		return
	pause_overlay.visible = true
