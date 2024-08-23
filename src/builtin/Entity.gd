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
	print("[SPAWN]" + str(multiplayer.get_unique_id()) + "  SPAWNED --> NAME " + name)

func _physics_process(delta):
	if not MultiplayerSystem.is_auth(self): return
	delta *= physics_timescale
	linear_velocity.y -= 9 * delta

func _process(delta):
	if MultiplayerSystem.is_auth(self):
		auth_multiplayer_sync(delta)
		if delete_on_no_nodes and get_child_count() < 1:
			print("[DESTROY]" + str(multiplayer.get_unique_id()) + "  DESTROYED --> " + name)
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
	if _network_tick > 0: _network_tick -= delta; return
	else: _network_tick += 0.2
	update_pos.rpc(global_position)
	update_velocity.rpc(linear_velocity)

func client_multiplayer_sync(_delta):
	if not _network_enable: return
	if s_pos_difference.length_squared() > 0.2:
		var interp = s_pos_difference * 0.05
		s_pos_difference -= interp
		global_position += interp
	if s_rot_difference.length_squared() > 0.2:
		var interp = s_rot_difference * 0.05
		s_rot_difference -= interp
		global_rotation += interp


@rpc("authority", "call_remote")
func update_velocity(vel:Vector3):
	linear_velocity = vel
@rpc("authority", "call_local")
func update_pos(pos:Vector3):
	s_pos_difference = global_position - pos
@rpc("authority", "call_local")
func update_rotation(rot:Vector3):
	s_rot_difference = global_position - rot
