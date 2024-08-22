extends CoreCharacter
class_name Player


@export var sensitivity: float = 0.2
var x_rotation: float
var y_rotation: float

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
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	super(delta)
	if MultiplayerSystem.is_auth(self):
		camera.current = true
	else:
		camera.current = false
	x_rotation = clampf(x_rotation, -80, 80)
	camera.rotation_degrees.x = x_rotation

func _ready():
	super()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func do_control(delta):
	if not MultiplayerSystem.is_auth(self): return
	process_character_input()
	apply_movement(delta)

func process_character_input():
	input_direction = Input.get_vector("move_left", "move_right", "move_down", "move_up")
	input_jump = Input.is_action_just_pressed("move_jump")

func apply_movement(delta: float):
	if input_jump:
		if is_on_floor:
			apply_central_impulse(floor_normal * jump_force)
		elif is_on_wall:
			var new_norma = (wall_normal + global_basis.y).normalized()
			apply_central_impulse(new_norma * jump_force)
	
	var forward = floor_normal.cross(orientation_node.global_basis.x)
	var right = forward.cross(floor_normal)
	var dir = ((forward * input_direction.y) + (right * input_direction.x)).normalized()
	if dir:
		var move_forc = air_force if not is_on_floor else run_force if is_running else walk_force
		apply_central_impulse(dir * move_forc * delta)


