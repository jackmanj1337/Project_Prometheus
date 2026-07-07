extends RefCounted

signal changed(index: int)

var index: int = -1

var _count: int = 0
var _cols: int = 1
var _wraps: bool = true
var _has_inactive: bool = false


func configure(count: int, cols: int = 1, wraps: bool = true, has_inactive: bool = false) -> void:
	_count = maxi(count, 0)
	_cols = maxi(cols, 1)
	_wraps = wraps
	_has_inactive = has_inactive
	if _count == 0:
		index = -1
	elif index >= _count or (index < 0 and not _has_inactive):
		index = -1


func reset() -> void:
	_set_index(-1)


func set_index(value: int) -> void:
	if value < -1 or value >= _count:
		return
	if value == -1 and not _has_inactive:
		_set_index(-1)
		return
	_set_index(value)


func advance(delta: int) -> void:
	if _count == 0 or delta == 0:
		return
	var slots: int = _count + (1 if _has_inactive else 0)
	var raw: int
	if index < 0:
		raw = 0 if delta > 0 else slots - 1
	else:
		raw = index + delta
	if _wraps:
		raw = posmod(raw, slots)
	else:
		raw = clampi(raw, 0, slots - 1)
	_set_index(_slot_to_index(raw))


func move_2d(row_delta: int, col_delta: int) -> void:
	if _count == 0:
		return
	if index < 0:
		advance(1 if row_delta >= 0 and col_delta >= 0 else -1)
		return
	if row_delta == 0:
		advance(col_delta)
		return
	if col_delta != 0:
		advance(col_delta)
		return
	var current_row: int = int(index / _cols)
	var current_col: int = index % _cols
	var target_row: int = _adjacent_row(current_row, row_delta)
	if target_row == current_row:
		return
	var best_index: int = index
	var best_dist: int = 1 << 30
	for i in _count:
		if int(i / _cols) != target_row:
			continue
		var dist: int = absi((i % _cols) - current_col)
		if dist < best_dist:
			best_dist = dist
			best_index = i
	_set_index(best_index)


func _slot_to_index(slot: int) -> int:
	if _has_inactive and slot == _count:
		return -1
	return slot


func _adjacent_row(from_row: int, dir: int) -> int:
	var max_row: int = int((_count - 1) / _cols)
	var target: int = from_row + (1 if dir > 0 else -1)
	if _wraps:
		return posmod(target, max_row + 1)
	return clampi(target, 0, max_row)


func _set_index(value: int) -> void:
	if index == value:
		return
	index = value
	changed.emit(index)
