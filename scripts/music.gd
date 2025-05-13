extends Node2D

var player: AudioStreamPlayer

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

var current_song_index = 0  # Track which song is playing

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = "Music"
	player.volume_db = -30.0
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	
	player.finished.connect(Callable(self, "play_next_song"))
	
	# Shuffle the music files array
	shuffle_music()

# Shuffle the music files.
func shuffle_music():
	scifi_music_files.shuffle()
	
# Play the next song
func play_next_song():
	if current_song_index >= scifi_music_files.size():
		current_song_index = 0 # Restart playlist
	# Load the current audio file
	var audio_stream = load(scifi_music_files[current_song_index])
	player.stream = audio_stream
	
	player.play()
	
	current_song_index = (current_song_index + 1) % scifi_music_files.size()
	
func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		if player:
			if player.playing:
				player.stop()

			if player.finished.is_connected(Callable(self, "play_next_song")):
				player.finished.disconnect(Callable(self, "play_next_song"))
		queue_free()
		print("MusicManager cleaned up before exit.")
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		# App moved to background
		if player and player.playing:
			player.stream_paused = true
			print("MusicManager paused.")
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		# App came back to foreground
		if player and player.stream_paused:
			player.stream_paused = false
			print("MusicManager resumed.")
