extends TileMapLayer

const BACKGROUND_TILE_ID := 0
const RAIL_TILE_ID := 1
const STATION_TILE_ID := 2

#var grid_size_x = 640 / 16
#var grid_size_y = 480 / 16
@export var grid_size_x = 16
@export var grid_size_y = 16
var cells: Dictionary[Vector2i, Dictionary] = {}
var astar = AStarGrid2D.new()
var stations : Array[Station] = []
var station_graph : Dictionary 

func _ready() -> void:
	_init_map()
	_init_astar()

func _init_map() -> void:
	for x in grid_size_x:
		for y in grid_size_y:
			var cell = Vector2i(x, y)
			cells[cell] = {"type": "background"}
			set_cell(cell, 0, Vector2i(0,0), 0)

func _init_astar() -> void:
	astar.region = Rect2i(0, 0, 16, 16)
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
	set_cell(cell, RAIL_TILE_ID, Vector2i.ZERO, 0)
	cells[cell]["type"] = "rail"
	astar.set_point_solid(cell, false)
	_update_connections()

func _remove_rail(cell: Vector2i) -> void:
	# Either erase the tile completely…
	#   erase_cell(cell)         # Godot 4 convenience
	# …or draw a background tile again:
	set_cell(cell, BACKGROUND_TILE_ID, Vector2i.ZERO, 0)

	cells[cell]["type"] = "background"
	astar.set_point_solid(cell, true)
	_update_connections()


func place_station_at(cell: Vector2i, station_scene: PackedScene):
	if not cells.has(cell) or cells[cell].type == "station":
		return
	
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

func generate_station_cells(n: int) -> Array[Vector2i]:
	var free = get_free_cells()
	free.shuffle()
	return free.slice(0, n)
