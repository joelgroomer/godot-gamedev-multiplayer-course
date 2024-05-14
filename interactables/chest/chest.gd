extends Node2D

@export var chest_locked: Sprite2D
@export var chest_unlocked: Sprite2D
@export var is_locked = true

func _on_interactable_interacted():
	if is_locked:
		is_locked = false
		set_chest_properties()

func set_chest_properties():
	chest_locked.visible = is_locked
	chest_unlocked.visible = !is_locked

func _on_chest_synchronizer_delta_synchronized():
	set_chest_properties()
