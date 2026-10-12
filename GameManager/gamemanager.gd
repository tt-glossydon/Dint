extends Node

const STEAM_APP_ID = 480

func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx( STEAM_APP_ID, true )
	print("Did Steam initialize?: %s " % initialize_response)
	
	if initialize_response['status'] > Steam.STEAM_API_INIT_RESULT_OK:
		print("Failed to initialize Steam, shutting down: %s" % initialize_response)
		# get_tree().quit()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_steam()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
