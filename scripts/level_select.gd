extends Control

const LEVEL_SPOTS := [
	{"id": 1, "center": Vector2(0.305, 0.468)},
	{"id": 2, "center": Vector2(0.408, 0.490)},
	{"id": 3, "center": Vector2(0.310, 0.524)},
]

@onready var toast: Label = %Toast
@onready var buttons_root: Control = %LevelButtons


func _ready() -> void:
	%Header.text = HGLoc.t("book_genesis").to_upper()
	%PageLabel.text = HGLoc.t("book_page_title")
	%BackButton.pressed.connect(_on_back)
	toast.modulate.a = 0.0
	_place_buttons()
	resized.connect(_place_buttons)
	get_viewport().size_changed.connect(_place_buttons)


func _place_page_label(vs: Vector2) -> void:
	var cover := $PageCover as ColorRect
	var label := %PageLabel
	var rect := Rect2(vs * Vector2(0.505, 0.385), vs * Vector2(0.29, 0.088))
	cover.position = rect.position
	cover.size = rect.size
	label.position = rect.position
	label.size = rect.size


func _place_buttons() -> void:
	var vs := size
	if vs.x <= 0.0:
		vs = get_viewport_rect().size
	_place_page_label(vs)
	var hit := Vector2(vs.x * 0.12, vs.x * 0.12)
	for child in buttons_root.get_children():
		child.queue_free()
	for spot in LEVEL_SPOTS:
		var level_id: int = int(spot.id)
		var button := TextureButton.new()
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.size = hit
		button.position = vs * spot.center - hit * 0.5
		button.modulate = Color(1, 1, 1, 0.01)
		button.pressed.connect(_on_level_pressed.bind(level_id))
		buttons_root.add_child(button)
		if not HGSave.is_unlocked(level_id) or not bool(LevelCatalog.get_level(level_id).get("playable", false)):
			var lock := TextureRect.new()
			lock.texture = preload("res://assets/ui/lock.png")
			lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lock.size = hit * 0.42
			lock.position = button.position + (hit - lock.size) * 0.5
			lock.modulate = Color(1, 1, 1, 0.95)
			buttons_root.add_child(lock)


func _on_level_pressed(level_id: int) -> void:
	var level := LevelCatalog.get_level(level_id)
	if level.is_empty():
		return
	if not HGSave.is_unlocked(level_id):
		_show_toast(HGLoc.t("book_sealed"))
		return
	if not bool(level.get("playable", false)):
		_show_toast(HGLoc.t("coming_soon"))
		return
	HGSave.start_level(level_id)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _show_toast(text: String) -> void:
	toast.text = text
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.1)
	tw.tween_property(toast, "modulate:a", 0.0, 0.3)
