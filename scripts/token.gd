extends Area2D

@onready var light: PointLight2D = $Light
@onready var collider: CollisionShape2D = $Collider
@onready var texture: TextureRect = $Texture
@onready var foll: Label = $Foll

var _scale := 1.0
var following := -1
var token_index : int
var main
var image

var owned_by = -1
func own(id):
	owned_by = id
	return self
	
func get_main():
	var nd = self
	while nd:
		if "_MALAPASTA_SAYS_THIS_IS_MAIN" in nd: return nd
		nd = nd.get_parent()
	return null

const _MALAPASTA_SAYS_THIS_IS_A_TOKEN = true

func set_image(path):
	var img = Image.load_from_file(path)
	var itexture = ImageTexture.create_from_image(img)
	texture.texture = itexture
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
	set_image(image)
	fit()
	main = get_main()

# code for moving the token when someone drags it

func _process(_delta):
	if following == multiplayer.get_unique_id():
		var pos = get_global_mouse_position()
		main.modify_token.rpc(token_index, "x", pos.x)
		main.modify_token.rpc(token_index, "y", pos.y)
	foll.text = str(following)

func player_dragging(id : int) -> bool:
	for t in main.token_array:
		if t["following"] == id: 
			return true
	return false

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var my_id = multiplayer.get_unique_id()
	if event is not InputEventMouseButton: return
	if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
	if following == my_id and not event.pressed:
		main.modify_token.rpc(token_index, "following", -1)
		return
	if following == -1 and event.pressed and not player_dragging(my_id) and \
			(owned_by == my_id or my_id == 1):
		main.modify_token.rpc(token_index, "following", multiplayer.get_unique_id())
