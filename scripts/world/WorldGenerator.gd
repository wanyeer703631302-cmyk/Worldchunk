extends Node

@export var chunk_scene: PackedScene

@export var chunk_size := Vector2(256, 256)
@export var chunk_count := Vector2i(3, 3)

var rng := RandomNumberGenerator.new()
var biome_data := load("res://data/biome_data.tres")

func _ready():
	rng.randomize()
	generate_demo_area()

func generate_demo_area():
	clear_world()
	generate_chunks()

func clear_world():
	var root := get_parent()
	for child in root.get_children():
		if child.name.ends_with("Container"):
			for n in child.get_children():
				n.queue_free()

func generate_chunks():
	var container := get_parent().get_node("ChunkContainer")

	for x in range(chunk_count.x):
		for y in range(chunk_count.y):
			var chunk := chunk_scene.instantiate()
			chunk.position = Vector2(
				x * chunk_size.x,
				y * chunk_size.y
			)
			# Load Biome Data
			var biomes = biome_data.get("biomes")
			if biomes and biomes is Array and biomes.size() > 0:
				var b: Dictionary = biomes[rng.randi_range(0, biomes.size() - 1)]
				
				var label: Label = chunk.get_node("Label")
				var rect: ColorRect = chunk.get_node("ColorRect")
				
				if label: label.text = str(b.get("name", "Unknown"))
				if rect: 
					# Generate random variation based on base color
					var base_color = Color(0.2, 0.6, 0.2) # Default green
					if b.get("name") == "wetlands": base_color = Color(0.2, 0.2, 0.6)
					elif b.get("name") == "forest": base_color = Color(0.1, 0.4, 0.1)
					
					rect.color = base_color.lightened(rng.randf() * 0.2)
					
					# Add random obstacles (Scaffold)
					_spawn_scaffold_obstacles(chunk, b.get("name"))
			
			container.add_child(chunk)

func _spawn_scaffold_obstacles(chunk: Node2D, biome_name: String):
	# Add simple walls or rocks
	var count = rng.randi_range(3, 8)
	for i in range(count):
		var obstacle = StaticBody2D.new()
		
		# Visual
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(32, 32)
		color_rect.color = Color(0.3, 0.3, 0.3) # Stone gray
		color_rect.position = Vector2(-16, -16) # Center pivot
		obstacle.add_child(color_rect)
		
		# Collider
		var shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(32, 32)
		shape.shape = rect_shape
		obstacle.add_child(shape)
		
		# Random Position in Chunk (avoid edges)
		obstacle.position = Vector2(
			rng.randf_range(32, 224),
			rng.randf_range(32, 224)
		)
		
		chunk.add_child(obstacle)
