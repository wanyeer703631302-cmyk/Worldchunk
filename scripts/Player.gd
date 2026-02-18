extends CharacterBody2D

@export var speed := 120.0

func _physics_process(delta):
	var input := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if input.length() > 1:
		input = input.normalized()

	velocity = input * speed
	move_and_slide()
