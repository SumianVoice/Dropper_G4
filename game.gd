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

@rpc("authority", "call_remote")
func spawn_object(scene_path, _name):
	var obj = load(scene_path).instantiate()
	obj.name = _name
	world.add_child(obj)

@rpc("authority", "call_remote")
func despawn_object(node_name):
	var obj = world.get_node_or_null(node_name)
	if not obj: return
	obj.queue_free()

func start_game():
	$PeerList.spawn_players()
