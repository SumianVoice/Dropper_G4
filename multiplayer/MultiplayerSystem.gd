extends Node

class_name MultiplayerSystem

static var instance : MultiplayerSystem
static var enet_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
static var peer_data = {}
# 0 = no connection, 1 = connected
static var server_status : int = 0

var player_count = 0

signal on_peer_connected(id)

func _ready():
	if instance:
		queue_free()
		print("[warning] cannot create another instance of MultiplayerSystem")
	else:
		instance = self
	
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)


func _process(_delta):
	pass


static func is_auth(obj):
	if server_status <= 0: return false
	if not obj.is_multiplayer_authority(): return false
	return true


func host_server(port, upnp_enable):
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	
	if upnp_enable == true:
		upnp_setup(port)
	
	server_status = 1
	_peer_connected(1)
	pass


func join_server(ip, port, peerdata):
	server_status = 0
	peer_data = peerdata
	enet_peer.create_client(ip, port)
	multiplayer.multiplayer_peer = enet_peer

func _server_disconnected():
	server_status = 0
func _connection_failed():
	server_status = 0
func _connected_to_server():
	server_status = 2
	self.set_alias.rpc_id(1, peer_data.alias)


func upnp_setup(port):
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP discover failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP invalid gateway!")
	
	var map_result = upnp.add_port_mapping(port)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP port mapping failed! Error %s" % map_result)
	
	print("Success! Join address: %s" % upnp.query_external_address())

# statics!
static var connected_players : Dictionary = {}

@rpc("any_peer")
static func set_alias(_alias:String):
	if not instance.multiplayer.is_server(): return
	if not _alias: return
	var id = instance.multiplayer.get_remote_sender_id()
	print("'" + connected_players[id].alias + "' renamed to '" + _alias + "'")
	if not connected_players.has(id):
		connected_players[id].alias = _alias
	
	print("There are " + str(get_connected_players().size()) + " players")
	pass


static func get_connected_players():
	return connected_players

func _peer_connected(id):
	if not MultiplayerSystem.is_auth(self): return
	print(str(id) + " PEER was CONNECTED")
	player_count += 1
	connected_players[id] = {
		alias = "anon " + str(id),
		team = player_count,
		obj = null,
		id = id,
		drops = 0,
	}
	on_peer_connected.emit(id)

func _peer_disconnected(id):
	if not MultiplayerSystem.is_auth(self): return
	connected_players.erase(id)


