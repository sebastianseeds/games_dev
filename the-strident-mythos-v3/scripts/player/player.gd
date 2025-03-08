extends CharacterBody2D

# Debug options
var debug_show_hitboxes = false  # Toggle with F3 key
var debug_hitbox_color = Color(1.0, 0.3, 0.3, 0.5)  # Semi-transparent red
var debug_hitbox_outline_color = Color(1.0, 0.1, 0.1, 0.8)  # Brighter red for outline
var debug_hitbox_node = null  # Reference to current debug visualization


const BASE_SPEED = 100.0
var speed = BASE_SPEED
var dialogue_manager
@onready var anim = $player_sprite
@onready var interaction_area = $InteractionArea

var direction = Vector2.ZERO
var facing_direction = "south"

# Character stats
var stats: CharacterStats
var inventory = []

# Stamina system variables
var max_stamina = 100
var current_stamina = 100
var stamina_regen_rate = 10  # Stamina points per second
var base_attack_stamina_cost = 20
var stamina_exhausted = false  # Flag for exhaustion state

# Attack variables
var can_attack = true
var attack_cooldown = 0.5  # Half a second between attacks
var base_attack_cooldown = 0.5  # Base cooldown in seconds between attacks
var attack_cooldown_timer = 0.0  # Timer to track cooldown
var attack_damage = 10
var is_attacking = false

# Base animation speed and modifier
var base_animation_speed = 1.0
var dex_animation_modifier = 0.0

# Weapon system
var weapon_system = null
var equipped_weapon = {}
var weapons_inventory = []  # Store weapon IDs that the player owns

func _ready():
	print("Player: _ready function called")
	
	stats = CharacterStats.new()
	
	# Set player's starting stats (customize these as needed)
	stats.set_ability_scores(14, 12, 14, 10, 10, 8)
	
	# Set skill proficiencies (example: athletics, perception)
	stats.set_skill_proficiency("athletics", true)
	stats.set_skill_proficiency("perception", true)
	
	# Set initial gold
	stats.add_gold(50)
	
	# Set initial HP
	stats.current_hp = stats.max_hp
	
	# Connect animation finished signal
	anim.animation_finished.connect(_on_animation_finished)
	
	# Calculate max stamina based on constitution
	update_stamina_max()
	
	# Calculate animation speed based on dexterity
	update_animation_speed()
	
	# Initialize the weapon system
	weapon_system = WeaponSystem.new()
	
	# Equip starter weapon
	equip_weapon("basic_sword")
	
	# Add a second weapon to inventory for testing
	add_weapon_to_inventory("steel_dagger")
	
	# Add player to players group for easy finding
	if not is_in_group("players"):
		add_to_group("players")
		print("✅ Added player to 'players' group")
	
	# Right before attempting to get dialogue_manager
	print("Player: About to get dialogue_manager at path: /root/Main/UI/UIRoot/DialogueManager")
	# Try to get dialogue_manager with multiple possible paths
	
	if has_node("/root/Main/UI/UIRoot/DialogueManager"):
		print("DialogueManager exists at /root/Main/UI/UIRoot/DialogueManager")
	else:
		print("DialogueManager NOT found at /root/Main/UI/UIRoot/DialogueManager")

	
	dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueManager")
	#if dialogue_manager == null:
	#	dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueBox") # Alternative path
	#if dialogue_manager == null:
	#	print("Note: DialogueManager not found - dialogue features will be disabled")

	call_deferred("init_dialogue_manager")

	# After attempting to get dialogue_manager
	print("Player: dialogue_manager search result: " + str(dialogue_manager))
	# Don't throw an error since dialogue is optional for player functionality
	if dialogue_manager == null:
		push_error("Player: DialogueManager not found!")
		print("🚨 ERROR: DialogueManager not found!")
	else:
		print("✅ DialogueManager found")
	
	# Check interaction area
	if interaction_area == null:
		print("🚨 WARNING: interaction_area was null in onready, trying to get it explicitly")
		interaction_area = $InteractionArea
		
	if interaction_area == null:
		push_error("Player: InteractionArea not found!")
		print("🚨 ERROR: InteractionArea not found!")
		print("🚨 DEBUG: Children nodes of player: " + str(get_children()))
	else:
		print("✅ InteractionArea found")
		
	print("Player stats initialized: STR " + str(stats.strength) + 
		", DEX " + str(stats.dexterity) + 
		", CON " + str(stats.constitution) + 
		", INT " + str(stats.intelligence) + 
		", WIS " + str(stats.wisdom) + 
		", CHA " + str(stats.charisma))
		
	print("Scene tree structure:")
	print_scene_tree(get_tree().root)
	
	# Create debug label if it doesn't exist
	if not has_node("DebugLabel"):
		var debug_label = Label.new()
		debug_label.name = "DebugLabel"
		debug_label.position = Vector2(0, -60)  # Above player
		debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  # Center align
		debug_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER  # Center align
		debug_label.visible = false
		add_child(debug_label)

func init_dialogue_manager():
	print("Player: About to get dialogue_manager at path: /root/Main/UI/UIRoot/DialogueManager")
	dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueManager")
	if dialogue_manager == null:
		dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueBox")
	if dialogue_manager == null:
		print("Note: DialogueManager not found - dialogue features will be disabled")
		push_error("Player: DialogueManager not found!")
	else:
		print("✅ DialogueManager found")

# Then add this function outside _ready(), at the class level
func print_scene_tree(node, indent=""):
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_scene_tree(child, indent + "  ")

func _on_animation_finished():
	# Check if we just finished an attack animation
	var current_anim = anim.animation
	if current_anim.begins_with("attack_") and is_attacking:
		is_attacking = false
		# Start playing the idle animation
		anim.play("idle_" + facing_direction)

# Call this whenever dexterity changes
func update_animation_speed():
	# Calculate dexterity modifier
	var dex_mod = stats.get_ability_modifier(stats.dexterity)
	
	# Convert the modifier to a speed multiplier
	# For example: +4 DEX gives 40% faster animations
	dex_animation_modifier = dex_mod * 0.1
	
	# Ensure a minimum speed (don't go too slow for low DEX)
	var attack_speed_multiplier = max(0.7, 1.0 + dex_animation_modifier)
	
	# Apply to attack animations
	for anim_name in anim.sprite_frames.get_animation_names():
		if anim_name.begins_with("attack_"):
			# Set attack animation speed based on dexterity
			anim.sprite_frames.set_animation_speed(anim_name, base_animation_speed * attack_speed_multiplier)
			print("Set " + anim_name + " speed to " + str(base_animation_speed * attack_speed_multiplier))

# Add a variable to track last frame's key states
var last_frame_keys = {}

func _process(delta):
	handle_input()
	update_animation()
	move_and_slide()
	
	# Regenerate stamina over time
	regenerate_stamina(delta)
	
	# Check for exhaustion recovery
	if stamina_exhausted and current_stamina > max_stamina * 0.3:
		stamina_exhausted = false
		print("Recovered from stamina exhaustion")
	
	# Handle attack cooldown
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			can_attack = true
	
	# Re-enable auto-close dialogue when walking away
	if dialogue_manager != null and dialogue_manager.is_showing:
		# Check if we're far from all NPCs
		if not is_near_any_npc():
			print("Player: Not near any NPCs, closing dialogue")
			dialogue_manager.hide_dialogue()

		# Debug controls
	if OS.is_debug_build():
		# Toggle hitbox visualization with F3
		if Input.is_key_pressed(KEY_F3) and not Input.is_key_pressed(KEY_F3) in last_frame_keys:
			debug_show_hitboxes = not debug_show_hitboxes
			print("Debug hitboxes: " + ("ON" if debug_show_hitboxes else "OFF"))
			
			# Visual feedback for the toggle
			modulate = Color(1.5, 1.5, 1.5)  # Flash white
			var timer = get_tree().create_timer(0.1)
			timer.timeout.connect(func(): modulate = Color(1, 1, 1))
	
	# Store key states for this frame to check for just-pressed keys
	last_frame_keys = {
		KEY_F3: Input.is_key_pressed(KEY_F3)
	}

# Check if we're near any NPC
func is_near_any_npc() -> bool:
	# Find all NPCs in the scene
	var npcs = get_tree().get_nodes_in_group("NPCs")
	
	# Check distance to each NPC
	for npc in npcs:
		var distance = global_position.distance_to(npc.global_position)
		if distance < 100:  # 100 is interaction distance
			return true
	
	return false

func handle_input():
	direction = Vector2.ZERO
	
	# Don't allow movement during attack animation
	if is_attacking:
		velocity = Vector2.ZERO
		return
	
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
		facing_direction = "north"
	elif Input.is_action_pressed("ui_down"):
		direction.y += 1
		facing_direction = "south"
	
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
		facing_direction = "west"
	elif Input.is_action_pressed("ui_right"):
		direction.x += 1
		facing_direction = "east"
	
	# Handle attack input
	if Input.is_action_just_pressed("ui_accept") and can_attack:
		perform_attack()
	
	# Add weapon cycle with Tab key
	if Input.is_action_just_pressed("ui_focus_next"):  # Tab key
		cycle_weapons()
	
	direction = direction.normalized()
	velocity = direction * speed

func update_animation():
	
	# Don't change animation if we're attacking
	if is_attacking:
		return
	
	if direction != Vector2.ZERO:
		anim.play("walk_" + facing_direction)
	else:
		anim.play("idle_" + facing_direction)

func update_stamina_max():
	# Base stamina + bonus from Constitution
	var con_mod = stats.get_ability_modifier(stats.constitution)
	max_stamina = 100 + (con_mod * 20)  # +20 stamina per CON point above 10
	current_stamina = min(current_stamina, max_stamina)  # Cap current at max
	print("Max stamina updated: " + str(max_stamina) + " (CON mod: " + str(con_mod) + ")")

func regenerate_stamina(delta):
	# Base regeneration rate + CON modifier bonus
	var con_mod = stats.get_ability_modifier(stats.constitution)
	var regen_amount = (stamina_regen_rate + con_mod) * delta
	
	# Slower regeneration when exhausted
	if stamina_exhausted:
		regen_amount *= 0.5
	
	current_stamina = min(max_stamina, current_stamina + regen_amount)

#func attack():
#	anim.play("attack_" + facing_direction)

func perform_attack():
	# Calculate stamina cost based on weapon and player stats
	var stamina_cost = equipped_weapon.stamina_cost * (1.0 + (equipped_weapon.weight * 0.1))
	
	# Get the primary ability for this weapon type
	var weapon_ability = WeaponSystem.WEAPON_ABILITY_MAP.get(equipped_weapon.type, "strength")
	var ability_mod = stats.get_ability_modifier(stats.get(weapon_ability))
	
	# Better abilities reduce stamina cost (min 0.7 multiplier)
	var ability_stamina_modifier = max(0.7, 1.0 - (ability_mod * 0.05))
	stamina_cost *= ability_stamina_modifier
	
	# Check if we have enough stamina
	if current_stamina < stamina_cost:
		# Not enough stamina - enter exhausted state
		stamina_exhausted = true
		print("Not enough stamina! Exhausted!")
		
		# Allow attack but at great cost
		stamina_cost = current_stamina  # Use whatever is left
	
	# Reduce stamina
	current_stamina -= stamina_cost
	print("Attack used " + str(stamina_cost) + " stamina. Remaining: " + str(current_stamina))
	
	# Set attacking state
	is_attacking = true
	can_attack = false
	
	# Calculate cooldown based on dexterity, weapon type and stamina state
	var dex_mod = stats.get_ability_modifier(stats.dexterity)
	var dex_cooldown_reduction = dex_mod * 0.05  # 5% reduction per DEX modifier
	
	var final_cooldown = equipped_weapon.cooldown - dex_cooldown_reduction
	
	# Much longer cooldown when exhausted
	if stamina_exhausted:
		final_cooldown *= 2.0
		print("Exhausted - slow attack!")
	
	# Ensure minimum cooldown (faster weapons can't go below 0.2s)
	attack_cooldown_timer = max(0.2, final_cooldown)
	
	# Adjust animation speed based on stamina, dexterity and weapon weight
	var animation_speed_multiplier = 1.0 + (dex_mod * 0.1) - (equipped_weapon.weight * 0.05)
	
	# Slower animation when exhausted
	if stamina_exhausted:
		animation_speed_multiplier *= 0.5
	
	# Get appropriate animation name for this weapon
	var anim_name = weapon_system.get_attack_animation_name(equipped_weapon, facing_direction)
	
	# Fall back to a generic attack animation if the specific one doesn't exist
	if not anim.sprite_frames.has_animation(anim_name):
		if anim.sprite_frames.has_animation("attack_" + facing_direction):
			anim_name = "attack_" + facing_direction
		else:
			anim_name = "attack_slash_" + facing_direction
	
	# Set animation speed for this attack (ensure positive value)
	animation_speed_multiplier = max(0.5, animation_speed_multiplier)
	anim.sprite_frames.set_animation_speed(anim_name, animation_speed_multiplier * 5.0)
	
	# Play attack animation
	anim.play(anim_name)
	
	# Create attack hitbox
	create_weapon_hitbox()
	
	print("Attack speed: " + str(animation_speed_multiplier) + ", Cooldown: " + str(attack_cooldown_timer))

func create_weapon_hitbox():
	# Create a hitbox based on facing direction and weapon properties
	var hitbox = Area2D.new()
	hitbox.name = "WeaponHitbox"
	add_child(hitbox)
	
	# Create the collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Get hitbox data for current direction
	var hitbox_data = equipped_weapon.hitbox[facing_direction]
	
	# Apply hitbox size and position
	shape.size = hitbox_data.size
	collision.position = hitbox_data.offset
	
	collision.shape = shape
	hitbox.add_child(collision)
	
	# Add metadata to hitbox for hit processing
	hitbox.set_meta("weapon_data", equipped_weapon)
	
	# Connect signal to handle enemy hit
	hitbox.connect("body_entered", _on_weapon_hitbox_body_entered)
	
	# Create debug visualization if enabled
	if debug_show_hitboxes:
		create_debug_hitbox_visualization(hitbox_data, equipped_weapon.damage_type)
	
	# Delete hitbox after a short time based on animation speed
	var anim_duration = 0.2
	if stamina_exhausted:
		anim_duration *= 1.5
	
	await get_tree().create_timer(anim_duration).timeout
	hitbox.queue_free()
	
	# Clean up debug visualization
	if debug_hitbox_node:
		debug_hitbox_node.queue_free()
		debug_hitbox_node = null

func _on_weapon_hitbox_body_entered(body):
	# Check if the body is an enemy
	if body.is_in_group("enemies") or body.name.begins_with("base_animal_enemy") or body.name.begins_with("base_humanoid_enemy") or body.name.begins_with("base_monster_enemy"):
		print("Hit enemy: " + body.name)
		
		# Get damage calculation from weapon system
		var damage_info = weapon_system.calculate_weapon_damage(equipped_weapon, stats)
		var final_damage = damage_info.damage
		
		# Check for critical hit
		var is_critical = randf() < damage_info.crit_chance
		if is_critical:
			final_damage = int(final_damage * (1.0 + damage_info.crit_bonus))
			print("Critical hit! (" + str(final_damage) + " damage)")
		
		# Apply damage to enemy
		if body.has_method("take_damage"):
			body.take_damage(final_damage)
			
			# Some enemies might have additional damage type method
			if body.has_method("take_typed_damage"):
				body.take_typed_damage(final_damage, equipped_weapon.damage_type)
		
		# Process weapon effects
		weapon_system.process_weapon_effects(equipped_weapon, body, stats)

# Add a function to equip weapons by ID
func equip_weapon(weapon_id: String):
	# Get weapon data from the weapon system
	equipped_weapon = weapon_system.get_weapon(weapon_id)
	print("Equipped: " + equipped_weapon.name)

# Add a function to add weapons to inventory
func add_weapon_to_inventory(weapon_id: String):
	if not weapons_inventory.has(weapon_id):
		weapons_inventory.append(weapon_id)
		print("Added " + weapon_id + " to weapons inventory")
		return true
	return false

# Add a function to cycle through equipped weapons
func cycle_weapons():
	if weapons_inventory.size() == 0:
		print("No other weapons available")
		return
	
	# Add current weapon's ID to inventory
	weapons_inventory.append(equipped_weapon.id)
	
	# Equip first weapon from inventory
	var next_weapon_id = weapons_inventory.pop_front()
	equip_weapon(next_weapon_id)
	
	# Let player know what weapon is now equipped
	print("Switched to: " + equipped_weapon.name)

# Player stats
var health = 100
var max_health = 100
var gold = 50
var is_poisoned = false
var is_bleeding = false

# Take damage
func take_damage(amount: int):
	stats.take_damage(amount)
	
	# Check for death
	if stats.current_hp <= 0:
		die()
	
	print("Player took " + str(amount) + " damage. HP: " + 
		  str(stats.current_hp) + "/" + str(stats.max_hp))

# Heal the player
func heal(amount: int):
	stats.heal(amount)
	print("Player healed for " + str(amount) + ". HP: " + 
		  str(stats.current_hp) + "/" + str(stats.max_hp))

# Die (game over)
func die():
	print("Player died!")
	# Implement game over logic here

# Get gold amount
func get_gold() -> int:
	return stats.get_gold()

# Add or remove gold
func add_gold(amount: int):
	return stats.add_gold(amount)

# Add item to inventory
func add_item(item_name: String):
	inventory.append(item_name)
	print("Added " + item_name + " to inventory")

# Check if player has an item
func has_item(item_name: String) -> bool:
	return item_name in inventory

# Remove item from inventory
func remove_item(item_name: String) -> bool:
	if item_name in inventory:
		inventory.erase(item_name)
		print("Removed " + item_name + " from inventory")
		return true
	return false

# Set status effect
func set_status_effect(effect: String, value: bool):
	stats.set_status_effect(effect, value)
	
	# Handle visual effects or other consequences of status effects
	match effect:
		"poisoned":
			if value:
				print("Player is poisoned!")
				# Add visual effect for poison
			else:
				print("Player is no longer poisoned")
				# Remove visual effect
		"bleeding":
			if value:
				print("Player is bleeding!")
				# Add visual effect for bleeding
			else:
				print("Player is no longer bleeding")
				# Remove visual effect

# Method for compatibility with existing code
func cure_poison():
	set_status_effect("poisoned", false)
	return false

# Method for compatibility with existing code
func cure_bleed():
	set_status_effect("bleeding", false)
	return false

# Make a skill check
func skill_check(skill_name: String, difficulty_class: int) -> bool:
	return stats.skill_check(skill_name, difficulty_class)

# Make an ability check
func ability_check(ability: String, difficulty_class: int) -> bool:
	return stats.ability_check(ability, difficulty_class)


# Add a new function to create debug visualization for hitboxes
func create_debug_hitbox_visualization(hitbox_data, damage_type):
	# Remove existing debug visualization if any
	if debug_hitbox_node:
		debug_hitbox_node.queue_free()
	
	# Create a new node for the debug visualization
	debug_hitbox_node = Node2D.new()
	debug_hitbox_node.name = "DebugHitboxVisualization"
	add_child(debug_hitbox_node)
	
	# Set position from hitbox data
	debug_hitbox_node.position = hitbox_data.offset
	
	# Customize color based on damage type
	var fill_color = debug_hitbox_color
	var outline_color = debug_hitbox_outline_color
	
	match damage_type:
		"slashing":
			fill_color = Color(1.0, 0.3, 0.3, 0.5)  # Red for slashing
		"piercing":
			fill_color = Color(0.3, 0.3, 1.0, 0.5)  # Blue for piercing
		"bludgeoning":
			fill_color = Color(0.3, 1.0, 0.3, 0.5)  # Green for bludgeoning
		"fire":
			fill_color = Color(1.0, 0.6, 0.0, 0.5)  # Orange for fire
		"cold":
			fill_color = Color(0.0, 0.8, 1.0, 0.5)  # Cyan for cold
		_:
			fill_color = Color(0.8, 0.3, 0.8, 0.5)  # Purple for other types
	
	outline_color = fill_color
	outline_color.a = 0.8  # More opaque for outline
	
	# Add custom drawing
	debug_hitbox_node.set_script(create_debug_draw_script(hitbox_data.size, fill_color, outline_color))
	
	# Show weapon stats on debug label if it exists
	if has_node("DebugLabel"):
		var debug_label = get_node("DebugLabel")
		var stats_text = equipped_weapon.name + " (" + equipped_weapon.damage_type + ")\n"
		stats_text += "Damage: " + str(equipped_weapon.damage) + "\n"
		stats_text += "Range: " + str(equipped_weapon.range) + "\n"
		stats_text += "Speed: " + str(equipped_weapon.cooldown) + "s"
		debug_label.text = stats_text
		debug_label.visible = true
		
		# Hide debug label after 2 seconds
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func(): debug_label.visible = false)

# Create a script on the fly for the debug drawing node
func create_debug_draw_script(size: Vector2, fill_color: Color, outline_color: Color):
	# Create a new script
	var script = GDScript.new()
	
	# Script content for drawing the hitbox
	var script_code = """
extends Node2D

var size = Vector2(SIZE_X, SIZE_Y)
var fill_color = Color(FILL_R, FILL_G, FILL_B, FILL_A)
var outline_color = Color(OUTLINE_R, OUTLINE_G, OUTLINE_B, OUTLINE_A)
var pulse_time = 0.0

func _process(delta):
	# Make the hitbox pulse for better visibility
	pulse_time += delta * 5.0
	fill_color.a = 0.3 + 0.2 * sin(pulse_time)
	
	# Force redraw
	queue_redraw()

func _draw():
	# Draw filled rectangle
	draw_rect(Rect2(-size/2, size), fill_color)
	
	# Draw outline
	draw_rect(Rect2(-size/2, size), outline_color, false, 2.0)
	
	# Draw center crosshair
	var crosshair_size = 5.0
	draw_line(Vector2(-crosshair_size, 0), Vector2(crosshair_size, 0), outline_color, 1.0)
	draw_line(Vector2(0, -crosshair_size), Vector2(0, crosshair_size), outline_color, 1.0)
"""
	
	# Replace placeholder values with actual values
	script_code = script_code.replace("SIZE_X", str(size.x))
	script_code = script_code.replace("SIZE_Y", str(size.y))
	script_code = script_code.replace("FILL_R", str(fill_color.r))
	script_code = script_code.replace("FILL_G", str(fill_color.g))
	script_code = script_code.replace("FILL_B", str(fill_color.b))
	script_code = script_code.replace("FILL_A", str(fill_color.a))
	script_code = script_code.replace("OUTLINE_R", str(outline_color.r))
	script_code = script_code.replace("OUTLINE_G", str(outline_color.g))
	script_code = script_code.replace("OUTLINE_B", str(outline_color.b))
	script_code = script_code.replace("OUTLINE_A", str(outline_color.a))
	
	# Set script source code
	script.source_code = script_code
	script.reload()
	
	return script
