extends CharacterBody2D

const GameConstants = preload("res://scripts/GameConstants.gd")
const ProjectileScript = preload("res://scripts/Projectile.gd")

@export var health := 30
@export var attack_attribute := GameConstants.Attribute.FIRE
@export var attack_interval := 2.0
@export var vulnerable_to := [GameConstants.Attribute.ICE]

@onready var player := get_tree().get_root().find_node("Player", true, false)

func _ready():
	var timer := Timer.new()
	timer.wait_time = attack_interval
	timer.autostart = true
	timer.timeout.connect(_attack)
	add_child(timer)

func _attack():
	if not is_instance_valid(player):
		return
	var proj := Area2D.new()
	proj.set_script(ProjectileScript)
	proj.attribute = attack_attribute
	var dir := (player.position - position).normalized()
	proj.position = position
	proj.direction = dir
	proj.rotation = dir.angle()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6
	shape.shape = circle
	proj.add_child(shape)
	add_child(proj)

func receive_melee_hit(damage: int, weapon_attr: int):
	var final_damage := damage
	if weapon_attr != GameConstants.Attribute.NONE and (weapon_attr in vulnerable_to):
		final_damage = int(round(damage * 2.0))
	health -= final_damage
	if health <= 0:
		queue_free()
