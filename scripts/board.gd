extends Sprite2D

var _thickness : float = 1.0
var _image_scale : float = 1.0
var _grid_dim : float = 64.0
var _color : Color = Color.RED
var _canvas : Node2D = null

@onready var color_rect: ColorRect = $ColorRect

func snap_one(x : float) -> float:
	# guesses
	var mid = int(x / _grid_dim) * _grid_dim
	var left = mid - _grid_dim
	var right = mid + _grid_dim
	# distances
	var mid_dist = abs(x - mid)
	var left_dist = abs(x - left)
	var right_dist = abs(x - right)
	# find best
	if mid_dist < left_dist:
		return mid if mid_dist < right_dist else right
	return left if left_dist < right_dist else right

func snap(p : Vector2) -> Vector2:
	return Vector2(snap_one(p.x), snap_one(p.y))

func bottom_left():
	var texture_size = texture.get_size()
	var corner = Vector2(0, 0)
	corner.x = global_position.x - 0.5 * (texture_size.x - _grid_dim)
	corner.y = global_position.y + 0.5 * (texture_size.y - _grid_dim)
	return corner

func grid_xy(x, y):
	var pos = bottom_left()
	pos.x += (x - 1) * _grid_dim
	pos.y -= (y - 1) * _grid_dim
	return pos

func load_image(path):
	var img = Image.load_from_file(path)
	texture = ImageTexture.create_from_image(img)
	_canvas.queue_redraw()
	return self

func color(c=null):
	if c:
		_color = c
		_canvas.queue_redraw()
		return self
	return _color

func thickness(x=null):
	if x:
		_thickness = x
		_canvas.queue_redraw()
		return self
	return _thickness

func scale(x=null):
	if x: 
		_image_scale = x
		return self
	return _image_scale
	
func grid(x=null):
	if x == null: return _grid_dim
	_grid_dim = x
	_canvas.queue_redraw()
	return self

func rows(r=null):
	var dim = texture.get_size()
	if r == null:
		r = int(dim.y / _grid_dim)
		if r * _grid_dim < dim.y: r += 1
		return r
	_grid_dim = dim.y / r
	_canvas.queue_redraw()
	return self
	
func cols(c=null):
	var dim = texture.get_size()
	if c == null:
		c = int(dim.x / _grid_dim)
		if c * _grid_dim < dim.x: c += 1
		return c
	_grid_dim = dim.x / c
	_canvas.queue_redraw()
	return self

func canvas_draw():
	var dim = texture.get_size()
	var x : float = _grid_dim
	while x < dim.x:
		draw_line(Vector2(x, 0), Vector2(x, dim.y), _color, _thickness)
		x += _grid_dim
	var y : float = _grid_dim
	while y < dim.y:
		draw_line(Vector2(0, y), Vector2(dim.x, y), _color, _thickness)

class BoardCanvas extends Node2D:
	var board : Node2D
	func _init(b):
		board = b
	func _draw():
		if not board.texture: return
		var dim = board.texture.get_size()
		position = dim * -0.5
		var x : float = board._grid_dim
		while x < dim.x:
			draw_line(Vector2(x, 0), Vector2(x, dim.y), board._color, board._thickness)
			x += board._grid_dim
		var y : float = board._grid_dim
		while y < dim.y:
			draw_line(Vector2(0, y), Vector2(dim.x, y), board._color, board._thickness)
			y += board._grid_dim

func _ready():
	_canvas = BoardCanvas.new(self)
	add_child(_canvas)
	
func _process(_delta):
	if not texture: return
	# global_position = snap(Vector2(0, 0)) - 0.5 * Vector2(_grid_dim, _grid_dim)
	color_rect.global_position = bottom_left()
