extends Node2D
@onready var LinesContainer: Node2D = $LinesContainer
@onready var Map: TileMapLayer = $TileMapLayer
@onready var StationsContainer: Node2D = $StationsContainer
@onready var GameOverScreen: CanvasLayer = $Gameover

var Station = preload("res://scenes/Station.tscn")
var graph = {}
var stations: Array[Station] = []
var pending_station: int = -1
var occupied_cells := {} # grid_pos -> station_id
var passengerTimer: Timer = Timer.new()
var station_timer: Timer = Timer.new()


func _ready() -> void:
	_generate_initial_stations()
	
	station_timer.wait_time = 5
	station_timer.one_shot = false
	add_child(station_timer)
	station_timer.connect("timeout", Callable(self, "_on_station_timer_timeout"))
	station_timer.start()
	
func _generate_initial_stations():
	generate_stations(2)

func _on_station_timer_timeout():
	generate_stations(1)

func generate_stations(n: int):
	var free_cells: Array[Vector2i] = Map.generate_station_cells(n)
	if free_cells.is_empty():
		GameManager.trigger_game_won()
		return
	for i in range(n):
		var st : Station = Map.place_station_at(free_cells[i], Station)
		if st == null:            
			continue
		stations.append(st)
