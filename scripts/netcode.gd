extends Node

@export var do_upnp := false

var Util = load("res://scripts/util.gd")

# must be set to get add_child to work
var multi = null
# called immediately when hosting or joining a game
# () -> void
var on_play = Util.Option.None(): 
	set(value):
		assert(value is Callable)
		on_play = Util.Option.Some(value)
# called after upnp setup when hosting or joining
# () -> void
var on_play_post = Util.Option.None():
	set(value):
		assert(value is Callable)
		on_play_post = Util.Option.Some(value)
# called when hosting a game after multiplayer setup
# () -> void
var on_host = Util.Option.None():
	set(value):
		assert(value is Callable)
		on_host = Util.Option.Some(value)
# called when joining a game after multiplayer setup
# () -> void
var on_join = Util.Option.None(): 
	set(value):
		assert(value is Callable)
		on_host = Util.Option.Some(value)
# called to create a player object. should not add the player object 
# to the tree, since the library renames it before adding it
# (peer_id:int) -> void
var spawn_player = Util.Option.None():
	set(value):
		assert(value is Callable)
		spawn_player = Util.Option.Some(value)
# where to send logs. each member must have method pause: (string) -> void
var loggers := []

const PORT := 9999
var enet_peer := ENetMultiplayerPeer.new()
var players := []

# connect these to your signals

func _on_host():
	if on_play.is_some: on_play.value.call()
	enet_peer.create_server(PORT)
	multi.multiplayer_peer = enet_peer
	multi.peer_connected.connect(add_player)
	multi.peer_disconnected.connect(remove_player)
	players = []
	if do_upnp: upnp_setup()
	if on_host.is_some: on_host.value.call()
	add_player(multi.get_unique_id())
	if on_play_post.is_some: on_play_post.value.call()
	
func _on_join(ip):
	if on_play.is_some: on_play.value.call()
	enet_peer.create_client(ip, PORT)
	multi.multiplayer_peer = enet_peer
	if on_join.is_some: on_join.value.call()
	if on_play_post.is_some: on_play_post.value.call()

func _leave_game():
	for player in players:
		if player != multi.get_unique_id():
			multi.disconnect_peer(player)
	multi.disconnect_peer(1)

# these are helpers

func add_player(peer_id):
	players.append(peer_id)
	if spawn_player.is_some:
		spawn_player.value.call(peer_id)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func get_port():
	return PORT

func my_log(msg):
	for l in loggers:
		l.log(msg)

func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		my_log("UPNP Discover Failed! Error " + str(discover_result))
		return
	if not upnp.get_gateway():
		my_log("UPNP No Gateway")
	if not upnp.get_gateway().is_valid_gateway():
		my_log("UPNP Invalid Gateway!")
		return
	var map_result = upnp.add_port_mapping(get_port())
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		my_log("UPNP Port Mapping Failed! Error " + str(map_result))
		return
	my_log("Success! Join Address: " + str(upnp.query_external_address()))
