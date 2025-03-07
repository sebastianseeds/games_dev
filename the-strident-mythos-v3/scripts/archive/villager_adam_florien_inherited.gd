extends "res://scripts/npc/base_npc.gd"

@export var wander_area_size: float = 100.0  # Max distance Adam can move from start
@export var wander_speed: float = BASE_SPEED  # Use base speed from `base_npc.gd`
@export var time_between_moves: float = 2.0  # Time before choosing a new direction

var start_position: Vector2
var wander_timer: float = 0.0

func _ready():
	super()
	start_position = global_position  # Save original spawn point
	print("✅ NPC Ready:", npc_name, "| Wander Area:", wander_area_size, "| Dialogue Count:", dialogue.size())
	#change_sprite_sheet()
	
func change_sprite_sheet(): 
	print("Loading new sprite sheet for Adam Florien...")
	var animated_sprite = get_node("base_npc_sprite")
	var new_sprite_sheet = load("res://assets/sprites/npc/villager_adam_florien.png") 
	animated_sprite.sprite_frames = new_sprite_sheet 

func _process(delta):
	if is_talking:
		return  # Don't move if talking

	# Handle wandering only if movement is enabled
	if can_move:
		wander_timer -= delta
		if wander_timer <= 0:
			choose_new_direction()
			wander_timer = time_between_moves  # Reset timer

		# Move in chosen direction
		move_and_slide()

func choose_new_direction():
	# Pick a random direction
	var directions = [
		Vector2(0, -1),  # Up
		Vector2(0, 1),   # Down
		Vector2(-1, 0),  # Left
		Vector2(1, 0)    # Right
	]
	direction = directions[randi() % directions.size()]

	# Check if movement would exceed wander area
	var target_position = start_position + (direction * wander_area_size)
	if (target_position - start_position).length() > wander_area_size:
		direction = Vector2.ZERO  # Stay in place if out of bounds

	velocity = direction * wander_speed

func interact():
	if dialogue.size() == 0:
		print("[" + npc_name + "] (Silent...)")  # If no dialogue is set in Inspector
		return

	if is_talking:
		dialogue_index += 1
		if dialogue_index >= dialogue.size():
			is_talking = false  # End conversation
			dialogue_index = 0  # Reset dialogue index
			print("[" + npc_name + "] Goodbye!")
		else:
			print("[" + npc_name + "] " + dialogue[dialogue_index])
	else:
		is_talking = true
		print("[" + npc_name + "] " + dialogue[dialogue_index])
