# Create a new file: scripts/rpg/character_stats.gd

extends Node
class_name CharacterStats

# Base ability scores
var strength: int = 10
var dexterity: int = 10
var constitution: int = 10
var intelligence: int = 10
var wisdom: int = 10
var charisma: int = 10

# Derived stats
var max_hp: int = 10
var current_hp: int = 10
var armor_class: int = 10
var proficiency_bonus: int = 2
var level: int = 1
var experience: int = 0

# Skills (based on D&D 5e)
# Format: {name: {ability: base_ability, proficient: is_proficient}}
var skills = {
	# Strength-based skills
	"athletics": {"ability": "strength", "proficient": false},
	
	# Dexterity-based skills
	"acrobatics": {"ability": "dexterity", "proficient": false},
	"sleight_of_hand": {"ability": "dexterity", "proficient": false},
	"stealth": {"ability": "dexterity", "proficient": false},
	
	# Constitution-based skills (none in standard 5e)
	
	# Intelligence-based skills
	"arcana": {"ability": "intelligence", "proficient": false},
	"history": {"ability": "intelligence", "proficient": false},
	"investigation": {"ability": "intelligence", "proficient": false},
	"nature": {"ability": "intelligence", "proficient": false},
	"religion": {"ability": "intelligence", "proficient": false},
	
	# Wisdom-based skills
	"animal_handling": {"ability": "wisdom", "proficient": false},
	"insight": {"ability": "wisdom", "proficient": false},
	"medicine": {"ability": "wisdom", "proficient": false},
	"perception": {"ability": "wisdom", "proficient": false},
	"survival": {"ability": "wisdom", "proficient": false},
	
	# Charisma-based skills
	"deception": {"ability": "charisma", "proficient": false},
	"intimidation": {"ability": "charisma", "proficient": false},
	"performance": {"ability": "charisma", "proficient": false},
	"persuasion": {"ability": "charisma", "proficient": false}
}

var gold: int = 0
var experience_to_next_level: int = 300

# Status effects
var is_poisoned: bool = false
var is_bleeding: bool = false
var is_stunned: bool = false
var is_charmed: bool = false

func _init():
	calculate_derived_stats()

# Set ability scores and update derived stats
func set_ability_scores(str_val: int, dex_val: int, con_val: int, 
						int_val: int, wis_val: int, cha_val: int):
	strength = str_val
	dexterity = dex_val
	constitution = con_val
	intelligence = int_val
	wisdom = wis_val
	charisma = cha_val
	
	calculate_derived_stats()

# Calculate derived stats like HP, AC, etc.
func calculate_derived_stats():
	# Calculate ability modifiers
	var con_mod = get_ability_modifier(constitution)
	var dex_mod = get_ability_modifier(dexterity)
	
	# Calculate max HP (based on level and constitution)
	max_hp = 10 + (level) * (6 + con_mod)  # Assuming d6 hit die + con mod per level
	
	# Calculate AC (10 + dex modifier by default)
	armor_class = 10 + dex_mod
	
	# Experience needed for next level
	experience_to_next_level = level * 300  # Simple progression

# Get ability modifier from ability score
func get_ability_modifier(score: int) -> int:
	return floor((score - 10) / 2)

# Get skill modifier (ability modifier + proficiency if proficient)
func get_skill_modifier(skill_name: String) -> int:
	if not skills.has(skill_name):
		push_error("Skill " + skill_name + " not found")
		return 0
		
	var skill = skills[skill_name]
	var ability_mod = 0
	
	# Get the corresponding ability modifier
	match skill.ability:
		"strength": ability_mod = get_ability_modifier(strength)
		"dexterity": ability_mod = get_ability_modifier(dexterity)
		"constitution": ability_mod = get_ability_modifier(constitution)
		"intelligence": ability_mod = get_ability_modifier(intelligence)
		"wisdom": ability_mod = get_ability_modifier(wisdom)
		"charisma": ability_mod = get_ability_modifier(charisma)
	
	# Add proficiency bonus if proficient
	if skill.proficient:
		return ability_mod + proficiency_bonus
	else:
		return ability_mod

# Set proficiency in a skill
func set_skill_proficiency(skill_name: String, is_proficient: bool):
	if skills.has(skill_name):
		skills[skill_name].proficient = is_proficient

# Add experience points and level up if needed
func add_experience(amount: int):
	experience += amount
	
	# Check for level up
	if experience >= experience_to_next_level:
		level_up()

# Level up the character
func level_up():
	level += 1
	
	# Recalculate stats
	calculate_derived_stats()
	
	# Update proficiency bonus (changes at levels 5, 9, 13, 17)
	if level >= 17:
		proficiency_bonus = 6
	elif level >= 13:
		proficiency_bonus = 5
	elif level >= 9:
		proficiency_bonus = 4
	elif level >= 5:
		proficiency_bonus = 3
	
	print("Level up! Now level " + str(level))

# Take damage
func take_damage(amount: int):
	current_hp = max(0, current_hp - amount)
	return current_hp

# Heal
func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)
	return current_hp

# Get current health as percentage
func get_health_percentage() -> float:
	return float(current_hp) / float(max_hp)

# Add or remove gold
func add_gold(amount: int):
	gold += amount
	return gold

# Get gold amount
func get_gold() -> int:
	return gold

# Set status effects
func set_status_effect(effect: String, value: bool):
	match effect:
		"poisoned": is_poisoned = value
		"bleeding": is_bleeding = value
		"stunned": is_stunned = value
		"charmed": is_charmed = value

# Check if character has a status effect
func has_status_effect(effect: String) -> bool:
	match effect:
		"poisoned": return is_poisoned
		"bleeding": return is_bleeding
		"stunned": return is_stunned
		"charmed": return is_charmed
		_: return false

# Make a skill check
func skill_check(skill_name: String, difficulty_class: int) -> bool:
	var d20_roll = randi() % 20 + 1  # Roll d20
	var skill_mod = get_skill_modifier(skill_name)
	var total = d20_roll + skill_mod
	
	print("Skill check: " + skill_name + " - Rolled " + str(d20_roll) + 
		  " + " + str(skill_mod) + " = " + str(total) + " vs DC " + str(difficulty_class))
	
	return total >= difficulty_class

# Make an ability check
func ability_check(ability: String, difficulty_class: int) -> bool:
	var d20_roll = randi() % 20 + 1  # Roll d20
	var ability_mod = 0
	
	match ability:
		"strength": ability_mod = get_ability_modifier(strength)
		"dexterity": ability_mod = get_ability_modifier(dexterity)
		"constitution": ability_mod = get_ability_modifier(constitution)
		"intelligence": ability_mod = get_ability_modifier(intelligence)
		"wisdom": ability_mod = get_ability_modifier(wisdom)
		"charisma": ability_mod = get_ability_modifier(charisma)
	
	var total = d20_roll + ability_mod
	
	print("Ability check: " + ability + " - Rolled " + str(d20_roll) + 
		  " + " + str(ability_mod) + " = " + str(total) + " vs DC " + str(difficulty_class))
	
	return total >= difficulty_class
