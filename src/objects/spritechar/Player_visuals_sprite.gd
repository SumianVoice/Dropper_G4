extends Node3D

@export var player : Player

func _ready():
	pass

func to_vec2(vec3):
	return Vector2(vec3.x, vec3.z)

func _process(delta):
	var cam = get_viewport().get_camera_3d()
	if not cam: return
	var angle_to_cam = to_vec2(global_position).direction_to(
		to_vec2(cam.global_position))
	var facing = to_vec2(basis.z).dot(angle_to_cam)
	#print(facing)
	
	var anim = "idle"
	var vel = player.linear_velocity
	vel.y = 0
	if vel.length_squared() > 0.1:
		anim = "walk"
	
	for node in get_children():
		node = node as AnimatedSprite3DFacer
		if not node is AnimatedSprite3DFacer: continue
		if node.is_enabled and facing >= node.dot_min and facing <= node.dot_max:
			show_sprite(node, anim)
			break
	
	rotation.y = floor(rotation.y * 4) / 4

func show_sprite(node, anim="idle"):
	for snode in get_children():
		snode = snode as AnimatedSprite3DFacer
		if not snode is AnimatedSprite3DFacer: continue
		if not node.is_enabled: continue
		if snode == node:
			snode.show()
			snode.play(anim)
		else:
			snode.hide()
