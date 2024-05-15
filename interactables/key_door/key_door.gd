extends Node2D

@export var is_open = false
@export var door_closed: Sprite2D
@export var door_open: Sprite2D


func _on_area_2d_area_entered(area):
	if not multiplayer.is_server():
		return
	if is_open:
		return
	
	is_open = true
	area.get_parent().queue_free()
	set_key_door_properties()

func _on_key_door_synchronizer_delta_synchronized():
	set_key_door_properties()

func set_key_door_properties():
	door_closed.visible = !is_open
	door_open.visible = is_open


