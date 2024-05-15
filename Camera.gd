extends Camera3D

@onready var game = $".."
var drops_used = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

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

func do_gui():
	var drops = game.drops_total - drops_used
	var p1 = game.player1
	var p2 = game.player2
	var t1 = $RichTextLabel as RichTextLabel
	var t2 = $RichTextLabel2 as RichTextLabel
	if not p1: t1.text = ""
	else: t1 = game.drops_total - p1.drops_used

var last_raycast
var selection : Platform
func _process(delta):
	var drops = game.drops_total - drops_used
	do_gui()
	var new_raycast = do_raycast_from_view()
	last_raycast = new_raycast
	if last_raycast.mouse_position_3D:
		$MeshInstance3D2.global_position = last_raycast.mouse_position_3D
	
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
		selection.drop_platform.rpc_id(1)
	

