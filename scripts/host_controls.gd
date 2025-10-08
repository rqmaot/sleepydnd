extends CanvasLayer

signal change_map

var dir := ""
var i : int = 0
var lo : int = 0
var hi : int = 0

@onready var directory: LineEdit = $Container/Directory
@onready var index: LineEdit = $Container/Index

func update():
	dir = directory.text
	i = clamp(index.text.to_int(), lo, hi)

func _on_load_dir_pressed() -> void:
	update()
	change_map.emit()

func _on_load_index_pressed() -> void:
	update()
	change_map.emit()

func _on_prev_pressed() -> void:
	i -= 1
	if i < lo: i = hi
	index.text = str(i)
	update()
	change_map.emit()

func _on_next_pressed() -> void:
	i += 1
	if i > hi: i = lo
	index.text = str(i)
	update()
	change_map.emit()
