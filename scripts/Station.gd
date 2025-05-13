class_name Station
extends Area2D
signal station_clicked(station_id: int)
@export var station_id: int = -1 
@export var cell_pos: Vector2i
@export var capacity: int = 10  # maks. pasażerów
var waiting_passengers: Array[int] = []

func _ready():
	pass

func setup(id: int, cell: Vector2i, pos: Vector2, parent: Node) -> void:
	station_id = id
	cell_pos = cell
	position = pos
	connect("station_clicked", Callable(parent, "_on_station_clicked"))

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Station clicked")
		emit_signal("station_clicked", station_id)
		
func set_connected(value : bool) -> void:
	# assumes the sprite is the first child; adjust as needed
	var spr : CanvasItem = get_child(0)
	if value:
		spr.modulate = Color(0,1,0)
	else:
		spr.modulate = Color(1,0,0)
