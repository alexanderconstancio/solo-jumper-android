extends Node2D
class_name MapRoot

signal all_scenes_loaded

const SCENE_PATHS = {
	"Dungeon": "res://scenes/dungeon.tscn",
	"Midieval": "res://scenes/midieval.tscn",
	"Forest": "res://scenes/forest.tscn",
	"Space": "res://scenes/space.tscn"
}

const HEIGHT_THRESHOLDS = {
	"AlienForestCave": 0,
	"Dungeon": -700,
	"Midieval": -1850,
	"Forest": -3000,
	"Space": -4600
}

const BELOW_THRESHOLDS = {
	"AlienForestCave": -1200,
	"Dungeon": -2600,
	"Midieval": -3850,
	"Forest": -5800,
	"Space": -10000
}

var loading_scenes: Dictionary = {}  # map_name -> scene_path
var loaded_maps: Dictionary = {}     # map_name -> instantiated node
var pending_loads: int = 0
var onAppear: bool = true
var isBelowFirstMapChunk = false

@onready var player: CharacterBody2D = %Player
@onready var map_building_node: Node2D = %MapBuildingNode

func _ready():
	loaded_maps["AlienForestCave"] = get_node("AlienForestCave")
	var player_y = player.position.y

func _process(_delta):
	var player_y = player.position.y
	if player_y >= HEIGHT_THRESHOLDS["Dungeon"] and onAppear:
		emit_signal("all_scenes_loaded")
		print("loaded only first scene")
		onAppear = false
	
	for map_name in HEIGHT_THRESHOLDS.keys():
		if player_y <= HEIGHT_THRESHOLDS[map_name] and player_y >= BELOW_THRESHOLDS[map_name] \
		and not loaded_maps.has(map_name) and not loading_scenes.has(map_name):
			print("should be loading another map besides bottom: ")
			load_tile_map_async(map_name)

func load_tile_map_async(map_name: String):
	if loaded_maps.has(map_name) or loading_scenes.has(map_name):
		return

	var scene_path = SCENE_PATHS.get(map_name, "")
	if scene_path == "":
		print("❌ Error: No scene path for", map_name)
		return

	loading_scenes[map_name] = scene_path
	pending_loads += 1
	ResourceLoader.load_threaded_request(scene_path)

func _physics_process(_delta):
	_process_loading()

func _process_loading():
	var to_finalize: Array = []

	for map_name in loading_scenes.keys():
		var scene_path = loading_scenes[map_name]
		if scene_path == "":
			continue

		var load_status = ResourceLoader.load_threaded_get_status(scene_path)
		if load_status == ResourceLoader.THREAD_LOAD_LOADED or load_status == ResourceLoader.THREAD_LOAD_FAILED:
			to_finalize.append(map_name)
			

	for map_name in to_finalize:
		var scene_path = loading_scenes[map_name]
		var packed_scene = ResourceLoader.load_threaded_get(scene_path)
		print("Trying to load packed scene scene: ", packed_scene)

		if packed_scene and packed_scene is PackedScene:
			var instance = packed_scene.instantiate()
			add_child(instance)
			instance.z_index = -1
			instance.process_mode = Node.PROCESS_MODE_DISABLED
			loaded_maps[map_name] = instance
			print("✅ Async Loaded:", map_name)
		else:
			print("❌ Failed to instantiate or invalid scene for:", map_name)

		loading_scenes.erase(map_name)
		pending_loads -= 1

	# ✅ Emit signal if all are done
	if pending_loads == 0 and to_finalize.size() > 0:
		print("🚀 All scenes finished loading!")
		emit_signal("all_scenes_loaded")

func determine_map_to_load(player_y: float) -> String:
	for map_name in ["Space", "Forest", "Midieval", "Dungeon"]:
		if player_y <= HEIGHT_THRESHOLDS[map_name]:
			return map_name
	return "AlienForestCave"

func determine_map_below(current_map: String) -> String:
	var order = ["AlienForestCave", "Dungeon", "Midieval", "Forest", "Space"]
	var index = order.find(current_map)
	if index > 0:
		return order[index - 1]
	return ""
