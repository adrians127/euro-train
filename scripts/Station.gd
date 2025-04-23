class_name Station
extends Area2D
signal station_clicked(station_id: int)
@export var station_id: int = -1
@export var capacity: int = 10  # maks. pasażerów
var waiting_passengers: Array[int] = []

func _ready():
	print(station_id)

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Station clicked")
		emit_signal("station_clicked", station_id)
