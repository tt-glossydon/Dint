@icon("res://Procedural/room_res_small_icon.png")
extends Resource
class_name BaseRoom
## The base class from which procedural rooms are built from.[br]


## The shape of the room.
enum RoomShape {
	CLOSET,		##	One entrance/exit.
	HALL,		##	Two entrances/exits, straightaway.
	HALLBEND,	##	Two entrances/exits, bend.
	JUNCT3,		##	Three entrances/exits, T-shape.
	JUNCT4,		##	Four entrances/exits, cross-shape.
}

## A file path which will point to a scene file.
@export_file_path("*.tscn", "*.scn") var room_file

## The shape of the room.
@export var room_shape : RoomShape
