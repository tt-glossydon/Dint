extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)

func _on_create_server_pressed() -> void:
	if Gamemanager.lobby_id != -1:
		if multiplayer.is_server():
			Gamemanager.change_level.rpc("res://dtest.tscn")
	else:
		var lobby_type: Steam.LobbyType = Steam.LobbyType.LOBBY_TYPE_PUBLIC
		Steam.createLobby(lobby_type, 3)


func _on_join_server_pressed() -> void:
	Steam.addRequestLobbyListStringFilter("is_dint", "you know it", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _on_lobby_created(connect_status: Steam.Result, lobby_id: int) -> void:
	if connect_status == Steam.Result.RESULT_OK:
		# Set the lobby ID in our global script (if using one)
		print("Successfully created lobby %s" % lobby_id)
		Gamemanager.lobby_id = lobby_id

		# Set the lobby name for displaying in searches, the lobby scene, etc.
		if not Steam.setLobbyData(Gamemanager.lobby_id, "lobby_name", "My Cool Lobby"):
			printerr("Failed to set lobby name")
			
		Steam.setLobbyData(Gamemanager.lobby_id, "is_dint", "you know it")
		
		Gamemanager.peer.host_with_lobby(Gamemanager.lobby_id)
		multiplayer.multiplayer_peer = Gamemanager.peer

	# Our lobby creation failed
	else:
		printerr("Failed to create a lobby: %s" % connect_status)

func _on_lobby_match_list(these_lobbies: Array) -> void:
	if these_lobbies.size() == 0:
		print("No lobbies were found")
		return

	Steam.joinLobby(these_lobbies[0])

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if Steam.getLobbyOwner(lobby_id) == Steam.getSteamID():
		return

	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		printerr("Failed to join lobby: %s" % response)
		return

	Gamemanager.lobby_id = lobby_id
	Gamemanager.peer.connect_to_lobby(lobby_id)
	multiplayer.multiplayer_peer = Gamemanager.peer
