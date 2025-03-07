extends CharacterBody2D

# --------------------------
# CONFIG / STATE
# --------------------------
var is_interactable := true
var is_talking := false

# This will eventually be replaced by a full dialogue system later.
var dialogue_lines := [
	"Hello, traveler!",
	"These roads aren't safe.",
	"Have you heard the news from the capital?"
]

# --------------------------
# REFERENCES
# --------------------------
@onready var anim := $npc_sprite

# --------------------------
# READY
# --------------------------
func _ready():
	idle()

# --------------------------
# STATE CONTROL
# --------------------------
func idle():
	anim.play("idle_south")  # Default idle, can be adjusted per NPC later

func interact():
	if is_talking:
		return

	is_talking = true
	print("%s says: \"%s\"" % [name, dialogue_lines.pick_random()])

	# Placeholder for more advanced systems later
	# E.g., open dialogue box, trigger quests, give items

	# You'd usually end dialogue on a button press, but we auto-end here for now:
	await get_tree().create_timer(1.5).timeout
	is_talking = false

# --------------------------
# INPUT (for testing interaction)
# --------------------------
func _input(event):
	if event.is_action_pressed("interact") and is_interactable:
		interact()
