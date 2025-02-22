extends "res://scripts/npc/base_npc.gd"

@export var custom_texture: Texture2D  # Villager’s unique sprite sheet
@export var dialogue: Array[String] = [
	"Hello, traveler!",
	"The weather is nice today, isn't it?"
]

func _ready():
	super()  # Calls base_npc.gd’s _ready()
	
	# Swap texture if assigned
	if custom_texture:
		$base_npc_sprite.set_texture(custom_texture)

func interact():
	if dialogue.size() > 0:
		print("[Villager] " + dialogue[0])  # Replace with actual UI later
		dialogue.pop_front()
	else:
		print("[Villager] I have nothing more to say.")
