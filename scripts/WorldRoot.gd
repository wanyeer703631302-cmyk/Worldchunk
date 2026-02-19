extends Node2D

@onready var player := $Player
@onready var encounter_container := $EncounterContainer
const EnemyScene := preload("res://scenes/Enemy.tscn")

func _ready():
	player.position = Vector2(128, 128)
	var enemy := EnemyScene.instantiate()
	enemy.position = Vector2(400, 300)
	encounter_container.add_child(enemy)
