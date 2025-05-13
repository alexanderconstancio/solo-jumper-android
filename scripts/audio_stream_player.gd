extends AudioStreamPlayer

var current_index = 0
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var bgm_player: AudioStreamPlayer

var scifi_music_files = [
	"res://assets/music/SciFi/ES_Behind the Curtain - Blue Saga.ogg",
	"res://assets/music/SciFi/ES_Between Moments - Amber Glow.ogg",
	"res://assets/music/SciFi/ES_Callisto 8 - Ben Elson.ogg",
	"res://assets/music/SciFi/ES_Helix Nebula - Curved Mirror.ogg",
	"res://assets/music/SciFi/ES_Orbit - Ebb & Flod.ogg",
	"res://assets/music/SciFi/ES_Parallel Events - Curved Mirror.ogg",
	"res://assets/music/SciFi/ES_Particle Emission - Silver Maple.ogg",
	"res://assets/music/SciFi/ES_Some Kind of Shadow - Mochas.ogg",
	"res://assets/music/SciFi/ES_Twostop - By Lotus.ogg",
	"res://assets/music/SciFi/ES_We Are the Visitors - Curved Mirror.ogg",
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bgm_player = self
	# Shuffle the music files array
	shuffle_music()
	# Play the first track
	play_next_song()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not playing:
		play_next_song()

# Shuffle the music files.
func shuffle_music():
	scifi_music_files.shuffle()
	
# Play the next song
func play_next_song():
	if current_index >= scifi_music_files.size():
		current_index = 0 # Restart playlist
	# Load the current audio file
	var audio_stream = load(scifi_music_files[current_index])
	stream = audio_stream
	
	play()
	
	current_index += 1
