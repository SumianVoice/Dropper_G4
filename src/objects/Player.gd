extends CoreCharacter
class_name Player


@export var sensitivity: float = 0.2
var x_rotation : float
var y_rotation : float
var since_jump : float = 0

var inhabited = false

var peer

@onready var collision : CollisionShape3D = $collision
@onready var camera : Camera3D = $camera
@onready var visuals : Node3D = $visuals

func _input(event):
	if not MultiplayerSystem.is_auth(self): return
	if event is InputEventMouseMotion and \
	Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		x_rotation += -event.relative.y * sensitivity
		camera.rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		collision.rotation.y = camera.rotation.y
		visuals.rotation.y = camera.rotation.y
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta):
	super(delta)
	x_rotation = clampf(x_rotation, -80, 80)
	camera.rotation_degrees.x = x_rotation
	
	if MultiplayerSystem.is_auth(self):
		if not inhabited:
			inhabited = true
			inhabit()
	else:
		if inhabited:
			inhabited = false
			deinhabit()


func _ready():
	super()


func inhabit():
	camera.current = true
	visuals.hide()

func deinhabit():
	camera.current = false
	visuals.show()

func do_control(delta):
	if not MultiplayerSystem.is_auth(self): return
	
	if is_on_floor:
		apply_force(Vector3(
			linear_velocity.x * -0.1,
			0,
			linear_velocity.z * -0.1,
		))
	
	since_jump += delta
	
	process_character_input()
	apply_movement(delta)

func process_character_input():
	input_direction = Input.get_vector("move_left", "move_right", "move_down", "move_up")
	input_jump = Input.is_action_just_pressed("move_jump")

func apply_movement(delta: float):
	if input_jump and since_jump > 0.1:
		if is_on_floor:
			since_jump = 0
			apply_central_impulse(floor_normal * jump_force)
		elif is_on_wall:
			since_jump = 0
			var new_norma = (wall_normal + global_basis.y).normalized()
			apply_central_impulse(new_norma * jump_force)
	
	var forward = floor_normal.cross(orientation_node.global_basis.x)
	var right = forward.cross(floor_normal)
	var dir = ((forward * input_direction.y) + (right * input_direction.x)).normalized()
	if dir:
		var move_forc = air_force if not is_on_floor else run_force if is_running else walk_force
		apply_central_impulse(dir * move_forc * delta)



###################
# Multiplayer stuff
###################

var s_look_rot : Vector3 = Vector3(0,0,0)

func auth_multiplayer_sync(delta):
	if not super(delta): return
	update_look_rotation.rpc(camera.rotation)

func angle_move_toward(a, b, r):
	if lerp_angle(a, b, 0.01) >= 0:
		return minf(b, a + r)
	else:
		return maxf(b, a + r)

func client_multiplayer_sync(delta):
	if not super(delta): return
	if s_look_rot.length_squared() > 0.2:
		var interp = Vector3(
			lerp_angle(camera.rotation.x, s_look_rot.x, 0.01),
			lerp_angle(camera.rotation.y, s_look_rot.y, 0.01),
			lerp_angle(camera.rotation.z, s_look_rot.z, 0.01),
		)
		camera.rotation = interp
		visuals.rotation.y = camera.global_rotation.y


@rpc("authority", "call_local")
func update_look_rotation(rot:Vector3):
	s_look_rot = rot
	#s_look_rot_difference = rot - camera.global_rotation
	#camera.rotation = rot
	#visuals.rotation.y = rot.y
