extends Control

# Paths using the correct syntax with TextBox and PortraitBox
@onready var dialogue_panel = $"../DialogueBox"
@onready var text_box = $"../DialogueBox/Panel/TextBox"
@onready var portrait_box = $"../DialogueBox/Panel/PortraitBox"
@onready var dialogue_label = $"../DialogueBox/Panel/TextBox/Label"
@onready var portrait = $"../DialogueBox/Panel/PortraitBox/TextureRect"

var is_showing = false

func _ready():
	print("DialogueManager: _ready function called")
	
	# Check for required nodes
	if dialogue_panel == null:
		push_error("DialogueManager: dialogue_panel not found!")
		return
	else:
		print("✅ dialogue_panel found")
		dialogue_panel.hide()
	
	if text_box == null:
		push_error("DialogueManager: text_box not found!")
		return
	else:
		print("✅ text_box found")
		text_box.hide()
	
	if portrait_box == null:
		push_error("DialogueManager: portrait_box not found!")
		return
	else:
		print("✅ portrait_box found")
		portrait_box.hide()
	
	if dialogue_label == null:
		push_error("DialogueManager: dialogue_label not found!")
		return
	else:
		print("✅ dialogue_label found")
		dialogue_label.hide()
	
	if portrait == null:
		push_error("DialogueManager: portrait not found!")
		return
	else:
		print("✅ portrait found")
		portrait.hide()

func show_dialogue(character_name: String, text: String, portrait_texture: Texture2D = null):
	print("DialogueManager: show_dialogue called for " + character_name)
	
	# Set is_showing first
	is_showing = true
	
	# Set the text
	dialogue_label.text = "[" + character_name + "]: " + text
	
	# Show dialogue panel and text box
	dialogue_panel.show()
	text_box.show()
	dialogue_label.show()
	
	# Apply custom styling to text box
	apply_text_box_style()
	
	# Handle portrait
	if portrait_texture:
		portrait.texture = portrait_texture
		portrait_box.show()
		portrait.show()
		
		# Apply custom styling to portrait box
		apply_portrait_style()
		print("✅ Portrait applied")
	else:
		portrait.texture = null
		portrait_box.hide()
		portrait.hide()
		print("❌ No portrait found")
	
	print("✅ Dialogue should now be visible")

func hide_dialogue():
	print("DialogueManager: hide_dialogue called")
	is_showing = false
	
	dialogue_panel.hide()
	text_box.hide()
	portrait_box.hide()
	dialogue_label.hide()
	portrait.hide()

func _input(event):
	if is_showing:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			print("DialogueManager: Input detected, hiding dialogue")
			hide_dialogue()

# Apply styling to text box
func apply_text_box_style():
	# Create stylish text box
	var text_style = StyleBoxFlat.new()
	text_style.bg_color = Color(0.1, 0.1, 0.3, 0.9)  # Dark blue, slightly transparent
	
	# Use the method instead of the property
	text_style.set_border_width_all(2)
	# Or set individual sides:
	# text_style.border_width_top = 2
	# text_style.border_width_bottom = 2
	# text_style.border_width_left = 2
	# text_style.border_width_right = 2
	
	text_style.border_color = Color(0.5, 0.5, 1.0)  # Light blue border
	text_style.corner_radius_top_left = 10
	text_style.corner_radius_top_right = 10
	text_style.corner_radius_bottom_left = 10
	text_style.corner_radius_bottom_right = 10
	
	# Apply style to text box panel
	text_box.add_theme_stylebox_override("panel", text_style)
	
	# Style the label
	dialogue_label.add_theme_color_override("font_color", Color(1, 1, 1))  # White text
	dialogue_label.add_theme_font_size_override("font_size", 16)  # Larger text

# Apply styling to portrait area
func apply_portrait_style():
	# Create stylish portrait box
	var portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)  # Dark gray
	
	# Use the method instead of the property
	portrait_style.set_border_width_all(2)
	
	portrait_style.border_color = Color(0.8, 0.8, 0.8)  # Light gray border
	
	# Use set_corner_radius_all method instead of corner_radius_all
	portrait_style.set_corner_radius_all(10)
	# Or set individual corners:
	# portrait_style.corner_radius_top_left = 10
	# portrait_style.corner_radius_top_right = 10
	# portrait_style.corner_radius_bottom_left = 10
	# portrait_style.corner_radius_bottom_right = 10
	
	# Apply style to portrait box panel
	portrait_box.add_theme_stylebox_override("panel", portrait_style)
	
	# Configure portrait texture
	portrait.expand_mode = 1  # Expand
	portrait.stretch_mode = 5  # Keep aspect centered
