extends CoreCharacter
class_name Player


@export var mouse_sensitivity: float = 0.2
var since_jump : float = 0

var inhabited = false

var picked_up : EntityComponentHost

var peer

@onready var collision : CollisionShape3D = $collision
@onready var camera : Camera3D = $camera
@onready var visuals : Node3D = $visuals
@onready var raycast_select : RayCast3D = $camera/raycast_select
@onready var drag_node : Node3D = $camera/drag_node


func _input(event):
	if not MultiplayerSystem.is_auth(self): return
	if (event is InputEventMouseMotion) and \
	(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		camera.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotation_degrees.x += -event.relative.y * mouse_sensitivity
		camera.rotation_degrees.x = clampf(camera.rotation_degrees.x, -80, 80)
		collision.rotation.y = camera.rotation.y
		visuals.rotation.y = camera.rotation.y
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.is_action_just_pressed("secondary_use") \
	and MultiplayerSystem.is_server():
		var path = "res://src/objects/components/ec_test_component.tscn"
		var com : EntityComponentHost =\
			GameManager.spawn_object(path, "ECH" + str(randi()))
		com.global_position.y += 2
		print("CREATED A COMPONENT")


var _t_ctrl = 0
func _process(delta):
	## PLAYER CLIENT
	if MultiplayerSystem.is_auth(self):
		auth_step(delta)
	## ALL OTHER CLIENTS
	else:
		peer_step(delta)
	
	## SERVER HOST ONLY
	if MultiplayerSystem.is_server():
		server_step(delta)
	
	for n in range(0, CTRLINDEX.size()):
		var cname = CTRLINDEX[n]
		last_ctrl[cname] = ctrl.get(cname, false)
	
	super(delta)


func auth_step(delta):
	if not inhabited:
		inhabited = true
		inhabit()
	get_all_controls()
	if _t_ctrl > 0:
		_t_ctrl -= delta
	else:
		_t_ctrl += 0.02
		update_ctrl.rpc(dict_to_ctrl_bits())

func peer_step(delta):
	if inhabited:
		inhabited = false
		deinhabit()

func server_step(delta):
	host_on_step_pickup(delta)
	#print("[" + str(multiplayer.get_unique_id()) + "] CTRL " + str(ctrl_bits))


func _ready():
	super()
	for n in range(0, CTRLINDEX.size()):
		var cname = CTRLINDEX[n]
		last_ctrl[cname] = false
		ctrl[cname] = false


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
			linear_velocity.x * -0.2,
			0,
			linear_velocity.z * -0.2,
		))
	
	since_jump += delta
	
	input_direction = Input.get_vector(
		"move_left", "move_right", "move_down", "move_up"
	)
	input_jump = Input.is_action_just_pressed("move_jump")
	
	apply_movement(delta)


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
		var move_force = (air_force if not is_on_floor else run_force
			if is_running else walk_force)
		apply_central_impulse(dir * move_force * delta)


func get_ray_selected():
	if not ctrl["interact"]: return
	if not raycast_select.is_colliding(): return null
	print(raycast_select.get_collider())
	return raycast_select.get_collider()


func host_on_step_pickup(_delta):
	if ctrl["interact"] and not last_ctrl["interact"]:
		print("INTERACT PRESSED")
	
	if picked_up == null and ctrl["interact"]:
		var sel = get_ray_selected() as Node
		if sel: sel = sel.get_parent()
		if (sel is EntityComponent) and (sel.get_parent() is Entity):
			sel = sel as EntityComponent
			picked_up = sel.entity_component_host as EntityComponentHost
			picked_up.request_pickup.rpc_id(1, self.get_path(), null)
			print("PICK UP")
	elif (not ctrl["interact"]) and picked_up != null:
		picked_up.request_drop.rpc_id(1, self.get_path(), picked_up)
		picked_up = null
		print("DROPPED")
	
	if picked_up == null: return
	
	picked_up.component.global_position = drag_node.global_position
	
	if (not last_ctrl["scroll_up"]) and ctrl["scroll_up"]:
		picked_up.component.global_rotation.y += 0.4
	if (not last_ctrl["scroll_down"]) and ctrl["scroll_down"]:
		picked_up.component.global_rotation.y -= 0.4



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
	var interp = Vector3(
		lerp_angle(camera.rotation.x, s_look_rot.x, 0.04),
		lerp_angle(camera.rotation.y, s_look_rot.y, 0.04),
		lerp_angle(camera.rotation.z, s_look_rot.z, 0.04),
	)
	camera.rotation = interp
	visuals.rotation.y = camera.global_rotation.y


@rpc("authority", "call_local", "unreliable")
func update_look_rotation(rot:Vector3):
	s_look_rot = rot

static var CTRLINDEX : Array = [
	"move_up","move_down","move_left","move_right","move_jump",
	"interact","use","secondary_use","scroll_up","scroll_down"
]

var last_ctrl : Dictionary = {}
var ctrl : Dictionary = {}
var ctrl_bits = 0

func get_all_controls():
	for n in range(0, CTRLINDEX.size()):
		var cname = CTRLINDEX[n]
		last_ctrl[cname] = ctrl.get(cname, false)
		ctrl[cname] = Input.is_action_pressed(cname) or Input.is_action_just_pressed(cname)

func ctrl_bits_to_dict():
	#print("[" + str(multiplayer.get_unique_id()) + "] IN " + str(ctrl_bits))
	for n in range(0, CTRLINDEX.size()):
		var cname = CTRLINDEX[n]
		last_ctrl[cname] = ctrl.get(cname, false)
		if ctrl_bits & (1 << n) > 0:
			ctrl[cname] = true
		else:
			ctrl[cname] = false
	return ctrl

func dict_to_ctrl_bits():
	ctrl_bits = 0
	for n in range(0, CTRLINDEX.size()):
		var cname = CTRLINDEX[n]
		var v = 1 if (ctrl.get(cname, false) == true) else 0
		#print(cname + " is " + str(v))
		ctrl_bits |= v << n
	#print("[" + str(multiplayer.get_unique_id()) + "] IN " + str(ctrl_bits))
	return ctrl_bits

@rpc("authority", "call_local", "reliable")
func update_ctrl(ctrl_int=0):
	ctrl_bits = ctrl_int
	ctrl_bits_to_dict()
	#if multiplayer.get_unique_id() == 1:
		#print(ctrl_bits)
		#print("[" + str(multiplayer.get_unique_id()) + "] " + str(ctrl_bits))

