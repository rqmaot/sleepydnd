extends Node2D

const VELOCITY = 1000.0

@onready var board: Sprite2D = $Board
@onready var camera: Camera2D = $Camera
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var coords: Label = $Coords

var logs = []

func log_pair(msg, x, y):
	for l in logs:
		if l[0] == x and l[1] == y: return
	logs.append([x, y])
	print("%s (%s, %s)" % [msg, x, y])

func get_main():
	var nd = self
	while nd:
		if "_MALAPASTA_SAYS_THIS_IS_MAIN" in nd: return nd
		nd = nd.get_parent()
	return null

func _process(delta):
	coords.text = str(global_position)
	if not get_main().paused:
		var v = Input.get_vector("left", "right", "up", "down")
		position += VELOCITY * v * delta
