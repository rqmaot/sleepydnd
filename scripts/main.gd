extends Node2D

# scenes
@onready var player_container: Node = $Player
@onready var tokens: Node = $Tokens
@onready var main_menu: CanvasLayer = $MainMenu
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var board: Sprite2D = $Board
@onready var host_controls: CanvasLayer = $HostControls
const player_scene = preload("res://scenes/player.tscn")
const token_scene = preload("res://scenes/token.tscn")
# libraries
var Net = load("res://scripts/netcode.gd").new()
var Game = load("res://scripts/game.gd")
# game state
const _MALAPASTA_SAYS_THIS_IS_MAIN := true
var paused := false
var on_main_menu := true
@export var token_array : Array = []
var spawned_tokens := 0
@export var game_dir := "":
	set(value):
		host_controls.directory.text = value
		game_dir = value
var loaded_dir := ""
@export var map_index := -1:
	set(value):
		host_controls.index.text = str(value)
		map_index = value
var loaded_index := -1
var gc

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	to_main_menu()
	# init netcode
	Net.multi = multiplayer
	Net.spawn_player = spawn_token
	Net.on_play = on_play
	Net.on_host = on_host
	Net.on_play_post = spawn_player
	# connect main menu to netcode
	main_menu.host.connect(Net._on_host)
	main_menu.join.connect(Net._on_join)
	# authority
	set_multiplayer_authority(1)

func push_token(to_push):
	var new_array = []
	for t in token_array: new_array.append(t)
	new_array.append(to_push)
	token_array = new_array

func spawn_token(peer_id):
	if peer_id == 1: return
	push_token({
		"owned_by": peer_id,
		"x": 0,
		"y": 0,
		"image": "res://images/warlock.jpg",
		"following": -1,
		"npc": false
	})

@rpc("any_peer", "call_local")
func modify_token(i : int, key, val):
	token_array[i][key] = val

func spawn_player():
	var player = player_scene.instantiate()
	player_container.add_child(player)

func on_host():
	game_dir = "res://example"
	map_index = 0
	host_controls.show()

func on_play():
	main_menu.hide()
	board.show()
	on_main_menu = false

func to_main_menu():
	paused = false
	on_main_menu = true
	loaded_dir = ""
	loaded_index = -1
	main_menu.show()
	pause_menu.hide()
	board.hide()
	host_controls.hide()
	for p in player_container.get_children(): player_container.remove_child(p)
	for t in tokens.get_children(): tokens.remove_child(t)

# pause menu

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	if on_main_menu: return
	if paused:
		pause_menu.hide()
		paused = false
	else:
		pause_menu.show()
		paused = true

func _on_pause_menu_quit() -> void:
	Net._leave_game()
	to_main_menu()
	
func _on_pause_menu_resume():
	toggle_pause()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# do nothing on main menu
	if on_main_menu: return
	# sync loaded map
	if loaded_dir != game_dir:
		gc = Game.GameContents.load_dir(game_dir)
		if gc == null:
			game_dir = loaded_dir
			map_index = loaded_index
			return
		loaded_dir = game_dir
		loaded_index = map_index
		load_map()
		host_controls.hi = gc.maps.size() - 1
	if loaded_index != map_index:
		loaded_index = map_index
		load_map()
	# sync tokens
	if spawned_tokens > token_array.size():
		clear_spawned_tokens()
	if spawned_tokens < token_array.size():
		clear_spawned_tokens()
		for i in range(0, token_array.size()):
			var t = token_scene.instantiate()
			t.image = token_array[i]["image"]
			t.owned_by = token_array[i]["owned_by"]
			t.token_index = i
			tokens.add_child(t)
			print("%s: set %s -> %s" % [multiplayer.get_unique_id(), i, token_array[i]])
		spawned_tokens = token_array.size()
		print("%s %s" % [multiplayer.get_unique_id(), token_array])
	if board.texture == null: return
	var offset = board.bottom_left() / board.grid()
	offset.x = (offset.x - int(offset.x)) * board.grid()
	offset.y = (offset.y - int(offset.y)) * board.grid()
	for t in tokens.get_children():
		t.following = token_array[t.token_index]["following"]
		var x = token_array[t.token_index]["x"]
		var y = token_array[t.token_index]["y"]
		if t.following == -1:
			t.global_position = board.snap(Vector2(x, y) - offset) + offset
		else:
			t.global_position = Vector2(x, y)
		t.scale_to(board.grid())

func clear_spawned_tokens():
	for t in tokens.get_children():
		tokens.remove_child(t)
	spawned_tokens = 0

func clear_tokens():
	clear_spawned_tokens()
	var players_only : Array[Dictionary] = []
	for t in token_array:
		if t["npc"]: continue
		players_only.append(t)
	token_array = players_only

func load_map():
	if gc == null: return
	var map = gc.maps[loaded_index]
	var img = gc.directory.path_join(map.image)
	board.load_image(img).color(map.color).thickness(map.thickness).grid(map.grid)
	clear_tokens()
	# only the host spawns in tokens
	if not multiplayer.is_server():
		return
	for t in map.tokens:
		var pos = board.grid_xy(t.x, t.y)
		push_token({
			"owned_by": 1,
			"x": pos.x,
			"y": pos.y,
			"image": gc.directory.path_join(t.image),
			"following": -1,
			"npc": true
		})

func _on_host_controls_change_map() -> void:
	game_dir = host_controls.dir
	map_index = host_controls.i
