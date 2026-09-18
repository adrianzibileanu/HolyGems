extends Control

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var language_option: OptionButton = %LanguageOption


func _ready() -> void:
	_apply_locale()
	music_slider.value = HGSave.music_volume
	sfx_slider.value = HGSave.sfx_volume
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	language_option.item_selected.connect(_on_language_selected)
	%BackButton.pressed.connect(_on_back)
	%MenuButton.pressed.connect(_on_menu)


func _apply_locale() -> void:
	%Title.text = HGLoc.t("settings")
	%MusicLabel.text = HGLoc.t("music")
	%SfxLabel.text = HGLoc.t("sound")
	%LanguageLabel.text = HGLoc.t("language")
	%MenuLabel.text = HGLoc.t("main_menu")
	language_option.set_block_signals(true)
	language_option.clear()
	language_option.add_item(HGLoc.t("lang_ro"), 0)
	language_option.add_item(HGLoc.t("lang_en"), 1)
	language_option.select(0 if HGLoc.is_ro() else 1)
	language_option.set_block_signals(false)


func _on_language_selected(index: int) -> void:
	HGSave.set_locale("ro" if index == 0 else "en")
	_apply_locale()


func _on_music_changed(value: float) -> void:
	HGSave.music_volume = value
	HGSave.apply_audio()
	HGSave.save_progress()


func _on_sfx_changed(value: float) -> void:
	HGSave.sfx_volume = value
	HGSave.save_progress()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
