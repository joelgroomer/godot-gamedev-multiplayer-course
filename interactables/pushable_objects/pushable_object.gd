extends RigidBody2D
class_name PushableObject

var requested_authority = false

func _ready():
	if !multiplayer.is_server():
		freeze = true

func push(impulse, point):
	if is_multiplayer_authority():
		apply_impulse(impulse, point)
	else:
		if !requested_authority:
			request_authority.rpc_id(get_multiplayer_authority(), multiplayer.get_unique_id())
			requested_authority = true

@rpc("any_peer", "call_remote", "reliable")
func request_authority(id):
	set_pushable_owner.rpc(id)

@rpc("authority", "call_local", "reliable")
func set_pushable_owner(id):
	set_multiplayer_authority(id)
	set_deferred("freeze", multiplayer.get_unique_id() != id)
	requested_authority = false
