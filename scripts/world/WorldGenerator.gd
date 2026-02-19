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
			
			container.add_child(chunk)
