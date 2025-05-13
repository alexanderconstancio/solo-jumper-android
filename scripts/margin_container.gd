extends MarginContainer

func _ready() -> void:
	# Ensure this runs only on mobile platforms
	if OS.get_name() in ["iOS", "Android"]:
		adjust_margins()

func adjust_margins() -> void:
	# Get the safe area rectangle
	var safe_area: Rect2 = DisplayServer.get_display_safe_area()
	# Get the viewport's transformation matrix
	var viewport_transform: Transform2D = get_viewport().get_final_transform()
	# Invert the transformation to map to viewport coordinates
	var viewport_safe_area: Rect2 = safe_area * viewport_transform.affine_inverse()
	# Get the full viewport rectangle
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	# Calculate margins
	var left_margin: float = viewport_safe_area.position.x - viewport_rect.position.x
	var top_margin: float = viewport_safe_area.position.y - viewport_rect.position.y
	var right_margin: float = (viewport_rect.position.x + viewport_rect.size.x) - (viewport_safe_area.position.x + viewport_safe_area.size.x)
	var bottom_margin: float = (viewport_rect.position.y + viewport_rect.size.y) - (viewport_safe_area.position.y + viewport_safe_area.size.y)
	# Apply margins
	add_theme_constant_override("margin_left", left_margin)
	add_theme_constant_override("margin_top", top_margin)
	add_theme_constant_override("margin_right", right_margin)
	add_theme_constant_override("margin_bottom", bottom_margin)
