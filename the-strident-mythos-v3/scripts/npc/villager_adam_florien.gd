extends CharacterBody2D

@export var npc_name: String = "Dr. Adam Florien"  
# Remove the static dialogue array and replace with dynamic dialogue functions
@export var portrait_path: String = "res://assets/portraits/adam_florien.png"
@export var wander_area_size: float = 100.0  
@export var wander_speed: float = 20.0  
@export var time_between_moves: float = 2.0  

# Medical service costs
const HEALING_COST = 15
const POISON_CURE_COST = 25
const BLEED_CURE_COST = 20

# Character stats
var stats: CharacterStats

# Medical items for sale
var medical_items = [
	{"name": "Healing Potion", "price": 20, "effect": "Restores 50 health"},
	{"name": "Antidote", "price": 30, "effect": "Cures poison"},
	{"name": "Bandages", "price": 25, "effect": "Stops bleeding"},
	{"name": "Elixir of Vitality", "price": 75, "effect": "Restores all health and cures ailments"}
]

# Dialogue states
enum DialogueState {
	GREETING,
	MAIN_MENU,
	HEALING,
	CURE_POISON,
	CURE_BLEED,
	SHOP
}

var current_dialogue_state = DialogueState.GREETING
var start_position: Vector2
var wander_timer: float = 0.0
var is_talking: bool = false
var direction: Vector2 = Vector2.ZERO
var facing_direction: String = "south"

# Greeting questions that the doctor might ask
var greeting_questions = [
	"How are you feeling today?",
	"Any aches or pains troubling you?",
	"Have you been taking care of your health lately?",
	"You look a bit pale. Are you getting enough rest?",
	"I notice you're favoring that leg. An old injury perhaps?",
	"Have you been keeping up with your medicinal herbs regimen?"
]

@onready var anim = $adam_florien_sprite
@onready var interaction_area = $InteractionArea
@onready var dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueManager")

func _ready():
	# Previous initialization code remains the same
	if interaction_area == null:
		print("🚨 WARNING: interaction_area was null in onready, trying to get it explicitly")
		interaction_area = $InteractionArea
		
	if interaction_area == null:
		push_error("InteractionArea not found in " + name)
		print("🚨 ERROR: `InteractionArea` not found in", name)
		print("🚨 DEBUG: Children nodes of " + name + ": " + str(get_children()))
	else:
		print("✅ InteractionArea found: " + str(interaction_area))
	
	if dialogue_manager == null:
		print("🚨 WARNING: dialogue_manager was null, trying another path")
		dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueManager")
		
		if dialogue_manager == null:
			dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueBox")
			print("🚨 WARNING: Attempting to use DialogueBox instead: " + str(dialogue_manager))
	
	if dialogue_manager == null:
		push_error("DialogueManager not found!")
		print("🚨 ERROR: `DialogueManager` not found in Main.tscn!")
	else:
		print("✅ DialogueManager found: " + str(dialogue_manager))
	
	start_position = global_position  
	print("✅ NPC Ready:", npc_name, "| Wander Area:", wander_area_size)
	anim.play("idle_" + facing_direction)

	# Initialize character stats for Dr. Adam Florien
	stats = CharacterStats.new()
	
	# Set doctor's stats - high wisdom and intelligence for a healer
	stats.set_ability_scores(10, 12, 14, 16, 18, 14)
	
	# Set skill proficiencies appropriate for a doctor
	stats.set_skill_proficiency("medicine", true)
	stats.set_skill_proficiency("insight", true)
	stats.set_skill_proficiency("nature", true)
	stats.set_skill_proficiency("investigation", true)
	stats.set_skill_proficiency("persuasion", true)
	
	# Set level higher than player (experienced healer)
	stats.level = 5
	stats.calculate_derived_stats()
	
	start_position = global_position  
	print("✅ NPC Ready:", npc_name, 
		"| Stats: WIS " + str(stats.wisdom) + 
		", INT " + str(stats.intelligence) + 
		", Medicine +" + str(stats.get_skill_modifier("medicine")))
	anim.play("idle_" + facing_direction)

# The existing _process function remains largely the same
func _process(delta):
	if is_talking:
		return  # Don't move while talking
	
	# Handle wandering
	wander_timer -= delta
	if wander_timer <= 0:
		choose_new_direction()
		wander_timer = time_between_moves  
	
	move_and_slide()
	
	# Detect if the player presses "interact" inside the interaction area
	if Input.is_action_just_pressed("interact"):
		if interaction_area == null:
			print("🚨 InteractionArea is null, trying to get it directly")
			interaction_area = $InteractionArea
			
		if interaction_area == null:
			print("🚨 Still can't find InteractionArea, trying direct player distance check")
			var player = get_node_or_null("/root/Main/player")
			if player and global_position.distance_to(player.global_position) < 50:
				print("✅ Player is close enough, triggering interaction")
				interact()
			return
				
		print("✅ Checking for overlapping bodies in InteractionArea")
		var overlapping = interaction_area.get_overlapping_bodies()
		for body in overlapping:
			if body.name == "player":
				print("✅ Player detected in interaction area")
				interact()
				return

# The choose_new_direction and update_animation functions remain the same
func choose_new_direction():
	# Existing wandering logic
	var directions = {
		"north": Vector2(0, -1),
		"south": Vector2(0, 1),
		"east": Vector2(1, 0),
		"west": Vector2(-1, 0)
	}
	
	if randf() < 0.2:
		direction = Vector2.ZERO
		velocity = Vector2.ZERO
		update_animation()
		return
	
	var chosen_direction = directions.keys()[randi() % directions.size()]
	direction = directions[chosen_direction]
	facing_direction = chosen_direction
	
	var potential_position = global_position + (direction * wander_speed * time_between_moves)
	if (potential_position - start_position).length() > wander_area_size:
		direction = (start_position - global_position).normalized()
		
		if abs(direction.x) > abs(direction.y):
			facing_direction = "east" if direction.x > 0 else "west"
		else:
			facing_direction = "south" if direction.y > 0 else "north"
	
	velocity = direction * wander_speed
	update_animation()

func update_animation():
	if direction != Vector2.ZERO:
		anim.play("walk_" + facing_direction)
	else:
		anim.play("idle_" + facing_direction)

# Modified interact function to handle dialogue states
func interact():
	# Stop moving while talking
	is_talking = true
	velocity = Vector2.ZERO  
	
	print("✅ Player interacted with", npc_name)
	
	# Try multiple paths to find the player
	var player = get_node_or_null("/root/Main/World/player")
	if player == null:
		player = get_node_or_null("/root/Main/player")
	
	if player == null:
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			player = players[0]
		else:
			for node in get_tree().get_nodes_in_group("players"):
				if node.name == "player":
					player = node
					break
	
	# Turn to face the player if found
	if player:
		print("✅ Found player at: " + str(player.get_path()))
		face_towards(player.global_position)
		print("✅", npc_name, "is now facing", facing_direction)
	else:
		print("❌ Could not find player after multiple attempts")
	
	# Ensure NPC is in the NPCs group
	if not is_in_group("NPCs"):
		add_to_group("NPCs")
		print("✅ Added NPC to 'NPCs' group")
	
	# Load portrait texture
	var portrait_texture = null
	if portrait_path != "":
		portrait_texture = load(portrait_path)
		if portrait_texture:
			print("✅ Loaded portrait:", portrait_path)
		else:
			print("❌ Failed to load portrait:", portrait_path)
	
	# Show dialogue based on current state
	if dialogue_manager:
		show_dialogue_for_current_state(portrait_texture, player)
		
		# Force NPC to stay in talking state until dialogue is closed
		is_talking = true
		
		# Set up a timer to check if dialogue is closed
		create_tween().tween_callback(check_dialogue_status).set_delay(0.5)
	else:
		push_error("DialogueManager not found!")
		print("🚨 ERROR: DialogueManager not found!")
		is_talking = false

# New function to handle dialogue based on the current state
func show_dialogue_for_current_state(portrait_texture, player):
	match current_dialogue_state:
		DialogueState.GREETING:
			# Select a random greeting question
			var greeting = greeting_questions[randi() % greeting_questions.size()]
			
			# Add a medical insight based on wisdom check
			if player and player.has_method("ability_check"):
				var player_condition = ""
				
				# Doctor can detect if player is poisoned or bleeding
				if player.stats.has_status_effect("poisoned"):
					player_condition = "\n\nI notice a greenish tint to your skin. Poison, perhaps? I can help with that."
				elif player.stats.has_status_effect("bleeding"):
					player_condition = "\n\nYou're bleeding! Let me tend to that wound immediately."
				elif player.stats.current_hp < player.stats.max_hp * 0.5:
					player_condition = "\n\nYou look quite injured. I should examine those wounds."
				
				# Insight check to detect player's condition
				if stats.skill_check("insight", 12):
					if player.stats.current_hp < player.stats.max_hp * 0.25:
						player_condition = "\n\nBy the gods! You're gravely wounded! Please, let me help you right away."
					elif player.ability_check("constitution", 10) == false:
						player_condition = "\n\nYou seem a bit frail. Perhaps some tonic to boost your constitution?"
				
				greeting += player_condition
			
			dialogue_manager.show_dialogue(npc_name, greeting + "\n\n[Press E to continue]", portrait_texture)
			current_dialogue_state = DialogueState.MAIN_MENU
			
		DialogueState.MAIN_MENU:
			var menu_text = "What can I help you with today?\n\n"
			menu_text += "1. Healing (15 gold)\n"
			menu_text += "2. Cure Poison (25 gold)\n"
			menu_text += "3. Stop Bleeding (20 gold)\n"
			menu_text += "4. Medical Supplies\n"
			menu_text += "5. Goodbye"
			
			dialogue_manager.show_dialogue(npc_name, menu_text, portrait_texture)
			
			# Set up input handling for menu choices
			set_process_input(true)
			
		DialogueState.HEALING:
			# Check if player has enough gold
			if player and player.has_method("get_gold") and player.get_gold() >= HEALING_COST:
				# Doctor's medicine skill affects healing amount
				var base_healing = 30
				var medicine_bonus = stats.get_skill_modifier("medicine") * 5
				var total_healing = base_healing + medicine_bonus
				
				dialogue_manager.show_dialogue(npc_name, 
					"Let me tend to those wounds. This might sting a bit...\n\n" +
					"[You were healed for " + str(total_healing) + " HP. -15 gold]", 
					portrait_texture)
				
				# Deduct gold and heal player
				player.add_gold(-HEALING_COST)
				if player.has_method("heal"):
					player.heal(total_healing)
					
				# Special insight on critical conditions
				if player.stats.current_hp < player.stats.max_hp * 0.5:
					dialogue_manager.show_dialogue(npc_name, 
						"You're still not fully recovered. Please be careful out there.\n\n" +
						"[Press E to continue]", 
						portrait_texture)
			else:
				dialogue_manager.show_dialogue(npc_name, 
					"I'm sorry, but you don't seem to have enough gold for my services. " +
					"I need to cover the cost of supplies.", portrait_texture)
			
			current_dialogue_state = DialogueState.MAIN_MENU
			
		# Add skill-based discounts for regular patients
		DialogueState.CURE_POISON:
			var discount = 0
			var dc = 15 # Difficulty class for persuasion
			
			# Check if player can persuade for a discount
			if player and player.has_method("skill_check") and player.skill_check("persuasion", dc):
				discount = 5
				dialogue_manager.show_dialogue(npc_name, 
					"You make a compelling case. I'll reduce my fee this time.\n\n" +
					"[Persuasion check successful! -5 gold discount]", 
					portrait_texture)
				
			if player and player.has_method("get_gold") and player.get_gold() >= (POISON_CURE_COST - discount):
				dialogue_manager.show_dialogue(npc_name, 
					"That looks like a nasty case of poisoning. Drink this antidote, " +
					"and you'll feel better soon.\n\n" +
					"[Poison status removed. -" + str(POISON_CURE_COST - discount) + " gold]", 
					portrait_texture)
				
				player.add_gold(-(POISON_CURE_COST - discount))
				if player.has_method("cure_poison"):
					player.cure_poison()
			else:
				dialogue_manager.show_dialogue(npc_name, 
					"I'm afraid these antidotes are quite rare and expensive. " +
					"Please come back when you have " + str(POISON_CURE_COST - discount) + " gold.", 
					portrait_texture)
			
			current_dialogue_state = DialogueState.MAIN_MENU
			
		DialogueState.CURE_BLEED:
			if player and player.has_method("get_gold") and player.get_gold() >= BLEED_CURE_COST:
				dialogue_manager.show_dialogue(npc_name, "Let me apply some pressure and bandages to stop that bleeding.\n\n[Bleeding status removed. -20 gold]", portrait_texture)
				
				player.add_gold(-BLEED_CURE_COST)
				if player.has_method("cure_bleed"):
					player.cure_bleed()
			else:
				dialogue_manager.show_dialogue(npc_name, "I need 20 gold for the bandages and salves. Please return when you can afford it.", portrait_texture)
			
			current_dialogue_state = DialogueState.MAIN_MENU
			
		DialogueState.SHOP:
			var shop_text = "Here are the medicinal supplies I have for sale:\n\n"
	
			# Use doctor's medicine skill to provide information on items
			var medicine_skill = stats.get_skill_modifier("medicine")
	
			for i in range(medical_items.size()):
				var item = medical_items[i]
				var item_text = str(i+1) + ". " + item.name + " - " + str(item.price) + " gold (" + item.effect + ")"
		
				# Add doctor's insights for high medicine skill
				if medicine_skill >= 5:
					match item.name:
						"Healing Potion":
							item_text += " - Made from fresh herbs, very effective for wounds."
						"Antidote":
							item_text += " - Counters most common poisons found in this region."
						"Bandages":
							item_text += " - Treated with a special salve to accelerate healing."
						"Elixir of Vitality":
							item_text += " - My finest work. Restores body and spirit alike."
		
				shop_text += item_text + "\n"
	
			shop_text += str(medical_items.size()+1) + ". Return to main menu"
	
			dialogue_manager.show_dialogue(npc_name, shop_text, portrait_texture)
	
			# Set up input handling for shop choices
			set_process_input(true)

# Handle input for dialogue choices
func _input(event):
	if not is_talking or dialogue_manager == null or not dialogue_manager.is_showing:
		return
	
	if event is InputEventKey and event.pressed:
		match current_dialogue_state:
			DialogueState.MAIN_MENU:
				if event.keycode == KEY_1:
					current_dialogue_state = DialogueState.HEALING
					show_dialogue_for_current_state(load(portrait_path) if portrait_path else null, find_player())
				
				elif event.keycode == KEY_2:
					current_dialogue_state = DialogueState.CURE_POISON
					show_dialogue_for_current_state(load(portrait_path) if portrait_path else null, find_player())
				
				elif event.keycode == KEY_3:
					current_dialogue_state = DialogueState.CURE_BLEED
					show_dialogue_for_current_state(load(portrait_path) if portrait_path else null, find_player())
				
				elif event.keycode == KEY_4:
					current_dialogue_state = DialogueState.SHOP
					show_dialogue_for_current_state(load(portrait_path) if portrait_path else null, find_player())
				
				elif event.keycode == KEY_5:
					dialogue_manager.show_dialogue(npc_name, "Take care, and come see me if you're not feeling well.", load(portrait_path) if portrait_path else null)
					current_dialogue_state = DialogueState.GREETING
					is_talking = false
			
			DialogueState.SHOP:
				# Handle shop item selection (1-4 for items, 5 to return)
				if event.keycode >= KEY_1 and event.keycode <= KEY_5:
					var index = event.keycode - KEY_1
					
					if index < medical_items.size():
						# Try to buy the selected item
						var player = find_player()
						var item = medical_items[index]
						
						if player and player.has_method("get_gold") and player.get_gold() >= item.price:
							dialogue_manager.show_dialogue(npc_name, "Here's your " + item.name + ". Use it wisely.\n\n[-" + str(item.price) + " gold]", load(portrait_path) if portrait_path else null)
							
							player.add_gold(-item.price)
							if player.has_method("add_item"):
								player.add_item(item.name)
						else:
							dialogue_manager.show_dialogue(npc_name, "I'm sorry, but you don't have enough gold for that item.", load(portrait_path) if portrait_path else null)
					else:
						# Return to main menu
						current_dialogue_state = DialogueState.MAIN_MENU
						show_dialogue_for_current_state(load(portrait_path) if portrait_path else null, find_player())

# Helper function to find player
func find_player():
	var player = get_node_or_null("/root/Main/World/player")
	if player == null:
		player = get_node_or_null("/root/Main/player")
	
	if player == null:
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			player = players[0]
	
	return player

# Face towards a specific world position - unchanged
func face_towards(target_position):
	var direction_to_target = (target_position - global_position).normalized()
	
	if abs(direction_to_target.x) > abs(direction_to_target.y):
		facing_direction = "east" if direction_to_target.x > 0 else "west"
	else:
		facing_direction = "south" if direction_to_target.y > 0 else "north"
	
	anim.play("idle_" + facing_direction)

# Check if dialogue is still showing - modified to handle dialogue state
func check_dialogue_status():
	if dialogue_manager and not dialogue_manager.is_showing:
		# If we're in GREETING state, advance to MAIN_MENU
		if current_dialogue_state == DialogueState.GREETING:
			current_dialogue_state = DialogueState.MAIN_MENU
			show_dialogue_for_current_state(load(portrait_path) if portrait_path else null, find_player())
		else:
			is_talking = false
			print("✅ Dialogue closed, resuming NPC behavior")
	else:
		# Keep checking until dialogue is closed
		create_tween().tween_callback(check_dialogue_status).set_delay(0.5)
