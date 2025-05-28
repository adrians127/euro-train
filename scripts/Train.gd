extends Node2D
class_name Train

@export var speed : float = 100.0
var boarding_rate : int   = 2

var _map_layer    : TileMapLayer
var _path         : Array[Vector2] = []
var _path_index   : int = 0

var _prev_station : Station = null
var _curr_station : Station = null        # where we’re heading / parked

# ------------------------------------------------------------------ #
#  Public entry — call from TileMapLayer.spawn_train()
# ------------------------------------------------------------------ #
func init(map_layer:TileMapLayer, start_station:Station) -> void:
	randomize()
	_map_layer   = map_layer
	_curr_station = start_station
	position      = _map_layer.map_to_local(start_station.cell_pos)
	choose_next_station()          # sets first _path & _prev_station
	set_process(true)

# ------------------------------------------------------------------ #
#  Per-frame movement
# ------------------------------------------------------------------ #
func _process(delta:float) -> void:
	if _path_index >= _path.size():
		arrive()
		return

	var target : Vector2 = _path[_path_index]
	var dir    : Vector2 = (target - position).normalized()
	position  += dir * speed * delta

	if position.distance_to(target) < 4.0:
		_path_index += 1

# ------------------------------------------------------------------ #
#  Actions at station
# ------------------------------------------------------------------ #
func arrive() -> void:
	set_process(false)

	# wait 2 s to simulate boarding
	await get_tree().create_timer(2.0).timeout
	var boarded := _curr_station.take_passengers(boarding_rate)

	choose_next_station()          # pick new destination and restart

# ------------------------------------------------------------------ #
#  Pick next destination and rebuild path
# ------------------------------------------------------------------ #
func choose_next_station() -> void:
	var next_ids :Array = _map_layer.get_connected_stations(_curr_station.station_id)
	# no neighbours at all  →  give up
	if next_ids.is_empty():
		queue_free()
		return

	# try to avoid an immediate U-turn, but only if there are alternatives
	if _prev_station and next_ids.size() > 1:
		next_ids.erase(_prev_station.station_id)

	# after filtering, verify again
	if next_ids.is_empty():
		queue_free()        # or allow a U-turn by removing this line
		return

	# safe: size ≥ 1
	var next_id  : int     = next_ids[randi() % next_ids.size()]
	var next_st  : Station = _map_layer.stations[next_id]

	# build fresh A* path
	var cell_path : Array = _map_layer.astar.get_point_path(_curr_station.cell_pos,
															next_st.cell_pos)
	if cell_path.is_empty():
		queue_free()
		return

	_path.clear()
	for cell in cell_path:
		_path.append(_map_layer.map_to_local(cell))

	_path_index   = 0
	_prev_station = _curr_station
	_curr_station = next_st
	set_process(true)
