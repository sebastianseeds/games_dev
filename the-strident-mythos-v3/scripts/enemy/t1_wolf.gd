extends CharacterBody2D

@export var detection_range := 150.0
@export var flee_range := 100.0
@export var safe_range := 140.0
@export var retreat_duration: float = 2.0
@export var attack_range := 30.0
@export var move_speed := 70.0
@export var is_hostile := true  # If false, wolf flees instead of chases
@export var base_attack_cooldown := 1.5  # Base time between attacks
@export var retreat_time := 2.0         # How long the wolf runs away after failing a Wisdom check
@export var wisdom_save_dc := 10        # Difficulty class for the wolf's will save

# Attack/cooldown logic
var can_attack: bool = true
var attack_cooldown_timer: float = 0.0

# Retreat logic
var retreat_timer: float = 0.0  # If you want a strict time-based retreat
var is_retreating_by_time: bool = false

# We'll store stats in a CharacterStats object
var stats: CharacterStats

var state = "idle"  # "idle", "fleeing", "attacking"
var player = null  # Player reference

@onready var anim = $t1_wolf_sprite
@onready var hurtbox_area = $t1_wolf_sprite/hurtbox_area
@onready var hurtbox_north = $t1_wolf_sprite/hurtbox_area/hurtbox_north
@onready var hurtbox_south = $t1_wolf_sprite/hurtbox_area/hurtbox_south
@onready var hurtbox_east = $t1_wolf_sprite/hurtbox_area/hurtbox_east
@onready var hurtbox_west = $t1_wolf_sprite/hurtbox_area/hurtbox_west

# Add these variables to the top of the script
var health = 30
var max_health = 30
var is_dead = false

func _ready():
	
	stats = CharacterStats.new()
	stats.set_ability_scores(
		10,  # STR
		14,  # DEX
		10,  # CON
		6,   # INT
		8,   # WIS
		6    # CHA
	)
	
	# Example: if your Player node is in the "players" group
	#var players = get_tree().get_nodes_in_group("players")
	#if players.size() > 0:
	#	player = players[0]
	# or:
	player = get_node("/root/Main/World/player")  # if that's the actual path
	
	disable_all_hurtboxes()

func _process(delta):
	
	# If below 10% HP, permanently flee (unless dead)
	if not is_dead and float(health) < float(max_health) * 0.1:
		state = "fleeing"
	
	# Handle attack cooldown
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			can_attack = true
			
	# Update retreat timer if using time-based retreat
	if is_retreating_by_time:
		retreat_timer -= delta
		if retreat_timer <= 0:
			is_retreating_by_time = false
			state = "cooldown"  # or go straight to "chasing"
	
	match state:
		"idle":
			detect_player()
		"chasing":
			chase_player(delta)
		"fleeing":
			flee_from_player()
		"attacking":
			attack_player(delta)
		"retreating":
			retreat_from_player(delta)
		"dead":
			pass  # do nothing

func detect_player():
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if is_hostile and distance < detection_range:
		state = "chasing"
	elif not is_hostile and distance < flee_range:
		state = "fleeing"
	else:
		state = "idle"

func chase_player(delta):
	if not player:
		state = "idle"
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# If player is too far, go back to idle
	if distance > detection_range:
		state = "idle"
		return
	
	# If close enough, start attacking
	if distance <= attack_range:
		state = "attacking"
		return
	
	# Otherwise, move toward the player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	# Face the player
	var facing_dir = get_facing_direction(player.global_position)
	update_hurtbox(facing_dir)
	anim.play("walk_" + facing_dir)

# Add this method to handle taking damage
func take_damage(amount: int):
	if is_dead:
		return
	
	health -= amount
	print(name + " took " + str(amount) + " damage! HP: " + str(health) + "/" + str(max_health))
	
	# Flash red briefly
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

# This method to handle death
func die():
	is_dead = true
	state = "dead"
	print(name + " died!")
	
	# Optional: play death animation
	var facing_dir = get_facing_direction(Vector2.ZERO)
	if anim.has_animation("death_" + facing_dir):
		anim.play("death_" + facing_dir)
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Remove after a delay
	await get_tree().create_timer(1.0).timeout
	queue_free()

func retreat_from_player(delta):
	if not player:
		state = "idle"
		return

	# Move away from player
	var direction = (global_position - player.global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	var facing_dir = get_facing_direction(player.global_position)
	update_hurtbox(facing_dir)
	anim.play("walk_" + facing_dir)

	# If not using strict time, you can check distance to see if we've reached "safe_range"
	if not is_retreating_by_time:
		var distance = global_position.distance_to(player.global_position)
		if distance >= safe_range:
			# Switch to cooldown or chasing
			state = "cooldown"

func flee_from_player():
	# Existing flee logic
	if not player:
		state = "idle"
		return
	
	var direction = (global_position - player.global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	var facing_direction = get_facing_direction(player.global_position)
	update_hurtbox(facing_direction)
	anim.play("walk_" + facing_direction)

#	if global_position.distance_to(player.global_position) > flee_range * 1.5:
#		state = "idle"

func attack_player(delta):
	if not player:
		state = "idle"
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# If the player is out of bite range, chase again
	if distance > attack_range:
		state = "chasing"
		return
	
	# Only deal damage if off cooldown
	if can_attack:
		# Do damage
		player.take_damage(4)

		# Start Dex-based cooldown
		can_attack = false
		var dex_mod = stats.get_ability_modifier(stats.dexterity)
		var final_cooldown = base_attack_cooldown - (dex_mod * 0.1)
		final_cooldown = max(final_cooldown, 0.3)  # Minimum cooldown
		attack_cooldown_timer = final_cooldown

		# Play bite animation
		var facing_dir = get_facing_direction(player.global_position)
		anim.play("attack_" + facing_dir)

		# Wisdom check to see if we stand or retreat
		var wis_mod = stats.get_ability_modifier(stats.wisdom)
		var roll = randi() % 20 + 1
		var total = roll + wis_mod

		if total < wisdom_save_dc:
			# Wolf retreats
			state = "retreating"
			# If you want time-based retreat, set it here
			retreat_timer = retreat_duration
			is_retreating_by_time = true
		else:
			# Wolf stands still until cooldown ends
			state = "cooldown"
	else:
		# If we're waiting for cooldown, remain "attacking" or
		# switch to "cooldown" to stand still
		state = "cooldown"

	# Optional: remain in attacking state for a moment, or transition back to chasing/idle
	# This could be done by waiting for the animation to finish, etc.

func cooldown_logic(delta: float):
	# Wolf stands still (idle anim) until cooldown is over
	var facing_dir = get_facing_direction(player.global_position)
	anim.play("idle_" + facing_dir)

	if can_attack:
		# Once cooldown ends, see if the player is in range again
		if player:
			var distance = global_position.distance_to(player.global_position)
			if distance <= attack_range:
				state = "attacking"
			elif distance <= detection_range:
				state = "chasing"
			else:
				state = "idle"

func get_facing_direction(target_pos: Vector2) -> String:
	var dir = (target_pos - global_position).normalized()
	
	if abs(dir.x) > abs(dir.y):
		return "east" if dir.x > 0 else "west"
	else:
		return "south" if dir.y > 0 else "north"

func disable_all_hurtboxes():
	hurtbox_north.disabled = true
	hurtbox_south.disabled = true
	hurtbox_east.disabled = true
	hurtbox_west.disabled = true

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
