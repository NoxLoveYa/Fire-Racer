extends Node3D

## Time before round starts
@export var freeze_delay: float = 10.0
## Round duration in mins
@export var game_duration: float = 2.5
## Immunity time (player doesn't gain points)
@export var immunity_time: float = 4.5
@export var state: String = "freeze"

@export var player_scene: PackedScene
@export var fire_scene: PackedScene

@export var fire_player_name: String = "None"

@onready var players: Array[Node3D] = []
@onready var timer: Timer = $Timer
## The player that holds the flame
@onready var fire_instance: Node3D = $Fire
@onready var fire_player: Node3D = null
var started = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not started or not multiplayer.is_server():
		return
	if (not fire_player):
		fire_player = $"1"
	fire_instance.position = fire_player.position + Vector3(0, 1, 0)

# Multiplayer
var peer = ENetMultiplayerPeer.new()

@rpc("any_peer", "call_local")
func _change_state():
	if state == "freeze":
		if multiplayer.is_server():
			fire_player = players.pick_random()
			fire_player_name = fire_player.name
		state = "imun"
	elif state == "imun":
		state = "game"
	elif state == "game":
		state = "disp_winner"
	else:
		state = "freeze"
	print(state)
	
func _on_timer_timeout():
	rpc("_change_state")

func _on_host_pressed():
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$CanvasLayer.hide()
	$Hud.show()
	timer.wait_time = freeze_delay
	timer.start()
	started = true

func _on_join_pressed():
	peer.create_client($"CanvasLayer/IpEdit".text, 135)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()
	$Hud.show()

func add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	players.append(player)

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id):
	pass
	get_node(str(id))
