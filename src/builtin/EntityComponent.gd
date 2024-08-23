extends CollisionShape3D
class_name EntityComponent

static var scene_path = "res://src/builtin/EntityComponent.tscn"
static var scene : PackedScene
static func instantiate():
	if not scene: scene = load(scene_path)
	return scene.instantiate()

@export var lift : float = 0
@export var torque : float = 0
@export var speed : float = 0

var picked_up : bool = false

func _ready():
	var col : CollisionShape3D = $Area3D/CollisionShape3D
	col.shape = shape

func _process(_delta):
	if not MultiplayerSystem.is_auth(self): return
	check_has_entity_parent()

func check_has_entity_parent():
	var parent = get_parent()
	if (not picked_up) and (not (parent is Entity)):
		var new_ent : Entity = Entity.instantiate()
		new_ent.name = str(randi())
		GameManager.instance.add_child(new_ent, true)
		new_ent.global_position = global_position
		reparent(new_ent, true)

func on_drop(_player, _wield):
	check_has_entity_parent()
	picked_up = false

func on_pickup(_player, _wield):
	reparent(GameManager.instance, true)
	picked_up = true

func on_interact(_player, _wield):
	on_pickup(_player, _wield)
