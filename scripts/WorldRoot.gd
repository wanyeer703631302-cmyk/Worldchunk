extends Node2D

const GameConstants = preload("res://scripts/GameConstants.gd")
const ProjectileScript = preload("res://scripts/Projectile.gd") # User needs to create this

@onready var player := $Player

func _ready():
	player.position = Vector2(128, 128)
	
	# DEBUG: Spawn a test projectile every 3 seconds
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true
	timer.timeout.connect(_spawn_test_projectile)
	add_child(timer)

func _spawn_test_projectile():
	if not is_instance_valid(player): return
	
	# Simulate an enemy shooting a FIRE projectile
	var proj = Area2D.new()
	var sprite = Sprite2D.new() # Placeholder visual
	# In a real game, use a packed scene
	
	# Add script dynamically for testing if file exists, 
	# but better to assume Projectile.gd is created.
	proj.set_script(ProjectileScript)
	
	# Setup Projectile
	proj.attribute = GameConstants.Attribute.FIRE
	proj.direction = (player.position - Vector2(300, 300)).normalized() # From fixed point
	proj.position = Vector2(300, 300) # Spawn from corner
	proj.rotation = proj.direction.angle()
	
	# Visual debug
	var mesh = MeshInstance2D.new()
	mesh.mesh = QuadMesh.new()
	mesh.mesh.size = Vector2(20, 5)
	mesh.modulate = Color.RED
	proj.add_child(mesh)
	
	# Collision
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 5
	proj.add_child(shape)
	
	add_child(proj)
	print("Debug: Fired FIRE projectile at Player")
    GameConstants.Attribute.keys()[random_attr])