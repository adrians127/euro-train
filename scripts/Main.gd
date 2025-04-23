extends Node2D
@onready var StationsContainer: Node2D = $StationsContainer
@onready var TrainsContainer: Node = $TrainsContainer
@onready var LinesContainer: Node2D = $LinesContainer

var station_scene = preload("res://scenes/Station.tscn")
var stations: Array[Station] = []
var graph = {}
var pending_station: int = -1
var astar = AStar2D.new()
var passengerTimer: Timer = Timer.new()

func _ready() -> void:
	generate_stations(8)
	init_graph()
	setup_astar()
	
func generate_stations(n: int):
	var margin = 50
	var viewport = get_viewport_rect()
	for i in range(n):
		var pos = Vector2(
			randi_range(margin, viewport.size.x - margin),
			randi_range(margin, viewport.size.y - margin)
		)
		var st = station_scene.instantiate()
		st.station_id = i
		st.position = pos
		st.connect("station_clicked", Callable(self, "_on_station_clicked"))
		StationsContainer.add_child(st)
		stations.append(st)

func init_graph():
	for st in stations:
		graph[st.station_id] = []

func _on_station_clicked(st_id: int):
	if pending_station < 0:
		pending_station = st_id
		return
	if st_id != pending_station:
		print("connected")
		add_connection(pending_station, st_id)
		pending_station = -1
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

func setup_astar():
	for st in stations:
		astar.add_point(st.station_id, st.position)
	for a in graph.keys():
		for b in graph[a]:
			if not astar.are_points_connected(a, b):
				astar.connect_points(a, b)

func send_train(from_id: int, to_id: int):
	var raw_path = astar.get_point_path(from_id, to_id)
	if raw_path.size() < 2:
		return
	var train = preload("res://scenes/Train.tscn").instantiate()
	train.position = raw_path[0]
	train.set_path(raw_path)
	TrainsContainer.add_child(train)
	
func _on_PassengerTimer_timeout():
	var a = randi() % stations.size()
	var b = randi() % stations.size()
	if a == b: return
	# dodaj 'pasażera' do stacji a
	stations[a].waiting_passengers.append(b)
	# ewentualnie: emit_signal("passenger_created", a, b)
