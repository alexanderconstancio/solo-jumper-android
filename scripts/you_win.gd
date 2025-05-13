extends CanvasLayer

signal new_game

func _on_new_game_pressed() -> void:
	new_game.emit()
	get_tree().paused = false
	queue_free()
