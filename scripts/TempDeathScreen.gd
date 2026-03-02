class_name TempDeathScreen extends Node

@export var isDeathScreen: bool
@export var savefile: SaveFileManager
@export var viewblocker: ColorRect
@export var speaker: AudioStreamPlayer2D
var allowed = true
var fs = false

func _ready():
	if (isDeathScreen):
		print("changing scene to: main")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
