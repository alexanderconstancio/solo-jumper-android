extends Node2D

signal restart
signal ad_more_life

var ad_view: AdView
var _interstitial_ad : InterstitialAd
var _full_screen_content_callback : FullScreenContentCallback

var just_resumed = false

@onready var player: CharacterBody2D = %Player
@onready var saver_loader: SaverLoader = %SaverLoader
@onready var map_building_node: Node2D = %MapBuildingNode
@onready var start_press_audio: AudioStreamPlayer = $UISounds/start_press_audio
@onready var button_press_audio: AudioStreamPlayer = $UISounds/button_press_audio
@onready var starting_node: Node2D = %StartingNode

@onready var gold_toilet: Area2D = $Gold_Toilet
@onready var map_root: MapRoot = $BaseFrame/MapRoot

@export
var music_bus = "Music"
@export
var sfx_bus = "SFX"

var music_bus_index: int
var sfx_bus_index: int

var loading_screen_scene = preload("res://scenes/loadingScreen.tscn")
var loading_screen: Node  # store the instance here
var onAppear: bool = false

func _ready() -> void:
	onAppear = true
	loading_screen = loading_screen_scene.instantiate()
	add_child(loading_screen)
	
	var request := ConsentRequestParameters.new()
	# Set tag for underage of consent. false means users are not underage.
	request.tag_for_under_age_of_consent = false
	UserMessagingPlatform.consent_information.update(request, _on_consent_info_updated_success, _on_consent_info_updated_failure)

	MobileAds.initialize()
	
	get_interstitial_ready()
	
	load_ad_banner()
	saver_loader.load_game()
	get_tree().paused = true
	player.connect("game_over", Callable(self, "_on_game_over"))
	player.connect("show_interstitial_ad", Callable(self, "show_interstitial"))
	gold_toilet.connect("you_win", Callable(self, "_on_you_win"))
	map_root.connect("all_scenes_loaded", Callable(self, "finished_loading"))
	MusicManager.play_next_song()
	
	if map_root.isBelowFirstMapChunk:
		finished_loading()

func _on_inapp_review_review_info_generated() -> void:
	print("launching review flow")
	
func finished_loading():
	if onAppear:
		if loading_screen and loading_screen.get_parent():
			loading_screen.queue_free()  # or remove_child(loading_screen)
		loading_screen = null  # optional cleanup

		print("finished loading from game script")
		var start_menu_scene = preload("res://scenes/main_menu.tscn").instantiate()
		add_child(start_menu_scene)
		
		start_menu_scene.connect("start_pressed", Callable(self, "play_start_sound"))
		start_menu_scene.connect("button_pressed", Callable(self, "play_button_sound"))
		onAppear = false

func _on_paused_pressed() -> void:
	var pause_menu = preload("res://scenes/pause_menu.tscn").instantiate()
	play_button_sound()
	pause_menu.connect("closedPause", Callable(self, "_on_unpaused"))
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	#player.global_position = map_building_node.global_position
	get_tree().paused = true
	add_child(pause_menu)

func _on_unpaused():
	play_button_sound()
	saver_loader.save_game()
	
func create_ad_view() -> void:
	var unit_id : String
	if OS.get_name() == "Android":
		unit_id = "ca-app-pub-8068639090866002/3066499079"
	elif OS.get_name() == "iOS":
		unit_id = "ca-app-pub-8068639090866002/3559569070"
		
	ad_view = AdView.new(unit_id, AdSize.BANNER, AdPosition.Values.TOP)

func load_ad_banner():
	if ad_view == null:
		create_ad_view()
	var ad_request = AdRequest.new()
	ad_view.load_ad(ad_request)

func _on_game_over(jump_count, highest_point):
	var high_score = saver_loader.highest_score
	var game_over = preload("res://scenes/game_over.tscn").instantiate()
	game_over.set_game_over_data(jump_count, highest_point, high_score)
	game_over.connect("restart_button", Callable(self, "_reset_game"))
	game_over.connect("more_life", Callable(self, "_add_more_life"))
	game_over.connect("ad_life_pressed", Callable(self, "play_button_sound"))
	add_child(game_over)
	
func _on_you_win():
	print("showing scene winner")
	var win_scene = preload("res://scenes/you_win.tscn").instantiate()
	win_scene.connect("new_game", Callable(self,"_reset_game" ))
	saver_loader.has_won_level_one = true
	add_child(win_scene)

func _reset_game():
	play_button_sound()
	restore_life_pickups()
	saver_loader.collected_lives.clear()
	get_interstitial_ready()
	restart.emit()
	
func restore_life_pickups():
	for life in get_tree().get_nodes_in_group("New_Life"):
		if life.has_method("get_life_id"):
		# Check if the node's id (assumed to be stored in "life_id") is in saver_loader.collected_lives.
			if life.life_id in saver_loader.collected_lives:
				life.reset()
	saver_loader.collected_lives.clear()

func _add_more_life():
	get_interstitial_ready()
	ad_more_life.emit()
	
# Interstitial Ad

func get_interstitial_ready():
	#free memory
	if _interstitial_ad:
		#always call this method on all AdFormats to free memory on Android/iOS
		_interstitial_ad.destroy()
		_interstitial_ad = null

	var unit_id : String
	if OS.get_name() == "Android":
		unit_id = "ca-app-pub-8068639090866002/1360866869"
	elif OS.get_name() == "iOS":
		unit_id = "ca-app-pub-8068639090866002/3471939168"

	var interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
	interstitial_ad_load_callback.on_ad_failed_to_load = func(adError : LoadAdError) -> void:
		print(adError.message)

	interstitial_ad_load_callback.on_ad_loaded = func(interstitial_ad : InterstitialAd) -> void:
		print("interstitial ad loaded" + str(interstitial_ad._uid))
		_interstitial_ad = interstitial_ad
		
		# Setup dismissal callback right after loading
		var full_screen_callback := FullScreenContentCallback.new()
		full_screen_callback.on_ad_dismissed_full_screen_content = func() -> void:
			MusicManager.player.stream_paused = false
			get_interstitial_ready()  # preload next ad
		_interstitial_ad.full_screen_content_callback = full_screen_callback
		
	InterstitialAdLoader.new().load(unit_id, AdRequest.new(), interstitial_ad_load_callback)
	
func show_interstitial():
	if _interstitial_ad:
		MusicManager.player.stream_paused = true
		_interstitial_ad.show()

func play_start_sound():
	var sound = load("res://assets/sounds/button_press.wav")
	start_press_audio.stream = sound
	start_press_audio.play()
	
func play_button_sound():
	var sound = load("res://assets/sounds/menu_button.mp3")
	button_press_audio.stream = sound
	button_press_audio.play()

func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		# Stop audio players safely
		if MusicManager and MusicManager.player:
			MusicManager.player.stop()

		if start_press_audio and start_press_audio.playing:
			start_press_audio.stop()
		
		if button_press_audio and button_press_audio.playing:
			button_press_audio.stop()

		# Destroy interstitial ad (again, just in case)
		if _interstitial_ad:
			_interstitial_ad.destroy()
			_interstitial_ad = null

		# Disconnect any dynamic signals to prevent dangling references
		# Example:
		if player.is_connected("game_over", Callable(self, "_on_game_over")):
			player.disconnect("game_over", Callable(self, "_on_game_over"))
		
		if player.is_connected("show_interstitial_ad", Callable(self, "show_interstitial")):
			player.disconnect("show_interstitial_ad", Callable(self, "show_interstitial"))

		if gold_toilet.is_connected("you_win", Callable(self, "_on_you_win")):
			gold_toilet.disconnect("you_win", Callable(self, "_on_you_win"))

		queue_free()
		print("Game cleaned up safely before exit.")
	if what == NOTIFICATION_APPLICATION_RESUMED:
		just_resumed = true
		

## Handle ATT Consent

func _on_consent_info_updated_success():
	print("_on_consent_info_updated_success called (Good)")
 # The consent information state was updated.
	# You are now ready to check if a form is available.
	if UserMessagingPlatform.consent_information.get_is_consent_form_available():
		load_form()

func _on_consent_info_updated_failure(form_error : FormError):
	# Handle the error.
	pass
	
var _consent_form : ConsentForm

func load_form():
	UserMessagingPlatform.load_consent_form(_on_consent_form_load_success, _on_consent_form_load_failure)

func _on_consent_form_load_success(consent_form : ConsentForm):
	print("_on_consent_form_load_success called (Good)")
	_consent_form = consent_form
	if UserMessagingPlatform.consent_information.get_consent_status() == UserMessagingPlatform.consent_information.ConsentStatus.REQUIRED:
		consent_form.show(_on_consent_form_dismissed)

func _on_consent_form_dismissed(form_error : FormError):
	if UserMessagingPlatform.consent_information.get_consent_status() == UserMessagingPlatform.consent_information.ConsentStatus.OBTAINED:
		# App can start requesting ads.
		pass
	# Handle dismissal by reloading form
	load_form()
	
func _on_consent_form_load_failure(form_error : FormError):
	# Handle the error.
	pass
		
