class_name GemBoard
extends Control

signal matched(piece_id: String, amount: int)
signal move_spent
signal settled

const TEXTURES := {
	"sun": preload("res://assets/pieces/genesis/sun.png"),
	"moon": preload("res://assets/pieces/genesis/moon.png"),
	"earth": preload("res://assets/pieces/genesis/earth.png"),
	"time": preload("res://assets/pieces/genesis/time.png"),
	"stars": preload("res://assets/pieces/genesis/stars.png"),
}

var grid_width: int = 8
var grid_height: int = 8
var cell_size: float = 80.0
var board_origin: Vector2 = Vector2.ZERO
var piece_ids: Array[String] = ["sun", "moon", "earth", "time", "stars"]

var grid: Array = []
var busy: bool = false
var selected: Vector2i = Vector2i(-1, -1)
var press_cell: Vector2i = Vector2i(-1, -1)

const SWAP_TIME := 0.16
const FALL_TIME := 0.2
const POP_TIME := 0.16


func setup(level: Dictionary) -> void:
	grid_width = int(level.get("width", 8))
	grid_height = int(level.get("height", 8))
	piece_ids.clear()
	for piece_id in level.get("pieces", ["sun", "moon", "earth", "time", "stars"]):
		piece_ids.append(String(piece_id))
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	await get_tree().process_frame
	_layout_metrics()
	_build_initial()
	queue_redraw()


func _layout_metrics() -> void:
	var area := size
	if area.x < 32.0 or area.y < 32.0:
		area = get_parent().size
	cell_size = floorf(minf(area.x / float(grid_width), area.y / float(grid_height)))
	var board := Vector2(grid_width, grid_height) * cell_size
	board_origin = (area - board) * 0.5


func _draw() -> void:
	if cell_size <= 0.0:
		return
	var rect := Rect2(board_origin - Vector2(10, 10), Vector2(grid_width, grid_height) * cell_size + Vector2(20, 20))
	draw_rect(rect, Color(0.07, 0.04, 0.02, 0.55), true)
	draw_rect(rect, Color(0.83, 0.68, 0.32, 0.55), false, 3.0)


func _build_initial() -> void:
	for child in get_children():
		child.queue_free()
	grid.clear()
	for x in grid_width:
		var column: Array = []
		for y in grid_height:
			var piece := _spawn(_random_id_without_match(x, y, column), Vector2i(x, y), false)
			column.append(piece)
		grid.append(column)
	if not _has_possible_move():
		_rebuild_until_playable()


func _spawn(piece_id: String, cell: Vector2i, from_above: bool) -> GemPiece:
	var piece := GemPiece.new()
	piece.setup(piece_id, TEXTURES[piece_id], cell_size)
	add_child(piece)
	var dest := _cell_position(cell)
	if from_above:
		piece.position = Vector2(dest.x, board_origin.y - cell_size * float(cell.y + 1))
	else:
		piece.position = dest
	piece.cell = cell
	return piece


func _cell_position(cell: Vector2i) -> Vector2:
	return board_origin + Vector2(cell) * cell_size


func _random_id_without_match(x: int, y: int, column: Array) -> String:
	for _try in 24:
		var piece_id: String = piece_ids[randi() % piece_ids.size()]
		var horizontal := 1
		if x >= 1 and grid[x - 1][y] != null and grid[x - 1][y].piece_id == piece_id:
			horizontal += 1
			if x >= 2 and grid[x - 2][y] != null and grid[x - 2][y].piece_id == piece_id:
				horizontal += 1
		var vertical := 1
		if y >= 1 and column[y - 1] != null and column[y - 1].piece_id == piece_id:
			vertical += 1
			if y >= 2 and column[y - 2] != null and column[y - 2].piece_id == piece_id:
				vertical += 1
		if horizontal < 3 and vertical < 3:
			return piece_id
	return piece_ids[randi() % piece_ids.size()]


func _gui_input(event: InputEvent) -> void:
	if busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_press(event.position)
		else:
			_on_release(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_press(event.position)
		else:
			_on_release(event.position)
	elif event is InputEventMouseMotion and press_cell != Vector2i(-1, -1) and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_on_drag(event.position)
	elif event is InputEventScreenDrag and press_cell != Vector2i(-1, -1):
		_on_drag(event.position)


func _on_press(local_pos: Vector2) -> void:
	var cell := _cell_at(local_pos)
	press_cell = cell
	if cell == Vector2i(-1, -1):
		return
	if selected != Vector2i(-1, -1) and selected != cell:
		if _is_adjacent(selected, cell):
			var from := selected
			_clear_selection()
			press_cell = Vector2i(-1, -1)
			_try_swap(from, cell)
			return
	_select(cell)


func _on_drag(local_pos: Vector2) -> void:
	var cell := _cell_at(local_pos)
	if cell == Vector2i(-1, -1) or press_cell == Vector2i(-1, -1):
		return
	if _is_adjacent(press_cell, cell):
		var from := press_cell
		press_cell = Vector2i(-1, -1)
		_clear_selection()
		_try_swap(from, cell)


func _on_release(_local_pos: Vector2) -> void:
	press_cell = Vector2i(-1, -1)


func _select(cell: Vector2i) -> void:
	_clear_selection()
	selected = cell
	var piece: GemPiece = grid[cell.x][cell.y]
	if piece:
		piece.z_index = 3
		var tw := piece.create_tween()
		tw.tween_property(piece, "scale", Vector2(1.08, 1.08), 0.08)


func _clear_selection() -> void:
	if selected != Vector2i(-1, -1):
		var piece: GemPiece = _piece_at(selected)
		if piece:
			piece.z_index = 0
			piece.scale = Vector2.ONE
	selected = Vector2i(-1, -1)


func _cell_at(local_pos: Vector2) -> Vector2i:
	var rel := (local_pos - board_origin) / cell_size
	var cell := Vector2i(floori(rel.x), floori(rel.y))
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_width or cell.y >= grid_height:
		return Vector2i(-1, -1)
	if _piece_at(cell) == null:
		return Vector2i(-1, -1)
	return cell


func _piece_at(cell: Vector2i) -> GemPiece:
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_width or cell.y >= grid_height:
		return null
	return grid[cell.x][cell.y]


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


func _try_swap(a: Vector2i, b: Vector2i) -> void:
	if busy or _piece_at(a) == null or _piece_at(b) == null:
		return
	busy = true
	await _swap_visual(a, b)
	var matches := _find_matches()
	if matches.is_empty():
		await _swap_visual(a, b)
		busy = false
		return
	move_spent.emit()
	await _resolve_board()
	busy = false
	settled.emit()


func _swap_visual(a: Vector2i, b: Vector2i) -> void:
	var piece_a: GemPiece = grid[a.x][a.y]
	var piece_b: GemPiece = grid[b.x][b.y]
	grid[a.x][a.y] = piece_b
	grid[b.x][b.y] = piece_a
	if piece_a:
		piece_a.cell = b
	if piece_b:
		piece_b.cell = a
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if piece_a:
		tw.tween_property(piece_a, "position", _cell_position(b), SWAP_TIME)
	if piece_b:
		tw.tween_property(piece_b, "position", _cell_position(a), SWAP_TIME)
	await tw.finished


func _resolve_board() -> void:
	while true:
		var matches := _find_matches()
		if matches.is_empty():
			break
		await _destroy_matches(matches)
		await _apply_gravity()
		await _refill()
	if not _has_possible_move():
		_rebuild_until_playable()


func _find_matches() -> Dictionary:
	var marked: Dictionary = {}
	for y in grid_height:
		var run := 1
		for x in range(1, grid_width + 1):
			var same := x < grid_width and _same(Vector2i(x, y), Vector2i(x - 1, y))
			if same:
				run += 1
			else:
				if run >= 3:
					for k in range(x - run, x):
						marked[Vector2i(k, y)] = grid[k][y].piece_id
				run = 1
	for x in grid_width:
		var run := 1
		for y in range(1, grid_height + 1):
			var same := y < grid_height and _same(Vector2i(x, y), Vector2i(x, y - 1))
			if same:
				run += 1
			else:
				if run >= 3:
					for k in range(y - run, y):
						marked[Vector2i(x, k)] = grid[x][k].piece_id
				run = 1
	return marked


func _same(a: Vector2i, b: Vector2i) -> bool:
	var pa := _piece_at(a)
	var pb := _piece_at(b)
	return pa != null and pb != null and pa.piece_id == pb.piece_id


func _destroy_matches(matches: Dictionary) -> void:
	var counts: Dictionary = {}
	var doomed: Array[GemPiece] = []
	var tw := create_tween()
	tw.set_parallel(true)
	for cell in matches.keys():
		var piece: GemPiece = _piece_at(cell)
		if piece == null:
			continue
		var piece_id: String = piece.piece_id
		counts[piece_id] = int(counts.get(piece_id, 0)) + 1
		grid[cell.x][cell.y] = null
		doomed.append(piece)
		tw.tween_property(piece, "scale", Vector2.ZERO, POP_TIME)
		tw.tween_property(piece, "modulate", Color(1, 1, 1, 0), POP_TIME)
	for piece_id in counts.keys():
		matched.emit(String(piece_id), int(counts[piece_id]))
	if doomed.is_empty():
		tw.kill()
		return
	await tw.finished
	for piece in doomed:
		if is_instance_valid(piece):
			piece.queue_free()


func _apply_gravity() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	var moving := false
	for x in grid_width:
		var write_y := grid_height - 1
		for y in range(grid_height - 1, -1, -1):
			var piece: GemPiece = grid[x][y]
			if piece == null:
				continue
			if y != write_y:
				grid[x][y] = null
				grid[x][write_y] = piece
				piece.cell = Vector2i(x, write_y)
				tw.tween_property(piece, "position", _cell_position(Vector2i(x, write_y)), FALL_TIME)
				moving = true
			write_y -= 1
	if moving:
		await tw.finished
	else:
		tw.kill()


func _refill() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	var spawned := false
	for x in grid_width:
		var missing := 0
		for y in grid_height:
			if grid[x][y] == null:
				missing += 1
		for i in missing:
			var y := missing - 1 - i
			var piece_id: String = piece_ids[randi() % piece_ids.size()]
			var piece := _spawn(piece_id, Vector2i(x, y), true)
			grid[x][y] = piece
			tw.tween_property(piece, "position", _cell_position(Vector2i(x, y)), FALL_TIME)
			spawned = true
	if spawned:
		await tw.finished
	else:
		tw.kill()


func _has_possible_move() -> bool:
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1)]
	for x in grid_width:
		for y in grid_height:
			var cell := Vector2i(x, y)
			for offset in dirs:
				var other: Vector2i = cell + offset
				if other.x >= grid_width or other.y >= grid_height:
					continue
				_swap_data(cell, other)
				var found := not _find_matches().is_empty()
				_swap_data(cell, other)
				if found:
					return true
	return false


func _swap_data(a: Vector2i, b: Vector2i) -> void:
	var tmp = grid[a.x][a.y]
	grid[a.x][a.y] = grid[b.x][b.y]
	grid[b.x][b.y] = tmp
	if grid[a.x][a.y]:
		grid[a.x][a.y].cell = a
	if grid[b.x][b.y]:
		grid[b.x][b.y].cell = b


func _rebuild_until_playable() -> void:
	for _try in 12:
		_build_initial_silent()
		if _find_matches().is_empty() and _has_possible_move():
			return


func _build_initial_silent() -> void:
	for x in grid_width:
		for y in grid_height:
			var piece: GemPiece = grid[x][y]
			if piece:
				piece.queue_free()
	grid.clear()
	for x in grid_width:
		var column: Array = []
		for y in grid_height:
			var piece := _spawn(_random_id_without_match(x, y, column), Vector2i(x, y), false)
			column.append(piece)
		grid.append(column)
