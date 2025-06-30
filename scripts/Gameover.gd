extends CanvasLayer

signal score_changed(new_score : int)
signal game_over(final_score : int)

var score : int = 0 
@onready var ScoreLabel: Label = get_node("VBoxContainer/ScoreLabel")

func _ready() -> void:
	ScoreLabel.text = "Final score: %d" % GameManager.score
	
func _set_score(v:int) -> void:
	score = v
	print(score)
	emit_signal("score_changed", score)

func add_score(amount:int) -> void:
	if amount <= 0:
		return
	_set_score(score + amount)

func trigger_game_over() -> void:
	emit_signal("game_over", score)
	get_tree().change_scene_to_file("res://scenes/Gameover.tscn")

func _on_mainmenu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Mainmenu.tscn")
