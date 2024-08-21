extends Area3D

class_name Bullet

var lifetime : float = 0
var dir : Vector3 = Vector3(0,0,0)
var movetopos : Vector3 = Vector3(0,0,0)
var speed : float = 6

func _ready():
	pass

var _t = 0

func host_process(delta):
	if (MultiplayerSystem.server_status != 1) or \
	not is_multiplayer_authority(): return
	lifetime += delta
	if lifetime > 2:
		queue_free()
		return

func _process(delta):
	host_process(delta)
	
	var add_pos = dir * speed * delta
	global_position += add_pos
	
	if movetopos:
		movetopos += add_pos
		global_position = lerp(global_position, movetopos, 0.1)
	
	if _t > 0: _t -= delta
	else:
		_t += 0.1

@rpc("authority", "call_local")
func set_dir(val:Vector3):
	dir = val
@rpc("authority", "call_local")
func move_to(val:Vector3):
	movetopos = val
@rpc("authority", "call_local")
func set_pos(val:Vector3):
	global_position = val
