extends Node3D

var lobby_id: int = -1
var peer := SteamMultiplayerPeer.new()

func _unhandled_input(event:InputEvent):
	# Toggles the fullscreen
	if event.is_action_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

## Networked level changing
@rpc("authority", "call_local", "reliable")
func change_level(path: String) -> void:
	get_tree().change_scene_to_file(path)
	while get_tree().current_scene == null or get_tree().current_scene.scene_file_path != path:
		await get_tree().process_frame
	spawn_players()

## Finds and returns a spawn location in the group "spawns"
func find_spawn_pos() -> Vector3:
	for spawn in get_tree().get_nodes_in_group("spawns"):
		if !spawn.used:
			spawn.used = true
			return spawn.position
	
	
	return Vector3(0, 0, 0)

## Networked spawning in all players with networked player ids
@rpc("authority", "call_local", "reliable")
func spawn_players():
	var p_ids = [multiplayer.get_unique_id()]
	p_ids.append_array(multiplayer.get_peers())
	p_ids.sort()
	var player_scene = preload("res://CharacterController/dint_body_3d.tscn")

	for id in p_ids:
		var player = player_scene.instantiate()
		player.name = str(id)
		player.position = find_spawn_pos()
		player.set_multiplayer_authority(id)
		add_child(player)
		
