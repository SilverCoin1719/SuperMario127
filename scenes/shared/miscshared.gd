extends Node
# This node was created to fix issues related to loading/unloading scenes

# For rainbow breakable boxes
var rainbow_gradient_texture := GradientTexture.new()
var rainbow_gradient := Gradient.new()
var rainbow_hue := 0.0

func _physics_process(delta: float) -> void:
	# Handle rainbow gradient
	rainbow_hue += 0.0075 * delta * 120
	rainbow_gradient.offsets = PoolRealArray([0, 0.5])
	rainbow_gradient.colors = PoolColorArray([Color.from_hsv(rainbow_hue, 1.35, 0.65), Color(1, 1, 1)])
	rainbow_gradient_texture.gradient = rainbow_gradient