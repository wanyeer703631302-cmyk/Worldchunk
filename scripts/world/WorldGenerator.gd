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
			var biomes := biome_data.get("biomes")
			if biomes and biomes.size() > 0:
				var b := biomes[rng.randi_range(0, biomes.size() - 1)]
				var label := chunk.get_node("Label")
				var rect := chunk.get_node("ColorRect")
				label.text = b["name"]
				rect.color = Color(0.1 + rng.randf() * 0.4, 0.1 + rng.randf() * 0.4, 0.1 + rng.randf() * 0.4, 1.0)
			container.add_child(chunk)
