extends CanvasLayer
class_name GameManager

signal score_changed(new_score : int)
signal game_over(final_score : int)

var score : int = 0 

func _set_score(v:int) -> void:
	score = v
	emit_signal("score_changed", score)

func add_score(amount:int) -> void:
	if amount <= 0:
		return
	_set_score(score + amount)

func trigger_game_over() -> void:
	emit_signal("game_over", score)
