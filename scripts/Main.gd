extends Node2D
@onready var LinesContainer: Node2D = $LinesContainer
@onready var Map: TileMapLayer = $TileMapLayer
@onready var StationsContainer: Node2D = $StationsContainer

var Station = preload("res://scenes/Station.tscn")
var graph = {}
var stations: Array[Station] = []
var pending_station: int = -1
var passengerTimer: Timer = Timer.new()
var occupied_cells := {} # grid_pos -> station_id


func _ready() -> void:
	generate_stations(3)
	init_graph()

	
func generate_stations(n: int):
	var free_cells: Array[Vector2i] = Map.generate_station_cells(n)
	for i in range(n):
		var cell = free_cells[i]
		print(cell)
		if cell in occupied_cells:
			continue
		occupied_cells[cell] = i
		Map.place_station_at(cell, Station)

func init_graph():
	for st in stations:
		graph[st.station_id] = []

var LineSegment = preload("res://scripts/LineSegment.gd") 
func add_connection(a: int, b: int):
	if b in graph[a]:
		return
	graph[a].append(b)
	graph[b].append(a)
	var a_pos = stations[a].position
	var b_pos = stations[b].position
	var seg = LineSegment.new()
	seg.from_id = a
	seg.to_id = b
	seg.f_pos = a_pos
	seg.t_pos = b_pos
	$LinesContainer.add_child(seg)
