class_name Station
extends Area2D

signal station_clicked(station_id: int)
@onready var count_label := $CountLabel
@export var station_id: int = -1 
@export var cell_pos: Vector2i
@export var capacity: int = 4    # max passengers
@export var spawn_interval: float = 1   # seconds between spawn attempts
@export var spawn_chance: float = 0.15    # chance per interval

var waiting_passengers: int = 0

var _spawn_timer: Timer
var _overload_timer: Timer

func _ready() -> void:
	randomize()
	# Create (or you can do this in the editor)
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	add_child(_spawn_timer)
	_spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	_spawn_timer.start()
	
	_load_overload()

func _load_overload():
	_overload_timer = Timer.new()
	_overload_timer.wait_time = 3.0
	add_child(_overload_timer)
	_overload_timer.connect("timeout", Callable(self, "_on_overload_timeout"))

func setup(id: int, cell: Vector2i, pos: Vector2, parent: Node) -> void:
	station_id = id
	cell_pos    = cell
	position    = pos
	connect("station_clicked", Callable(parent, "_on_station_clicked"))

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("station_clicked", station_id)
		
func take_passengers(count: int):
	var boarded = min(count, waiting_passengers)
	waiting_passengers -= boarded
	count_label.text = str(waiting_passengers)
	_check_overload()
	return boarded

func set_connected(value: bool) -> void:
	var spr: CanvasItem = get_child(0)
	if value:
		spr.modulate = Color(0,1,0)
	else:
		spr.modulate = Color(1,0,0)

func _on_spawn_timer_timeout() -> void:
	if randf() < spawn_chance:
		waiting_passengers += 1
		count_label.text = str(waiting_passengers)
	_check_overload()

func _check_overload() -> void:
	var overloaded := waiting_passengers > capacity
	count_label.modulate = Color(1,0,0) if overloaded else Color(1,1,1)
	if overloaded and _overload_timer.is_stopped():
		_overload_timer.start()
	elif not overloaded:
		_overload_timer.stop()

func _on_overload_timeout():
	emit_signal("overload_lost")
	get_tree().change_scene_to_file("res://scenes/Gameover.tscn")
