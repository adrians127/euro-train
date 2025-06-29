extends TileMapLayer

const BACKGROUND_TILE_ID := 5
const RAIL_TILE_ID := 1
const STATION_TILE_ID := 2

@onready var TrainsContainer: Node = $TrainsContainer
@export var grid_size_x = 26
@export var grid_size_y = 16
var TrainScene = preload("res://scenes/Train.tscn")
var cells: Dictionary[Vector2i, Dictionary] = {}
var astar = AStarGrid2D.new()
var stations : Array[Station] = []
var station_graph : Dictionary 

@export var score: int = 0

var tracks = 20
@export var trains_available = 3
@export var track_interval_seconds : float = 10.0   # how often to give tracks
@export var tracks_per_drop        : int   = 5      # how many to give each time
@export var train_drop_interval_seconds: float = 20.0
@export var trains_per_drop : int = 2

@onready var TrackCounterLabel: Label = get_node("../UI/Label")
@onready var TrainCounterLabel: Label = get_node("../UI/Trainlabel")
@onready var ScoreCounterLabel: Label = get_node("../UI/Scorelabel")

signal score_changed(new_score: int)

var track_count: int = 0

func _ready() -> void:
	clear()
	_init_map()
	_update_track_counter()
	_init_astar()
	_start_track_timer()
	_start_train_timer()
	_update_score_counter()
	
	
var _track_timer : Timer 
var _train_timer : Timer
func _start_track_timer():
	_track_timer = Timer.new()
	_track_timer.wait_time = track_interval_seconds
	_track_timer.one_shot  = false
	add_child(_track_timer)
	_track_timer.connect("timeout", Callable(self, "_on_track_timer_timeout"))
	_track_timer.start()

func _start_train_timer() -> void:
	_train_timer = Timer.new()
	_train_timer.wait_time = train_drop_interval_seconds
	_train_timer.one_shot = false
	add_child(_train_timer)
	_train_timer.connect("timeout", Callable(self, "_on_train_timer_timeout"))
	_train_timer.start()
	_update_train_counter()

func _on_train_timer_timeout() -> void:
	trains_available += trains_per_drop
	_update_train_counter()

func _on_track_timer_timeout() -> void:
	tracks += tracks_per_drop
	_update_track_counter()

func _init_map() -> void:
	set_rendering_quadrant_size(24)
	for x in grid_size_x:
		for y in grid_size_y:
			var cell = Vector2i(x, y)
			cells[cell] = {"type": "background"}
			set_cell(cell, -1, Vector2i(0,0), 0)

func _init_astar() -> void:
	astar.region = Rect2i(0, 0, grid_size_x, grid_size_y)
	astar.cell_size = Vector2i(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for x in range(grid_size_x):
		for y in range(grid_size_y):
			astar.set_point_solid(Vector2i(x,y), true)
			
func _input(event: InputEvent):
	if event is InputEventMouseButton \
	and event.is_pressed() \
	and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_rail_at(local_to_map(get_global_mouse_position()))
			
func get_free_cells() -> Array[Vector2i]:
	var free: Array[Vector2i] = []
	for key in cells.keys():
		if cells[key].type == "background":
			free.append(key)
	return free

func toggle_rail_at(cell: Vector2i) -> void:
	if not cells.has(cell) or cells[cell]["type"] == "station":
		return                         # nothing to do / don’t touch stations

	match cells[cell]["type"]:
		"background":
			_add_rail(cell)
		"rail":
			_remove_rail(cell)

func _add_rail(cell: Vector2i) -> void:
	if (tracks == 0):
		return;
	elif (tracks < 0):
		print("Shouldn t tracks be below 0")
	tracks -= 1
	set_cell(cell, RAIL_TILE_ID, Vector2i.ZERO, 0)
	cells[cell]["type"] = "rail"
	astar.set_point_solid(cell, false)
	_update_track_counter()
	_update_connections()


func _remove_rail(cell: Vector2i) -> void:
	# Either erase the tile completely…
	#   erase_cell(cell)         # Godot 4 convenience
	# …or draw a background tile again:
	tracks += 1
	set_cell(cell, -1, Vector2i.ZERO, 0)

	cells[cell]["type"] = "background"
	astar.set_point_solid(cell, true)
	_update_track_counter()
	_update_connections()

func _update_track_counter() -> void:
	TrackCounterLabel.text = "Tracks: %d" % tracks
	
func _update_train_counter() -> void:
	TrainCounterLabel.text = "Trains: %d " % trains_available

func place_station_at(cell: Vector2i, station_scene: PackedScene):
	if not cells.has(cell) or cells[cell].type == "station":
		return null
	
	cells[cell].type = "station"
	set_cell(cell, STATION_TILE_ID, Vector2i(0,0), 0)
	astar.set_point_solid(cell, false)
	var st : Station = station_scene.instantiate()
	st.setup(stations.size(), cell, map_to_local(cell), self)
	add_child(st)
	stations.append(st)
	_update_connections()

func _update_connections() -> void:
	if stations.is_empty():
		return
	station_graph = {}
	for st in stations:
		station_graph[st.station_id] = []
	for i in range(stations.size()):
		for j in range(i + 1, stations.size()):
			var sA : Station = stations[i]
			var sB : Station = stations[j]

			var path : Array = astar.get_point_path(sA.cell_pos, sB.cell_pos)
			if path.size() == 0:
				continue

			station_graph[sA.station_id].append(sB.station_id)
			station_graph[sB.station_id].append(sA.station_id)

			sA.set_connected(true)
			sB.set_connected(true)

	for st in stations:
		if station_graph[st.station_id].is_empty():
			st.set_connected(false)

	print('---   STATION GRAPH   ---')
	for id in station_graph.keys():
		print('Station %d → %s' % [id, station_graph[id]])

func get_connected_stations(station_id: int) -> Array:
	return station_graph.get(station_id, [])

func generate_station_cells(n: int) -> Array[Vector2i]:
	var free = get_free_cells()
	free.shuffle()
	return free.slice(0, n)
	
func _on_station_clicked(station_id: int) -> void:
	if (get_connected_stations(station_id).is_empty()):
		return
	if trains_available <= 0:
		return
	trains_available -= 1
	_update_train_counter()
	spawn_train(station_id)
	
func spawn_train(from_id: int) -> void:
	var st_start : Station = stations[from_id]

	var train = TrainScene.instantiate()
	train.init(self, st_start)          # NEW
	train.position = map_to_local(st_start.cell_pos)
	TrainsContainer.add_child(train)
	
func despawn_train():
	trains_available += 1
	_update_train_counter()
func add_score(points: int) -> void:
	GameManager.add_score(points)
	score += points
	emit_signal("score_changed", score)
	_update_score_counter()
	
func _update_score_counter() -> void:
	ScoreCounterLabel.text = "Score: %d " % score
