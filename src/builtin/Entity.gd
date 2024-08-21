extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	if MultiplayerSystem.is_auth(self): return
	move_and_slide()

func _process(delta):
	if MultiplayerSystem.is_auth(self): return
	do_multiplayer_sync(delta)



###################
# Multiplayer stuff
###################
# diff between last server pos and current pos, to interpolate
var s_pos_difference : Vector3 = Vector3(0,0,0)
var s_rot_difference : Vector3 = Vector3(0,0,0)
# time until next sync
var _network_tick = 0.5
var _network_enable = true

func do_multiplayer_sync(delta):
	if not _network_enable: return
	if s_pos_difference.length_squared() > 0.2:
		var interp = lerp(Vector3.ZERO, s_pos_difference, 0.05)
		s_pos_difference -= interp
		global_position += interp
	if s_rot_difference.length_squared() > 0.2:
		var interp = lerp(Vector3.ZERO, s_rot_difference, 0.05)
		s_rot_difference -= interp
		global_rotation += interp
	
	if _network_tick > 0: _network_tick -= delta; return
	else: _network_tick += 0.2
	update_pos.rpc(global_position)
	update_velocity.rpc(velocity)

@rpc("authority", "call_local")
func update_velocity(vel:Vector3):
	velocity = vel
@rpc("authority", "call_local")
func update_pos(pos:Vector3):
	s_pos_difference = global_position - pos
@rpc("authority", "call_local")
func update_rotation(rot:Vector3):
	s_rot_difference = global_position - rot
