extends CharacterBody2D

const SPEED = 100.0  # Lower speed because it's an NPC, adjust as needed

@onready var anim = $npc_sprite

func _ready():
	anim.play("idle_south")  # Default animation when the NPC spawns

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

func attack(direction):
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
