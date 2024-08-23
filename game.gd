extends Node3D

class_name GameManager

var player1
var player2

static var instance : GameManager
static var world : Node3D
static var world_spawner : MultiplayerSpawner

func _ready():
	instance = self
	world = $world
	world_spawner = $MultiplayerSpawnerRoot

var matchtime = 0
func _process(delta):
	if MultiplayerSystem.server_status != 1: return
	if not is_multiplayer_authority(): return
	matchtime += delta

func start_game():
	$PeerList.spawn_players()
