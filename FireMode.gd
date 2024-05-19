extends Node3D

## Time before round starts
@export var freeze_delay: float = 10.0
## Round duration in mins
@export var game_time: float = 2.5
## Immunity time (player doesn't gain points)
@export var immunity_time: float = 4.5

@export var player_scene: PackedScene

## The player that holds the flame
var fire_player: Node3D = null

var fire = null

# Called when the node enters the scene tree for the first time.
func _ready():
	fire = $Fire
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if fire_player == null:
		fire.position = Vector3(0, -100, 0)
	#else:
		#fire.position = fire_player.position + get_node(fire_player.name + "/Player").position + Vector3(0, 1.5, 0)
	pass


# Multiplayer
var peer = ENetMultiplayerPeer.new()

func _on_host_pressed():
	peer.create_server(1027)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$CanvasLayer.hide()

func _on_join_pressed():
	peer.create_client("127.0.0.1", 1027)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()

func add_player(id = 1):
	var test = player_scene.instantiate()
	test.name = str(id)
	call_deferred("add_child", test)

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id):
	get_node(str(id))
