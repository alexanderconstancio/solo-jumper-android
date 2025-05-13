extends Area2D

#signal new_life_gained(is_super_life)

@onready var saver_loader = get_node("/root/Game/BaseFrame/Utilities/SaverLoader")
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var life_id: String = ""
@export var is_super_life: bool = false

func _ready() -> void:
	saver_loader.connect("lives_collected", Callable(self, "_on_collected_lives_loaded"))

#func _on_body_entered(body: Node2D) -> void:
	#if body.is_in_group("Player"):
		#if body.playerLives < 5:
			#saver_loader.collected_lives.append(life_id)
			#saver_loader.save_game()
			#new_life_gained.emit(is_super_life)
			#hide()
			#collision_shape_2d.call_deferred("set", "disabled", true)
			
func _on_collected_lives_loaded(lives_array):
	if lives_array.has(life_id):
		print("lives loaded: ", lives_array)
		hide()
		collision_shape_2d.call_deferred("set", "disabled", true)
		
func reset():
	print("resetting life: ", life_id)
	show()
	collision_shape_2d.call_deferred("set", "disabled", false)

func get_life_id():
	return life_id
