extends CharacterBody2D

# 引用 GameConstants
const GameConstants = preload("res://scripts/GameConstants.gd")

@export var speed := 120.0
@export var health := 100
@export var max_health := 100

# 战斗状态
enum State {
	IDLE,
	MOVE,
	ATTACK,
	PARRY
}

var current_state = State.IDLE

# 武器属性系统
var weapon_attribute = GameConstants.Attribute.NONE
var attribute_buff_timer: Timer = null
const BUFF_DURATION := 8.0 # 6-10秒

# 格挡相关
var parry_window := 0.2 # 0.2秒完美格挡窗口
var parry_timer: Timer = null

func _ready():
	# 初始化 Buff 计时器
	attribute_buff_timer = Timer.new()
	attribute_buff_timer.one_shot = true
	attribute_buff_timer.timeout.connect(_on_buff_timeout)
	add_child(attribute_buff_timer)
	
	# 初始化 格挡 计时器
	parry_timer = Timer.new()
	parry_timer.one_shot = true
	parry_timer.timeout.connect(_on_parry_end)
	add_child(parry_timer)

func _physics_process(delta):
	if current_state == State.ATTACK or current_state == State.PARRY:
		# 攻击或格挡硬直中不能移动
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if input.length() > 0.1:
		current_state = State.MOVE
		input = input.normalized()
		velocity = input * speed
	else:
		current_state = State.IDLE
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# 处理输入
	_handle_combat_input()

func _handle_combat_input():
	if Input.is_action_just_pressed("ui_accept"): # 假设 Space 为格挡
		start_parry()
	elif Input.is_action_just_pressed("ui_select"): # 假设 Enter/Z 为攻击
		start_attack()

func start_parry():
	if current_state == State.PARRY: return
	current_state = State.PARRY
	print("Combat: Starting Parry Attempt!")
	parry_timer.start(parry_window)
	# TODO: 播放格挡动画

func _on_parry_end():
	if current_state == State.PARRY:
		current_state = State.IDLE
		print("Combat: Parry Window Closed (Missed)")

func start_attack():
	if current_state == State.ATTACK: return
	current_state = State.ATTACK
	print("Combat: Attacking with Attribute: ", GameConstants.Attribute.keys()[weapon_attribute])
	# 简单攻击后摇
	await get_tree().create_timer(0.4).timeout
	current_state = State.IDLE

# 受到攻击的核心逻辑
func take_damage(amount: int, attack_attribute: int):
	if current_state == State.PARRY:
		# 判定成功：精准格挡！
		print("Combat: PERFECT PARRY! Incoming: ", GameConstants.Attribute.keys()[attack_attribute])
		_apply_weapon_attribute(attack_attribute)
		# 格挡成功后立即恢复行动
		current_state = State.IDLE
		parry_timer.stop()
		return
	
	# 受伤逻辑
	health -= amount
	print("Combat: Took Damage! Health: ", health)
	if health <= 0:
		die()

# 核心机制：格挡成功赋予武器属性
func _apply_weapon_attribute(new_attr: int):
	if new_attr == GameConstants.Attribute.NONE: return
	
	weapon_attribute = new_attr
	attribute_buff_timer.start(BUFF_DURATION)
	print("Combat: Weapon Imbued with ", GameConstants.Attribute.keys()[new_attr], " for ", BUFF_DURATION, "s")
	# TODO: 更新武器视觉特效

func _on_buff_timeout():
	weapon_attribute = GameConstants.Attribute.NONE
	print("Combat: Weapon Attribute Buff Expired")

func die():
	print("Player Died")
	queue_free()
