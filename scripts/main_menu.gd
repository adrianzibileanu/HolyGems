extends Control

const PLAY_TEXTURE := preload("res://assets/ui/play_button.png")
const TEMPLATE_TEXTURE := preload("res://assets/ui/button_template.png")

@onready var video: VideoStreamPlayer = %Video
@onready var transition_video: VideoStreamPlayer = %TransitionVideo
@onready var play_button: TextureButton = %PlayButton
@onready var play_label: Label = %PlayLabel
@onready var continue_button: TextureButton = %ContinueButton
@onready var continue_label: Label = %ContinueLabel
@onready var settings_button: TextureButton = %SettingsButton
@onready var logo: TextureRect = %Logo
@onready var buttons: VBoxContainer = %Buttons
@onready var white_flash: ColorRect = %WhiteFlash

var _busy: bool = false


func _ready() -> void:
	_apply_locale()
	_try_play_video()
	continue_button.disabled = not HGSave.can_continue()
	continue_button.modulate = Color(1, 1, 1, 1) if HGSave.can_continue() else Color(0.55, 0.55, 0.55, 0.85)
	play_button.pressed.connect(_on_play_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	play_button.mouse_entered.connect(_pulse.bind(play_button, true))
	play_button.mouse_exited.connect(_pulse.bind(play_button, false))
	continue_button.mouse_entered.connect(_pulse.bind(continue_button, true))
	continue_button.mouse_exited.connect(_pulse.bind(continue_button, false))
	settings_button.mouse_entered.connect(_pulse.bind(settings_button, true))
	settings_button.mouse_exited.connect(_pulse.bind(settings_button, false))
	await get_tree().process_frame
	for button in [play_button, continue_button, settings_button]:
		button.pivot_offset = button.size * 0.5


func _apply_locale() -> void:
	continue_label.text = HGLoc.t("continue")
	if HGLoc.is_ro():
		play_button.texture_normal = TEMPLATE_TEXTURE
		play_label.text = HGLoc.t("play")
		play_label.visible = true
	else:
		play_button.texture_normal = PLAY_TEXTURE
		play_label.text = ""
		play_label.visible = false


const VIDEO_SIZE := Vector2(720, 1280)


func _try_play_video() -> void:
	# Godot 4.7 decodes Theora, not H.264. titlebgfinal.mp4 is muted and
	# kept at 720x1280 / 24 fps as title_bg_final.ogv.
	clip_contents = true
	video.volume_db = -80.0
	video.volume = 0.0
	video.loop = true
	video.expand = true
	var path := "res://assets/ui/title_bg_final.ogv"
	if not ResourceLoader.exists(path):
		video.visible = false
		return
	video.stream = load(path)
	if video.stream == null:
		video.visible = false
		return
	_fit_video()
	if not resized.is_connected(_fit_video):
		resized.connect(_fit_video)
	video.play()


func _fit_video() -> void:
	var vs := size
	if vs.x <= 1.0:
		vs = get_viewport_rect().size
	var cover := maxf(vs.x / VIDEO_SIZE.x, vs.y / VIDEO_SIZE.y)
	var fitted := VIDEO_SIZE * cover
	video.size = fitted
	video.position = (vs - fitted) * 0.5
	transition_video.size = fitted
	transition_video.position = (vs - fitted) * 0.5


func _on_play_pressed() -> void:
	if _busy:
		return
	_busy = true
	await _play_title_to_level()
	HGSave.flash_from_title = true
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _play_title_to_level() -> void:
	play_button.disabled = true
	continue_button.disabled = true
	settings_button.disabled = true
	var hide_ui := create_tween()
	hide_ui.set_parallel(true)
	hide_ui.tween_property(logo, "modulate:a", 0.0, 0.28)
	hide_ui.tween_property(buttons, "modulate:a", 0.0, 0.28)
	var path := "res://assets/ui/title_to_level.ogv"
	var length := 6.04
	if ResourceLoader.exists(path):
		_fit_video()
		transition_video.volume_db = -80.0
		transition_video.volume = 0.0
		transition_video.loop = false
		transition_video.expand = true
		transition_video.stream = load(path)
		transition_video.visible = true
		transition_video.play()
		video.stop()
		video.visible = false
		for _i in 20:
			await get_tree().process_frame
			if transition_video.get_stream_length() > 0.1:
				length = transition_video.get_stream_length()
				break
		await get_tree().create_timer(maxf(0.2, length - 0.9)).timeout
	await _engulf_screen()
	if is_instance_valid(transition_video) and transition_video.is_playing():
		var leftover := length - transition_video.get_stream_position()
		if leftover > 0.02:
			await get_tree().create_timer(leftover).timeout
	await get_tree().create_timer(0.08).timeout


func _engulf_screen() -> void:
	white_flash.visible = true
	white_flash.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(white_flash, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


func _on_continue_pressed() -> void:
	if HGSave.can_continue():
		HGSave.continue_game()


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _pulse(button: Control, on: bool) -> void:
	if button is TextureButton and (button as TextureButton).disabled:
		return
	var tw := button.create_tween()
	tw.tween_property(button, "scale", Vector2(1.05, 1.05) if on else Vector2.ONE, 0.12)
