extends Button

func _ready():
	hide()

var shown = false
func _process(_delta):
	if MultiplayerSystem.server_status == 1:
		if (not visible) and (not shown):
			shown = true
			show()




func _on_pressed():
	#hide()
	release_focus()
	$"..".start_game()
