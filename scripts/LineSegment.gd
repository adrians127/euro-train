extends Node2D
class_name LineSegment

@export var from_id:   int
@export var to_id:     int
@export var f_pos:    Vector2
@export var t_pos:    Vector2

func _ready():
	var line = Line2D.new()
	line.width = 6
	line.default_color = Color.WHITE
	line.points = [ f_pos, t_pos ]
	add_child(line)
