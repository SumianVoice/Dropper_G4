extends CharacterBody3D


const SPEED = 2.0
const JUMP_VELOCITY = 4.5
var peer
var dash_time = 1
var dash_time_max = 5
var OVERRIDEPOS_ = Vector3(0,0,0)
var pos_auth
@onready var dash_bar = $ProgressBar
var peerid = 1
var alive_time = 0
static var bulletscene : PackedScene = load("res://game/Bullet.tscn")

var drops_used = 0

#@rpc("authority", "call_local")
#func use_drop(platform:Platform):
	#drops_used += 1
	#pass

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Fucking retarded workaround for SHITTY godot design
@rpc("any_peer", "call_local")
func OVERRIDEPOS(pos):
	if multiplayer.get_remote_sender_id() != 1: return
	OVERRIDEPOS_ = pos
	global_position = OVERRIDEPOS_

@rpc("authority", "call_remote")
func update_position(pos):
	if alive_time < 0.01:
		global_position = OVERRIDEPOS_
		return
	pos_auth = pos

func _enter_tree():
	set_multiplayer_authority(str(name).to_int(), true)
	pass

func _ready():
	pass

var t = 0
func _physics_process(delta):
	alive_time += delta
	
	if not is_multiplayer_authority():
		if pos_auth:
			global_position = lerp(global_position, pos_auth, 0.5)
		return
	$ProgressBar.show()
	
	if t < 0:
		update_position.rpc(global_position + velocity * 0.05)
		t += 0.05
	else: t -= delta
	
	if dash_time > 0: dash_time -= delta
	dash_bar.value = 1 - clamp(dash_time / dash_time_max,0,1)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	
	var speed = SPEED
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if Input.is_action_just_pressed("move_dash") and dash_time <= 0:
		var bu : Bullet = bulletscene.instantiate()
		GameManager.instance.add_child(bu, true)
		bu.set_dir.rpc(Vector3(direction))
		bu.set_pos.rpc(Vector3(global_position))
		#speed *= (1 + Input.get_action_strength("move_dash")*3)
		#dash_time = dash_time_max
		#velocity.x = direction.x * speed
		#velocity.z = direction.z * speed
		#velocity.y = 2
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, speed*delta*10)
		velocity.z = move_toward(velocity.z, direction.z * speed, speed*delta*10)
	else:
		velocity.x = move_toward(velocity.x, 0, speed*delta*10)
		velocity.z = move_toward(velocity.z, 0, speed*delta*10)
	
	move_and_slide()
