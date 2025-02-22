extends CharacterBody2D

const BASE_SPEED = 100.0
var speed = BASE_SPEED

@onready var anim = $player_sprite  # Ensure this matches the node name!

var direction = Vector2.ZERO
var facing_direction = "south"

func _process(_delta):
	handle_input()
	update_animation()
	move_and_slide()

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
