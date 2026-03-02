class_name TextShaker extends Node

@export var delay: float
@export var offset1: float
@export var offset2: float
@export var text: Control
var looping = false
var origpos

func _ready():
    origpos = text.position
    looping = true
    Shake()

func Shake():
    while (looping):
        if not is_inside_tree(): break
        var tree = get_tree()
        if not tree: break

        var randx = randf_range(offset1, offset2)
        var randy = randf_range(offset1, offset2)
        text.position = Vector2(randx, randy)
        await tree.create_timer(delay, false).timeout

        if not is_inside_tree(): break
        text.position = origpos
        await tree.create_timer(delay, false).timeout
        pass
    pass
