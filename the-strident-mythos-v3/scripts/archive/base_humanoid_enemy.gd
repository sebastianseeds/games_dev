extends CharacterBody2D

@export var patrol_path: NodePath  # Optional patrol route
@export var detection_range: float = 200.0  # Distance to detect player
@export var attack_range: float = 40.0  # Distance to attack
@export var attack_damage: int = 5  # Base damage
@export var move_speed: float = 60.0  # Movement speed

var state = "idle"  # "idle", "patrolling", "chasing", "attacking"
var player = null  # Reference to player

@onready var anim = $base_humanoid_enemy_sprite  # Ensure this matches node name!

func _ready():
	anim.play("idle_south")  # Default idle animation

func _process(_delta):
	match state:
		"idle":
			idle_behavior()
		"patrolling":
			patrol_behavior()
		"chasing":
			chase_player()
		"attacking":
			attack_player()

func get_facing_direction(target_position: Vector2) -> String:
	var direction = (target_position - global_position).normalized()
	
	if abs(direction.x) > abs(direction.y):  # Prioritize horizontal movement
		return "east" if direction.x > 0 else "west"
	else:  # Otherwise, prioritize vertical movement
		return "south" if direction.y > 0 else "north"

func detect_player():
	if player and global_position.distance_to(player.global_position) < detection_range:
		state = "chasing"

func idle_behavior():
	detect_player()  # Switch to chasing if player is detected

func patrol_behavior():
	detect_player()  # Switch to chasing if player is detected

func chase_player():
	if not player:
		state = "idle"
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	if global_position.distance_to(player.global_position) < attack_range:
		state = "attacking"

func attack_player():
	if player and global_position.distance_to(player.global_position) < attack_range:
		anim.play("attack_" + get_facing_direction(player.global_position))
		player.take_damage(attack_damage)  # Assuming player has take_damage() method
	else:
		state = "chasing"
