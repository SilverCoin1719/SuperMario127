#Note: when the enter or exit animation starts, it sets the characters controllable and invulnerable variables, make sure to set them back in the parent code
extends Node2D

signal pipe_animation_finished

onready var area2d : Area2D = $Area2D
onready var tween : Tween = $Tween
onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer

onready var collision_width : float = $Area2D/CollisionShape2D.shape.extents.x

const PIPE_BOTTOM_DISTANCE := 35

export (float) var slide_to_center_length := 1.0
export (float) var entering_pipe_length := 1.0 
export (float) var exiting_pipe_length := 1.0

var is_idle := true

var stored_character : Character

func _physics_process(_delta : float) -> void:
	if is_idle:
		#the area2d is set to only collide with characters, so we can (hopefullY) safely assume if there 
		#is a collision it's with a character
		for body in area2d.get_overlapping_bodies(): 
			if global_rotation == 0 and body.is_grounded() and body.get_input(Character.input_names.crouch, true) and get_parent().enabled:
				start_pipe_enter_animation(body)

func start_pipe_ground_pound_animation(_character : Character) -> void:
	pass #to be implemented
	
func start_pipe_enter_animation(character : Character) -> void:
	stored_character = character 

	is_idle = false

	character.invulnerable = true 
	character.controllable = false
	character.movable = false
	character.sprite.rotation = 0
	character.global_position.y = global_position.y + -22
	
	character.sprite.animation = "pipe" + ("Right" if character.facing_direction == 1 else "Left")
	character.sprite.playing = true

	var slide_length : float = slide_to_center_length

	#calculate the amount of time it should take based on the players distance from the center
	var distance_from_center_normalized : float = abs((character.position.x - global_position.x)) / collision_width 
	distance_from_center_normalized = clamp(distance_from_center_normalized, 0.1, 1)
	slide_length = slide_to_center_length * distance_from_center_normalized

	# warning-ignore: return_value_discarded
	tween.interpolate_property(character, "position:x", null, global_position.x, slide_length)
	# warning-ignore: return_value_discarded
	tween.interpolate_property(character, "position:y", null, global_position.y + PIPE_BOTTOM_DISTANCE, \
			entering_pipe_length, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, slide_length)
	# warning-ignore: return_value_discarded
	tween.interpolate_callback(audio_player, slide_length, "play")

	# warning-ignore: return_value_discarded
	tween.start()

func start_pipe_exit_animation(character : Character) -> void:
	stored_character = character

	is_idle = false	

	character.invulnerable = true 
	character.controllable = false
	character.movable = false

	# warning-ignore: return_value_discarded
	tween.interpolate_property(character, "position:y", global_position.y + PIPE_BOTTOM_DISTANCE, \
			global_position.y, exiting_pipe_length)
	#this next line is kinda janky but hopefully it should set the animation after the above property
	#finishes animating, basically it has duration 0 and a delay the same length as the duration of the above line
	# warning-ignore: return_value_discarded
	tween.interpolate_property(character.sprite, "animation", null, "pipeExit" + \
			("Right" if character.facing_direction == 1 else "Left"), 0, 0, 2, exiting_pipe_length)

	# warning-ignore: return_value_discarded
	tween.start()

func _tween_all_completed() -> void:
	emit_signal("pipe_animation_finished", stored_character)	

	stored_character = null