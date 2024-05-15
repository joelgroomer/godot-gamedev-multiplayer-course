extends Node2D

@export var follow_offset: Vector2
@export var lerp_speed = 0.5

var following_body

func _on_area_2d_body_entered(body):
	following_body = body

func _process(delta):
	if multiplayer.multiplayer_peer == null:
		return
		
	if multiplayer.is_server() && following_body != null:
		global_position = lerp(
			following_body.global_position + follow_offset,
			global_position,
			pow(0.5, delta * lerp_speed)
		)


