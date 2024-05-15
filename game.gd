extends Node3D

class_name GameManager

var drops_total = 0
var drop_add_time = 1
var drop_add_time_max = 2

var player1
var player2

static var instance : GameManager

func _ready():
	instance = self

var matchtime = 0
func _process(delta):
	if not is_multiplayer_authority(): return
	matchtime += delta
	drop_add_time -= delta
	if drop_add_time <= 0:
		drop_add_time += drop_add_time_max
		drops_total += 1
		add_drop_to_all_peers.rpc()
	pass

@rpc("authority", "call_local")
func add_drop_to_all_peers():
	for peer in $PeerList.get_children():
		peer.drops += 1
	pass

func start_game():
	$PeerList.spawn_players()
	$Droppers.reset.rpc()
	drop_add_time = 1
