# weapons.gd
# Store this file in the rpg folder: scripts/rpg/weapons.gd

extends Node
class_name WeaponSystem

# Map of weapon types to primary ability scores
const WEAPON_ABILITY_MAP = {
	"sword": "strength",
	"dagger": "dexterity",
	"axe": "strength",
	"mace": "strength",
	"spear": "dexterity",
	"bow": "dexterity",
	"staff": "intelligence",
	"wand": "intelligence"
}

# Standard weapon blueprint
const WEAPON_BLUEPRINT = {
	"name": "",
	"type": "",            # sword, axe, dagger, mace, spear, bow, etc.
	"damage": 0,            # Base damage
	"damage_type": "",      # slashing, piercing, bludgeoning, fire, etc.
	"range": 0,             # Attack range in pixels
	"stamina_cost": 0,      # Stamina cost to use
	"cooldown": 0.0,        # Base cooldown in seconds
	"weight": 0,            # Affects stamina usage and swing speed
	"quality": 1.0,         # Multiplier for damage (1.0 = normal)
	"value": 0,             # Gold value
	"hitbox": {
		"north": {"size": Vector2.ZERO, "offset": Vector2.ZERO},
		"south": {"size": Vector2.ZERO, "offset": Vector2.ZERO},
		"east": {"size": Vector2.ZERO, "offset": Vector2.ZERO},
		"west": {"size": Vector2.ZERO, "offset": Vector2.ZERO}
	},
	"properties": {
		"can_parry": false,
		"two_handed": false,
		"ranged": false,
		"magical": false
	},
	"effects": {
		"bleed_chance": 0.0,
		"stun_chance": 0.0,
		"critical_bonus": 0.0
	}
}

# Catalog of all weapons in the game
var weapon_catalog = {}

func _init():
	# Initialize the catalog with all available weapons
	register_all_weapons()
	
func register_all_weapons():
	# Register basic weapons
	register_basic_weapons()
	
	# Register magical weapons
	register_magical_weapons()
	
	# Register legendary weapons
	register_legendary_weapons()
	
	print("WeaponSystem: Registered " + str(weapon_catalog.size()) + " weapons")

# Get a weapon by its ID
func get_weapon(weapon_id: String) -> Dictionary:
	if weapon_catalog.has(weapon_id):
		# Return a copy to prevent modification of the original
		return weapon_catalog[weapon_id].duplicate(true)
	else:
		push_error("Weapon ID not found: " + weapon_id)
		# Return basic weapon as fallback
		return weapon_catalog["basic_sword"].duplicate(true)

# Register basic weapons
func register_basic_weapons():
	# SWORDS
	register_weapon({
		"id": "basic_sword",
		"name": "Basic Sword",
		"type": "sword",
		"damage": 10,
		"damage_type": "slashing",
		"range": 50,
		"stamina_cost": 20,
		"cooldown": 0.5,
		"weight": 3,
		"quality": 1.0,
		"value": 50,
		"hitbox": {
			"north": {"size": Vector2(40, 20), "offset": Vector2(0, -30)},
			"south": {"size": Vector2(40, 20), "offset": Vector2(0, 30)},
			"east": {"size": Vector2(20, 40), "offset": Vector2(30, 0)},
			"west": {"size": Vector2(20, 40), "offset": Vector2(-30, 0)}
		},
		"properties": {
			"can_parry": true,
			"two_handed": false
		},
		"effects": {
			"bleed_chance": 0.1
		}
	})
	
	register_weapon({
		"id": "iron_longsword",
		"name": "Iron Longsword",
		"type": "sword",
		"damage": 15,
		"damage_type": "slashing",
		"range": 55,
		"stamina_cost": 22,
		"cooldown": 0.6,
		"weight": 4,
		"quality": 1.2,
		"value": 100,
		"hitbox": {
			"north": {"size": Vector2(45, 25), "offset": Vector2(0, -32)},
			"south": {"size": Vector2(45, 25), "offset": Vector2(0, 32)},
			"east": {"size": Vector2(25, 45), "offset": Vector2(32, 0)},
			"west": {"size": Vector2(25, 45), "offset": Vector2(-32, 0)}
		},
		"properties": {
			"can_parry": true,
			"two_handed": false
		},
		"effects": {
			"bleed_chance": 0.15
		}
	})
	
	# DAGGERS
	register_weapon({
		"id": "basic_dagger",
		"name": "Basic Dagger",
		"type": "dagger",
		"damage": 6,
		"damage_type": "piercing",
		"range": 30,
		"stamina_cost": 12,
		"cooldown": 0.3,
		"weight": 1,
		"quality": 1.0,
		"value": 25,
		"hitbox": {
			"north": {"size": Vector2(25, 15), "offset": Vector2(0, -20)},
			"south": {"size": Vector2(25, 15), "offset": Vector2(0, 20)},
			"east": {"size": Vector2(15, 25), "offset": Vector2(20, 0)},
			"west": {"size": Vector2(15, 25), "offset": Vector2(-20, 0)}
		},
		"properties": {
			"can_parry": false,
			"two_handed": false
		},
		"effects": {
			"critical_bonus": 0.1
		}
	})
	
	register_weapon({
		"id": "steel_dagger",
		"name": "Steel Dagger",
		"type": "dagger",
		"damage": 8,
		"damage_type": "piercing",
		"range": 30,
		"stamina_cost": 15,
		"cooldown": 0.3,
		"weight": 1,
		"quality": 1.0,
		"value": 75,
		"hitbox": {
			"north": {"size": Vector2(25, 15), "offset": Vector2(0, -25)},
			"south": {"size": Vector2(25, 15), "offset": Vector2(0, 25)},
			"east": {"size": Vector2(15, 25), "offset": Vector2(25, 0)},
			"west": {"size": Vector2(15, 25), "offset": Vector2(-25, 0)}
		},
		"properties": {
			"can_parry": false,
			"two_handed": false
		},
		"effects": {
			"critical_bonus": 0.15
		}
	})
	
	# AXES
	register_weapon({
		"id": "basic_axe",
		"name": "Basic Axe",
		"type": "axe",
		"damage": 12,
		"damage_type": "slashing",
		"range": 45,
		"stamina_cost": 25,
		"cooldown": 0.7,
		"weight": 4,
		"quality": 1.0,
		"value": 40,
		"hitbox": {
			"north": {"size": Vector2(40, 20), "offset": Vector2(0, -30)},
			"south": {"size": Vector2(40, 20), "offset": Vector2(0, 30)},
			"east": {"size": Vector2(20, 40), "offset": Vector2(30, 0)},
			"west": {"size": Vector2(20, 40), "offset": Vector2(-30, 0)}
		},
		"properties": {
			"can_parry": false,
			"two_handed": false
		},
		"effects": {
			"bleed_chance": 0.2
		}
	})
	
	# MACES
	register_weapon({
		"id": "basic_mace",
		"name": "Basic Mace",
		"type": "mace",
		"damage": 14,
		"damage_type": "bludgeoning",
		"range": 40,
		"stamina_cost": 22,
		"cooldown": 0.6,
		"weight": 4,
		"quality": 1.0,
		"value": 45,
		"hitbox": {
			"north": {"size": Vector2(35, 20), "offset": Vector2(0, -25)},
			"south": {"size": Vector2(35, 20), "offset": Vector2(0, 25)},
			"east": {"size": Vector2(20, 35), "offset": Vector2(25, 0)},
			"west": {"size": Vector2(20, 35), "offset": Vector2(-25, 0)}
		},
		"properties": {
			"can_parry": false,
			"two_handed": false
		},
		"effects": {
			"stun_chance": 0.15
		}
	})
	
	register_weapon({
		"id": "heavy_maul",
		"name": "Heavy Maul",
		"type": "mace",
		"damage": 20,
		"damage_type": "bludgeoning",
		"range": 50,
		"stamina_cost": 30,
		"cooldown": 0.9,
		"weight": 6,
		"quality": 1.3,
		"value": 120,
		"hitbox": {
			"north": {"size": Vector2(50, 30), "offset": Vector2(0, -35)},
			"south": {"size": Vector2(50, 30), "offset": Vector2(0, 35)},
			"east": {"size": Vector2(30, 50), "offset": Vector2(35, 0)},
			"west": {"size": Vector2(30, 50), "offset": Vector2(-35, 0)}
		},
		"properties": {
			"can_parry": false,
			"two_handed": true
		},
		"effects": {
			"stun_chance": 0.25
		}
	})
	
	# SPEARS
	register_weapon({
		"id": "basic_spear",
		"name": "Basic Spear",
		"type": "spear",
		"damage": 12,
		"damage_type": "piercing",
		"range": 70,  # Longer range
		"stamina_cost": 20,
		"cooldown": 0.5,
		"weight": 3,
		"quality": 1.0,
		"value": 40,
		"hitbox": {
			"north": {"size": Vector2(20, 50), "offset": Vector2(0, -40)},
			"south": {"size": Vector2(20, 50), "offset": Vector2(0, 40)},
			"east": {"size": Vector2(50, 20), "offset": Vector2(40, 0)},
			"west": {"size": Vector2(50, 20), "offset": Vector2(-40, 0)}
		},
		"properties": {
			"can_parry": true,
			"two_handed": true
		}
	})

# Register magical weapons
func register_magical_weapons():
	register_weapon({
		"id": "flame_blade",
		"name": "Flame Blade",
		"type": "sword",
		"damage": 18,
		"damage_type": "fire",
		"range": 55,
		"stamina_cost": 25,
		"cooldown": 0.6,
		"weight": 3,
		"quality": 1.5,
		"value": 500,
		"hitbox": {
			"north": {"size": Vector2(45, 25), "offset": Vector2(0, -32)},
			"south": {"size": Vector2(45, 25), "offset": Vector2(0, 32)},
			"east": {"size": Vector2(25, 45), "offset": Vector2(32, 0)},
			"west": {"size": Vector2(25, 45), "offset": Vector2(-32, 0)}
		},
		"properties": {
			"can_parry": true,
			"two_handed": false,
			"magical": true
		},
		"effects": {
			"dot_damage": 5,  # Damage over time
			"dot_type": "fire",
			"dot_duration": 3  # seconds
		}
	})
	
	register_weapon({
		"id": "frost_staff",
		"name": "Frost Staff",
		"type": "staff",
		"damage": 15,
		"damage_type": "cold",
		"range": 80,
		"stamina_cost": 30,
		"cooldown": 0.8,
		"weight": 4,
		"quality": 1.4,
		"value": 450,
		"hitbox": {
			"north": {"size": Vector2(50, 30), "offset": Vector2(0, -40)},
			"south": {"size": Vector2(50, 30), "offset": Vector2(0, 40)},
			"east": {"size": Vector2(30, 50), "offset": Vector2(40, 0)},
			"west": {"size": Vector2(30, 50), "offset": Vector2(-40, 0)}
		},
		"properties": {
			"can_parry": false,
			"two_handed": true,
			"magical": true,
			"ranged": true
		},
		"effects": {
			"slow_chance": 0.3,
			"slow_amount": 0.5,  # 50% slow
			"slow_duration": 2  # seconds
		}
	})

# Register legendary weapons
func register_legendary_weapons():
	register_weapon({
		"id": "excalibur",
		"name": "Excalibur",
		"type": "sword",
		"damage": 30,
		"damage_type": "slashing",
		"range": 60,
		"stamina_cost": 25,
		"cooldown": 0.5,
		"weight": 3,
		"quality": 2.0,
		"value": 2000,
		"hitbox": {
			"north": {"size": Vector2(60, 30), "offset": Vector2(0, -40)},
			"south": {"size": Vector2(60, 30), "offset": Vector2(0, 40)},
			"east": {"size": Vector2(30, 60), "offset": Vector2(40, 0)},
			"west": {"size": Vector2(30, 60), "offset": Vector2(-40, 0)}
		},
		"properties": {
			"can_parry": true,
			"two_handed": false,
			"legendary": true
		},
		"effects": {
			"bleed_chance": 0.3,
			"critical_bonus": 0.2,
			"healing_on_hit": 2
		}
	})

# Helper function to register a weapon in the catalog
func register_weapon(data: Dictionary):
	# Create a new weapon using the blueprint as base
	var weapon = WEAPON_BLUEPRINT.duplicate(true)
	
	# Ensure weapon has an ID
	if not data.has("id"):
		push_error("Weapon missing ID, skipping registration")
		return
	
	# Transfer all provided data to the weapon
	for key in data:
		if key == "hitbox" or key == "properties" or key == "effects":
			# For nested dictionaries, we need to merge them
			for subkey in data[key]:
				weapon[key][subkey] = data[key][subkey]
		else:
			weapon[key] = data[key]
	
	# Register in catalog
	weapon_catalog[data.id] = weapon

# Calculate damage for a weapon based on character stats
func calculate_weapon_damage(weapon: Dictionary, character_stats) -> Dictionary:
	# Get the primary ability for this weapon type
	var ability_name = WEAPON_ABILITY_MAP.get(weapon.type, "strength")
	var ability_value = character_stats.get(ability_name)
	var ability_mod = character_stats.get_ability_modifier(ability_value)
	
	# Calculate base damage
	var base_damage = weapon.damage
	var quality_multiplier = weapon.quality
	var ability_bonus = ability_mod
	
	# Calculate final damage
	var damage = (base_damage * quality_multiplier) + ability_bonus
	
	# Calculate critical chance and damage
	var crit_chance = 0.05  # Base 5% chance
	var crit_bonus = 0.5   # Base +50% damage
	
	# Add DEX bonus to crit chance
	var dex_mod = character_stats.get_ability_modifier(character_stats.dexterity)
	crit_chance += dex_mod * 0.02  # +2% per DEX mod
	
	# Add weapon's critical bonus
	if weapon.effects.has("critical_bonus"):
		crit_bonus += weapon.effects.critical_bonus
	
	# Return all calculated values
	return {
		"damage": int(damage),
		"crit_chance": crit_chance,
		"crit_bonus": crit_bonus,
		"ability_used": ability_name,
		"weapon_type": weapon.type,
		"damage_type": weapon.damage_type
	}

# Get preferred animation name for a weapon
func get_attack_animation_name(weapon: Dictionary, facing_direction: String) -> String:
	var base_name = "attack_"
	
	# Add weapon-specific prefix
	match weapon.type:
		"sword": base_name += "slash_"
		"axe": base_name += "chop_"
		"dagger": base_name += "stab_"
		"mace": base_name += "crush_"
		"spear": base_name += "thrust_"
		"bow": base_name += "shoot_"
		"staff", "wand": base_name += "cast_"
		_: base_name += "slash_"  # Default
	
	return base_name + facing_direction

# Process weapon effects on a successful hit
func process_weapon_effects(weapon: Dictionary, target, character_stats = null):
	# Process standard effects
	if weapon.effects.has("bleed_chance") and weapon.effects.bleed_chance > 0:
		if randf() < weapon.effects.bleed_chance and target.has_method("set_status_effect"):
			target.set_status_effect("bleeding", true)
			print("Target is bleeding!")
	
	if weapon.effects.has("stun_chance") and weapon.effects.stun_chance > 0:
		if randf() < weapon.effects.stun_chance and target.has_method("set_status_effect"):
			target.set_status_effect("stunned", true)
			print("Target is stunned!")
	
	# Process magical effects
	if weapon.properties.has("magical") and weapon.properties.magical:
		# Apply damage over time effects
		if weapon.effects.has("dot_damage"):
			if target.has_method("apply_dot"):
				target.apply_dot(
					weapon.effects.dot_damage,
					weapon.effects.dot_type,
					weapon.effects.dot_duration
				)
			elif target.has_method("set_status_effect"):
				# Fallback for enemies without full DOT support
				match weapon.effects.dot_type:
					"fire": target.set_status_effect("burning", true)
					"poison": target.set_status_effect("poisoned", true)
		
		# Apply slow effects
		if weapon.effects.has("slow_chance") and weapon.effects.has("slow_amount"):
			if randf() < weapon.effects.slow_chance and target.has_method("apply_slow"):
				target.apply_slow(
					weapon.effects.slow_amount,
					weapon.effects.slow_duration
				)
	
	# Process legendary effects
	if weapon.properties.has("legendary") and weapon.properties.legendary:
		# Healing on hit
		if weapon.effects.has("healing_on_hit") and character_stats != null:
			if character_stats.has_method("heal"):
				character_stats.heal(weapon.effects.healing_on_hit)
