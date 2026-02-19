extends CharacterBody2D

const GameConstants = preload("res://scripts/GameConstants.gd")
const ProjectileScript = preload("res://scripts/Projectile.gd")

@export var health := 30
@export var attack_attribute := GameConstants.Attribute.FIRE
@export var attack_interval := 2.0
@export var vulnerable_to := [GameConstants.Attribute.ICE]

@onready var player: Node2D = get_tree().get_root().find_child("Player", true, false)

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
	
	var dir: Vector2 = (player.position - position).normalized()
	proj.position = position
	proj.direction = dir
	proj.rotation = dir.angle()
	
	# Visual
	var mesh = MeshInstance2D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 6
	mesh.mesh.height = 12
	mesh.modulate = GameConstants.ATTRIBUTE_COLORS.get(attack_attribute, Color.WHITE)
	proj.add_child(mesh)
	
	# Collider
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6
	shape.shape = circle
	proj.add_child(shape)
	
	get_parent().add_child(proj) # Add to container, not self

func receive_melee_hit(damage: int, weapon_attr: int):
	var final_damage := damage
	if weapon_attr != GameConstants.Attribute.NONE and (weapon_attr in vulnerable_to):
		final_damage = int(round(damage * 2.0))
	health -= final_damage
	if health <= 0:
		queue_free()
