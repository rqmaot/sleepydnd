extends CanvasLayer

signal resume
signal quit

@onready var log_box: TextEdit = $Container/Log

var log_contents = ""
func log(msg):
	log_contents += msg

func clear():
	log_contents = ""

func _process(_delta):
	log_box.text = log_contents
	
func _on_resume_button_pressed() -> void:
	resume.emit()

func _on_quit_button_pressed() -> void:
	quit.emit()
