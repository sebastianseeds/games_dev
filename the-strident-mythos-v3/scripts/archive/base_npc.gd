extends CharacterBody2D

@export var npc_name: String = "NPC"  # Customizable per NPC
@export var dialogue: Array[String] = []  # Holds dialogue lines
@export var can_move: bool = false  # Enable wandering behavior

const BASE_SPEED = 30.0  # NPCs move slowly when wandering
var direction = Vector2.ZERO
var facing_direction = "south"
var dialogue_index = 0
var is_talking = false

@onready var anim = $base_npc_sprite

func _ready():
	anim.play("idle_" + facing_direction)

func _process(_delta):
	if is_talking:
		return  # NPC doesn't move while talking

	if can_move:
		wander()

	update_animation()

func update_animation():
	if direction != Vector2.ZERO:
		anim.play("walk_" + facing_direction)
	else:
		anim.play("idle_" + facing_direction)

func interact():
	if dialogue.size() > 0:
		is_talking = true
		print(npc_name + ": " + dialogue[dialogue_index])  # Placeholder for UI system
		dialogue_index = (dialogue_index + 1) % dialogue.size()
	else:
		print(npc_name + " has nothing to say.")  # Placeholder for UI system

func wander():
	if randf() < 0.005:  # Small chance to change direction
		var possible_directions = ["north", "south", "east", "west"]
		facing_direction = possible_directions[randi() % possible_directions.size()]
		match facing_direction:
			"north": direction = Vector2(0, -1)
			"south": direction = Vector2(0, 1)
			"east": direction = Vector2(1, 0)
			"west": direction = Vector2(-1, 0)

	direction = direction.normalized()
	velocity = direction * BASE_SPEED
	move_and_slide()
