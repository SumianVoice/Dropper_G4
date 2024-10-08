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
	for peer in get_children():
		if peer is Peer:
			spawn_player(peer)

func spawn_player(peer:Peer):
	if playerlist.get_node_or_null(str(peer.peerid)):
		return
	var inst = player.instantiate() as Player
	var id = peer.peerid
	inst.name = str(id)
	inst.peer = peer
	print(str(id) + " player was created")
	playerlist.add_child(inst, true)
	var d = 3
	var pos = global_position + Vector3(
		randf_range(-d, d),
		0,
		randf_range(-d, d)
	)
	pos.y += 3
	inst.global_position = pos
	inst.update_pos.rpc(pos)
	inst.set_auth.rpc(id)
