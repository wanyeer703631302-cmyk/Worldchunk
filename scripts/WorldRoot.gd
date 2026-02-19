extends Node2D

@onready var player := $Player
@onready var encounter_container := $EncounterContainer
const EnemyScene := preload("res://scenes/Enemy.tscn")

const GameConstants = preload("res://scripts/GameConstants.gd")

func _ready():
	player.position = Vector2(128, 128)
	
	# Spawn Fire Enemy (Red, Weak to Ice)
	var enemy1 := EnemyScene.instantiate()
	enemy1.position = Vector2(400, 300)
	enemy1.attack_attribute = GameConstants.Attribute.FIRE
	enemy1.vulnerable_to = [GameConstants.Attribute.ICE]
	encounter_container.add_child(enemy1)
	
	# Spawn Ice Enemy (Blue, Weak to Fire)
	var enemy2 := EnemyScene.instantiate()
	enemy2.position = Vector2(600, 300)
	enemy2.attack_attribute = GameConstants.Attribute.ICE
	enemy2.vulnerable_to = [GameConstants.Attribute.FIRE]
	encounter_container.add_child(enemy2)
