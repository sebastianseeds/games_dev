extends CharacterBody2D

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
var attack_cooldown_timer = 0.0  # Timer to track cooldown
var attack_damage = 10
var is_attacking = false

# Base animation speed and modifier
var base_animation_speed = 1.0
var dex_animation_modifier = 0.0

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
	
	# Add player to players group for easy finding
	if not is_in_group("players"):
		add_to_group("players")
		print("✅ Added player to 'players' group")
	
	# Try to get dialogue_manager
	dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueManager")
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
	# Calculate stamina cost
	var stamina_cost = base_attack_stamina_cost
	
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
	
	# Calculate cooldown based on dexterity and stamina state
	var dex_mod = stats.get_ability_modifier(stats.dexterity)
	var dex_cooldown_reduction = dex_mod * 0.05  # 5% reduction per DEX modifier
	
	var final_cooldown = base_attack_cooldown - dex_cooldown_reduction
	
	# Much longer cooldown when exhausted
	if stamina_exhausted:
		final_cooldown *= 2.0
		print("Exhausted - slow attack!")
	
	# Ensure minimum cooldown
	attack_cooldown_timer = max(0.2, final_cooldown)
	
	# Adjust animation speed based on stamina and dexterity
	var animation_speed_multiplier = 1.0 + (dex_mod * 0.1)
	
	# Slower animation when exhausted
	if stamina_exhausted:
		animation_speed_multiplier *= 0.5
	
	# Set animation speed for this attack
	var anim_name = "attack_slash_" + facing_direction
	anim.sprite_frames.set_animation_speed(anim_name, animation_speed_multiplier * 5.0)  # Assuming base is 5.0
	
	# Play attack animation
	anim.play(anim_name)
	
	# Create attack hitbox
	create_attack_hitbox()
	
	print("Attack speed: " + str(animation_speed_multiplier) + ", Cooldown: " + str(attack_cooldown_timer))

func create_attack_hitbox():
	# Create a hitbox based on facing direction
	var hitbox = Area2D.new()
	hitbox.name = "AttackHitbox"
	add_child(hitbox)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Set hitbox size and position based on facing direction
	match facing_direction:
		"north":
			shape.size = Vector2(30, 20)
			collision.position = Vector2(0, -25)
		"south":
			shape.size = Vector2(30, 20)
			collision.position = Vector2(0, 25)
		"east":
			shape.size = Vector2(20, 30)
			collision.position = Vector2(25, 0)
		"west":
			shape.size = Vector2(20, 30)
			collision.position = Vector2(-25, 0)
	
	collision.shape = shape
	hitbox.add_child(collision)
	
	# Connect signal to handle enemy hit
	hitbox.connect("body_entered", _on_attack_hitbox_body_entered)
	
	# Delete hitbox after a short time
	await get_tree().create_timer(0.2).timeout
	hitbox.queue_free()

func _on_attack_hitbox_body_entered(body):
	# Check if the body is an enemy
	if body.is_in_group("enemies") or (body.name.begins_with("base_animal_enemy") or body.name.begins_with("base_humanoid_enemy") or body.name.begins_with("base_monster_enemy")):
		print("Hit enemy: " + body.name)
		
		# Calculate damage based on player's strength
		var damage = attack_damage + stats.get_ability_modifier(stats.strength)
		
		# Apply damage to enemy
		if body.has_method("take_damage"):
			body.take_damage(damage)

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
