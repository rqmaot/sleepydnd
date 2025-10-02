extends CanvasLayer

signal resume
signal quit

@onready var log_box: TextEdit = $Log
var log_contents := ""

func log(msg):
	log_contents += msg
	if log_box: log_box.text += msg

func clear_log():
	log_contents = ""
	if log_box: log_box.text = ""

func _ready():
	log_box.text = log_contents

func _on_quit_pressed() -> void:
	quit.emit()

func _on_resume_pressed() -> void:
	resume.emit()
