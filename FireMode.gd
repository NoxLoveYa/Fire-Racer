extends Node3D

## Time before round starts
@export var freeze_delay: float = 10.0
## Round duration in mins
@export var game_duration: float = 1.5
## Immunity time (player doesn't gain points)
@export var immunity_time: float = 4.5
@export var state: String = "freeze"
@export var next_game_time: float = 3.0

@export var player_scene: PackedScene
@export var fire_scene: PackedScene

@export var fire_player_name: String = "None"

@onready var players: Array[Node3D] = []
@onready var timer: Timer = $Timer
## The player that holds the flame
@onready var fire_instance: Node3D = $Fire
@onready var fire_player: CharacterBody3D = null
var started = false
@export var time_left: int = 0

@onready var timer_hud = $Hud/TimerDisplay

@onready var points_cooldown = $PointsCooldown

@export var points: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

@rpc("any_peer", "call_local")
func update_time(state, time_left):
	if state == "freeze":
		timer_hud.text = "[center] Game starting in: " + str(time_left)
	elif state == "imun":
		timer_hud.text = "[center] Starting to count point in: " + str(time_left)
	elif state == "game":
		timer_hud.text = "[center] End of the game in: " + str(time_left)
	elif state == "disp_winner":
		timer_hud.text = "[center] Next game in: " + str(time_left)


func _on_points_cooldown_timeout():
	points[fire_player_name] += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not started or not multiplayer.is_server():
		return
	if (not fire_player):
		fire_player = $"1"
	if (fire_player.name != fire_player_name):
		rpc("_change_fire_player")
	if fire_player:
		fire_instance.position = fire_player.position + Vector3(0, 1, 0)
	if timer_hud.visible:
		time_left = timer.time_left
		rpc("update_time", state, time_left)
	if state == "game" and points_cooldown.is_stopped():
		points_cooldown.start()

func get_random_float(min_val: float, max_val: float):
	return min_val + (max_val - min_val) * randf()

func get_spawn_point():
	return Vector3(get_random_float(-0.5, 12), 0.10, get_random_float(-20, -27))

# Multiplayer
var peer = ENetMultiplayerPeer.new()

func get_max_from_dict(dict: Dictionary):
	var max_val = 0

	for key in dict:
		if dict[key] > max_val:
			max_val = dict[key]
	return max_val

func get_winner():
	var max_val = get_max_from_dict(points)
	for key in points:
		if points[key] == max_val:
			return key

@rpc("any_peer", "call_local")
func _change_fire_player():
	if (has_node(NodePath(fire_player_name))):
		fire_player = get_node(NodePath(fire_player_name))

@rpc("any_peer", "call_local")
func _change_state():
	if state == "freeze":
		if multiplayer.is_server():
			fire_player = players.pick_random()
			fire_player_name = fire_player.name
			timer.wait_time = immunity_time
			timer.start()
		state = "imun"
	elif state == "imun":
		for key in points:
			points[key] = 0
		if multiplayer.is_server():
			timer.wait_time = game_duration * 60
			timer.start()
		state = "game"
	elif state == "game":
		if multiplayer.is_server():
			timer.wait_time = next_game_time
			timer.start()
		$Hud/Winners.text = "[center] Winner is: " + get_winner()
		$Hud/Winners.visible = true
		state = "disp_winner"
	else:
		state = "freeze"
		$Hud/Winners.visible = false		
		if multiplayer.is_server():
			timer.wait_time = freeze_delay
			timer.start()
			for player in players:
				rpc("_set_position", player.name, get_spawn_point())
	
func _on_timer_timeout():
	rpc("_change_state")

func _on_host_pressed():
	peer.create_server(1027)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$CanvasLayer.hide()
	$Hud.show()
	timer.wait_time = freeze_delay
	timer.start()
	started = true

func _on_join_pressed():
	peer.create_client($"CanvasLayer/IpEdit".text, 1027)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()
	$Hud.show()

func add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	players.append(player)
	points[player.name] = 0
	rpc("_set_position", player.name, get_spawn_point())

@rpc("any_peer", "call_local")
func _set_position(player, pos):
	if !has_node(NodePath(player)):
		await get_tree().node_added
	get_node(NodePath(player)).position = pos
	get_node(NodePath(player)).rotation = Vector3(0, 0, 0)

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id):
	get_node(str(id))
