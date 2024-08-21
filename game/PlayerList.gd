extends Node3D


func _ready():
	pass

func _process(_delta):
	pass

func clear_players():
	for child in get_children():
		child.name = child.name + "_REMOVED"
		child.free()
