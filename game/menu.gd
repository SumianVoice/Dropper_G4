extends Node2D

const PEER_SCENE = preload("res://game/peer.tscn")
const PLAYER_SCENE = preload("res://game/peer.tscn")
@onready var main_menu = $CanvasLayer/main_menu
@onready var address_entry = $CanvasLayer/main_menu/MarginContainer/VBoxContainer/address
@onready var port_entry = $CanvasLayer/main_menu/MarginContainer/VBoxContainer/port
var upnp_enable = false # will be changed by the checkbox

var PORT = 9997
var enet_peer = ENetMultiplayerPeer.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_host_pressed():
	PORT = (port_entry.text).to_int()
	print(PORT)
	if (not PORT) or PORT <= 0:
		PORT = 9997
	main_menu.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
	$host_status.text = ">> HOST <<"
	
	if upnp_enable == true:
		upnp_setup()
	pass

func _on_join_pressed():
	PORT = (port_entry.text).to_int()
	print(PORT)
	if (not PORT) or PORT <= 0:
		PORT = 9997
	main_menu.hide()
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	$host_status.text = "PEER"
	pass

func add_player(peerid):
	var player = PEER_SCENE.instantiate()
	player.name = str(peerid)
	add_child(player)
	player.global_position = Vector2(500, 200)

func remove_player(peerid):
	var player = get_node_or_null(str(peerid))
	if player:
		player.queue_free()

# sets up auto port forwarding basically, but only for routers that allow it
func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP discover failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP invalid gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP port mapping failed! Error %s" % map_result)
	
	print("Success! Join address: %s" % upnp.query_external_address())













func _on_upnp_enable_toggled(button_pressed):
	upnp_enable = button_pressed
