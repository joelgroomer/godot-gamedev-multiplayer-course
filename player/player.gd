extends CharacterBody2D

@export var player_sprite: AnimatedSprite2D
@export var move_speed = 300
@export var gravity = 30
@export var jump_strength = 600

@onready var initial_sprite_scale = player_sprite.scale

func _physics_process(delta):
	var h_input = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left")
	)
	
	velocity.x = h_input * move_speed
	velocity.y += gravity
	
	var is_falling = velocity.y > 0.0 && !is_on_floor()
	var is_jumping = Input.is_action_just_pressed("jump") && is_on_floor()
	var is_jump_cancelled = Input.is_action_just_released("jump") && velocity.y < 0.0
	var is_idle = is_on_floor() && is_zero_approx(velocity.x)
	var is_walking = is_on_floor() && !is_zero_approx(velocity.x)
	
	if is_jumping:
		velocity.y = -jump_strength
		
	move_and_slide()
	
	if is_jumping:
		player_sprite.play("jump_start")
	elif is_walking:
		player_sprite.play("walk")
	elif is_falling:
		player_sprite.play("fall")
	elif is_idle:
		player_sprite.play("idle")
	
	if not is_zero_approx(h_input):
		if h_input < 0:
			player_sprite.scale = Vector2(-initial_sprite_scale.x, initial_sprite_scale.y)
		else:
			player_sprite.scale = initial_sprite_scale
