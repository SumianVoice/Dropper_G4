extends Node3D
class_name Peer

@export var peerid : int
@export var alias : String = "anon"
@export var team : int = -1
@export var drops_used : int = 0
@export var drops : int = 0
@export var game : GameManager

func do_raycast_from_view():
	var viewport := get_viewport()
	var mouse_position := viewport.get_mouse_position()
	var camera := viewport.get_camera_3d()
	var origin := camera.project_ray_origin(mouse_position)
	var direction := camera.project_ray_normal(mouse_position)
	var ray_length := camera.far
	var end := origin + direction * ray_length
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	var result := space_state.intersect_ray(query)
	var mouse_position_3D:Vector3 = result.get("position", end)
	result.mouse_position_3D = mouse_position_3D
	return result

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	print(("[" + str(multiplayer.get_unique_id()) + "] --> ") + name + "  PEER entered tree and set auth")

func do_gui():
	var num = get_index()
	var t1 = $Control/MarginContainer/RichTextLabel as RichTextLabel
	var margin : MarginContainer = $Control/MarginContainer
	if num == 0:
		margin.anchors_preset = 2
	else:
		margin.anchors_preset = 3
	t1.text = str(drops)

@rpc("any_peer", "call_local")
func set_drops(amount):
	var id = multiplayer.get_remote_sender_id()
	if (id != 1) and id != get_multiplayer_authority(): return
	drops = amount
	pass

func drop_platform(platform:Platform):
	if drops <= 0: return false
	if platform.fall_state != 0: return false
	set_drops.rpc(drops - 1)
	platform.drop_platform.rpc_id(1)

var last_raycast
var selection : Platform
func do_selection(_delta):
	var new_raycast = do_raycast_from_view()
	last_raycast = new_raycast
	
	if drops <= 0 or (new_raycast == null) or (new_raycast.get("collider") == null):
		if selection:
			selection.deselect()
			selection = null
	
	if drops > 0 and (last_raycast.get("collider") and (last_raycast.collider is Platform)
	and last_raycast.collider != selection):
		if selection:
			selection.deselect()
		selection = last_raycast.collider
		selection.select()
		pass
	
	if drops <= 0: return
	if selection and Input.is_action_just_pressed("select"):
		drop_platform(selection)

func _ready():
	#print(str(peerid) + " PEER was created")
	game = get_parent().get_parent()

func _process(delta):
	do_gui()
	if not is_multiplayer_authority(): return
	do_selection(delta)
