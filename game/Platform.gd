#@tool
extends StaticBody3D
class_name Platform


@export var fall_state = 0
@export var time_to_state = -1
var selected = false
@export var audio : AudioStreamPlayer
@export var drop_sound : AudioStream

@rpc("authority", "call_local")
func set_fall_state(_state):
	fall_state = _state
	if fall_state == 1:
		time_to_state = 1
		audio.stream = drop_sound
		audio.pitch_scale = randf() * 0.2 + 0.95
		audio.play()
	if fall_state == 2:
		time_to_state = 5
	if fall_state == 3:
		#queue_free()
		pass

@rpc("any_peer", "call_local")
func drop_platform():
	if fall_state != 0: return
	set_fall_state.rpc(1)




@onready var meshes_list = $meshes
var mesh_nodes = []

func collect_meshes():
	for child in meshes_list.get_children():
		if child is MeshInstance3D:
			mesh_nodes.append({
				obj = child,
				pos = child.position
				})

func _ready():
	collect_meshes()
	pass

var tt = 1
func _process(delta):
	if tt > 0: tt -= delta; return
	if fall_state == 1:
		set_flash()
		shake(delta, 0.05)
	elif fall_state == 2:
		set_flash()
		position.y -= delta * 2
	else:
		shake(delta, 0)
	
	if fall_state < 1:
		if selected:
			do_flash(delta)
		else:
			reset_flash()
	
	if time_to_state > 0:
		time_to_state -= delta
		if time_to_state < 0:
			set_fall_state(fall_state + 1)

func select():
	if selected: return
	selected = true
	set_flash()
	do_flash(0.1)
func deselect():
	if not selected: return
	selected = false
	reset_flash()


var flash_time = 0
func do_flash(delta):
	flash_time += delta
	set_flash()
func reset_flash():
	for mesh_meta in mesh_nodes:
		var mesh = mesh_meta.obj as MeshInstance3D
		var mat = mesh.get_active_material(0) as StandardMaterial3D
		mat.emission.r = 0
func set_flash():
	var s = (sin(flash_time * 10) + 1) * 0.2 + 0.3
	for mesh_meta in mesh_nodes:
		var mesh = mesh_meta.obj as MeshInstance3D
		var mat = mesh.get_active_material(0) as StandardMaterial3D
		mat.emission.r = mat.emission.g + s

var shake_time : float = 0.0
func shake(delta, amount):
	if shake_time > 0: shake_time -= delta; return
	else: shake_time += 0.05
	for mesh_meta in mesh_nodes:
		var mesh = mesh_meta.obj as MeshInstance3D
		mesh.position = Vector3(
			randf() * amount,
			0,
			randf() * amount
		) + mesh_meta.pos
	pass

