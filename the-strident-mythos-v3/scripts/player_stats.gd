extends Control

@onready var stamina_bar = $StaminaBar
@onready var stamina_label = $StaminaLabel
@onready var player = get_node("/root/Main/World/player")  # Adjust this path to match your scene structure

func _ready():
	if player == null:
		player = get_node("/root/Main/player")  # Alternative path
		
	if player == null:
		push_error("Player not found for UI!")
		return
		
	print("Player UI initialized")

func _process(_delta):
	if player == null:
		return
		
	# Update stamina display
	if stamina_bar != null:
		stamina_bar.value = player.current_stamina
		stamina_bar.max_value = player.max_stamina
		
		# Change color based on stamina state
		if player.stamina_exhausted:
			stamina_bar.modulate = Color(1.0, 0.3, 0.3)  # Red when exhausted
		elif player.current_stamina < player.max_stamina * 0.3:
			stamina_bar.modulate = Color(1.0, 0.6, 0.2)  # Orange when low
		else:
			stamina_bar.modulate = Color(0.2, 0.8, 0.2)  # Green when good
		
		# Update label
		if stamina_label != null:
			stamina_label.text = "Stamina: " + str(int(player.current_stamina)) + "/" + str(int(player.max_stamina))
