extends Node2D

signal player_can_open(lock)

export(int) var OPENING_EXPLOSIONS = 8

onready var closed_area = $ClosedArea
onready var sprite = $Sprite

const BigExplosionEffect = preload("res://scenes/Effects/BigExplosionEffect.tscn") 

export(String) var opened_by = ""
export(bool) var explodes_on_opening = false

var player_stats = ResourceLoader.player_stats
var can_open = false

func _process(delta):
	if can_open:
		emit_signal("player_can_open", self)

func _on_OpenerArea_body_entered(body):
	if body.is_in_group("PlayerGroup"):
		if player_stats.selected_item == opened_by:
			can_open = true

func _on_OpenerArea_body_exited(body):
	can_open = false

func open():
	if explodes_on_opening:
		var sprite_size = sprite.texture.get_size()
		for i in OPENING_EXPLOSIONS:
			var position = Vector2(
					global_position.x + rand_range(0, sprite_size.x / sprite.hframes), 
					global_position.y + rand_range((sprite_size.y / sprite.vframes) * -1, 0)
			)
			var explosion = BigExplosionEffect.instance()
			explosion.global_position = position
			yield(get_tree().create_timer(rand_range(0.0, 0.1)), "timeout")
			get_tree().current_scene.add_child(explosion)
	queue_free()
