extends CanvasLayer

signal start_pressed
signal button_pressed
@onready var start: Button = $MainMenu/Start/Start

const start_y_position = 694.0

func _ready() -> void:
	_set_start_button_state()
	
func _set_start_button_state():
	var player = get_node("/root/Game/BaseFrame/Player")
	var player_y = round(player.global_position.y)
	if player_y == start_y_position:
		start.text = "Begin Level 1"
	else:
		start.text = "Continue Level 1"

func _on_start_pressed() -> void:
	start_pressed.emit()
	get_tree().paused = false
	queue_free()

func _on_credits_pressed() -> void:
	button_pressed.emit()
	var credits_scene = preload("res://scenes/credits.tscn").instantiate()
	credits_scene.connect("closed", Callable(self, "_on_credits_closed"))
	self.visible = false
	add_child(credits_scene)

func _on_credits_closed():
	button_pressed.emit()
	self.visible = true


func _on_privacy_pressed() -> void:
	button_pressed.emit()
	var scene = preload("res://scenes/privacy.tscn").instantiate()
	scene.connect("closed", Callable(self, "_on_credits_closed"))
	self.visible = false
	add_child(scene)
	

func _on_eula_pressed() -> void:
	button_pressed.emit()
	var scene = preload("res://scenes/EULA.tscn").instantiate()
	scene.connect("closed", Callable(self, "_on_credits_closed"))
	self.visible = false
	add_child(scene)
