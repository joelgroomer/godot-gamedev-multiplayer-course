extends CharacterBody2D

@export var player_camera: PackedScene
@export var camera_height = -132
@export var player_sprite: AnimatedSprite2D
@export var player_finder: Node2D
@export var move_speed = 300
@export var gravity = 30
@export var jump_strength = 600
@export var max_jumps = 1
@export var push_force = 10
@export var target_position: Vector2 = Vector2.INF

@onready var initial_sprite_scale = player_sprite.scale

var owner_id = 1
var jump_count = 0
var camera_instance
var state = PlayerState.IDLE
var current_interactable

enum PlayerState {
	IDLE,
	WALKING,
	JUMP_STARTED,
	JUMPING,
	DOUBLE_JUMPING,
	FALLING
}

func _enter_tree():
	owner_id = name.to_int()
	set_multiplayer_authority(owner_id)
	if owner_id != multiplayer.get_unique_id():
		return
		
	set_up_camera()

func _process(delta):
	if multiplayer.multiplayer_peer == null:
		return
	if owner_id != multiplayer.get_unique_id():
		global_position = HelperFunctions.ClientInterpolate(
			global_position,
			target_position,
			delta)
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
	
	if Input.is_action_just_pressed("interact"):
		if current_interactable != null:
			current_interactable.interact.rpc_id(1)
	
	handle_movement_state()
	move_and_slide()
	target_position = global_position
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var pushable = collision.get_collider() as PushableObject
		if pushable == null:
			continue
			
		var point = collision.get_position() - pushable.global_position
		pushable.push(-collision.get_normal() * push_force, point)
	
	face_movement_direction(h_input)


func _on_animated_sprite_2d_animation_finished():
	if state == PlayerState.JUMPING:
		player_sprite.play("jump")

func set_up_camera():
	camera_instance = player_camera.instantiate()
	camera_instance.global_position.y = camera_height
	get_parent().add_child.call_deferred(camera_instance)
	
func update_camera_pos():
	camera_instance.global_position.x = global_position.x

func face_movement_direction(h_input):
	if !is_zero_approx(h_input):
		if h_input < 0:
			player_sprite.scale = Vector2(-initial_sprite_scale.x, initial_sprite_scale.y)
		else:
			player_sprite.scale = initial_sprite_scale

func handle_movement_state():
	# Decide State
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			state = PlayerState.JUMP_STARTED
		else:
			if is_zero_approx(velocity.x):
				state = PlayerState.IDLE
			else:
				state = PlayerState.WALKING
	else:
		if velocity.y > 0.0:
			if Input.is_action_just_pressed("jump"):
				state = PlayerState.DOUBLE_JUMPING
			else:
				state = PlayerState.FALLING
		else:
			state = PlayerState.JUMPING

	# Process State
	match state:
		PlayerState.IDLE:
			player_sprite.play("idle")
			jump_count = 0
		PlayerState.WALKING:
			player_sprite.play("walk")
			jump_count = 0
		PlayerState.JUMP_STARTED:
			player_sprite.play("jump_start")
			jump_count += 1
			velocity.y = -jump_strength
		PlayerState.JUMPING:
			pass	# Handled in _on_animated_sprite_2d_animation_finished
		PlayerState.DOUBLE_JUMPING:
			jump_count += 1
			if jump_count <= max_jumps:
				player_sprite.play("double_jump_start")
				velocity.y = -jump_strength
		PlayerState.FALLING:
			player_sprite.play("fall")
	
	# Jump Cancelling
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y = 0.0


func _on_interaction_handler_area_entered(area):
	current_interactable = area


func _on_interaction_handler_area_exited(area):
	if current_interactable == area:	# in case of multiple interactables, this ensures we don't accidentally remove
		current_interactable = null		# the most recently added one (the current one)


func _on_visible_on_screen_notifier_2d_screen_entered():
	player_finder.visible = false


func _on_visible_on_screen_notifier_2d_screen_exited():
	player_finder.visible = true
