extends TileMapLayer
const MIN_STATION_DISTANCE := 2

const BACKGROUND_TILE_ID := -1
const BACKGROUND_UNUSABLE_ID := -1
const RAIL_TILE_ID := 9
const STATION_TILE_ID := 0

const WATER_CELLS : Array[Vector2i] = [
	Vector2i(0,0), Vector2i( 8,0), Vector2i( 9,0), Vector2i(10,0), Vector2i(11,0),
	Vector2i(12,0), Vector2i(13,0), Vector2i(14,0), Vector2i(15,0), Vector2i(16, 0),

	Vector2i(0,1),Vector2i(10,1), Vector2i(11,1), Vector2i(12,1), Vector2i(13,1),  # powtórzenia zachowane
	Vector2i(10,2), Vector2i(11,2), Vector2i(12,2), Vector2i(13,2),

	Vector2i(0,3),Vector2i( 9,3), Vector2i(10,3), Vector2i(11,3), Vector2i(12,3),
	Vector2i(0,4),Vector2i(1,4),Vector2i( 8,4), Vector2i( 9,4), Vector2i(10,4), Vector2i(11,4),
	Vector2i( 9,5), Vector2i(10,5),
	Vector2i(1,6),Vector2i( 3,6),Vector2i( 4,6),Vector2i( 5,6),Vector2i( 6,6),Vector2i( 7,6),Vector2i( 8,6),Vector2i( 9,6),
	Vector2i(0,7), Vector2i(1,7),Vector2i(2,7),Vector2i( 3,7),Vector2i( 4,7),Vector2i( 5,7),Vector2i( 6,7),Vector2i( 7,7),Vector2i( 8,7),Vector2i( 9,7),
	Vector2i(0,8), Vector2i(1,8),Vector2i(2,8),Vector2i( 3,8),Vector2i( 4,8),Vector2i( 5,8),Vector2i( 6,8),Vector2i( 7,8),
	Vector2i(0,9), Vector2i(1,9),Vector2i(2,9),Vector2i( 4,9),Vector2i(5, 9),
	Vector2i(2,10),
	Vector2i(0,11),
	Vector2i(0,12),Vector2i(1,12),
	Vector2i(0,13),Vector2i(1,13),Vector2i(2, 13),
	Vector2i(0,14),Vector2i(1,14),Vector2i(2, 14),Vector2i(3, 14),
	Vector2i(0,15),Vector2i(1,15),Vector2i(2, 15),Vector2i(3, 15),
]

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

@onready var TrackCounterLabel: Label = get_node("../UI/VBoxContainer/HBoxContainer/TracksLabel")
@onready var TrainCounterLabel: Label = get_node("../UI/VBoxContainer/HBoxContainer2/Trainlabel")
@onready var ScoreCounterLabel: Label = get_node("../UI/VBoxContainer2/HBoxContainer3/Scorelabel")
@onready var StationCounterLabel: Label = get_node("../UI/VBoxContainer2/HBoxContainer/StationsLabel")

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
	for x in grid_size_x:
		for y in grid_size_y:
			var cell = Vector2i(x, y)
			if WATER_CELLS.has(cell):
				print("SRAKA")
				cells[cell] = {"type": "background_unusable"}
				set_cell(cell, BACKGROUND_UNUSABLE_ID, Vector2i.ZERO, 0)
				continue
			cells[cell] = {"type": "background"}
			set_cell(cell, BACKGROUND_TILE_ID, Vector2i(0,0), 0)

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
		"background_unusable":
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
	set_cell(cell, BACKGROUND_TILE_ID, Vector2i.ZERO, 0)

	cells[cell]["type"] = "background"
	astar.set_point_solid(cell, true)
	_update_track_counter()
	_update_connections()

func _update_track_counter() -> void:
	TrackCounterLabel.text = "Tracks: %d" % tracks
	
func _update_train_counter() -> void:
	TrainCounterLabel.text = "Trains: %d " % trains_available

func _update_score_counter() -> void:
	ScoreCounterLabel.text = "Score: %d " % score

func _update_stations_counter() -> void:
	StationCounterLabel.text = "Stations: %d " % len(stations)
	
func _is_far_enough_from_other_stations(cell: Vector2i) -> bool:
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:        
				continue
			var neighbour := cell + Vector2i(dx, dy)
			if cells.has(neighbour) and cells[neighbour]["type"] == "station":
				return false
	return true
	
func _is_station_allowed(cell: Vector2i) -> bool:
	return cells.has(cell) \
		and cells[cell]["type"] != "station" \
		and cells[cell]["type"] != "background_unusable" \
		and _is_far_enough_from_other_stations(cell)

func place_station_at(cell: Vector2i, station_scene: PackedScene):
	if not _is_station_allowed(cell):
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
	print(free)
	free = free.filter(func(pos): return _is_far_enough_from_other_stations(pos))
	print(free)
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
	
