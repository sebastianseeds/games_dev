extends CharacterBody2D

@export var npc_name: String = "Adam Florien"  
@export var dialogue: Array[String] = [
	"Hello, traveler!",
	"The weather is nice today, isn't it?",
	"Have you seen the merchant in town?",
	"Get the fuck outta my face!"
]
@export var portrait_path: String = "res://assets/portraits/adam_florien.png"
@export var wander_area_size: float = 100.0  
@export var wander_speed: float = 20.0  
@export var time_between_moves: float = 2.0  

var start_position: Vector2
var wander_timer: float = 0.0
var is_talking: bool = false
var dialogue_index: int = 0
var direction: Vector2 = Vector2.ZERO
var facing_direction: String = "south"

@onready var anim = $adam_florien_sprite
@onready var interaction_area = $InteractionArea
# Fix: Reference the DialogueManager instead of DialogueBox
@onready var dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueManager")

func _ready():
	# Try to get interaction area if it's null
	if interaction_area == null:
		print("🚨 WARNING: interaction_area was null in onready, trying to get it explicitly")
		interaction_area = $InteractionArea
		
	# Check if it's still null after explicit attempt
	if interaction_area == null:
		push_error("InteractionArea not found in " + name)
		print("🚨 ERROR: `InteractionArea` not found in", name)
		print("🚨 DEBUG: Children nodes of " + name + ": " + str(get_children()))
	else:
		print("✅ InteractionArea found: " + str(interaction_area))
	
	# Try to get dialogue_manager if it's null
	if dialogue_manager == null:
		print("🚨 WARNING: dialogue_manager was null, trying another path")
		dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueManager")
		
		# If still null, try the DialogueBox directly
		if dialogue_manager == null:
			dialogue_manager = get_node_or_null("/root/Main/UI/UIRoot/DialogueBox")
			print("🚨 WARNING: Attempting to use DialogueBox instead: " + str(dialogue_manager))
	
	if dialogue_manager == null:
		push_error("DialogueManager not found!")
		print("🚨 ERROR: `DialogueManager` not found in Main.tscn!")
	else:
		print("✅ DialogueManager found: " + str(dialogue_manager))
	
	start_position = global_position  
	print("✅ NPC Ready:", npc_name, "| Wander Area:", wander_area_size, "| Dialogue Count:", dialogue.size())
	anim.play("idle_" + facing_direction)

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
		# First check if we have a valid interaction area
		if interaction_area == null:
			print("🚨 InteractionArea is null, trying to get it directly")
			interaction_area = $InteractionArea
			
		# Try to get player node directly if interaction area isn't working
		if interaction_area == null:
			print("🚨 Still can't find InteractionArea, trying direct player distance check")
			var player = get_node_or_null("/root/Main/player")
			if player and global_position.distance_to(player.global_position) < 50:
				print("✅ Player is close enough, triggering interaction")
				interact()
			return
				
		# Normal interaction check
		print("✅ Checking for overlapping bodies in InteractionArea")
		var overlapping = interaction_area.get_overlapping_bodies()
		for body in overlapping:
			if body.name == "player":
				print("✅ Player detected in interaction area")
				interact()
				return

func choose_new_direction():
	var directions = {
		"north": Vector2(0, -1),
		"south": Vector2(0, 1),
		"east": Vector2(1, 0),
		"west": Vector2(-1, 0)
	}
	
	# 20% chance to just stand still
	if randf() < 0.2:
		direction = Vector2.ZERO
		velocity = Vector2.ZERO
		facing_direction = facing_direction  # Keep current facing direction
		update_animation()
		return
	
	var chosen_direction = directions.keys()[randi() % directions.size()]
	direction = directions[chosen_direction]
	facing_direction = chosen_direction
	
	# Check if moving in this direction would take us too far from start position
	var potential_position = global_position + (direction * wander_speed * time_between_moves)
	if (potential_position - start_position).length() > wander_area_size:
		# Turn around - go back toward start position
		direction = (start_position - global_position).normalized()
		
		# Update facing direction based on movement
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

func interact():
	if dialogue.size() == 0:
		print("[" + npc_name + "] (Silent...)")  
		return
	
	# Stop moving while talking
	is_talking = true
	velocity = Vector2.ZERO  
	
	print("✅ Player interacted with", npc_name)
	
	# Try multiple paths to find the player
	var player = get_node_or_null("/root/Main/World/player")
	if player == null:
		player = get_node_or_null("/root/Main/player")
	
	if player == null:
		# Last resort - find player by name
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			player = players[0]
		else:
			# Try direct class-based search
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
	
	# Ensure NPC is in the NPCs group (for player distance checks)
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
	
	# Show dialogue box
	if dialogue_manager:
		print("✅ Calling show_dialogue() on DialogueManager")
		dialogue_manager.show_dialogue(npc_name, dialogue[dialogue_index], portrait_texture)
		
		# Force NPC to stay in talking state until dialogue is closed
		is_talking = true
		
		# Set up a timer to check if dialogue is closed
		create_tween().tween_callback(check_dialogue_status).set_delay(0.5)
	else:
		push_error("DialogueManager not found!")
		print("🚨 ERROR: DialogueManager not found!")
		is_talking = false
	
	# Move to next dialogue line for next interaction
	dialogue_index = (dialogue_index + 1) % dialogue.size()

# Face towards a specific world position
func face_towards(target_position):
	var direction_to_target = (target_position - global_position).normalized()
	
	# Determine which direction has the largest component
	if abs(direction_to_target.x) > abs(direction_to_target.y):
		# Horizontal movement is dominant
		facing_direction = "east" if direction_to_target.x > 0 else "west"
	else:
		# Vertical movement is dominant
		facing_direction = "south" if direction_to_target.y > 0 else "north"
	
	anim.play("idle_" + facing_direction)

# Check if dialogue is still showing
func check_dialogue_status():
	if dialogue_manager and not dialogue_manager.is_showing:
		is_talking = false
		print("✅ Dialogue closed, resuming NPC behavior")
	else:
		# Keep checking until dialogue is closed
		create_tween().tween_callback(check_dialogue_status).set_delay(0.5)
