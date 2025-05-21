extends Node2D
class_name Train
var path_points: Array[Vector2] = []
var station_nodes:   Array[Station]  = []
@export var speed: float = 100.0
var current_idx: int = 0
var boarding_rate = 2
var active_station = null
func set_path(points: Array[Vector2], stations: Array[Station]):
	path_points = points.duplicate()
	current_idx = 0
	if path_points.size() > 0:
		position = path_points[0]
	set_process(true)
	station_nodes = stations
	active_station = station_nodes[1]

func _process(delta):
	if current_idx < path_points.size():
		var target = path_points[current_idx]
		var dir = (target - position).normalized()
		position += dir * speed * delta
		if position.distance_to(target) < 4:
			current_idx += 1
	else:
		arrive()
		
func arrive():
	set_process(false)
		
	await get_tree().create_timer(2.0).timeout
	active_station.take_passengers(boarding_rate)
	path_points.reverse()
	current_idx = 0
	if path_points.size() > 0:
		position = path_points[0]
	
	if (active_station == station_nodes[0]):
		active_station = station_nodes[1]
	else:
		active_station = station_nodes[0]
	set_process(true)
