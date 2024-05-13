extends Node2D

@export var players_container: Node2D
@export var player_scene: PackedScene
@export var spawn_points: Array[Node2D]

var next_spawn_point_index = 0

func _ready():
	if not multiplayer.is_server():
		return
	
	multiplayer.peer_disconnected.connect(delete_player)
		
	add_player(1)	# host is always 1, and not included in get_peers()
	
	for id in multiplayer.get_peers():
		add_player(id)
		
	
func _exit_tree():
	if multiplayer.multiplayer_peer == null:
		return
	if not multiplayer.is_server():
		return
	
	multiplayer.peer_disconnected.disconnect(delete_player)

func add_player(id):
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id)
	player_instance.position = get_spawn_point()
	players_container.add_child(player_instance)

func delete_player(id):
	if not players_container.has_node(str(id)):
		return
	
	players_container.get_node(str(id)).queue_free()

func get_spawn_point():
	var spawn_point = spawn_points[next_spawn_point_index].position
	next_spawn_point_index += 1
	if next_spawn_point_index >= len(spawn_points):
		next_spawn_point_index = 0
	return spawn_point
