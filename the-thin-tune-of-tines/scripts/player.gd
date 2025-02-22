extends CharacterBody2D

const SPEED = 100.0

@onready var anim = $npc_sprite  # Assuming the node is still named npc_sprite

var direction = "south"  # Track which direction the player is facing

func _process(delta):
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
		direction = "north"
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
		direction = "south"
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
		direction = "west"
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
		direction = "east"

	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		walk(direction)
	else:
		idle(direction)

	velocity = input_vector * SPEED
	move_and_slide()

func walk(direction):
	if direction == "north":
		anim.flip_h = false
		anim.play("walk_north")
	elif direction == "east":
		anim.flip_h = false
		anim.play("walk_east")
	elif direction == "west":
		anim.flip_h = true
		anim.play("walk_east")
	elif direction == "south":
		anim.flip_h = false
		anim.play("walk_south")

func idle(direction):
	if direction == "north":
		anim.flip_h = false
		anim.play("idle_north")
	elif direction == "east":
		anim.flip_h = false
		anim.play("idle_east")
	elif direction == "west":
		anim.flip_h = true
		anim.play("idle_east")
	elif direction == "south":
		anim.flip_h = false
		anim.play("idle_south")

func attack():
	if direction == "north":
		anim.flip_h = false
		anim.play("attack_north")
	elif direction == "east":
		anim.flip_h = false
		anim.play("attack_east")
	elif direction == "west":
		anim.flip_h = true
		anim.play("attack_east")
	elif direction == "south":
		anim.flip_h = false
		anim.play("attack_south")
