extends CollisionShape3D
class_name EntityComponent

static var scene = preload("res://src/builtin/EntityComponent.tscn")

@export var lift : float = 0
@export var torque : float = 0
@export var speed : float = 0

func _ready():
	var col : CollisionShape3D = $Area3D/CollisionShape3D
	col.shape = shape

func _process(delta):
	if not MultiplayerSystem.is_auth(self): return
	_check_has_entity_parent()

func _check_has_entity_parent():
	var parent = get_parent()
	if not (parent is Entity):
		var new_ent = Entity.scene.instantiate() as Entity
		parent.add_child(new_ent, true)
		new_ent.global_position = global_position
		new_ent.add_child(self, true)

func on_drop(player, wield):
	pass

func on_pickup(player, wield):
	pass

func on_interact(player, wield):
	pass
