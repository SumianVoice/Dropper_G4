extends Node3D

@rpc("authority", "call_local")
func reset():
	for dropper in get_children():
		for p in dropper.get_children():
			if p is Platform:
				p.deselect()
				p.set_fall_state(0)
				p.time_to_state = -1
				p.position.y = 0
