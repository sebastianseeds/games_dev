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

func _process(delta):
	handle_input()
	update_animation()
	move_and_slide()
	
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
	
	direction = direction.normalized()
	velocity = direction * speed

func update_animation():
	if direction != Vector2.ZERO:
		anim.play("walk_" + facing_direction)
	else:
		anim.play("idle_" + facing_direction)

func attack():
	anim.play("attack_" + facing_direction)


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
