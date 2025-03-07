extends CharacterBody2D

@export var detection_range: float = 300.0  # Monsters detect from farther away
@export var attack_range: float = 50.0  # Attack distance
@export var attack_damage: int = 8  # Higher damage than humanoids
@export var move_speed: float = 80.0  # Slightly faster movement

var state = "roaming"  # "roaming", "chasing", "attacking"
var player = null  # Player reference

@onready var anim = $base_enemy_sprite

func _ready():
	anim.play("idle_south")

func _process(_delta):
	match state:
		"roaming":
			roam_around()
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

func roam_around():
	if randf() < 0.01:
		velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * move_speed
		move_and_slide()

	if player and global_position.distance_to(player.global_position) < detection_range:
		state = "chasing"

func chase_player():
	if not player:
		state = "roaming"
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	if global_position.distance_to(player.global_position) < attack_range:
		state = "attacking"

func attack_player():
	if player and global_position.distance_to(player.global_position) < attack_range:
		anim.play("attack_" + get_facing_direction(player.global_position))
		player.take_damage(attack_damage)
	else:
		state = "chasing"
