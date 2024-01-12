extends Node2D

onready var timer = $Timer
onready var transition = $Transition

const VERSION = "1.0.4"

func _ready():
	var number_of_joypads_connected
	
	print("Solstice " + VERSION + " is running...")
	set_mouse_cursor()
	Configuration.load_and_save_config()
	transition.fadein()
	
	number_of_joypads_connected = Input.get_connected_joypads().size()
	if number_of_joypads_connected > 0:
		Configuration.set_joypad_connected(true)
		
	# Low End Hardware caps the target framerate at 30fps
	# Also reduces the CPU Particle effects
	if OS.get_name() == "Vita":
		Configuration.set_low_end_hardware(true)
		# remove the mapping for the "mouse", which is the touchscreen.
		for x in InputMap.get_action_list("primary"):
			if x is InputEventMouseButton:
				InputMap.action_erase_event("primary", x)

	Configuration.set_fullscreen(false)

func set_mouse_cursor():
	var window_size = OS.get_real_window_size()
	var scale_factor = int(ceil(window_size.y / 192)) if window_size.y >= 192 else 1
	if OS.get_name() == "HTML5":
		scale_factor = int(floor(window_size.y / 192)) if window_size.y >= 192 else 1
	var hotspot = scale_factor * 7.5
	var cursor = load("res://resources/textures/cursor_" + str(scale_factor) + ".png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(hotspot, hotspot))

func _on_Transition_fadein_finished(_transition_name):
	SoundFx.play("love4retro")
	timer.start()

func _on_Transition_fadeout_finished(_transition_name):
	visible = false
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(ResourceLoader.Intro)

func _on_Timer_timeout():
	transition.fadeout()
