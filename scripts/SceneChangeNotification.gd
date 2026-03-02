extends Node

func _ready():
    if get_tree() and get_tree().current_scene:
        print("user entered scene: ", get_tree().current_scene.name)
