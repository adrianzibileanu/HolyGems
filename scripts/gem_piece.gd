class_name GemPiece
extends TextureRect

var piece_id: String = ""
var cell: Vector2i = Vector2i.ZERO


func setup(id: String, texture: Texture2D, cell_size: float) -> void:
	piece_id = id
	self.texture = texture
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	size = Vector2(cell_size, cell_size)
	custom_minimum_size = size
	pivot_offset = size * 0.5
	scale = Vector2.ONE
	modulate = Color.WHITE


func place(cell_pos: Vector2i, origin: Vector2, cell_size: float, animated := false) -> void:
	cell = cell_pos
	var dest := origin + Vector2(cell_pos) * cell_size
	if animated:
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position", dest, 0.22)
		await tw.finished
	else:
		position = dest
