extends CanvasLayer

signal closedPause

@onready var music_master_slider: HSlider = $PauseMenu/Panel/VBoxContainer/VBoxContainer/SliderContainer/MusicMasterSlider
#@onready var sfx_sound_slider: HSlider = $PauseMenu/Panel/VBoxContainer/VBoxContainer2/PlayerSoundContainer/SFXSoundSlider
@onready var mute_player_sound: Button = $PauseMenu/Panel/VBoxContainer/VBoxContainer2/PlayerSoundContainer/MutePlayerSound
@onready var mute_music_button: Button = $PauseMenu/Panel/VBoxContainer/VBoxContainer/SliderContainer/MuteMusicButton

var music_icon = preload("res://assets/sprites/music.png")
var muted_icon = preload("res://assets/sprites/music_muted.png")
var sound_icon = preload("res://assets/sprites/unmute.png")

@export
var music_bus = "Music"
@export
var sfx_bus = "SFX"

var music_bus_index: int
var sfx_bus_index: int

var sfx_volume_linear: float

var music_volume_linear: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_bus_index = AudioServer.get_bus_index(music_bus)
	sfx_bus_index = AudioServer.get_bus_index(sfx_bus)
	
	var music_volume = AudioServer.get_bus_volume_db(music_bus_index)
	var sfx_volume = AudioServer.get_bus_volume_db(sfx_bus_index)
	
	music_volume_linear = db_to_linear(music_volume)
	sfx_volume_linear = db_to_linear(sfx_volume)
	
	music_master_slider.value = db_to_linear(music_volume)
	
	update_sfx_ui()
	update_music_ui()

func _on_resume_pressed() -> void:
	closedPause.emit()
	queue_free()
	get_tree().paused = false

func _on_mute_music_button_pressed() -> void:
	if music_volume_linear == 0:
		music_volume_linear = 1
		music_master_slider.value = 1
	else:
		music_volume_linear = 0
		music_master_slider.value = 0
		
	update_music_ui()
		
	AudioServer.set_bus_volume_db(
		music_bus_index,
		linear_to_db(music_volume_linear)
	)
	

func _on_mute_player_sound_pressed() -> void:
	if sfx_volume_linear == 0:
		sfx_volume_linear = 1
	else:
		sfx_volume_linear = 0
	
	update_sfx_ui()
	
	AudioServer.set_bus_volume_db(
		sfx_bus_index,
		linear_to_db(sfx_volume_linear)
	)

func _on_music_master_slider_value_changed(value: float) -> void:
	music_volume_linear = value
	update_music_ui()
	AudioServer.set_bus_volume_db(
		music_bus_index,
		linear_to_db(value)
	)

func update_sfx_ui():
	if sfx_volume_linear == 0:
		mute_player_sound.icon = muted_icon
	else:
		mute_player_sound.icon = sound_icon
		

func update_music_ui():
	if music_volume_linear == 0:
		mute_music_button.icon = muted_icon
	else:
		mute_music_button.icon = music_icon
		
