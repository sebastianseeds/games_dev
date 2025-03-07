extends CharacterBody2D

@export var detection_range: float = 150.0  # Distance to detect player
@export var flee_range: float = 100.0  # Distance at which the animal starts fleeing
@export var move_speed: float = 70.0  # Default movement speed
@export var is_hostile: bool = false  # If true, will attack instead of fleeing

var state = "idle"  # "idle", "fleeing", "attacking"
var player = null  # Player reference

@onready var anim = $base_animal_enemy_sprite
@onready var hurtbox_area = $base_animal_enemy_sprite/hurtbox_area
@onready var hurtbox_north = $base_animal_enemy_sprite/hurtbox_area/hurtbox_north
@onready var hurtbox_south = $base_animal_enemy_sprite/hurtbox_area/hurtbox_south
@onready var hurtbox_east = $base_animal_enemy_sprite/hurtbox_area/hurtbox_east
@onready var hurtbox_west = $base_animal_enemy_sprite/hurtbox_area/hurtbox_west

# Add these variables to the top of the script
var health = 30
var max_health = 30
var is_dead = false

func _ready():
	if not anim:
		print("🚨 ERROR: `base_enemy_sprite` not found in", name)
	if not hurtbox_area:
		print("🚨 ERROR: `Hurtbox_Area` not found in", name)
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

# Add this method to handle taking damage
func take_damage(amount: int):
	if is_dead:
		return
		
	health -= amount
	print(name + " took " + str(amount) + " damage! HP: " + str(health) + "/" + str(max_health))
	
	# Flash red to indicate damage
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

# Add this method to handle death
func die():
	is_dead = true
	state = "dead"
	print(name + " died!")
	
	# Play death animation if available
	if anim.has_animation("death_" + get_facing_direction(Vector2.ZERO)):
		anim.play("death_" + get_facing_direction(Vector2.ZERO))
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Remove from game after a delay
	await get_tree().create_timer(1.0).timeout
	queue_free()


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
