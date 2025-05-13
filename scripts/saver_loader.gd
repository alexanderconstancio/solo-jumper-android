class_name SaverLoader
extends Node

signal data_loaded(lives, jumps)

signal lives_collected(collected)

@onready var player: CharacterBody2D = %Player

@export
var music_bus = "Music"
@export
var sfx_bus = "SFX"

var music_bus_index: int
var sfx_bus_index: int

var player_lives = 0
var highest_score = 0
var jumps_made = 0

var new_life_id = ""

var collected_lives: Array = []

var has_won_level_one: bool = false

func save_game():
	print("saving game")
	var saved_game: SavedGame = SavedGame.new()
	saved_game.player_position = player.global_position
	
	music_bus_index = AudioServer.get_bus_index(music_bus)
	sfx_bus_index = AudioServer.get_bus_index(sfx_bus)
	
	var music_vol = AudioServer.get_bus_volume_db(music_bus_index)
	var sfx_vol = AudioServer.get_bus_volume_db(sfx_bus_index)
	
	saved_game.music_master_volume = db_to_linear(music_vol)
	saved_game.player_sfx_volume = db_to_linear(sfx_vol)
	
	saved_game.player_lives = player_lives
	saved_game.high_score = highest_score
	saved_game.jumps_made = jumps_made
	saved_game.collected_hearts = collected_lives
	saved_game.has_won_level_one = has_won_level_one
	
	ResourceSaver.save(saved_game, "user://savegame.tres")

func load_game():
	var save_path = "user://savegame.tres"
	if FileAccess.file_exists(save_path):
		var saved_game: SavedGame = ResourceLoader.load(save_path) as SavedGame
		if saved_game:
			var player_position = saved_game.player_position
			var music_master_volume = saved_game.music_master_volume
			var player_sfx_volume = saved_game.player_sfx_volume
			
			player_lives = saved_game.player_lives
			highest_score = saved_game.high_score
			jumps_made = saved_game.jumps_made
			collected_lives = saved_game.collected_hearts
			player.global_position = saved_game.player_position
			has_won_level_one = saved_game.has_won_level_one
			
			music_bus_index = AudioServer.get_bus_index(music_bus)
			sfx_bus_index = AudioServer.get_bus_index(sfx_bus)
			
			AudioServer.set_bus_volume_db(
				music_bus_index,
				linear_to_db(music_master_volume)
			)
		
			AudioServer.set_bus_volume_db(
				sfx_bus_index,
				linear_to_db(player_sfx_volume)
			)
			
			emit_signal("data_loaded", player_lives, jumps_made)
			emit_signal("lives_collected", collected_lives)
		# Process the loaded data here
		else:
			print("Failed to load save data")
	else:
		print("Save file does not exist")
		player.playerLives = 3
		save_game()
	# Handle the case where no save file is found
