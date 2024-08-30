extends Node3D
class_name EntityComponentHost

static var scene_path = "res://src/builtin/EntityComponent.tscn"
static var scene : PackedScene
static func instantiate():
	if not scene: scene = load(scene_path)
	return scene.instantiate()

@export var component : CollisionShape3D

@export var lift : float = 0
@export var torque : float = 0
@export var speed : float = 0

var reparent_grace = 1

var picked_up_by = null

func _ready():
	var col : CollisionShape3D = $Component/Area3D/CollisionShape3D
	if not component: component = $Component
	col.shape = component.shape
	multiplayer.allow_object_decoding = true

var _t_sync = 0

func _process(delta):
	if not MultiplayerSystem.is_auth(self): return
	host_check_has_entity_parent()
	reparent_grace -= delta
	
	if _t_sync > 0:
		_t_sync -= delta
	else:
		_t_sync += 0.1
		sync_position.rpc(position)
		sync_rotation.rpc(rotation)

@rpc("authority", "call_local")
func _reparent(to_node, rel_pos=null, rel_rot=null):
	to_node = get_tree().root.get_node_or_null(to_node)
	print(" reparent set to " + str(to_node))
	if to_node == null: return
	component.reparent(to_node, true)
	if rel_pos == null: rel_pos = Vector3(0,0,0)
	if rel_rot == null: rel_rot = Vector3(0,0,0)
	component.position = rel_pos
	component.rotation = rel_rot

func host_check_has_entity_parent():
	if not MultiplayerSystem.is_auth(self): return
	if reparent_grace > 0: return
	var parent = component.get_parent()
	if (not picked_up_by) and (not (parent is Entity)):
		reparent_grace = 0.5
		print("  REPARENTING --> PID " + str(multiplayer.get_unique_id()))
		var new_ent : Entity = Entity.instantiate()
		new_ent.name = "ENT" + str(randi())
		GameManager.world.add_child(new_ent)
		new_ent.set_pos.rpc(component.global_position)
		_reparent.rpc(new_ent.get_path(), null, null)

@rpc("authority", "call_local", "reliable")
func sync_on_drop(_player, _wield):
	MultiplayerSystem.peer_print("drop")
	picked_up_by = null

@rpc("authority", "call_local", "reliable")
func sync_on_pickup(_player, _wield):
	MultiplayerSystem.peer_print("pickup")
	picked_up_by = _player

@rpc("authority", "call_local", "reliable")
func sync_on_interact(_player, _wield):
	print("[ERROR] NO on_interact func listed, something is \
	calling this when it shouldn't")

@rpc("any_peer", "call_local", "reliable")
func request_pickup(_player, _wield):
	if not MultiplayerSystem.is_auth(self): return
	if picked_up_by != null: return
	_reparent.rpc(GameManager.world.get_path(), null)
	sync_on_pickup.rpc(_player, _wield)

@rpc("any_peer", "call_local", "reliable")
func request_drop(_player, _wield):
	if not MultiplayerSystem.is_auth(self): return
	sync_on_drop.rpc(_player, _wield)


@rpc("authority", "call_remote", "reliable")
func sync_position(pos:Vector3):
	position = pos
	MultiplayerSystem.peer_print(str(global_position))

@rpc("authority", "call_remote", "reliable")
func sync_rotation(rot:Vector3):
	rotation = rot
