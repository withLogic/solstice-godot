extends KinematicBody2D

const Accept = preload("res://scenes/Player/accept.ogg")
const Hurt = preload("res://scenes/Player/hurt.ogg")
const Explosion = preload("res://scenes/Effects/explosion.ogg")
const ThrustUp = preload("res://scenes/Player/thrustup.ogg")
const LaserUp = preload("res://scenes/Player/laserup.ogg")

onready var laser = $Laser
onready var invincible_timer = $InvincibleTimer
onready var damage_timer = $DamageTimer
onready var sprite : Sprite = $Sprite
onready var big_explosion = $BigExplosionParticles
onready var particles : CPUParticles2D = $SmokeParticles
onready var damage_particles : CPUParticles2D = $DamageParticles
onready var animation_player : AnimationPlayer = $AnimationPlayer
onready var rebuild_particles : CPUParticles2D = $RebuildParticles
onready var rebuild_timer: Timer = $RebuildTimer
onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

export(int) var ACCELERATION = 400
export(int) var MAX_SPEED = 80
export(int) var GRAVITY = 150
export(float) var FRICTION = .2

signal item_picked(item)
signal item_used

enum Facing {
	LEFT, RIGHT
}

var motion = Vector2.ZERO
var facing = Facing.RIGHT
var is_in_magnetic_area = false
var item_definitions = ResourceLoader.item_defs.definitions

func _ready():
	ResourceLoader.player = self
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	if Input.is_action_pressed("primary"):
		laser.fire()
	
	if Input.is_action_pressed("secondary"):
		var selected_item = PlayerData.selected_item
		match selected_item:
			"redbarrel":
				audio_player.stream = ThrustUp
				audio_player.play()
				PlayerData.thrust = PlayerData.MAX_THRUST
				emit_signal("item_used")
			"battery":
				audio_player.stream = LaserUp
				audio_player.play()
				PlayerData.laser = PlayerData.MAX_LASER
				emit_signal("item_used")

func _physics_process(delta):
	var input_vector = get_input_vector()
	apply_horizontal_force(input_vector, delta)
	apply_vertical_force(input_vector, delta)
	apply_friction(input_vector)
	apply_gravity(delta)
	update_animation(input_vector)
	motion = move_and_slide(motion, Vector2.UP)

func get_input_vector():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	if Input.get_action_strength("up") and PlayerData.thrust > 5:
		input_vector.y = -1
		particles.emitting = true
		PlayerData.thrust -= .025
	else:
		particles.emitting = false
	if input_vector.x < 0:
		facing = Facing.LEFT
	elif input_vector.x > 0:
		facing = Facing.RIGHT
	return input_vector

func apply_horizontal_force(input_vector, delta):
	if input_vector != Vector2.ZERO:
		motion.x += input_vector.x * ACCELERATION * delta
		motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)

func apply_vertical_force(input_vector, delta):
	if not is_in_magnetic_area:
		motion.y += input_vector.y * ACCELERATION * delta
		motion.y = clamp(motion.y, -MAX_SPEED, MAX_SPEED)
	else:
		motion.y -= ACCELERATION * delta
		motion.y = clamp(motion.y, -MAX_SPEED, MAX_SPEED)

func apply_friction(input_vector):
	if input_vector == Vector2.ZERO && is_on_floor():
		motion.x = lerp(motion.x, 0, FRICTION)

func apply_gravity(delta):
	if !is_on_floor() and !is_in_magnetic_area and PlayerData.status != PlayerData.Status.TELEPORT:
		motion.y += GRAVITY * delta

func update_animation(input_vector):
	var current_animation = animation_player.current_animation
	if facing == Facing.LEFT:
		animation_player.play_backwards(current_animation)
	elif facing == Facing.RIGHT:
		animation_player.play(current_animation)

func on_item_picked(item):
	audio_player.stream = Accept
	audio_player.play()
	if PlayerData.selected_item != null:
		create_new_item(item)
	PlayerData.selected_item = item.item_name
	item.queue_free()
	emit_signal("item_picked", item_definitions[PlayerData.selected_item].texture)

func create_new_item(item):
	var item_scene = item_definitions[PlayerData.selected_item].scene.instance()
	item_scene.global_position = item.global_position
	item_scene.connect("item_picked", self, "on_item_picked")
	get_tree().current_scene.add_child(item_scene)
	
func on_lock_opened(lock):
	emit_signal("item_used")

func on_teleporter_charged(teleporter_group, teleporter):
	emit_signal("item_used")

func on_teleporter_activated(teleporter_group, teleporter):
	PlayerData.status = PlayerData.Status.TELEPORT
	set_process(false)
	set_physics_process(false)
	for tele in teleporter_group.get_children():
		if tele.name != teleporter.name and tele is Teleporter:
			yield(get_tree().create_timer(.4), "timeout")
			global_position.x = tele.global_position.x + 24
			global_position.y  = tele.global_position.y - 16
			tele.particles.emitting = true
			yield(get_tree().create_timer(.4), "timeout")
			PlayerData.status = PlayerData.Status.OK
			set_process(true)
			set_physics_process(true)

func on_pass_dispatched(dispatcher):
	PlayerData.health = 0
	create_teleporter_pass(dispatcher.spawner.global_position)

func create_teleporter_pass(position: Vector2):
	var item_scene = item_definitions["teleportpass"].scene.instance()
	item_scene.global_position = position
	item_scene.connect("item_picked", self, "on_item_picked")
	get_tree().current_scene.add_child(item_scene)

func on_nuclear_waste_stored(storage):
	emit_signal("item_used")

func on_player_destroyed():
	set_physics_process(false)
	set_process(false)
	big_explosion.global_position = global_position
	big_explosion.emitting = true
	audio_player.stream = Explosion
	audio_player.play()
	PlayerData.invincible = true
	animation_player.play("rebuilding")
	PlayerData.lives -= 1
	PlayerData.health = PlayerData.MAX_HEALTH
	rebuild_particles.emitting = true
	rebuild_timer.start()

func _on_DamageTimer_timeout():
	PlayerData.status = PlayerData.Status.OK

func _on_InvincibleTimer_timeout():
	PlayerData.invincible = false
	PlayerData.status = PlayerData.Status.OK

func on_enemy_attacked(damage):
	if not PlayerData.invincible:
		damage_particles.emitting = true
		audio_player.stream = Hurt
		audio_player.play()
		PlayerData.health -= damage
		PlayerData.status = PlayerData.Status.DAMAGED

func on_status_changed(old_status, new_status):
	if old_status != new_status:
		match new_status:
			PlayerData.Status.OK:
				animation_player.play("rotation")
			PlayerData.Status.DAMAGED:
				animation_player.play("hurt")
				damage_timer.start()
			PlayerData.Status.DESTROYED:
				animation_player.play("destroyed")
			PlayerData.Status.TELEPORT:
				animation_player.play("teleport")
			PlayerData.Status.INVINCIBLE:
				invincible_timer.start()
	if PlayerData.invincible:
		animation_player.play("invincible")

func on_item_used():
	PlayerData.selected_item = null

func on_explosion_triggered():
	pass

func on_player_has_to_move(direction):
	if direction == 0:
		motion.x = Vector2.LEFT.x * 75
	else:
		motion.x = Vector2.RIGHT.x * 75

func _on_RebuildTimer_timeout():
	set_physics_process(true)
	set_process(true)
	PlayerData.status = PlayerData.Status.INVINCIBLE
	PlayerData.invincible = true
