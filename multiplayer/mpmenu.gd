extends CanvasLayer

class_name MPMenu

@export var main_menu : Node
@export var alias_node : LineEdit
@export var address_entry : LineEdit
@export var port_entry : LineEdit
@export var host_status : Node
@export var peers_node : Node

static var peer_scene : PackedScene = preload("res://game/peer.tscn")
static var upnp_enable : bool = false # will be changed by the checkbox
static var alias : String
static var port : int = 9997

var player_count = 0

func _ready():
	show()
	var mpsystem = $MultiplayerSystem
	mpsystem.multiplayer.connected_to_server.connect(_connected_to_server)
	mpsystem.multiplayer.connection_failed.connect(_connection_failed)
	mpsystem.multiplayer.server_disconnected.connect(_server_disconnected)
	mpsystem.on_peer_connected.connect(_peer_connected)
	mpsystem.multiplayer.peer_disconnected.connect(_peer_disconnected)

func _server_disconnected():
	show()
func _connection_failed():
	show()
func _connected_to_server():
	hide()

func _peer_connected(id):
	if not MultiplayerSystem.is_auth(self): return
	player_count += 1
	var pnode = peer_scene.instantiate()
	pnode.name = str(id)
	pnode.team = player_count
	pnode.peerid = id
	peers_node.add_child(pnode)

func _peer_disconnected(id):
	if not MultiplayerSystem.is_auth(self): return
	var pnode = peers_node.get_node_or_null(str(id))
	if pnode:
		pnode.queue_free()

func is_valid_data_entered():
	if alias.length() < 3:
		alias = str(randi_range(1111,9999))
		return
#		return "ERROR: alias must be at least 3 chars long"
	return

func _on_host_pressed():
	if MultiplayerSystem.server_status != 0: return
	alias = alias_node.text
	port = (port_entry.text).to_int()
	var err = is_valid_data_entered()
	if err:
		host_status.text = err
		return
	hide()
	
	host_status.text = ">> HOST <<"
	
	MultiplayerSystem.instance.host_server(port, upnp_enable)
	pass


func _on_join_pressed():
	if MultiplayerSystem.server_status != 0: return
	alias = alias_node.text
	port = (port_entry.text).to_int()
	var err = is_valid_data_entered()
	if err:
		host_status.text = err
		return
	hide()
	host_status.text = "CONNECTING..."
	
	MultiplayerSystem.instance.join_server(address_entry.text, port, {
		alias = alias
	})
	pass

func _on_upnp_enable_toggled(button_pressed):
	upnp_enable = button_pressed
