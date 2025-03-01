extends CharacterBody2D

const BASE_SPEED = 100.0
var speed = BASE_SPEED
var dialogue_manager
@onready var anim = $player_sprite
@onready var interaction_area = $InteractionArea

var direction = Vector2.ZERO
var facing_direction = "south"

func _ready():
	print("Player: _ready function called")
	
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
