extends GameObject

## My stinky poopoo ass forgot about inheritance smh

onready var attack_area = $Rex/AttackArea
onready var attack_area_small = $Rex/AttackAreaSmall
onready var hitbox_shape = $Rex/NormalShape
onready var hitbox_shape_small = $Rex/SquishedShape
onready var kinematic_body = $Rex
onready var sprite = $Rex/Sprite
onready var platform_detector = $Rex/PlatformDetector
onready var visibility_enabler = $VisibilityEnabler2D
onready var player_detector = $Rex/PlayerDetector
onready var stomp_area = $Rex/StompDetector
onready var stomp_area_small = $Rex/StompDetectorSmall
onready var stomp_sound = $Rex/Stomp
onready var anim_player = $Rex/AnimationPlayer
onready var hit_sound = $Rex/Hit
onready var bottom_pos = $Rex/BottomPos
onready var wall_check_cast = $Rex/WallCheck
onready var wall_check_cast2 = $Rex/WallCheck2
onready var poof_sound = $Rex/Disappear
onready var particles = $Rex/Poof
onready var collision_layer_area = $Rex/CollisionLayerArea
onready var ground_collision_left = $Rex/GroundCollisionL
onready var ground_collision_right = $Rex/GroundCollisionR

var gravity: float = 0.0
var gravity_scale: float = 1.0
var time_alive: float = 0.0

var boost_timer: = 0.0
var hide_timer: = 0.0
var delete_timer: = 0.0
var speed: = 80
var run_speed: = 200
var shell_max_speed: = 560
var accel: = 1.25
var jump_buffer = 0.0

var facing_direction: = -1

export var velocity: Vector2 = Vector2.ZERO
export var snap: Vector2 = Vector2(0, 12)
export var hit: = false
export var squish: = false
export var inv_timer: = -1.0
export var flicker_timer: = 0.0
var attack_timer: = 0.0

var character:Character

var loaded: = true
var dead: = false
var was_stomped: = false
var was_ground_pound: = false
var played_spin_anim_death: = false
var jumped: = false

export var top_point:Vector2

onready var raycasts = [wall_check_cast, wall_check_cast2]

func on_hide()->void :
	on_visibility_changed(false)

func on_show()->void :
	on_visibility_changed(true)

func _set_properties():
	savable_properties = ["squish"]
	editable_properties = ["squish"]
	
func _set_property_values():
	set_property("squish", squish, true)

func _ready():
	visibility_enabler.connect("screen_exited", self, "on_hide")
	visibility_enabler.connect("screen_entered", self, "on_show")
	on_visibility_changed(visibility_enabler.is_on_screen())
	
	player_detector.connect("body_entered", self, "detect_player")
	player_detector.scale = Vector2(1, 1) / scale
	Singleton.CurrentLevelData.enemies_instanced += 1
	time_alive += float(Singleton.CurrentLevelData.enemies_instanced) / 2.0
	gravity = Singleton.CurrentLevelData.level_data.areas[Singleton.CurrentLevelData.area].settings.gravity
	inv_timer = -1.0
	
	if scale.x < 0:
		scale.x = abs(scale.x)
		facing_direction = - facing_direction

func jump():
	position.y -= 2
	velocity.y = -80
	snap = Vector2.ZERO
	jumped = true

func create_coin()->void :
	var object: = LevelObject.new()
	object.type_id = 1
	object.properties = []
	object.properties.append(kinematic_body.global_position)
	object.properties.append(Vector2(1, 1))
	object.properties.append(0)
	object.properties.append(true)
	object.properties.append(true)
	object.properties.append(true)
	var velocity_x = - 80 if int(time_alive * 10) % 2 == 0 else 80
	object.properties.append(Vector2(velocity_x, - 300))
	get_parent().create_object(object, false)

func detect_player(body:Character)->void :
	if character == null and enabled and body != null and not dead:
		character = body
		
		facing_direction = sign(character.global_position.x - body.global_position.x)
		if kinematic_body.is_on_floor():
			jump()

func on_visibility_changed(is_visible:bool)->void :
	for raycast in raycasts:
		if is_instance_valid(raycast):
			raycast.enabled = is_visible

func reset_collision_layers():
	kinematic_body.set_collision_layer_bit(2, true)
	attack_area.set_collision_layer_bit(2, true)
	attack_area_small.set_collision_layer_bit(2, true)
	stomp_area.set_collision_layer_bit(2, true)
	kinematic_body.set_collision_mask_bit(2, true)
	attack_area.set_collision_mask_bit(2, true)
	attack_area_small.set_collision_mask_bit(2, true)
	stomp_area.set_collision_mask_bit(2, true)

func kill(hit_pos:Vector2):
	if not hit and not dead and enabled and inv_timer <= 0:
		if is_instance_valid(kinematic_body):
			kinematic_body.set_collision_layer_bit(2, false)
			stomp_area.set_collision_layer_bit(2, false)
			kinematic_body.set_collision_mask_bit(2, false)
			stomp_area.set_collision_mask_bit(2, false)
			attack_area.set_collision_mask_bit(2, false)
			attack_area_small.set_collision_mask_bit(2, false)
			
			if was_stomped:
				hit = true
				stomp_sound.play()
				velocity = Vector2()
				sprite.animation = "default"
				anim_player.play("Stomped", -1, 2.0)
				boost_timer = 0.05
				if was_ground_pound:
					squish = true
			else:
				hit_sound.play()
				inv_timer = 1.0
				flicker_timer = 0.01
				var normal: = sign((kinematic_body.global_position - hit_pos).x)
				velocity = Vector2(normal * 225, - 90)
				position.y -= 2
				snap = Vector2(0, 0)
				
				# if squish:
				# 	flicker_timer = 0
				# 	sprite.playing = false
				# 	hit = true
				# 	dead = true

func _physics_process(delta:float)->void :
	time_alive += delta
	
	sprite.animation = "walking" if not squish else "walking_squished"
	attack_area.get_node("Collision").disabled = squish
	attack_area_small.get_node("Collision").disabled = not squish
	hitbox_shape.disabled = squish
	hitbox_shape_small.disabled = not squish
	
	if (flicker_timer > 0):
		flicker_timer -= delta
		
		if (flicker_timer <= 0):
			flicker_timer = 0.015
			sprite.visible = not sprite.visible
	
	if hide_timer > 0:
		hide_timer -= delta
		
		if hide_timer <= 0:
			if squish:
				if (not played_spin_anim_death and kinematic_body.is_on_floor()):
					anim_player.play("Stomped", -1, 2.0)
					sprite.rotation_degrees = 0
					sprite.offset.y = 0
					sprite.position.y = 0
					hide_timer = 0.1
					played_spin_anim_death = true
					character = null
					dead = false
				else:
					dead = true
					hide_timer = 0
					particles.emitting = true
					particles.emitting = true
					sprite.visible = false
					flicker_timer = -1
					delete_timer = 1.25
					poof_sound.play()
					velocity = Vector2()
					create_coin()
			else:
				was_stomped = false
				was_ground_pound = false
				jumped = false
				flicker_timer = 0.01
				inv_timer = 1.0
				squish = true
				hit = false
				jump()
	
	if delete_timer > 0:
		delete_timer -= delta
		if delete_timer <= 0:
			delete_timer = 0
			queue_free()
			return 
	
	if not hit:
		if (inv_timer > 0):
			inv_timer -= delta
			
			if (inv_timer <= 0):
				sprite.visible = true
				flicker_timer = 0
				inv_timer = -1.0
		elif (inv_timer <= 0 and collision_layer_area.get_overlapping_bodies().empty()):
			reset_collision_layers()
	
	if mode != 1 and enabled and loaded:
		var is_in_platform: = false
		var platform_collision_enabled: = false
		for platform_body in platform_detector.get_overlapping_areas():
			if platform_body.has_method("is_platform_area"):
				if platform_body.is_platform_area():
					is_in_platform = true
				if platform_body.get_parent().has_method("can_collide_with") and platform_body.get_parent().can_collide_with(kinematic_body):
					platform_collision_enabled = true
		kinematic_body.set_collision_mask_bit(4, platform_collision_enabled)
		for raycast in raycasts:
			raycast.set_collision_mask_bit(4, platform_collision_enabled)
		
		if is_instance_valid(kinematic_body):
			visibility_enabler.global_position = kinematic_body.global_position
			if not hit:
				physics_process_normal(delta, is_in_platform)
			else:
				physics_process_hit(delta, is_in_platform)
	
	if was_stomped:
		if boost_timer > 0:
			if not was_ground_pound and is_instance_valid(character):
				character.velocity.y = 0
				if character.move_direction != 0:
					character.global_position.x += character.move_direction * 2
				top_point = $Rex/TopPos.position
				character.global_position.y = lerp(character.global_position.y, (kinematic_body.global_position.y + top_point.y) - 25, fps_util.PHYSICS_DELTA * 6)
				
				var lerp_strength = 15
				lerp_strength = clamp(abs(character.global_position.x - kinematic_body.global_position.x), 0, 15)
				character.global_position.x = lerp(character.global_position.x, kinematic_body.global_position.x, fps_util.PHYSICS_DELTA * lerp_strength)
			boost_timer -= delta
			
			if boost_timer <= 0:
				boost_timer = 0
				hide_timer = 0.1
				if not was_ground_pound and is_instance_valid(character):
					character.velocity.y = -325
					character.position.y -= 2
					if character.state != character.get_state_node("DiveState"):
						character.set_state_by_name("BounceState", delta)

func physics_process_hit(delta, is_in_platform: bool):
	velocity.y += gravity * gravity_scale
	velocity = kinematic_body.move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 4, deg2rad(46))
	
	if dead:
		sprite.rotation_degrees += (velocity.x / 15)
		sprite.offset.y = -8
		sprite.position.y = 8
			
		if (velocity.length_squared() == 0 and hide_timer <= 0 and delete_timer <= 0):
			hide_timer = 0.01

func reset_hit():
	if hide_timer > 0 or delete_timer > 0:
		return
	hit = false

func attempt_disappear():
	if not squish:
		return
	flicker_timer = -1
	inv_timer = -1
	hide_timer = 0.01
	hit = true

func physics_process_normal(delta, is_in_platform: bool):
	if not hit and not dead and inv_timer <= 0:
		var _stomp_area = stomp_area if not squish else stomp_area_small
		for hit_body in _stomp_area.get_overlapping_bodies():
			if hit_body.name.begins_with("Character"):
				if hit_body.velocity.y > 0 and not hit_body.swimming:
					was_stomped = true
					if hit_body.big_attack or hit_body.invincible:
						was_ground_pound = true
					kill(hit_body.global_position)
	
	var _attack_area = attack_area if not squish else attack_area_small
	if not hit and not dead and inv_timer <= 0:
		for hit_area in _attack_area.get_overlapping_areas():
			if hit_area.has_method("is_hurt_area"):
				kill(hit_area.global_position)
		
		for hit_body in _attack_area.get_overlapping_bodies():
			if hit_body.name.begins_with("Character"):
				if hit_body.invincible or hit_body.attacking:
					kill(hit_body.global_position)
				else:
					hit_body.damage_with_knockback(kinematic_body.global_position)
	
	if is_instance_valid(character):
		facing_direction = sign(character.global_position.x - kinematic_body.global_position.x)
	else:
		wall_check_cast.cast_to = Vector2(10 * facing_direction, 0)
		wall_check_cast2.cast_to = Vector2(10 * facing_direction, 0)
		if wall_check_cast.is_colliding() or wall_check_cast2.is_colliding() or kinematic_body.is_on_wall():
			facing_direction *= -1
			position.x += 2 * facing_direction
	
	var _spd = speed if not squish else run_speed
	sprite.speed_scale = 1 if not squish else 1.25
	sprite.flip_h = (true if (facing_direction > 0) else false) if (facing_direction != 0) else sprite.flip_h
	velocity.x = lerp(velocity.x, facing_direction * _spd, fps_util.PHYSICS_DELTA * accel)
	
	if kinematic_body.is_on_floor():
		if (velocity.y >= 0):
			jumped = false
		snap = Vector2(0, 0 if is_in_platform or jumped else 12)
	else:
		velocity.y += gravity * gravity_scale
		snap = Vector2.ZERO
	
	velocity = kinematic_body.move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 4, deg2rad(46))
