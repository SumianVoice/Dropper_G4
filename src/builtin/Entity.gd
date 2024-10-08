extends RigidBody3D
class_name Entity

static var scene_path = "res://src/builtin/Entity.tscn"
static var scene : PackedScene
static func instantiate():
	if not scene: scene = load(scene_path)
	return scene.instantiate()

var physics_timescale : float = 1
var delete_on_no_nodes : bool = true


func _ready():
	print("[SPAWN] PID " + str(multiplayer.get_unique_id()) +\
	"   SPAWNED NAME   " + name)

func _physics_process(delta):
	if not MultiplayerSystem.is_auth(self): return
	delta *= physics_timescale
	linear_velocity.y -= 9 * delta

func get_component_count():
	var c = 0
	for child in get_children():
		if child is EntityComponent:
			c += 1
	return c

func _process(delta):
	if MultiplayerSystem.is_auth(self):
		auth_multiplayer_sync(delta)
		if delete_on_no_nodes and get_component_count() < 1:
			print("[DESTROY] PID " + str(multiplayer.get_unique_id()) +\
			"   DESTROYED NAME   " + name)
			queue_free()
	else:
		client_multiplayer_sync(delta)


@rpc("authority", "call_local")
func add_component(component:EntityComponent, rel_pos):
	component.reparent(self, true)
	component.position = rel_pos


###################
# Multiplayer stuff
###################
# diff between last server pos and current pos, to interpolate
var s_pos_difference : Vector3 = Vector3(0,0,0)
var s_rot_difference : Vector3 = Vector3(0,0,0)
# time until next sync
var _network_tick = 0.5
var _network_enable = true


func auth_multiplayer_sync(delta):
	if not _network_enable: return
	if _network_tick < 0 \
	or (linear_velocity.length_squared() > 0.001 and _network_tick < 0.15):
		_network_tick = 0.2
	else:
		_network_tick -= delta; return
	update_pos.rpc(global_position)
	update_rotation.rpc(global_rotation)
	#update_velocity.rpc(linear_velocity)

func client_multiplayer_sync(_delta):
	if not _network_enable: return
	if s_pos_difference.length_squared() > 0.0:
		var interp = s_pos_difference * 1
		s_pos_difference -= interp
		global_position += interp
	if s_rot_difference.length_squared() > 0.0:
		var interp = s_rot_difference * 1
		s_rot_difference -= interp
		global_rotation += interp


@rpc("authority", "call_remote", "unreliable")
func update_velocity(vel:Vector3):
	linear_velocity = vel
@rpc("authority", "call_local", "unreliable")
func update_pos(pos:Vector3):
	s_pos_difference = pos - global_position
@rpc("authority", "call_local", "reliable")
func set_pos(pos:Vector3):
	s_pos_difference = Vector3(0,0,0)
	global_position = pos
@rpc("authority", "call_local", "unreliable")
func update_rotation(rot:Vector3):
	#global_rotation = rot
	s_rot_difference = rot - global_rotation
