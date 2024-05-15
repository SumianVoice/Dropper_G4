extends CanvasLayer

class_name MultiplayerSystem

@export var main_menu : Node
@export var alias_node : LineEdit
@export var address_entry : LineEdit
@export var port_entry : LineEdit
@export var host_status : Node
@export var players : Node
@export var peer_scene : PackedScene

static var instance : MultiplayerSystem

static var upnp_enable : bool = false # will be changed by the checkbox
static var alias : String
static var port : int = 9997
static var enet_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
# 0 = no connection, 1 = connected
static var server_status : int = 0

var player_count = 0

func _ready():
	show()
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
	pass


func _process(_delta):
	pass


func is_valid_data_entered():
	if alias.length() < 3:
		alias = str(randi_range(1111,9999))
		return
#		return "ERROR: alias must be at least 3 chars long"
	pass

func _on_host_pressed():
	if server_status != 0: return
	alias = alias_node.text
	port = (port_entry.text).to_int()
	var err = is_valid_data_entered()
	if err:
		host_status.text = err
		return
	hide()
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	
	host_status.text = ">> HOST <<"
	
	if upnp_enable == true:
		upnp_setup()
	
	server_status = 1
	_peer_connected(1)
	pass


func _on_join_pressed():
	if server_status != 0: return
	alias = alias_node.text
	port = (port_entry.text).to_int()
	var err = is_valid_data_entered()
	if err:
		host_status.text = err
		return
	enet_peer.create_client(address_entry.text, port)
	multiplayer.multiplayer_peer = enet_peer
	hide()
	host_status.text = "CONNECTING..."
	pass


func _server_disconnected():
	server_status = 0
	host_status.text = "CONNECTION LOST"
	show()


func _connection_failed():
	server_status = 0
	host_status.text = "CONNECTION FAILED"
	show()


func _connected_to_server():
	server_status = 2
	host_status.text = "PEER"
	MultiplayerSystem.instance.set_alias.rpc_id(1, alias)
	pass


func upnp_setup():
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


func _on_upnp_enable_toggled(button_pressed):
	upnp_enable = button_pressed



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
	print(str(id) + " PEER was CONNECTED")
	player_count += 1
	connected_players[id] = {
		alias = "anon " + str(id),
		team = player_count,
		obj = null,
		id = id,
		drops = 0,
	}
	var pnode = instance.peer_scene.instantiate()
	pnode.name = str(id)
	pnode.team = player_count
	pnode.peerid = id
	instance.players.add_child(pnode)

func _peer_disconnected(id):
	connected_players.erase(id)
	var pnode = instance.players.get_node_or_null(str(id))
	if pnode:
		pnode.queue_free()
	

