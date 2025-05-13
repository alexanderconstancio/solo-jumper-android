extends Node2D

var ad_view: AdView

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_ad_banner()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func create_ad_view() -> void:
	ad_view = AdView.new("ca-app-pub-3940256099942544/2934735716", AdSize.BANNER, AdPosition.Values.CENTER)

	
func load_ad_banner():
	if ad_view == null:
		create_ad_view()
	var ad_request = AdRequest.new()
	ad_view.load_ad(ad_request)
