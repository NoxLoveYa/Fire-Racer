extends CharacterBody3D

@export var gravity = -20.0
@export var engine_power = 10.0
@export var braking = -1.5
@export var friction = -10.0
@export var drag = -20.0
@export var steering_limit = 2.0
@export var max_speed_reverse = 7.0

# Car state properties
var acceleration = Vector3.ZERO  # current acceleration
var steer_angle = 0.0  # current wheel angle
var steer_axis = Vector3(0, 1, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func apply_friction(delta):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force

func get_input():
	var turn = Input.get_action_strength("Turn Left")
	turn -= Input.get_action_strength("Turn Right")
	steer_angle = turn * deg_to_rad(steering_limit)
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("Accelerate"):
		acceleration += transform.basis.z * engine_power
	if Input.is_action_pressed("Brake"):
		acceleration += transform.basis.z * braking

func steer_car():
	transform.basis = transform.basis.rotated(steer_axis, steer_angle)

func _physics_process(delta):
	if is_on_floor():
		get_input()
		steer_car()
		apply_friction(delta)
	velocity.y += gravity * delta
	velocity += acceleration * delta
	move_and_slide()
