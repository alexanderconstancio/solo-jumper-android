extends CanvasLayer

signal closed

func _on_close_button_pressed():
	closed.emit()

func _on_back_pressed() -> void:
	closed.emit()
	queue_free()
