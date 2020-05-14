extends Node2D

export(float) var field_of_view: float = 60.0
export(float) var radius_warn: float = 500.0
export(float) var radius_danger: float = 200.0
export(float) var view_detail: float = 60.0

export(bool) var show_circle: bool = false
export(bool) var show_fov: bool = true
export(bool) var show_target_line: bool = true

export(Color) var circle_color: Color = Color("#9f185c0b")
export(Color) var fov_color: Color = Color("#b23d7f0b")
export(Color) var fov_warn_color: Color = Color("#b1eedf0b")
export(Color) var fov_danger_color: Color = Color("#9dfb320b")

export(Array) var enemy_groups: Array = ["Enemy"]

var in_danger_area: Array = []
var in_warn_area: Array = []

# Buffer to target points
var points_arc: Array = []
var is_update: bool = false

func _process(delta: float) -> void:
	is_update = true
	check_view()
	update()

func _draw() -> void:
	if show_circle:
		draw_circle(get_position(), radius_warn, circle_color)

	if show_fov && is_update:
		draw_circle_arc()

func draw_circle_arc() -> void:
	for aux in points_arc:
		if aux.level == 1 && show_target_line:
				draw_line(get_position(), aux.pos, fov_warn_color, 3)
		elif aux.level == 2 && show_target_line:
			draw_line(get_position(), aux.pos, fov_danger_color, 5)
		else:
				draw_line(get_position(), aux.pos, fov_color)

func deg_to_vector(deg: float) -> Vector2:
	return Vector2(cos(deg2rad(deg)), sin(deg2rad(deg)))

func check_view() -> void:
	var dir_deg = rad2deg(transform.get_rotation())
	var start_angle = dir_deg - (field_of_view * 0.5)
	var end_angle = start_angle + field_of_view

	points_arc = []
	in_danger_area = []
	in_warn_area = []

	var space_state = get_world_2d().direct_space_state

	for i in range(view_detail + 1):
		var cur_angle = start_angle + (i * (field_of_view / view_detail)) + 90
		var point = get_position() + deg_to_vector(cur_angle) * radius_warn

		# use global coordinates, not local to node
		var result = space_state.intersect_ray(get_global_transform().origin, to_global(point), [get_parent()])

		if result.empty():
			points_arc.append({"pos": point, "level": 0})
			continue

		var local_pos = to_local(result.position)
		var dist = get_position().distance_to(local_pos)
		var level = 0
		var is_enemy = false

		if in_danger_area.has(result.collider) || in_warn_area.has(result.collider):
			points_arc.append({"pos": local_pos, "level": level})
			continue

		for g in enemy_groups :
			if result.collider.get_groups().has(g):
				is_enemy = true

		if !is_enemy:
			points_arc.append({"pos": local_pos, "level": level})
			continue

		level = 1

		if dist < radius_danger :
			level = 2
			in_danger_area.append(result.collider)
		else :
			in_warn_area.append(result.collider)

		# check if directly to target, we can "shoot"
		var tgt_pos = result.collider.get_global_transform().origin
		var this_pos = get_global_transform().origin
		var tgt_dir = (tgt_pos - this_pos).normalized()
		var view_angle = rad2deg(deg_to_vector(rad2deg(get_global_transform().get_rotation())+90).angle_to(tgt_dir))

		if !(view_angle > start_angle && view_angle < end_angle):
			points_arc.append({"pos": local_pos, "level": level})
			continue

		var result2 = space_state.intersect_ray(this_pos, tgt_pos, [get_parent()])

		if !result2.empty() && result2.collider == result.collider :
			# we can, then use this as line
			points_arc.append({"pos": local_pos, "level": 0})
			if show_target_line:
				points_arc.append({"pos": to_local(tgt_pos), "level": level})
		else :
			points_arc.append({"pos": local_pos, "level": level})
