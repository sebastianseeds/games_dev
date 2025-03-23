extends Control

@onready var stamina_bar = $StaminaBar
@onready var stamina_label = $StaminaLabel
@onready var health_bar = $HealthBar
@onready var health_label = $HealthLabel
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
		#print("Setting stamina bar value to:", player.current_stamina, "/", player.max_stamina)
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
			
	# Update health display
	if health_bar != null:
		#print("Setting health bar value to:", player.stats.current_hp, "/", player.stats.max_hp)
		health_bar.value = player.stats.current_hp
		health_bar.max_value = player.stats.max_hp

		# Optionally, change the color based on health
		if player.stats.current_hp < (player.stats.max_hp * 0.3):
			health_bar.modulate = Color(1.0, 0.3, 0.3)  # Red when low
		else:
			health_bar.modulate = Color(1.0, 1.0, 1.0)  # Normal color

		# Update health label
		if health_label != null:
			health_label.text = "HP: %d / %d" % [int(player.stats.current_hp), int(player.stats.max_hp)]
