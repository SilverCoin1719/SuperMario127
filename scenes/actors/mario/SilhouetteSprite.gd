tool
extends "res://scenes/actors/mario/FluddAnimSync.gd"


func _process(delta):
	if frames != mario_sprite.frames:
		frames = mario_sprite.frames
