extends Area2D

signal you_win

var fade_duration = 2.0
var is_in_toilet_zone = false

var overlap_time = 0.5

@onready var golden_music: AudioStreamPlayer = $GoldenToiletMusic

func _on_ready() -> void:
	var audio_stream = load("res://assets/music/GoldToilet/ES_Ethos - Johannes Bornlof.mp3")
	golden_music.stream = audio_stream
	
	golden_music.bus = "Music"
	golden_music.volume_db = -20.0
	golden_music.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_tree().paused = true
		print("you win from toilet script")
		play_win_sound()
		emit_signal("you_win")
		
func _on_sound_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		is_in_toilet_zone = true
		switch_to_golden_music()
			
func _on_sound_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		is_in_toilet_zone = false
		switch_back_to_background()

func switch_to_golden_music():
	if not golden_music.playing:
		golden_music.play()
	# Let both tracks play for a bit, then stop background
	if MusicManager.player.playing:
		await get_tree().create_timer(overlap_time).timeout
		MusicManager.player.stop()

func switch_back_to_background():
	if not MusicManager.player.playing:
		MusicManager.player.play()
	# Let both tracks play for a bit, then stop golden
	if golden_music.playing:
		await get_tree().create_timer(overlap_time).timeout
		golden_music.stop()
		
		
@onready var winner: AudioStreamPlayer = $winner

func play_win_sound():
	var win_sounds = load("res://assets/sounds/holy_win.mp3")
	winner.stream = win_sounds
	winner.play()
