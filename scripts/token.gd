extends Area2D

@onready var light: PointLight2D = $Light
@onready var collider: CollisionShape2D = $Collider
@onready var texture: TextureRect = $Texture
@onready var foll: Label = $Foll

@export var _scale := 1.0
@export var following := -1

@export var owned_by = -1
func own(id):
	owned_by = id
	return self

var _game : Node2D = null
func game(g):
	_game = g
	return self

const MALAPASTA_SAYS_THIS_IS_A_TOKEN = true

func set_image(path):
	var img = Image.load_from_file(path)
	texture.texture = ImageTexture.create_from_image(img)
	fit()

# code for fitting the image in the circle

func fit():
	light.texture_scale = _scale
	collider.scale = Vector2(_scale, _scale)
	texture.position = Vector2(-40, -40) * _scale
	texture.scale = Vector2(_scale, _scale) * 2

func scale(s = null):
	if s:
		_scale = s
		fit()
		return self
	return _scale	

func scale_to(px):
	var r = collider.shape.radius
	var ratio = px / (r * 2)
	return scale(ratio)

func _ready():
	fit()

# code for moving the token when someone drags it

func _process(_delta):
	if following == multiplayer.get_unique_id():
		rpc_set_position.rpc(get_global_mouse_position())
	foll.text = str(following)

@rpc("any_peer", "call_local")
func set_following(f):
	following = f

@rpc("any_peer", "call_local")
func rpc_set_position(p):
	global_position = p

func player_dragging(id : int) -> bool:
	if not _game: return false
	for t in _game.get_children():
		if "MALAPASTA_SAYS_THIS_IS_A_TOKEN" in t and t.following == id: 
			return true
	return false

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var my_id = multiplayer.get_unique_id()
	if event is not InputEventMouseButton: return
	if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
	if following == my_id and not event.pressed:
		set_following.rpc(-1)
		return
	if following == -1 and event.pressed and not player_dragging(my_id) and \
		(owned_by == my_id or my_id == 1):
		set_following.rpc(multiplayer.get_unique_id())
