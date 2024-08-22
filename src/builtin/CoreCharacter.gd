extends RigidCharacterBody3D
class_name CoreCharacter

var physics_timescale : float = 1

func _physics_process(delta):
	if not MultiplayerSystem.is_auth(self): return
	delta *= physics_timescale
	linear_velocity.y -= 9 * delta
	super(delta)

func _process(delta):
	if MultiplayerSystem.is_auth(self):
		auth_multiplayer_sync(delta)
	else:
		client_multiplayer_sync(delta)


###################
# Multiplayer stuff
###################
# diff between last server pos and current pos, to interpolate
var s_pos_difference : Vector3 = Vector3(0,0,0)
var s_rot_difference : Vector3 = Vector3(0,0,0)
# time until next sync
var _network_tick = 0.5
var _network_enable = true


@rpc("any_peer", "call_local")
func set_auth(id):
	if multiplayer.get_remote_sender_id() != 1: return
	set_multiplayer_authority(id, true)

func auth_multiplayer_sync(delta):
	if not _network_enable: return
	if _network_tick > 0: _network_tick -= delta; return
	else: _network_tick += 0.2
	update_pos.rpc(global_position)
	update_velocity.rpc(linear_velocity)

func client_multiplayer_sync(delta):
	if not _network_enable: return
	if s_pos_difference.length_squared() > 0.2:
		var interp = lerp(Vector3.ZERO, s_pos_difference, 0.05)
		s_pos_difference -= interp
		global_position += interp
	if s_rot_difference.length_squared() > 0.2:
		var interp = lerp(Vector3.ZERO, s_rot_difference, 0.05)
		s_rot_difference -= interp
		global_rotation += interp


@rpc("authority", "call_local")
func update_velocity(vel:Vector3):
	linear_velocity = vel
@rpc("authority", "call_local")
func update_pos(pos:Vector3):
	s_pos_difference = global_position - pos
@rpc("authority", "call_local")
func update_rotation(rot:Vector3):
	s_rot_difference = global_position - rot
