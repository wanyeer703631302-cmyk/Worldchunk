extends CharacterBody2D

const GameConstants = preload("res://scripts/GameConstants.gd")
const ProjectileScene = preload("res://scenes/Projectile.tscn")

@export var health := 30
@export var max_health := 30
@export var attack_attribute := GameConstants.Attribute.FIRE
@export var attack_interval := 2.0
@export var vulnerable_to := [GameConstants.Attribute.ICE]
@export var speed := 80.0
@export var detection_range := 300.0
@export var attack_range := 150.0

# AI States
enum State {
	IDLE,
	CHASE,
	ATTACK
}
var current_state = State.IDLE

@onready var player: Node2D = get_tree().get_root().find_child("Player", true, false)
@onready var charge_indicator = $ChargeIndicator
@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

func _ready():
	# 初始化 HealthBar
	if health_bar:
		health_bar.init_health(health, health) # Max health assumed same as init health
		
	# Attack Timer is now managed by State Machine or separate logic
	# We'll keep the timer for attack cooldown but control it via state
	var timer := Timer.new()
	timer.wait_time = attack_interval
	timer.autostart = true
	timer.timeout.connect(_on_attack_timer)
	add_child(timer)
	
	# Set color based on attribute
	sprite.modulate = GameConstants.ATTRIBUTE_COLORS.get(attack_attribute, Color.WHITE).darkened(0.2)

func _physics_process(delta):
	if not is_instance_valid(player):
		current_state = State.IDLE
		return
		
	var dist = global_position.distance_to(player.global_position)
	
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			if dist < detection_range:
				current_state = State.CHASE
		State.CHASE:
			if dist < attack_range:
				current_state = State.ATTACK
				velocity = Vector2.ZERO
			elif dist > detection_range * 1.5:
				current_state = State.IDLE
				velocity = Vector2.ZERO
			else:
				var dir = (player.global_position - global_position).normalized()
				velocity = dir * speed
		State.ATTACK:
			velocity = Vector2.ZERO
			if dist > attack_range * 1.2:
				current_state = State.CHASE
	
	move_and_slide()

func _on_attack_timer():
	if current_state == State.ATTACK and is_instance_valid(player):
		_start_attack_sequence()

func _start_attack_sequence():
	if not is_instance_valid(player): return
	
	# Telegraphing (蓄力预警)
	charge_indicator.visible = true
	var tween = create_tween()
	tween.tween_property(charge_indicator, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(charge_indicator, "scale", Vector2(0.1, 0.1), 0.2)
	
	await tween.finished
	charge_indicator.visible = false
	charge_indicator.scale = Vector2(1, 1)
	
	_fire_projectile()

func _fire_projectile():
	if not is_instance_valid(player):
		return
		
	var proj = ProjectileScene.instantiate()
	proj.attribute = attack_attribute
	
	var dir: Vector2 = (player.position - position).normalized()
	proj.position = position
	proj.direction = dir
	proj.rotation = dir.angle()
	
	# Visual Color Override
	var mesh = proj.get_node_or_null("MeshInstance2D")
	if mesh:
		mesh.modulate = GameConstants.ATTRIBUTE_COLORS.get(attack_attribute, Color.WHITE)
	
	get_parent().add_child(proj) # Add to container, not self

func receive_melee_hit(damage: int, weapon_attr: int):
	var final_damage := damage
	if weapon_attr != GameConstants.Attribute.NONE and (weapon_attr in vulnerable_to):
		final_damage = int(round(damage * 2.0))
		# Visual feedback for Critical Hit
		var label = Label.new()
		label.text = "CRIT!"
		label.modulate = Color.YELLOW
		label.position = Vector2(-20, -60)
		add_child(label)
		var t = create_tween()
		t.tween_property(label, "position:y", -80.0, 0.5)
		t.tween_callback(label.queue_free)
		
	health -= final_damage
	
	if health_bar:
		health_bar.update_health(health, max_health)
		health_bar.show_damage(final_damage)
		
	# Hit Flash
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", GameConstants.ATTRIBUTE_COLORS.get(attack_attribute, Color.WHITE).darkened(0.2), 0.2)
	
	if health <= 0:
		queue_free()
