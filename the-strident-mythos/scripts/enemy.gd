extends "res://scripts/enemy.gd"

var current_facing := "south"

func _ready():
	super()  # Calls the _ready() from enemy.gd
	update_hitbox()

func update_hitbox():
	# Disable all direction-specific hitboxes
	for dir in ["North", "East", "South", "West"]:
		var shape_name = "Hurtbox_" + dir
		if has_node(shape_name):
			get_node(shape_name).disabled = true

	# Enable the correct one
	var active_hitbox = "Hurtbox_" + current_facing.capitalize()
	if has_node(active_hitbox):
		get_node(active_hitbox).disabled = false

func set_facing(direction):
	current_facing = direction
	update_hitbox()
