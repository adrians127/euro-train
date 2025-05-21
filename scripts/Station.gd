class_name Station
extends Area2D

signal station_clicked(station_id: int)
@onready var count_label := $CountLabel
@export var station_id: int = -1 
@export var cell_pos: Vector2i
@export var capacity: int = 10    # max passengers
@export var spawn_interval: float = 1.0   # seconds between spawn attempts
@export var spawn_chance: float = 0.2     # 20% chance per interval

var waiting_passengers: int = 0
var _spawn_timer: Timer

func _ready() -> void:
	# make sure randoms aren't the same each run
	randomize()
	# Create (or you can do this in the editor)
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	add_child(_spawn_timer)
	_spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	_spawn_timer.start()

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

func set_connected(value: bool) -> void:
	var spr: CanvasItem = get_child(0)
	if value:
		spr.modulate = Color(0,1,0)
	else:
		spr.modulate = Color(1,0,0)

func _on_spawn_timer_timeout() -> void:
	# Only spawn if we're under capacity
	if waiting_passengers < capacity:
		# roll a random float in [0,1)
		if randf() < spawn_chance:
			waiting_passengers += 1
			#print(waiting_passengers)
			count_label.text = str(waiting_passengers)
			# optional: update UI, emit signal, etc.
			# e.g. emit_signal("passenger_arrived", station_id, waiting_passengers)
