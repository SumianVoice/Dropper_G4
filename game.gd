extends Node3D

class_name GameManager

var player1
var player2

static var instance : GameManager

func _ready():
	instance = self

var matchtime = 0
func _process(delta):
	if MultiplayerSystem.server_status != 1: return
	if not is_multiplayer_authority(): return
	matchtime += delta

func start_game():
	$PeerList.spawn_players()
