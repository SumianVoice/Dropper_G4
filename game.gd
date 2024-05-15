extends Node3D

var drops_total = 0
var drop_add_time = 1
var drop_add_time_max = 2

var player1
var player2

func _ready():
	pass

var matchtime = 0
func _process(delta):
	matchtime += delta
	drop_add_time -= delta
	if drop_add_time <= 0:
		drop_add_time += drop_add_time_max
		drops_total += 1
	pass

func start_game():
	$PeerList.spawn_players()
	$Droppers.reset.rpc()
	drops_total = 0
