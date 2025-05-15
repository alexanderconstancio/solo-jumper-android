extends CharacterBody2D

signal game_over(jump_amount, highest_point)
signal show_interstitial_ad

@onready var game: Node2D = $"../.."
@onready var joystick: TouchScreenButton = %Joystick
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_button: TouchScreenButton = %JumpButton
@onready var distance_label: Label = %distance_label
@onready var starting_node: Node2D = $"../Utilities/StartingNode"
@onready var saver_loader: SaverLoader = $"../Utilities/SaverLoader"
@onready var jump_particles: GPUParticles2D = $Jump_particles

@onready var heart_1: AnimatedSprite2D = $"../UI/MarginContainer/Health_bar/heart_1"
@onready var heart_2: AnimatedSprite2D = $"../UI/MarginContainer/Health_bar/heart_2"
@onready var heart_3: AnimatedSprite2D = $"../UI/MarginContainer/Health_bar/heart_3"
@onready var heart_4: AnimatedSprite2D = $"../UI/MarginContainer/Health_bar/heart_4"
@onready var heart_5: AnimatedSprite2D = $"../UI/MarginContainer/Health_bar/heart_5"

@onready var camera_2d: Camera2D = $Camera2D

const SPEED = 75.0
const JUMP_VELOCITY = -500.0

var press_start_time: float = -1.0  # Variable to store the time when button is pressed
var press_duration: float = 0.0  

static var playerLives: int = 0

var jumpBeingPressed: bool = false
var jumpHoldTime: int = 0

var did_fall: bool = false
var did_land: bool = false
var fall_threshold = 1600.0
var jump_move_speed = 300.0
var run_move_speed = 200.0

var run_sound_switch = false
var land_count = 0

var last_stick_direction = 0.0  # Store the last direction
var isFalling = false

# The player becomes stunned when coming into contact with something other than the floor.
var player_stunned = false

# A timer used to control whether or not the jump button should release after
# holding it for a certain amount of time.
var timer = Timer.new()

# Whether or not the timer was called for releaseing the jump button.
var timer_called = false

# The last direction that was inputed before jump began.
var last_direction = 0.0

# The current key direction.
var key_direction = 0.0

# Whether or not the game is over.
var game_is_over = false

# The current height in the current session.
var current_height: int = 0

# The highest point in the current session.
var highest_point: int = 0

# The amount of jumps in the current session.
var jump_counter: int = 0

var land_count_rate_app = 0

var hit_floor_from_fall = false

var fall_count = 0

func increment_lives(is_super_life):
	play_new_life_sound()
	if is_super_life:
		if playerLives == 4:
			heart_5.play("new_life")
			playerLives += 1
		elif playerLives == 3:
			heart_4.play("new_life")
			heart_5.play("new_life")
			playerLives += 2
		elif playerLives == 2:
			heart_3.play("new_life")
			heart_4.play("new_life")
			heart_5.play("new_life")
			playerLives += 3
		elif playerLives == 1:
			heart_2.play("new_life")
			heart_3.play("new_life")
			heart_4.play("new_life")
			heart_5.play("new_life")
			playerLives += 4
	else:
		if playerLives == 4:
			heart_5.play("new_life")
			playerLives += 1
		elif playerLives == 3:
			heart_4.play("new_life")
			playerLives += 1
		elif playerLives == 2:
			heart_3.play("new_life")
			playerLives += 1
		elif playerLives == 1:
			heart_2.play("new_life")
			playerLives += 1

func _ready() -> void:
	print("setting up player: Ready called ------")
	add_child(timer)
	get_tree().connect("node_added", Callable(self, "_on_node_added"))
	timer.wait_time = 1
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "jump_from_timer"))
	game.connect("restart", Callable(self, "_on_restart"))
	game.connect("ad_more_life", Callable(self, "ad_more_life"))
	
	#for life in get_tree().get_nodes_in_group("New_Life"):
		#if life.has_signal("new_life_gained"):
			#life.connect("new_life_gained", Callable(self, "increment_lives"))
	saver_loader.connect("data_loaded", Callable(self, "_on_save_data_loaded"))
	
	play_run_sound()

	
func _on_save_data_loaded(lives, jumps):
	print("printing from saver in player: ", lives)
	playerLives = lives
	jump_counter = jumps
	#if lives == 5:
		#heart_5.play()
		#heart_4.play()
	#elif lives == 4:
		#heart_4.play()
	#elif lives == 3:
		#playerLives = 3
	#elif lives <= 0:
		#_on_restart()
	#elif lives == 2:
		#heart_3.play()
	#elif lives == 1:
		#heart_3.play()
		#heart_2.play()

func _physics_process(delta: float) -> void:
	if game.just_resumed:
		game.just_resumed = false
		print("just now returning, skipping movement once: -- ")
		return
		
	delta = clamp(delta, 0.0, 0.05)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 2.25
		
	# Reset stun if on floor.
	if is_on_floor():
		player_stunned = false
	
	set_distance_label()
	handle_jump_keyboard()
	handle_move_mobile()
	
	_fell_lost_life()

	if velocity.y < fall_threshold and not is_on_floor():
		did_land = true

	handle_wall_collision()
	
	move_and_slide()
	
## MOVEMENT:

# Logic for when the player hits a wall.
func handle_wall_collision():
	# Handle stun when hit wall.
	if is_on_wall_only() or is_on_ceiling():
		if !player_stunned:
			Input.vibrate_handheld(20, 0.7)
			play_stun_sound()
		player_stunned = true
		animated_sprite.play("stun_2")
		run_audio.stop()
		velocity.x = 0
	
	# Handle bounce off the wall.
	if not is_on_floor():
		if velocity.x == 0:
			if last_direction < 0:
				last_direction = 0.8
			elif last_direction > 0:
				last_direction = -0.8
		if player_stunned:
			velocity.x = last_direction * jump_move_speed
		else:
			var keys_direction = Input.get_axis("move_left", "move_right")
			var joy_direction = joystick.get_horizontal_dir()
			var key_direction_new = 0
			
			if joy_direction != 0:
				key_direction_new = joy_direction
			elif keys_direction != 0: 
				key_direction_new = keys_direction
			else:
				key_direction = 0
			velocity.x = key_direction_new * jump_move_speed

func handle_land_show_ad():
	land_count += 1
	land_count_rate_app += 1
	
	if land_count == 20:
		land_count = 0
		show_interstitial_ad.emit()
	
		
func handle_move_mobile():
	var keys_direction = Input.get_axis("move_left", "move_right")
	var joy_direction = joystick.get_horizontal_dir()
	
	if joy_direction != 0:
		key_direction = joy_direction
	elif keys_direction != 0: 
		key_direction = keys_direction
	else:
		key_direction = 0
		
	if not jumpBeingPressed:
		# Flip character
		if key_direction > 0:
			animated_sprite.flip_h = false
		elif key_direction < 0:
			animated_sprite.flip_h = true
		
		if is_on_floor():
			last_direction = key_direction
			if not did_fall and not player_stunned:
				if did_land:
					play_land_sound()
					_handle_save_game()
					handle_land_show_ad()
					did_land = false
					
			if key_direction == 0 and not did_fall and not player_stunned:
				if animated_sprite.animation != "idle":
					animated_sprite.play("idle")
				run_audio.stop()
			elif did_fall and key_direction == 0:
				if animated_sprite.animation != "fall":
					animated_sprite.play("fall")
				run_audio.stop()
			else:
				if did_fall:
					hit_floor_from_fall = false
					did_fall = false
				if animated_sprite.animation != "run":
					animated_sprite.play("run")
				if not run_audio.playing:
					run_audio.play()
					
			velocity.x = key_direction * run_move_speed
		else:
			if not player_stunned:
				if velocity.y < 0:
					if animated_sprite.animation != "jump_up":
						print("jumping up")
						animated_sprite.play("jump_up")
					run_audio.stop()
					jump_particles.emitting = true
				else:
					if animated_sprite.animation != "jump_down":
						animated_sprite.play("jump_down")
					run_audio.stop()
	elif jumpBeingPressed:
		run_audio.stop()
		velocity.x = 0


# Handle fell too far.
func _fell_lost_life():
	# Player fell far.
	if velocity.y > fall_threshold and not is_on_floor():
		play_fall_sound()
		if did_fall == false:
			did_fall = true
			fall_count += 1
			if fall_count == 3:
				fall_count = 0
			#playerLives -= 1
			_handle_life_UI()
			#if playerLives == 1:
				#print("launching app review ios")
	# Player has collided with ground from far fall.
	if did_fall and is_on_floor() and not hit_floor_from_fall:
		Input.vibrate_handheld(500, 1)
		_handle_save_game()
		hit_floor_from_fall = true
	#if did_fall and playerLives <= 0 and game_is_over == false:
		#game_is_over = true
		#_on_game_over()
	
func _handle_life_UI():
	if playerLives == 4:
		heart_5.play("Life_lost")
	elif playerLives == 3:
		heart_4.play("Life_lost")
	elif playerLives == 2:
		heart_3.play("Life_lost")
	elif playerLives == 1:
		heart_2.play("Life_lost")
	elif playerLives == 0:
		heart_1.play("Life_lost")

## Jump Logic:
var is_jumping = false
func _on_jump_button_pressed() -> void:
	if is_on_floor():
		jump_press()  
	
func _on_jump_button_released() -> void:
	if is_on_floor() and timer_called == false:
		jump_release()
		jump_counter += 1

# The jump button was pressed.
func jump_press():
	timer_called = false
	Input.vibrate_handheld(10)
	if did_fall == true:
		hit_floor_from_fall = false
		did_fall = false	
	jumpBeingPressed = true
	animated_sprite.play("load_jump")
	
	press_start_time = Time.get_ticks_msec() / 1000.0
	
	if jumpBeingPressed == true:
		timer.start()

# The jump action was released from the timer started when the user pressed down on the button.
func jump_from_timer():
	timer_called = true
	jump_release()

func _handle_save_game():
	var high_score = saver_loader.highest_score
	if high_score < highest_point:
		saver_loader.highest_score = highest_point
	saver_loader.player_lives = playerLives
	
	saver_loader.save_game()
	
# The jump button was released.
func jump_release():
	timer.stop()
	
	Input.vibrate_handheld(10)
	
	if press_start_time != 0:
		press_duration = Time.get_ticks_msec() / 1000.0 - press_start_time  # Get the press duration
	
	jumpBeingPressed = false
	play_jump_sound()
	play_jump_ground_sound()
	print(press_duration)
	if press_duration > 0.2:
		velocity.y = JUMP_VELOCITY * press_duration * 2.2
	if press_duration < 0.2:
		velocity.y = JUMP_VELOCITY * 0.2 * 2.2
	press_start_time = 0.0

# Handle jump with keyboard keys.
func handle_jump_keyboard():
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump_press()
	if Input.is_action_just_released("jump") and is_on_floor() and timer_called == false:
		jump_release()

func set_distance_label():
	var player_height = global_position.y
	var height_in_feet = round(player_height)
	var base_level = 691
	var distance_from_base = (height_in_feet - base_level) / 9
	var distance_rounded = round(abs(distance_from_base))
	current_height = distance_rounded
	if current_height >= highest_point:
		highest_point = current_height
	
	distance_label.text = "  " + str(distance_rounded) + " ft"
	
## Player Sounds: 
	
var current_index = 0

var jump_sounds = [
	"res://assets/sounds/jump_1.wav",
	"res://assets/sounds/jump_3.wav",
	"res://assets/sounds/jump_4.wav",
	"res://assets/sounds/jump_5.wav",
]

@onready var jump_audio: AudioStreamPlayer2D = $JumpAudio
@onready var run_audio: AudioStreamPlayer2D = $RunAudio
@onready var fall_audio: AudioStreamPlayer2D = $FallAudio
@onready var jump_ground_audio: AudioStreamPlayer2D = $JumpGroundAudio
@onready var stun_audio: AudioStreamPlayer2D = $StunAudio
@onready var land_audio: AudioStreamPlayer2D = $LandAudio
@onready var gained_audio: AudioStreamPlayer2D = $Gained_audio

	
# Play the next song
func play_jump_sound():
	if current_index >= jump_sounds.size():
		current_index = 0 # Restart playlist
	# Load the current audio file
	var audio_stream = load(jump_sounds[current_index])
	jump_audio.stream = audio_stream
	jump_audio.play()
	current_index += 1
	
func play_new_life_sound():
	var life_sounds = load("res://assets/sounds/new_life.wav")
	gained_audio.stream = life_sounds
	gained_audio.play()
	
func play_fall_sound():
	var fall_sounds = load("res://assets/sounds/fall.wav")
	fall_audio.stream = fall_sounds
	fall_audio.play()

func play_jump_ground_sound():
	var jump_ground_sounds = load("res://assets/sounds/jump_ground.wav")
	jump_ground_audio.stream = jump_ground_sounds
	jump_ground_audio.play()
	
func play_stun_sound():
	var stun_sounds = load("res://assets/sounds/stun_4.wav")
	stun_audio.stream = stun_sounds
	stun_audio.play()
	
func play_land_sound():
	var land_sounds = load("res://assets/sounds/land_gravel.wav")
	land_audio.stream = land_sounds
	land_audio.play()

func play_run_sound():
	var run_sounds = load("res://assets/sounds/run_new.wav")
	run_audio.stream = run_sounds

func _on_joystick_pressed() -> void:
	Input.vibrate_handheld(10)
	
# Game over
func _on_game_over():
	if game_is_over:
		await get_tree().create_timer(0.5).timeout
		get_tree().paused = true
		show_interstitial_ad.emit()
		_handle_save_game()
		emit_signal("game_over", jump_counter, highest_point)

func _on_restart():
	global_position = starting_node.global_position
	restore_life_pickups()
	playerLives = 3
	heart_1.stop()
	heart_2.stop()
	heart_3.stop()
	jump_counter = 0
	highest_point = 0
	game_is_over = false
	saver_loader.save_game()
	
func restore_life_pickups():
	for life in get_tree().get_nodes_in_group("New_Life"):
		if life.has_method("get_life_id"):
		# Check if the node's id (assumed to be stored in "life_id") is in saver_loader.collected_lives.
			if life.life_id in saver_loader.collected_lives:
				life.reset()
	saver_loader.collected_lives.clear()

func ad_more_life():
	game_is_over = false
	playerLives = 1
	heart_1.play("new_life")
	play_new_life_sound()
	_handle_save_game()
	
func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		# Stop any sounds playing
		for audio in [jump_audio, run_audio, fall_audio, jump_ground_audio, stun_audio, land_audio, gained_audio]:
			if audio and audio.playing:
				audio.stop()

		# Stop and clean up timer
		if timer:
			timer.stop()
			if timer.is_connected("timeout", Callable(self, "jump_from_timer")):
				timer.disconnect("timeout", Callable(self, "jump_from_timer"))

		# Disconnect signals
		if game.is_connected("restart", Callable(self, "_on_restart")):
			game.disconnect("restart", Callable(self, "_on_restart"))
		if game.is_connected("ad_more_life", Callable(self, "ad_more_life")):
			game.disconnect("ad_more_life", Callable(self, "ad_more_life"))
		if saver_loader.is_connected("data_loaded", Callable(self, "_on_save_data_loaded")):
			saver_loader.disconnect("data_loaded", Callable(self, "_on_save_data_loaded"))

		for life in get_tree().get_nodes_in_group("New_Life"):
			if life.has_signal("new_life_gained") and life.is_connected("new_life_gained", Callable(self, "increment_lives")):
				life.disconnect("new_life_gained", Callable(self, "increment_lives"))

		#if game_over_timer:
			#game_over_timer.stop()
