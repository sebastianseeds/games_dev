extends CharacterBody2D

func process_idle(delta):
	# First check for player detection
	detect_player()
	
	# If state changed in detect_player, don't continue
	if state != "idle":
		return
	
	# Update idle timer
	idle_timer -= delta
	
	# Add a periodic bark chance while idle
	# Check every 1-2 seconds if the wolf should bark
	bark_check_timer -= delta
	if bark_check_timer <= 0:
		# Reset the bark check timer
		bark_check_timer = randf_range(1.0, 2.0)
		
		# Give wolf a chance to bark
		if randf() < bark_chance and not is_barking:
			bark()
	
	# If idle timer runs out, decide next action
	if idle_timer <= 0:
		# Start wandering (wolf has already had chances to bark)
		get_new_wander_target()
		state = "wandering"
		wander_timer = randf_range(min_wander_time, max_wander_time)
			
func bark():
	# Set barking flag
	is_barking = true
	
	# Get current direction
	var current_dir = get_facing_direction(global_position + wander_direction)
	
	# Check if bark animation exists
	var bark_anim = "bark_" + current_dir
	
	if anim.sprite_frames.has_animation(bark_anim):
		print("Wolf: Barking! " + bark_anim)
		anim.play(bark_anim)
		
		# Handle animation completion
		if not anim.animation_finished.is_connected(_on_bark_animation_finished):
			anim.animation_finished.connect(_on_bark_animation_finished, CONNECT_ONE_SHOT)
	else:
		# No bark animation, just use idle animation
		print("Wolf: Would bark, but no bark animation found, using idle")
		is_barking = false
		var idle_anim = "idle_" + current_dir
		anim.play(idle_anim)

func _on_bark_animation_finished():
	print("Wolf: Finished barking")
	is_barking = false
	
	# Return to previous state (usually idle)
	var current_dir = get_facing_direction(global_position + wander_direction)
	anim.play("idle_" + current_dir)
	
	# Reset idle timer
	idle_timer = randf_range(min_idle_time, max_idle_time)
	
func get_new_wander_target():
	# Get a random point within the wander radius
	var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	wander_target = home_position + (random_direction * randf_range(0, wander_radius))
	wander_direction = (wander_target - global_position).normalized()
	
func process_wandering(delta):
	# First check for player detection
	detect_player()
	
	# If state changed in detect_player, don't continue
	if state != "wandering":
		return
	
	# Update wander timer
	wander_timer -= delta
	
	# If wander timer runs out, go back to idle
	if wander_timer <= 0:
		state = "idle"
		idle_timer = randf_range(min_idle_time, max_idle_time)
		
		# Stop and play idle animation
		velocity = Vector2.ZERO
		var facing_dir = get_facing_direction(global_position + wander_direction)
		anim.play("idle_" + facing_dir)
		return
	
	# Move towards wander target
	wander_direction = (wander_target - global_position).normalized()
	
	# Apply DEX modifier to walking speed
	var dex_mod = stats.get_ability_modifier(stats.dexterity)
	var adjusted_walk_speed = walk_speed + (dex_mod * 2)  # +2 speed per DEX point above 10
	
	velocity = wander_direction * adjusted_walk_speed
	move_and_slide()
	
	# Update animation based on movement direction
	var facing_dir = get_facing_direction(global_position + wander_direction)
	update_hurtbox(facing_dir)
	anim.play("walk_" + facing_dir)
	
	# If we've reached the target, get a new one
	if global_position.distance_to(wander_target) < 10:
		get_new_wander_target()
		

@export var hit_dice := 2       # Number of hit dice
@export var hit_die_type := 8   # Type of hit die (d8)
var max_health = 0
var health = 0
var is_dead = false
var is_attacking = false  # Track when attack animation is playing# Add this new function to handle starting the attack
func start_attack():
	if not player:
		state = "idle"
		return
		
	print("Wolf: Starting new attack sequence in start_attack()")
	
	# Face the player
	var facing_dir = get_facing_direction(player.global_position)
	update_hurtbox(facing_dir)
	
	# Deal damage to player
	if player.has_method("take_damage"):
		player.take_damage(4)
		print("Wolf: Dealt 4 damage to player")
	
	# Start Dex-based cooldown
	can_attack = false
	var dex_mod = stats.get_ability_modifier(stats.dexterity)
	var final_cooldown = base_attack_cooldown - (dex_mod * 0.1)
	final_cooldown = max(final_cooldown, 0.3)  # Minimum cooldown
	attack_cooldown_timer = final_cooldown
	
	# Set the animation
	var attack_anim = "attack_" + facing_dir
	
	# IMPORTANT: Use play() but IMMEDIATELY change state to attacking_playing
	# This prevents any other code from changing animations or states
	print("Wolf: Playing animation: " + attack_anim + " then changing to attacking_playing state")
	anim.stop()  # Stop any current animation
	anim.play(attack_anim)
	
	# IMMEDIATELY change to attacking_playing state to prevent state machine from interrupting
	state = "attacking_playing"
	is_attacking = true
	
	# Connect to the animation_finished signal ONCE for this attack
	if not anim.animation_finished.is_connected(_on_attack_animation_finished):
		anim.animation_finished.connect(_on_attack_animation_finished, CONNECT_ONE_SHOT)
	
func _on_attack_animation_finished():
	print("Wolf: Attack animation finished!")
	
	# Clear the attacking flag
	is_attacking = false
	
	# Roll wisdom save to determine next state
	var wis_mod = stats.get_ability_modifier(stats.wisdom)
	var roll = randi() % 20 + 1
	var total = roll + wis_mod
	
	if total < wisdom_save_dc:
		# Wolf retreats
		state = "retreating"
		retreat_timer = retreat_duration
		is_retreating_by_time = true
		print("Wolf: Failed wisdom save, retreating")
	else:
		# Wolf stands still until cooldown ends
		state = "cooldown"
		print("Wolf: Passed wisdom save, staying in cooldown")# Handle animation completion
func _on_animation_finished():
	# When an attack animation finishes, return to appropriate state
	var current_anim = anim.animation
	if current_anim.begins_with("attack_"):
		is_attacking = false
		
		# Decide next state based on player distance
		if player:
			var distance = global_position.distance_to(player.global_position)
			if distance <= attack_range:
				state = "cooldown"
			else:
				state = "chasing"
		else:
			state = "idle"

@export var detection_range := 150.0
@export var flee_range := 100.0
@export var safe_range := 200.0
@export var retreat_duration: float = 2.0
@export var attack_range := 50.0
@export var move_speed := 70.0
@export var is_hostile := true  # If false, wolf flees instead of chases
@export var base_attack_cooldown := 1.5  # Base time between attacks
@export var retreat_time := 2.0         # How long the wolf runs away after failing a Wisdom check
@export var wisdom_save_dc := 10        # Difficulty class for the wolf's will save
@export var walk_speed := 40.0   # Speed for walking (wandering, idle)
@export var run_speed := 100.0   # Speed for running (chasing, attacking)

# Attack/cooldown logic
var can_attack: bool = true
var attack_cooldown_timer: float = 0.0

# Retreat logic
var retreat_timer: float = 0.0  # If you want a strict time-based retreat
var is_retreating_by_time: bool = false

# We'll store stats in a CharacterStats object
var stats: CharacterStats

var state = "idle"  # "idle", "wandering", "chasing", "fleeing", "attacking", "attacking_playing", "retreating", "cooldown", "dead"
var player = null  # Player reference

@onready var anim = $t1_wolf_sprite
@onready var hurtbox_area = $t1_wolf_sprite/hurtbox_area
@onready var hurtbox_north = $t1_wolf_sprite/hurtbox_area/hurtbox_north
@onready var hurtbox_south = $t1_wolf_sprite/hurtbox_area/hurtbox_south
@onready var hurtbox_east = $t1_wolf_sprite/hurtbox_area/hurtbox_east
@onready var hurtbox_west = $t1_wolf_sprite/hurtbox_area/hurtbox_west

# Wandering parameters
@export var wander_speed := 40.0
@export var wander_radius := 100.0
@export var min_wander_time := 1.0
@export var max_wander_time := 4.0
@export var min_idle_time := 2.0
@export var max_idle_time := 5.0
@export var bark_chance := 0.1  # 10% chance to bark each idle period

# Wandering state
var wander_target := Vector2.ZERO
var wander_direction := Vector2.ZERO
var wander_timer := 0.0
var idle_timer := 0.0
var home_position := Vector2.ZERO  # Original spawn position
var is_barking := false
var bark_check_timer := 0.0  # Timer for periodic bark checks while idle

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
	
	# Calculate HP based on hit dice and Constitution
	calculate_max_health()
	
	# Store initial position as home position
	home_position = global_position
	
	# Set initial wander target
	get_new_wander_target()
	
	# Start in idle state with a random timer
	idle_timer = randf_range(min_idle_time, max_idle_time)
	# Initialize bark check timer
	bark_check_timer = randf_range(1.0, 2.0)
	
	# Try to find the player
	player = get_node_or_null("/root/Main/World/player")
	
	# If that path didn't work, try a more generic approach
	if not player:
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			player = players[0]
	
	if not player:
		push_error("Wolf: Could not find player!")
	
	disable_all_hurtboxes()
	
	# Ensure we're added to the enemies group for attack detection
	if not is_in_group("enemies"):
		add_to_group("enemies")
		
	# Print all animation names at startup
	print("Wolf: Available animations at startup: " + str(anim.sprite_frames.get_animation_names()))
	
# Calculate maximum health based on hit dice and Constitution
func calculate_max_health():
	var con_modifier = stats.get_ability_modifier(stats.constitution)
	
	# Reset health calculation
	max_health = 0
	
	# Roll each hit die and add Constitution modifier
	for i in range(hit_dice):
		# Roll the hit die (e.g., d8)
		var roll = randi() % hit_die_type + 1
		max_health += roll + con_modifier
	
	# Ensure minimum of 1 HP per hit die
	max_health = max(hit_dice, max_health)
	
	# Set current health to max
	health = max_health
	
	print("Wolf: Calculated max health = " + str(max_health) + 
		  " (" + str(hit_dice) + "d" + str(hit_die_type) + 
		  " + " + str(con_modifier) + " CON modifier per die)")


func _process(delta):
	if is_dead:
		return
	
	# Debug animations
	if OS.is_debug_build() and Input.is_key_pressed(KEY_F1):
		print("Wolf: Current animation: " + anim.animation)
		print("Wolf: Current state: " + state)
		print("Wolf: can_attack: " + str(can_attack))
		print("Wolf: is_attacking: " + str(is_attacking))
		print("Wolf: is_barking: " + str(is_barking))
		print("Wolf: Available animations: " + str(anim.sprite_frames.get_animation_names()))
		
		# Force animation test with F2
		if Input.is_key_pressed(KEY_F2):
			print("Wolf: Debug - Forcing attack state")
			state = "attacking"
			
			# Flash red to confirm action
			modulate = Color(1, 0.3, 0.3)
			var timer = get_tree().create_timer(0.1)
			timer.timeout.connect(func(): modulate = Color(1, 1, 1))
	
	# If below 10% HP, permanently flee (unless already dead)
	if float(health) < float(max_health) * 0.1:
		if state != "attacking_playing" and not is_barking:  # Don't interrupt attack animation or barking
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
			
			# Roll another Wisdom save to determine if wolf returns to attack
			var wis_mod = stats.get_ability_modifier(stats.wisdom)
			var roll = randi() % 20 + 1
			var total = roll + wis_mod
			
			if total >= wisdom_save_dc:
				# Success - Wolf returns to chase
				state = "chasing"
				print(name + " regains courage (Wisdom save: " + str(total) + " vs DC " + str(wisdom_save_dc) + ")")
			else:
				# Failure - Wolf continues retreating
				print(name + " continues fleeing (Wisdom save: " + str(total) + " vs DC " + str(wisdom_save_dc) + ")")
				retreat_timer = retreat_duration  # Reset timer for another retreat period
	
	# If barking, wait for animation but don't process state machine
	if is_barking:
		return
		
	# If we're in the middle of an attack animation, don't process state machine
	if is_attacking:
		return
	
	# State machine
	match state:
		"idle":
			process_idle(delta)
		"wandering":
			process_wandering(delta)
		"chasing":
			chase_player(delta)
		"fleeing":
			flee_from_player()
		"attacking":
			# This state just initiates the attack, then immediately switches to attacking_playing
			start_attack()
		"attacking_playing":
			# This state does nothing but wait for the animation to complete
			pass  # Do nothing - animation is playing
		"retreating":
			retreat_from_player(delta)
		"cooldown":
			cooldown_logic(delta)
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
	if distance <= attack_range and can_attack:
		state = "attacking"
		return
	
	# Otherwise, move toward the player
	var direction = (player.global_position - global_position).normalized()

	# Use run_speed based on Dexterity
	var dex_mod = stats.get_ability_modifier(stats.dexterity)
	var adjusted_run_speed = run_speed + (dex_mod * 5)  # +5 speed per DEX point above 10
	
	velocity = direction * adjusted_run_speed
	move_and_slide()

	# Face the player and use running animation
	var facing_dir = get_facing_direction(player.global_position)
	update_hurtbox(facing_dir)
	
	# Use run animation if available, otherwise fall back to walk
	var run_anim = "run_" + facing_dir
	if anim.sprite_frames.has_animation(run_anim):
		anim.play(run_anim)
	else:
		anim.play("walk_" + facing_dir)

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

func die():
	is_dead = true
	state = "dead"
	print(name + " died!")
	
	# Play death animation if available
	var facing_dir = get_facing_direction(Vector2.ZERO)
	if anim.has_animation("death_" + facing_dir):
		anim.play("death_" + facing_dir)
	else:
		# Default to idle animation if no death animation
		anim.play("idle_" + facing_dir)
	
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
	
	# Apply DEX modifier to running speed when retreating
	var dex_mod = stats.get_ability_modifier(stats.dexterity)
	var adjusted_run_speed = run_speed + (dex_mod * 5)
	
	velocity = direction * adjusted_run_speed
	move_and_slide()

	# Set animation based on movement direction
	var facing_dir = get_facing_direction(-direction)  # Face away from player
	update_hurtbox(facing_dir)
	
	# Use run animation if available
	var run_anim = "run_" + facing_dir
	if anim.sprite_frames.has_animation(run_anim):
		anim.play(run_anim)
	else:
		anim.play("walk_" + facing_dir)

	# Check if we've reached safe distance regardless of timer
	var distance = global_position.distance_to(player.global_position)
	if distance >= safe_range:
		# If we've reached safe distance, roll Wisdom save to see if wolf returns to chase
		var wis_mod = stats.get_ability_modifier(stats.wisdom)
		var roll = randi() % 20 + 1
		var total = roll + wis_mod
		
		if total >= wisdom_save_dc:
			# Success - Wolf returns to chase
			state = "chasing"
			is_retreating_by_time = false
			print(name + " returns to chase (safe distance reached, Wisdom save: " + str(total) + " vs DC " + str(wisdom_save_dc) + ")")
		else:
			# Failed save but at safe distance - continue retreating but without timer
			is_retreating_by_time = false
			print(name + " stays cautious despite safe distance (Wisdom save: " + str(total) + " vs DC " + str(wisdom_save_dc) + ")")


func flee_from_player():
	if not player:
		state = "idle"
		return
	
	var direction = (global_position - player.global_position).normalized()
	
	# Apply DEX modifier to running speed when fleeing
	var dex_mod = stats.get_ability_modifier(stats.dexterity)
	var adjusted_run_speed = run_speed + (dex_mod * 5)
	
	velocity = direction * adjusted_run_speed
	move_and_slide()
	
	var facing_direction = get_facing_direction(-direction)  # Face away from player
	update_hurtbox(facing_direction)
	
	# Use run animation if available
	var run_anim = "run_" + facing_direction
	if anim.sprite_frames.has_animation(run_anim):
		anim.play(run_anim)
	else:
		anim.play("walk_" + facing_direction)

	# Only return to idle if player is far enough away
	if global_position.distance_to(player.global_position) > flee_range * 1.5:
		state = "idle"

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
		# Face the player
		var facing_dir = get_facing_direction(player.global_position)
		update_hurtbox(facing_dir)
		
		# Do damage
		if player.has_method("take_damage"):
			player.take_damage(4)

		# Start Dex-based cooldown
		can_attack = false
		var dex_mod = stats.get_ability_modifier(stats.dexterity)
		var final_cooldown = base_attack_cooldown - (dex_mod * 0.1)
		final_cooldown = max(final_cooldown, 0.3)  # Minimum cooldown
		attack_cooldown_timer = final_cooldown

		# Play bite animation - try different naming conventions
		var attack_anim = "attack_" + facing_dir
		var bite_anim = "bite_" + facing_dir
		var slash_anim = "attack_slash_" + facing_dir
		
		# Check which animation exists and play it
		if anim.sprite_frames.has_animation(attack_anim):
			anim.play(attack_anim)
		elif anim.sprite_frames.has_animation(bite_anim):
			anim.play(bite_anim)
		elif anim.sprite_frames.has_animation(slash_anim):
			anim.play(slash_anim)
		else:
			print("Warning: No attack animation found for direction: " + facing_dir)
			anim.play("idle_" + facing_dir) # Fallback to idle

		# Wisdom check to see if we stand or retreat
		var wis_mod = stats.get_ability_modifier(stats.wisdom)
		var roll = randi() % 20 + 1
		var total = roll + wis_mod

		if total < wisdom_save_dc:
			# Wolf retreats
			state = "retreating"
			# Set time-based retreat
			retreat_timer = retreat_duration
			is_retreating_by_time = true
		else:
			# Wolf stands still until cooldown ends
			state = "cooldown"
	else:
		# If we're waiting for cooldown, go to cooldown state
		state = "cooldown"

func cooldown_logic(delta: float):
	# Wolf stands still (idle anim) while waiting for attack cooldown
	if player:
		var facing_dir = get_facing_direction(player.global_position)
		update_hurtbox(facing_dir)
		anim.play("idle_" + facing_dir)

		if can_attack:
			# Once cooldown ends, see if the player is in range again
			var distance = global_position.distance_to(player.global_position)
			if distance <= attack_range:
				state = "attacking"
			elif distance <= detection_range:
				state = "chasing"
			else:
				state = "idle"
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
