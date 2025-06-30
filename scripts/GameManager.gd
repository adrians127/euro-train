# res://scripts/gamemanager.gd
extends Node

signal score_changed(new_score : int)
signal game_over(final_score : int)
signal game_won(final_score : int)

var score : int = 0

func add_score(amount:int) -> void:
	if amount <= 0: return
	score += amount
	emit_signal("score_changed", score)

func trigger_game_over() -> void:
	emit_signal("game_over", score)
	get_tree().change_scene_to_file("res://scenes/Gameover.tscn")
	
func trigger_game_won() -> void:
	emit_signal("game_won", score)
	get_tree().change_scene_to_file("res://scenes/Win.tscn")
