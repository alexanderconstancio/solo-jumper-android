extends CanvasLayer

var _rewarded_ad : RewardedAd
var on_user_earned_reward_listener := OnUserEarnedRewardListener.new()

signal restart_button
signal more_life
signal ad_life_pressed

@onready var jumps_label: Label = $Control/VBoxContainer/Score/VBoxContainer/jumps
@onready var highest_label: Label = $Control/VBoxContainer/Score/VBoxContainer/highest
@onready var high_score_label: Label = $Control/VBoxContainer/Score/VBoxContainer/high_score

var jumps_made = 0
var highest_point = 0
var highest_gone = 0

func set_game_over_data(jumps, highest, high_score):
	jumps_made = jumps
	highest_point = highest
	highest_gone = high_score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	jumps_label.text = "JUMPS MADE: " + str(jumps_made)
	highest_label.text = "HIGHEST POINT: " + str(highest_point) + " FT"
	high_score_label.text = "HIGH SCORE: " + str(highest_gone) + " FT"
	
	_on_load_pressed()
	
	on_user_earned_reward_listener.on_user_earned_reward = func(_rewarded_item : RewardedItem):
		MusicManager.player.stream_paused = false
		get_tree().paused = false
		queue_free()
		more_life.emit()

func _restart_pressed() -> void:
	restart_button.emit()
	MusicManager.player.stream_paused = false
	get_tree().paused = false
	queue_free()

func _on_more_life_pressed() -> void:
	ad_life_pressed.emit()
	if _rewarded_ad:
		MusicManager.player.stream_paused = true
		_rewarded_ad.show(on_user_earned_reward_listener)
	
func _on_load_pressed():
	#free memory
	if _rewarded_ad:
		#always call this method on all AdFormats to free memory on Android/iOS
		_rewarded_ad.destroy()
		_rewarded_ad = null

	var unit_id : String
	if OS.get_name() == "Android":
		unit_id = "ca-app-pub-8068639090866002/8739448411"
	elif OS.get_name() == "iOS":
		unit_id = "ca-app-pub-8068639090866002/6683296565"

	var rewarded_ad_load_callback := RewardedAdLoadCallback.new()
	rewarded_ad_load_callback.on_ad_failed_to_load = func(adError : LoadAdError) -> void:
		print("rewarded ad failed to load" + adError.message)

	rewarded_ad_load_callback.on_ad_loaded = func(rewarded_ad : RewardedAd) -> void:
		print("rewarded ad loaded" + str(rewarded_ad._uid))
		_rewarded_ad = rewarded_ad
	
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), rewarded_ad_load_callback)
