extends CharacterBody2D

@export var player_camera: PackedScene
@export var camera_height = -132
@export var player_sprite: AnimatedSprite2D
@export var move_speed = 300
@export var gravity = 30
@export var jump_strength = 600
@export var max_jumps = 1

@onready var initial_sprite_scale = player_sprite.scale

var owner_id = 1
var jump_count = 0
var camera_instance

func _enter_tree():
	owner_id = name.to_int()
	set_multiplayer_authority(owner_id)
	if owner_id != multiplayer.get_unique_id():
		return
		
	set_up_camera()

func _process(_delta):
	if multiplayer.multiplayer_peer == null:
		return
	if owner_id != multiplayer.get_unique_id():
		return
		
	update_camera_pos()

func _physics_process(_delta):
	if owner_id != multiplayer.get_unique_id():
		return
	
	var h_input = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left")
	)
	
	velocity.x = h_input * move_speed
	velocity.y += gravity
	
	handle_movement_state()
	move_and_slide()
	
	face_movement_direction(h_input)


func _on_animated_sprite_2d_animation_finished():
	player_sprite.play("jump")

func set_up_camera():
	camera_instance = player_camera.instantiate()
	camera_instance.global_position.y = camera_height
	get_tree().current_scene.add_child.call_deferred(camera_instance)
	
func update_camera_pos():
	camera_instance.global_position.x = global_position.x

func face_movement_direction(h_input):
	if !is_zero_approx(h_input):
		if h_input < 0:
			player_sprite.scale = Vector2(-initial_sprite_scale.x, initial_sprite_scale.y)
		else:
			player_sprite.scale = initial_sprite_scale

func handle_movement_state():
	var is_falling = velocity.y > 0.0 && !is_on_floor()
	var is_jumping = Input.is_action_just_pressed("jump") && is_on_floor()
	var is_double_jumping = Input.is_action_just_pressed("jump") && is_falling
	var is_jump_cancelled = Input.is_action_just_released("jump") && velocity.y < 0.0
	var is_idle = is_on_floor() && is_zero_approx(velocity.x)
	var is_walking = is_on_floor() && !is_zero_approx(velocity.x)
	
	if is_jumping:
		player_sprite.play("jump_start")
	elif is_double_jumping:
		player_sprite.play("double_jump_start")
	elif is_walking:
		player_sprite.play("walk")
	elif is_falling:
		player_sprite.play("fall")
	elif is_idle:
		player_sprite.play("idle")
	
	if is_jumping:
		jump_count += 1
		velocity.y = -jump_strength
	elif is_double_jumping:
		jump_count += 1
		if jump_count <= max_jumps:
			velocity.y = -jump_strength
	elif is_jump_cancelled:
		velocity.y = 0.0
	elif is_on_floor():
		jump_count = 0
