extends Node3D

@export var droppers : Node3D
@export var playerlist : Node3D
@export var player : PackedScene

func _ready():
	pass

func _process(_delta):
	pass

func spawn_players():
	if not is_multiplayer_authority(): return
	playerlist.clear_players()
	for child in get_children():
		if child is Peer:
			child.set_drops.rpc(0)
			var dropper = droppers.get_children()[child.team - 1]
			if dropper:
				var inst = player.instantiate() as Node3D
				var id = child.peerid
				inst.name = str(id)
				inst.peer = child
				print(str(id) + " player was created")
				playerlist.add_child(inst, true)
				var pos = dropper.global_position
				pos.y += 3
				inst.OVERRIDEPOS.rpc(pos)
				print(pos)
				if child.team == 1:
					$"..".player1 = inst
				elif child.team == 2:
					$"..".player2 = inst
					
				#inst.manual_set_multiplayer_authority(child.peerid)
				#inst.set_multiplayer_authority(child.peerid, true)



# AUTH IS ONLY WORKING ON HOST, TEST FOR ONLY PEER WHICH AUTH FOR WHICH NODE, SHOW ABOVE CHARACTER
# THIS IS FUCKING RETARDED

