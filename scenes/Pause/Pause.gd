extends CanvasLayer

signal pause_shown
signal pause_hidden
signal cheats_activated

onready var control = $Control
onready var cheats_label = $Cheats
onready var texture = $TextureRect
onready var transition = $Transition
onready var animation_player = $AnimationPlayer
onready var pause_button = $Control/Button

var pause_is_possible = true
var cheats = false setget set_cheats
var game_paused = false setget set_game_paused

func _ready():
	cheats_label.visible = self.cheats

func _input(_event):
	if Input.is_action_just_pressed("ui_cancel") and pause_is_possible and !Configuration.joypad_connected:
		self.game_paused = !self.game_paused
		
	if Input.is_action_just_pressed("joypay_start") and pause_is_possible and Configuration.joypad_connected:
		self.game_paused = !self.game_paused
	
	if self.game_paused:
		if Input.is_key_pressed(KEY_P) and Input.is_key_pressed(KEY_O) \
				and Input.is_key_pressed(KEY_K) and Input.is_key_pressed(KEY_E):
			self.cheats = true
			
		if Configuration.joypad_connected and Input.is_action_just_pressed("joypad_select"):
			self.cheats = true

func back_to_menu():
	cheats_label.visible = false
	control.visible = false
	texture.visible = false
	transition.fadeout()

func set_cheats(value):
	cheats = value
	if cheats:
		emit_signal("cheats_activated")
		cheats_label.visible = true

func set_game_paused(value):
	game_paused = value
	if game_paused:
		cheats_label.visible = self.cheats
		get_tree().paused = game_paused
		animation_player.play("pause_on")
		pause_button.grab_focus()
		emit_signal("pause_shown")
	else:
		cheats_label.visible = false
		animation_player.play("pause_off")
		emit_signal("pause_hidden")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "pause_off":
		get_tree().paused = game_paused

func _on_Transition_fadeout_finished(_transition_name):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(0))
	SoundFx.clear()
	get_tree().paused = false
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(ResourceLoader.Intro)
	
func _on_Help_help_hidden():
	pause_is_possible = true

func _on_Help_help_shown():
	pause_is_possible = false

func _on_Button_pressed():
	back_to_menu()

func _on_Button_focus_exited():
	# not really sure why this works, but it does
	if control.get_focus_owner() != null:
		pause_button.grab_focus()
	else:
		pause_button.grab_focus()

func _on_CancelButton_pressed():
	set_game_paused(false)
