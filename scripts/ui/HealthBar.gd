extends Control

@onready var progress_bar = $ProgressBar
@onready var damage_label = $DamageLabel

func init_health(health: int, max_health: int):
	progress_bar.max_value = max_health
	progress_bar.value = health
	_update_color(health, max_health)

func update_health(health: int, max_health: int):
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", health, 0.2).set_trans(Tween.TRANS_SINE)
	_update_color(health, max_health)

func _update_color(health: int, max_health: int):
	var ratio = float(health) / float(max_health)
	if ratio > 0.5:
		progress_bar.modulate = Color.GREEN
	elif ratio > 0.2:
		progress_bar.modulate = Color.YELLOW
	else:
		progress_bar.modulate = Color.RED

func show_damage(amount: int):
	var label = damage_label.duplicate()
	add_child(label)
	label.text = str(amount)
	label.visible = true
	label.position = Vector2(0, -20)
	label.modulate = Color(1, 0, 0, 1)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30, 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	await tween.finished
	label.queue_free()
