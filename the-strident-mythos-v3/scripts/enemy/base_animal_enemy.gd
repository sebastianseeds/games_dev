extends CharacterBody2D

@export var detection_range: float = 150.0  # Distance to detect player
@export var flee_range: float = 100.0  # Distance at which the animal starts fleeing
@export var move_speed: float = 70.0  # Default movement speed
@export var is_hostile: bool = false  # If true, will attack instead of fleeing

var state = "idle"  # "idle", "fleeing", "attacking"
var player = null  # Player reference

@onready var anim = $base_enemy_sprite
@onready var hurtbox_area = $Hurtbox_Area
@onready var hurtbox_north = $Hurtbox_Area/Hurtbox_North
@onready var hurtbox_south = $Hurtbox_Area/Hurtbox_South
@onready var hurtbox_east = $Hurtbox_Area/Hurtbox_East
@onready var hurtbox_west = $Hurtbox_Area/Hurtbox_West

func _ready():
	disable_all_hurtboxes()  # Ensure only one is active at a time

func _process(_delta):
	match state:
		"idle":
			detect_player()
		"fleeing":
			flee_from_player()
		"attacking":
			attack_player()

func detect_player():
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)
	if is_hostile and distance < detection_range:
		state = "attacking"
	elif not is_hostile and distance < flee_range:
		state = "fleeing"

func flee_from_player():
	if not player:
		state = "idle"
		return

	var direction = (global_position - player.global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	var facing_direction = get_facing_direction(player.global_position)
	update_hurtbox(facing_direction)

	if global_position.distance_to(player.global_position) > flee_range * 1.5:
		state = "idle"

func attack_player():
	if player and global_position.distance_to(player.global_position) < flee_range:
		var facing_direction = get_facing_direction(player.global_position)
		update_hurtbox(facing_direction)

		anim.play("attack_" + facing_direction)
		player.take_damage(4)  # Lower attack damage for animals
	else:
		state = "idle"

func get_facing_direction(target_position: Vector2) -> String:
	var direction = (target_position - global_position).normalized()
	
	if abs(direction.x) > abs(direction.y):  # Prioritize horizontal movement
		return "east" if direction.x > 0 else "west"
	else:  # Otherwise, prioritize vertical movement
		return "south" if direction.y > 0 else "north"

func update_hurtbox(direction: String):
	disable_all_hurtboxes()
	
	match direction:
		"north":
			hurtbox_north.disabled = false
		"south":
			hurtbox_south.disabled = false
		"east":
			hurtbox_east.disabled = false
		"west":
			hurtbox_west.disabled = false

func disable_all_hurtboxes():
	hurtbox_north.disabled = true
	hurtbox_south.disabled = true
	hurtbox_east.disabled = true
	hurtbox_west.disabled = true
