extends KinematicBody2D

export(float) var speed: float = 200.0
export(NodePath) var danger_text_path: NodePath
export(NodePath) var warn_text_path: NodePath

var move_control: Vector2 = Vector2()
var vel: Vector2 = Vector2()
var moving: bool = false

onready var danger_txt = get_node(danger_text_path)
onready var warn_txt = get_node(warn_text_path)

func check_fov() -> void:
	if danger_txt:
		danger_txt.text = "DANGER\n" + str($field_of_view.in_danger_area)
	if warn_txt:
		warn_txt.text = "WARNING\n" + str($field_of_view.in_warn_area)

func _process(_delta: float) -> void:
	check_fov()

	var pos = get_position()
	var dir = (get_global_mouse_position() - pos).normalized()
	set_rotation(deg2rad(rad2deg(dir.angle()) - 90))

	# vel = Vector2()
	move_control = Vector2()

	moving = false

	if Input.is_key_pressed(KEY_A):
		move_control.x = 1
		moving = true
	elif Input.is_key_pressed(KEY_D):
		move_control.x = -1
		moving = true

	if Input.is_key_pressed(KEY_W):
		move_control.y = 1
		moving = true
	elif  Input.is_key_pressed(KEY_S):
		move_control.y = -1
		moving = true

	vel = (move_control.normalized() * speed).rotated(transform.get_rotation())

	vel = move_and_slide(vel, Vector2())
