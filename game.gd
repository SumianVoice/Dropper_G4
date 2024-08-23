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
	if not MultiplayerSystem.is_auth(self): return
	matchtime += delta

@rpc("authority", "call_remote")
func spawn_object(scene_path, _name):
	var obj = load(scene_path).instantiate()
	obj.name = _name
	world.add_child(obj)
	if MultiplayerSystem.is_auth(self):
		spawn_object.rpc(scene_path, _name)
		return obj

@rpc("authority", "call_remote")
func despawn_object(node_name):
	var obj = world.get_node_or_null(node_name)
	if not obj: return
	obj.queue_free()
	if MultiplayerSystem.is_auth(self):
		despawn_object.rpc(node_name)

func start_game():
	$PeerList.spawn_players()
