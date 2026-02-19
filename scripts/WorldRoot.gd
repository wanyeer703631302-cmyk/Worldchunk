extends Node2D

@onready var player := $Player

func _ready():
	player.position = Vector2(128, 128)
