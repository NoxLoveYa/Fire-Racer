extends Node3D

## Time before round starts
@export var freeze_delay: float = 10.0
## Round duration in mins
@export var game_time: float = 2.5
## Immunity time (player doesn't gain points)
@export var immunity_time: float = 4.5

## The player that holds the flame
var fire_player: Node3D = null

var fire = null

# Called when the node enters the scene tree for the first time.
func _ready():
	fire = $Fire
	fire_player = $Player1
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if fire_player == null:
		fire.position = Vector3(0, -100, 0)
	else:
		fire.position = fire_player.position + get_node(fire_player.name + "/Player").position + Vector3(0, 1, 0)
	pass
