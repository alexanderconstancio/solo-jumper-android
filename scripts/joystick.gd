extends TouchScreenButton

@onready var knob: Sprite2D = $Knob
@onready var max_distance = shape.radius
@onready var joystick: TouchScreenButton = %Joystick

var stick_center: Vector2 = texture_normal.get_size() / 2

func _ready():
	knob.position = stick_center

func _input(event):
	if event is InputEventScreenTouch:
		var touch_position = (event.position - global_position) / scale.x
		if event.pressed and touch_position.distance_to(stick_center) <= max_distance:
		# Activate joystick only if touch is near the center
			var relative_postition = (event.position - global_position) / scale.x
			knob.position = stick_center + (relative_postition - stick_center).limit_length(max_distance)
		else:
			return
	elif event is InputEventScreenDrag:
		var touch_position = (event.position - global_position) / scale.x
		if touch_position.distance_to(stick_center) <= max_distance:
			var relative_postition = (event.position - global_position) / scale.x
			knob.position = stick_center + (relative_postition - stick_center).limit_length(max_distance)
		else:
			return

func get_joystick_dir() -> Vector2:
	var dir = knob.position - stick_center
	return dir.normalized()

	
var new_texture_left = preload("res://assets/sprites/controller button 58.png")
var new_texture_right = preload("res://assets/sprites/controller button 56.png")
var new_texture_idle = preload("res://assets/sprites/controller button 54.png")

func get_horizontal_dir() -> float:
	# Calculate horizontal direction
	var direction = knob.position.x - stick_center.x
	if direction <= -0.001:
		joystick.texture_pressed = new_texture_left
		return -1
	elif direction >= 0.001:
		joystick.texture_pressed = new_texture_right
		return 1
	else:
		return 0
	 
func _on_released() -> void:
	# Reset joystick on touch release
	knob.position = stick_center
