extends "res://scripts/npc/base_npc.gd"

# Hardcoded path to the correct Villager sprite sheet
const SPRITE_SHEET_PATH = "res://sprites/npc/villager_adam_florien.png"

@onready var sprite_node = $base_npc_sprite  # Ensure this matches the node name!

func _ready():
	super()  # Calls _ready() from base_npc.gd
	load_custom_sprite()  # Set the correct sprite sheet

func load_custom_sprite():
	var texture = load(SPRITE_SHEET_PATH)  # Load the correct sprite sheet dynamically
	if texture:
		sprite_node.set_texture(texture)  # Apply it to the NPC sprite
	else:
		print("🚨 ERROR: Could not load texture:", SPRITE_SHEET_PATH)

func interact():
	print("[Villager Adam Florien] Hello, traveler!")  # Placeholder for real dialogue system
