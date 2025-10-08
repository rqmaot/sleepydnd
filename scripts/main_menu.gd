extends CanvasLayer

signal host
signal join(ip)

@onready var join_button: Button = $Menu/JoinButton
@onready var host_button: Button = $Menu/HostButton
@onready var background: Sprite2D = $Background
@onready var menu: ColorRect = $Menu

func _on_join_button_pressed() -> void:
	join.emit("localhost")

func _on_host_button_pressed() -> void:
	host.emit()

func center_x(nd, x):
	nd.position.x = x / 2

func center_y(nd, y):
	nd.position.y = y / 2
	
func center(nd, xy, by_topleft=false):
	nd.position = xy / 2

func _process(_delta):
	# scale the background
	var res = get_viewport().get_visible_rect().size
	var bg_size = background.texture.get_size()
	var scale_x = res.x / bg_size.x
	var scale_y = res.y / bg_size.y
	var bg_scale = scale_x if scale_x > scale_y else scale_y
	background.scale = Vector2(bg_scale, bg_scale)
	# center everything
	center(background, res)
	center(menu, res, true)
