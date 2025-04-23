extends Control

# referencja do scene root, by móc dodać LineSegment
@export_node_path(NodePath) var lines_node_path
var lines_node: Node2D

# Stan maszyny: 
enum State { IDLE, DRAWING }
var state: State = State.IDLE

# Wybrana stacja początkowa
var start_station: Station = null

# Linia podglądu rysowana dynamicznie
var preview_line: Line2D = null

func _ready():
	lines_node = get_node(lines_node_path)
	# subskrybuj sygnały ze wszystkich istniejących stacji
	for station in get_tree().get_nodes_in_group("stations"):
		station.connect("station_clicked", self, "_on_station_clicked")

func _on_station_clicked(station: Station) -> void:
	match state:
		State.IDLE:
			# zaczynamy rysowanie
			start_station = station
			_create_preview_line(start_station.position)
			state = State.DRAWING
		State.DRAWING:
			if station != start_station:
				_finalize_connection(start_station, station)
			_clear_preview()
			state = State.IDLE

func _unhandled_input(event: InputEvent) -> void:
	if state == State.DRAWING and event is InputEventMouseMotion:
		# aktualizuj podgląd linii do pozycji kursora
		var global_mouse = get_viewport().get_mouse_position()
		preview_line.set_point_position(1, global_mouse)

func _create_preview_line(from_pos: Vector2) -> void:
	preview_line = Line2D.new()
	preview_line.width = 4
	preview_line.default_color = Color(1,1,1,0.7)
	preview_line.add_point(from_pos)
	preview_line.add_point(from_pos)  # drugi punkt będzie ruszany
	add_child(preview_line)

func _clear_preview() -> void:
	if preview_line:
		preview_line.queue_free()
		preview_line = null
	start_station = null

func _finalize_connection(f: Station, t: Station) -> void:
	# zapobiegamy duplikatom — zakładamy, że graph to słownik w Main.gd
	var main = get_tree().get_root().get_node("Main")
	var graph = main.graph
	if t.station_id in graph[f.station_id]:
		return  # już istnieje
	# dodajemy do grafu
	graph[f.station_id].append(t.station_id)
	graph[t.station_id].append(f.station_id)
	# instancjonujemy gotową scenę odcinka
	var line_seg = preload("res://scenes/LineSegment.tscn").instantiate() as Node2D
	line_seg.from_station = f
	line_seg.to_station = t
	lines_node.add_child(line_seg)
