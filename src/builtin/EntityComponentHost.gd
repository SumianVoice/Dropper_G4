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

func _process(_delta):
	if not MultiplayerSystem.is_auth(self): return
	check_has_entity_parent()
	reparent_grace -= _delta

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

func check_has_entity_parent():
	if not MultiplayerSystem.is_auth(self): return
	if reparent_grace > 0: return
	var parent = component.get_parent()
	if (not picked_up_by) and (not (parent is Entity)):
		reparent_grace = 0.5
		print("  REPARENTING --> PID " + str(multiplayer.get_unique_id()))
		var new_ent : Entity = Entity.instantiate()
		new_ent.name = str(randi()) + "ENT"
		#GameManager.world_spawner.spawn(new_ent)
		GameManager.world.add_child(new_ent)
		#GameManager.instance.spawn_object.rpc(Entity.scene_path, new_ent.name)
		new_ent.global_position = component.global_position
		new_ent.update_pos.rpc(component.global_position)
		#print(new_ent.get_path())
		_reparent.rpc(new_ent.get_path(), null)

func on_drop(_player, _wield):
	picked_up_by = null

func on_pickup(_player, _wield):
	print("pickup")
	_reparent.rpc(GameManager.world.get_path(), null)
	picked_up_by = _player

func on_interact(_player, _wield):
	on_pickup.rpc(_player, _wield)

@rpc("any_peer", "call_local")
func request_pickup(_player, _wield):
	pass

