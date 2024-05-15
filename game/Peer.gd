extends Node3D
class_name Peer

@export var peerid : int
@export var alias : String = "anon"
@export var team : int = -1
@export var drops : int = 0

func _ready():
	print(str(peerid) + " PEER was created")
	pass

func _process(delta):
	pass
