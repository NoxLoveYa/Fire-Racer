extends Node3D

## Time before round starts
@export var freeze_delay: float = 10.0
## Round duration in mins
@export var game_time: float = 2.5
## Immunity time (player doesn't gain points)
@export var immunity_time: float = 4.5

@export var player_scene: PackedScene
@export var fire_scene: PackedScene

var started = false

## The player that holds the flame
var fire_instance: Node3D = null
var fire_player: Node3D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not started or not multiplayer.is_server():
		return
	if (fire_instance == null):
		fire_instance = $"fire"
	if (not fire_player):
		fire_player = $"1"
	fire_instance.position = fire_player.position + Vector3(0, 1, 0)

# Multiplayer
var peer = ENetMultiplayerPeer.new()

func _on_host_pressed():
	peer.create_server(1027)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$CanvasLayer.hide()
	started = true

func _on_join_pressed():
	peer.create_client($"CanvasLayer/IpEdit".text, 1027)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()

func add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	var fire = fire_scene.instantiate()
	fire.set_multiplayer_authority(1)
	fire.name = "fire"
	call_deferred("add_child", fire, true)

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id):
	pass
	get_node(str(id))
