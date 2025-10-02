extends Node2D

# nodes
var menu : Node2D
var pause : CanvasLayer
var loading : Node2D
var game : Node2D
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
# game state
var paused := false
var on_main_menu := true
const _MALAPSTA_SAYS_THIS_IS_MAIN = true
# net state
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()
var players = []
var camera

func init_scenes():
	menu = load("res://scenes/menu.tscn").instantiate()
	menu.host.connect(_on_host)
	menu.quit.connect(_on_quit)
	menu.join.connect(_on_join)
	pause = load("res://scenes/pause.tscn").instantiate()
	pause.resume.connect(_on_resume)
	pause.quit.connect(_on_pause_quit)
	loading = load("res://scenes/loading.tscn").instantiate()
	game = load("res://scenes/game.tscn").instantiate().set_main(self)

func to_main_menu():
	init_scenes()
	for nd in get_children():
		if nd != spawner:
			remove_child(nd)
	paused = false
	on_main_menu = true
	add_child(menu)

func _ready():
	to_main_menu()

func _input(event):
	if event.is_action_pressed('ui_cancel'):
		if paused: unpause_game()
		else: pause_game()

func _on_quit():
	get_tree().quit()

# pause code

func _on_pause_quit():
	unpause_game()
	leave_game()
	to_main_menu()

func _on_resume():
	remove_child(pause)

func pause_game():
	if on_main_menu: return
	paused = true
	add_child(pause)
	
func unpause_game():
	paused = false
	remove_child(pause)

# network code

func add_player(peer_id):
	players.append(peer_id)
	var player = load("res://scenes/player.tscn").instantiate().set_main(self)
	player.name = str(peer_id)
	game.add_child(player)
	game.spawn_token.rpc(peer_id)

func _on_host():
	on_main_menu = false
	remove_child(menu)
	add_child(loading)
	await get_tree().create_timer(1.0).timeout
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	players = []
	# upnp_setup()
	remove_child(loading)
	add_child(game)
	add_player(multiplayer.get_unique_id())
	
func _on_join(ip):
	on_main_menu = false
	remove_child(menu)
	add_child(loading)
	await get_tree().create_timer(1.0).timeout
	enet_peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = enet_peer

func leave_game():
	for player in players:
		if player != multiplayer.get_unique_id():
			multiplayer.disconnect_peer(player)
	multiplayer.disconnect_peer(1)

func remove_player(peer_id):
	var player = game.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func get_port():
	return PORT

func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		pause.log("UPNP Discover Failed! Error " + str(discover_result))
		return
	if not upnp.get_gateway():
		pause.log("UPNP No Gateway")
	if not upnp.get_gateway().is_valid_gateway():
		pause.log("UPNP Invalid Gateway!")
		return
	var map_result = upnp.add_port_mapping(get_port())
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		pause.log("UPNP Port Mapping Failed! Error " + str(map_result))
		return
	pause.log("Success! Join Address: " + str(upnp.query_external_address()))
