extends Area2D

const GameConstants = preload("res://scripts/GameConstants.gd")

var speed = 200.0
var direction = Vector2.RIGHT
var damage = 10
var attribute = GameConstants.Attribute.NONE
var lifetime = 5.0

func _ready():
	# 碰撞检测
	body_entered.connect(_on_body_entered)
	
	# 自动销毁
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	# Setup visual if Polygon2D exists
	var poly = get_node_or_null("Visual")
	if poly:
		poly.color = GameConstants.ATTRIBUTE_COLORS.get(attribute, Color.WHITE)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_attribute_damage"):
		# 触发玩家的“属性伤害判定”
		body.take_attribute_damage(damage, attribute)
		queue_free()
	elif body.name != "Player": # 撞墙销毁
		queue_free()