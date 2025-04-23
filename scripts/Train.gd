extends Node2D

var path_points: Array[Vector2] = []
@export var speed: float = 100.0
var current_idx: int = 0

func set_path(points: Array[Vector2]):
	path_points = points
	current_idx = 0

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
	# sygnał lub bezpośrednio: obsłuż wysiadanie pasażerów
	queue_free()
