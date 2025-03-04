extends Node2D

const RedStarParticle = preload("res://scenes/Effects/RedStar/RedStarParticle.tscn")
const GreenStarParticle = preload("res://scenes/Effects/GreenStar/GreenStarParticle.tscn")

onready var animation_player = $AnimationPlayer
onready var timer: Timer = $Timer
onready var recharge_timer: Timer = $RechargeTimer
onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
onready var raycast: RayCast2D = $RayCast2D
onready var detonation_sprite: Sprite = $LaserDetonationSprite
onready var ray_position: Position2D = $Position2D
onready var ray: Line2D = $Line2D

var can_shoot = true

func _process(_delta):
	# i guess this is where we should be able to track the right joystick and use it.
	var direction
	
	if !Configuration.joypad_connected:
		direction = (get_global_mouse_position() - global_position).normalized()
		
	if Configuration.joypad_connected:
		direction = Input.get_vector("joypad_rs_left", "joypad_rs_right", "joypad_rs_up", "joypad_rs_down")
		direction = direction.normalized()
		
	rotation = direction.angle()

func fire():
	if can_shoot and PlayerData.laser > 5:
		can_shoot = false
		PlayerData.laser -= .25
		animation_player.play("detonation")
		audio_player.play()
		if raycast.is_colliding():
			var body = raycast.get_collider()
			var point = raycast.get_collision_point()
			ray.set_point_position(1, to_local(point))
			var particles = null
			if body != null and body.is_in_group("EnemyHurtboxGroup"):
				body.health -= 1
				particles = GreenStarParticle.instance()
				if Configuration.low_end_hardware:
					particles.amount = 1
			else:
				particles = RedStarParticle.instance()
				if Configuration.low_end_hardware:
					particles.amount = 1
			particles.global_position = point
			particles.emitting = true
			get_tree().current_scene.add_child(particles)
		else:
			ray.set_point_position(1, get_local_mouse_position() * 200)
		ray.visible = true
		timer.start()
		recharge_timer.start()

func _on_Timer_timeout():
	ray.visible = false

func _on_RechargeTimer_timeout():
	can_shoot = true
