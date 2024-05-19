extends CanvasLayer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$"FirePlayer".text = "Fire Player: " + str($"../".fire_player_name)
