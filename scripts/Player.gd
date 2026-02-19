extends CharacterBody2D

# 引用 GameConstants
const GameConstants = preload("res://scripts/GameConstants.gd")

@export var health := 100
@export var max_health := 100
@export var base_damage := 8

# 战斗状态
enum State {
	IDLE,
	MOVE,
	ATTACK,
	PARRY,
	DASH
}

var current_state = State.IDLE

# 移动属性
@export var speed := 120.0
@export var dash_speed := 400.0
@export var dash_duration := 0.2
@export var dash_cooldown := 1.0
var can_dash := true

# 武器属性系统
var weapon_attribute = GameConstants.Attribute.NONE
var attribute_buff_timer: Timer = null
const BUFF_DURATION := 8.0 # 6-10秒

# 格挡相关
var parry_window := 0.2 # 0.2秒完美格挡窗口
var parry_timer: Timer = null

# HealthBar
@onready var health_bar = $HealthBar

@onready var weapon_pivot = $WeaponPivot
@onready var weapon_visual = $WeaponPivot/WeaponVisual
@onready var parry_shield = $ParryShield

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

	# 初始化 HealthBar
	if health_bar:
		health_bar.init_health(health, max_health)

func _physics_process(delta):
	# 状态锁定
	if current_state == State.ATTACK or current_state == State.PARRY:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if current_state == State.DASH:
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
		
		# 武器跟随移动方向旋转
		weapon_pivot.rotation = lerp_angle(weapon_pivot.rotation, input.angle(), 15 * delta)
	else:
		current_state = State.IDLE
		velocity = Vector2.ZERO
	
	move_and_slide()
	_handle_combat_input(input)

func _handle_combat_input(input_dir: Vector2):
	if Input.is_action_just_pressed("ui_accept"): # Space: Parry
		start_parry()
	elif Input.is_action_just_pressed("ui_select"): # Enter/Z: Attack
		start_attack()
	elif Input.is_action_just_pressed("ui_focus_next") and can_dash and input_dir.length() > 0: # Tab/Shift: Dash
		start_dash(input_dir)

func start_dash(dir: Vector2):
	current_state = State.DASH
	can_dash = false
	velocity = dir * dash_speed
	
	# Visual feedback
	var ghost = weapon_visual.duplicate()
	get_parent().add_child(ghost)
	ghost.global_position = weapon_visual.global_position
	ghost.global_rotation = weapon_visual.global_rotation
	ghost.modulate.a = 0.5
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ghost.queue_free)
	
	print("Combat: Dash!")
	
	await get_tree().create_timer(dash_duration).timeout
	current_state = State.IDLE
	velocity = Vector2.ZERO
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func start_parry():
	if current_state == State.PARRY: return
	current_state = State.PARRY
	parry_shield.visible = true # 视觉反馈
	modulate = Color(0.5, 1.0, 0.5) 
	print("Combat: Parry Window OPEN (0.2s)")
	parry_timer.start(parry_window)

func _on_parry_end():
	if current_state == State.PARRY:
		current_state = State.IDLE
		parry_shield.visible = false
		modulate = Color.WHITE
		print("Combat: Parry Failed (Missed)")

func start_attack():
	if current_state == State.ATTACK: return
	current_state = State.ATTACK
	var attr_name = GameConstants.Attribute.keys()[weapon_attribute]
	print("Combat: Attack! Attribute: ", attr_name)
	
	# 攻击动作：武器向前突刺
	var original_pos = weapon_visual.position
	var tween = create_tween()
	tween.tween_property(weapon_visual, "position", Vector2(40, 0), 0.1)
	tween.tween_property(weapon_visual, "position", original_pos, 0.2)
	
	# 生成攻击判定
	var hitbox = Area2D.new()
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	shape.shape = rect
	hitbox.add_child(shape)
	
	# 将 hitbox 添加到 WeaponPivot 下，随方向旋转
	weapon_pivot.add_child(hitbox)
	hitbox.position = Vector2(40, 0)
	
	# 检查碰撞
	await get_tree().physics_frame
	await get_tree().physics_frame # 等待物理帧更新
	
	for body in hitbox.get_overlapping_bodies():
		if body.has_method("receive_melee_hit") and body != self:
			body.receive_melee_hit(10, weapon_attribute)
	
	hitbox.queue_free()
	
	await get_tree().create_timer(0.3).timeout
	current_state = State.IDLE

# 核心机制：精准格挡判定
func take_attribute_damage(amount: int, incoming_attr: int):
	if current_state == State.PARRY:
		# 判定成功
		print("Combat: >>> PERFECT PARRY! <<< Absorbed: ", GameConstants.Attribute.keys()[incoming_attr])
		_apply_weapon_attribute(incoming_attr)
		current_state = State.IDLE
		parry_shield.visible = false
		parry_timer.stop()
		modulate = Color.WHITE # 恢复颜色
		return
	
	# 判定失败
	health -= amount
	if health_bar:
		health_bar.update_health(health, max_health)
		health_bar.show_damage(amount)
		
	modulate = Color.RED # 受伤反馈
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	print("Combat: Hit! Damage: ", amount, " Remaining HP: ", health)
	if health <= 0:
		die()

func _apply_weapon_attribute(new_attr: int):
	if new_attr == GameConstants.Attribute.NONE: return
	
	weapon_attribute = new_attr
	attribute_buff_timer.start(BUFF_DURATION)
	
	# 视觉反馈：武器变色
	var color = GameConstants.ATTRIBUTE_COLORS.get(new_attr, Color.WHITE)
	weapon_visual.color = color
	parry_shield.color = color.lightened(0.5)
	parry_shield.color.a = 0.5
	
	print("Combat: Weapon Empowered with ", GameConstants.Attribute.keys()[new_attr])

func _on_buff_timeout():
	weapon_attribute = GameConstants.Attribute.NONE
	weapon_visual.color = Color(0.8, 0.8, 0.8, 1) # 恢复默认白/灰
	parry_shield.color = Color(0.2, 1, 0.2, 0.3) # 恢复默认绿盾
	print("Combat: Weapon Buff Faded")

func die():
	print("Player Died")
	queue_free()

func _spawn_melee_hitbox():
	var hb := Area2D.new()
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 12)
	cs.shape = rect
	hb.add_child(cs)
	hb.position = position + Vector2(20, 0)
	hb.body_entered.connect(func(body):
		if body.has_method("receive_melee_hit") and body != self:
			body.receive_melee_hit(base_damage, weapon_attribute)
	)
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = 0.1
	t.timeout.connect(hb.queue_free)
	hb.add_child(t)
	get_parent().add_child(hb)
	t.start()
