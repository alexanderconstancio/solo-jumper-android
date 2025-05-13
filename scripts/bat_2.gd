extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $bat_2_animation

func _ready() -> void:
	animated_sprite.play("idle")
