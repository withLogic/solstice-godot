extends CanvasLayer

signal fullscreen_toggled(button_pressed)
signal sound_volume_changed(volume)
signal music_volume_changed(volume)
signal return_to_main_menu

onready var fullscreen = $NinePatchRect/VBoxContainer/FullscreenCheckBox
onready var sound_volume = $NinePatchRect/VBoxContainer/SoundSlider
onready var sound_volume_label = $NinePatchRect/VBoxContainer/SoundLabel
onready var music_volume = $NinePatchRect/VBoxContainer/MusicSlider
onready var music_volume_label = $NinePatchRect/VBoxContainer/MusicLabel

func _ready():
	refresh()

func refresh():
	Configuration.load_and_save_config()
	fullscreen.pressed = Configuration.fullscreen
	sound_volume.value = Configuration.sfx_volume
	music_volume.value = Configuration.music_volume

func _on_FullscreenCheckBox_toggled(button_pressed):
	emit_signal("fullscreen_toggled", button_pressed)

func _on_SoundSlider_value_changed(_value):
	emit_signal("sound_volume_changed", sound_volume.value)

func _on_MusicSlider_value_changed(_value):
	emit_signal("music_volume_changed", music_volume.value)

func _on_BackButton_pressed():
	emit_signal("return_to_main_menu")

func _on_SoundSlider_focus_entered():
	sound_volume_label.add_color_override("font_color", Color("b2dcef"))

func _on_SoundSlider_focus_exited():
	sound_volume_label.add_color_override("font_color", Color("ffffff"))

func _on_MusicSlider_focus_entered():
	music_volume_label.add_color_override("font_color", Color("b2dcef"))

func _on_MusicSlider_focus_exited():
	music_volume_label.add_color_override("font_color", Color("ffffff"))
