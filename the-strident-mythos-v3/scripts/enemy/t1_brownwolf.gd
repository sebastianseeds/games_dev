extends "res://scripts/enemy/base_animal_enemy.gd"

# Path to the wolf sprite sheet
const SPRITE_SHEET_PATH = "res://assets/sprites/enemies/enemy_t1_wolf_edit.png"

@onready var sprite_node = $base_enemy_sprite  # Reference to the sprite

func _ready():
	super()  # Calls _ready() from base_animal_enemy.gd
	load_custom_sprite()  # Set the correct sprite sheet

func load_custom_sprite():
	var texture = load(SPRITE_SHEET_PATH)  # Load the correct sprite sheet dynamically
	if texture:
		sprite_node.set_texture(texture)  # Apply it to the NPC sprite
	else:
		print("🚨 ERROR: Could not load texture:", SPRITE_SHEET_PATH)
