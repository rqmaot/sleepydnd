extends Node2D

signal join(address)
signal host
signal quit

@onready var ip_field : LineEdit = $Control/IP
@onready var log_box: Label = $Control/Log

func log(msg):
	log_box.text += msg

func clear():
	log_box.text = ""

func get_ip():
	if ip_field.text == "": return "localhost"
	return ip_field.text

func _on_quit_pressed() -> void:
	quit.emit()

func _on_host_button_pressed() -> void:
	host.emit()

func _on_join_button_pressed() -> void:
	join.emit(get_ip())
