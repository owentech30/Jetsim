extends CharacterBody3D

@export var military_max_speed := 520.0
@export var afterburner_max_speed := 1250.0
@export var stall_speed := 48.0
@export var acceleration := 95.0
@export var pitch_speed := 1.45
@export var roll_speed := 2.4
@export var yaw_speed := 0.75

var current_speed := 180.0
var throttle := 0.75
var flaps_deployed := false
var gear_deployed := false
var cockpit_view := false
var autopilot_on := false
var prev_altitude := 800.0
var prev_velocity := Vector3.ZERO
var key_cooldown := 0.0

var cam: Camera3D
var cockpit_frame: Node3D
var gear_group: Node3D
var flame_left: MeshInstance3D
var flame_right: MeshInstance3D
var hud_left: Label
var hud_right: Label
var hud_warning: Label

func _ready() -> void:
	global_position = Vector3(0.0, 800.0, 800.0)
	_build_jet_and_hud()
	_build_massive_world()
	_update_visual_toggles()

func _make_mat(col: Color, metallic := 0.0, emissive := false, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, alpha)
	m.metallic = metallic
	m.roughness = 0.32
	if emissive:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 3.0
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _add_mesh(parent: Node, mesh: Mesh, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

func _add_box(parent: Node, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _add_mesh(parent, bm, pos, mat, rot)

func _add_prism(parent: Node, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var pm := PrismMesh.new()
	pm.size = size
	return _add_mesh(parent, pm, pos, mat, rot)

func _add_cyl(parent: Node, top_r: float, bot_r: float, height: float, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = height
	cm.radial_segments = 12
	return _add_mesh(parent, cm, pos, mat, rot)

func _add_label(layer: CanvasLayer, preset: int, rect: Vector4, col: Color, font_sz: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.set_anchors_preset(preset)
	lbl.offset_left = rect.x
	lbl.offset_top = rect.y
	lbl.offset_right = rect.z
	lbl.offset_bottom = rect.w
	lbl.horizontal_alignment = align
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", font_sz)
	layer.add_child(lbl)
	return lbl

func _build_jet_and_hud() -> void:
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(5.0, 1.5, 9.0)
	col.shape = box_shape
	add_child(col)

	var mat_hull := _make_mat(Color(0.36, 0.40, 0.45), 0.55)
	var mat_trim := _make_mat(Color(0.24, 0.27, 0.31), 0.65)
	var mat_canopy := _make_mat(Color(0.85, 0.62, 0.18), 0.90, false, 0.85)
	var mat_flame := _make_mat(Color(1.0, 0.50, 0.08), 0.0, true)
	var mat_dark := _make_mat(Color(0.11, 0.12, 0.14), 0.30)

	_add_cyl(self, 0.65, 0.82, 6.2, Vector3(0, 0, 0.4), mat_hull, Vector3(90, 0, 0))
	_add_cyl(self, 0.02, 0.65, 3.4, Vector3(0, -0.05, -4.4), mat_trim, Vector3(90, 0, 0))
	_add_prism(self, Vector3(1.5, 3.8, 0.85), Vector3(0, 0.25, -2.2), mat_hull, Vector3(-90, 0, 0))
	_add_cyl(self, 0.32, 0.48, 2.6, Vector3(0, 0.55, -1.7), mat_canopy, Vector3(84, 0, 0))
	_add_box(self, Vector3(0.75, 0.45, 3.8), Vector3(0, 0.45, 1.1), mat_hull)

	for s in [-1.0, 1.0]:
		_add_box(self, Vector3(0.65, 0.72, 3.2), Vector3(0.88 * s, -0.08, -0.6), mat_trim, Vector3(0, -6.0 * s, 0))
		_add_box(self, Vector3(0.52, 0.58, 0.20), Vector3(0.94 * s, -0.08, -2.22), mat_dark)
		_add_cyl(self, 0.36, 0.44, 0.90, Vector3(0.45 * s, 0, 3.85), mat_dark, Vector3(90, 0, 0))
		_add_prism(self, Vector3(3.4, 4.4, 0.14), Vector3(2.9 * s, 0.02, 0.9), mat_hull, Vector3(90, 90.0 * s, 0))
		_add_box(self, Vector3(2.8, 0.14, 0.9), Vector3(2.2 * s, 0.02, 1.8), mat_trim)
		_add_cyl(self, 0.08, 0.08, 2.6, Vector3(5.1 * s, 0.02, 1.6), mat_trim, Vector3(90, 0, 0))
		var nav_col := Color(1.0, 0.15, 0.15) if s < 0 else Color(0.15, 1.0, 0.25)
		_add_box(self, Vector3(0.16, 0.16, 0.25), Vector3(5.1 * s, 0.05, 0.35), _make_mat(nav_col, 0.0, true))
		_add_prism(self, Vector3(1.8, 2.2, 0.10), Vector3(1.7 * s, 0.0, 3.4), mat_trim, Vector3(90, 90.0 * s, 0))
		_add_prism(self, Vector3(1.9, 1.8, 0.12), Vector3(0.95 * s, 0.9, 3.1), mat_hull, Vector3(0, 90, -24.0 * s))

	gear_group = Node3D.new()
	add_child(gear_group)
	for gp in [Vector3(0, -0.85, -3.1), Vector3(-1.4, -0.85, 1.2), Vector3(1.4, -0.85, 1.2)]:
		_add_cyl(gear_group, 0.08, 0.08, 0.95, gp, mat_trim)
		_add_cyl(gear_group, 0.32, 0.32, 0.22, gp + Vector3(0, -0.45, 0), mat_dark, Vector3(0, 0, 90))

	flame_left = _add_cyl(self, 0.05, 0.34, 3.2, Vector3(-0.45, 0, 5.7), mat_flame, Vector3(90, 0, 0))
	flame_right = _add_cyl(self, 0.05, 0.34, 3.2, Vector3(0.45, 0, 5.7), mat_flame, Vector3(90, 0, 0))

	cockpit_frame = Node3D.new()
	add_child(cockpit_frame)
	_add_box(cockpit_frame, Vector3(0.95, 0.35, 0.6), Vector3(0, 0.32, -2.3), mat_dark)

	cam = Camera3D.new()
	cam.far = 65000.0
	add_child(cam)

	var hud_layer := CanvasLayer.new()
	add_child(hud_layer)
	var grn := Color(0.15, 1.0, 0.35)
	hud_left = _add_label(hud_layer, Control.PRESET_TOP_LEFT, Vector4(20, 20, 460, 260), grn, 17)
	hud_right = _add_label(hud_layer, Control.PRESET_TOP_RIGHT, Vector4(-380, 20, -20, 280), grn, 16, HORIZONTAL_ALIGNMENT_RIGHT)
	var crosshair := _add_label(hud_layer, Control.PRESET_CENTER, Vector4(-60, -20, 60, 20), grn, 24, HORIZONTAL_ALIGNMENT_CENTER)
	crosshair.text = "---( + )---"
	hud_warning = _add_label(hud_layer, Control.PRESET_CENTER_TOP, Vector4(-300, 36, 300, 85), Color(1.0, 0.25, 0.2), 20, HORIZONTAL_ALIGNMENT_CENTER)

func _build_massive_world() -> void:
	var wr := get_parent()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.08, 0.28, 0.72)
	sky_mat.sky_horizon_color = Color(0.66, 0.82, 0.96)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.fog_enabled = true
	env.fog_light_color = Color(0.68, 0.83, 0.96)
	env.fog_density = 0.00008
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	wr.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 30.0, 0.0)
	sun.light_energy = 1.25
	wr.add_child(sun)

	var ocean_mesh := PlaneMesh.new()
	ocean_mesh.size = Vector2(160000.0, 160000.0)
	_add_mesh(wr, ocean_mesh, Vector3(0.0, -0.5, 0.0), _make_mat(Color(0.06, 0.24, 0.48)))

	var land_mesh := PlaneMesh.new()
	land_mesh.size = Vector2(100000.0, 100000.0)
	_add_mesh(wr, land_mesh, Vector3.ZERO, _make_mat(Color(0.20, 0.40, 0.22)))

	var mat_runway := _make_mat(Color(0.13, 0.14, 0.16))
	_add_box(wr, Vector3(50, 0.5, 2400), Vector3(0, 0.25, -900), mat_runway)
	_add_box(wr, Vector3(50, 0.5, 2400), Vector3(14000, 0.25, -22000), mat_runway, Vector3(0, 45, 0))
	_add_box(wr, Vector3(18, 45, 18), Vector3(65, 22.5, -800), _make_mat(Color(0.36, 0.40, 0.45), 0.55))

	var mat_mountain := _make_mat(Color(0.28, 0.33, 0.30))
	var mat_snow := _make_mat(Color(0.92, 0.95, 0.98))
	for i in range(65):
		var mx := rng.randf_range(-42000.0, 42000.0)
		var mz := rng.randf_range(-42000.0, 42000.0)
		if abs(mx) < 1800.0 and abs(mz) < 3500.0:
			continue
		var h := rng.randf_range(600.0, 2600.0)
		var w := rng.randf_range(1600.0, 4200.0)
		var ry := rng.randf_range(0.0, 360.0)
		_add_prism(wr, Vector3(w, h, w), Vector3(mx, h * 0.48, mz), mat_mountain, Vector3(0, ry, 0))
		if h > 1200.0:
			_add_prism(wr, Vector3(w * 0.42, h * 0.42, w * 0.42), Vector3(mx, h * 0.76, mz), mat_snow, Vector3(0, ry, 0))

	var mat_cloud := _make_mat(Color(1.0, 1.0, 1.0), 0.0, false, 0.82)
	for i in range(90):
		var cw := rng.randf_range(600.0, 2200.0)
		var ch := rng.randf_range(60.0, 180.0)
		var cd_sz := rng.randf_range(600.0, 2200.0)
		_add_box(wr, Vector3(cw, ch, cd_sz), Vector3(rng.randf_range(-35000.0, 35000.0), rng.randf_range(1400.0, 3200.0), rng.randf_range(-35000.0, 35000.0)), mat_cloud)

	var mat_light := _make_mat(Color(0.2, 1.0, 0.4), 0.0, true)
	for z_pos in range(-2100, 350, 150):
		for x_side in [-26.0, 26.0]:
			_add_box(wr, Vector3(2.5, 2.5, 2.5), Vector3(x_side, 1.5, float(z_pos)), mat_light)

func _update_visual_toggles() -> void:
	gear_group.visible = gear_deployed
	cockpit_frame.visible = cockpit_view
	if cockpit_view:
		cam.position = Vector3(0.0, 0.75, -1.55)
		cam.rotation_degrees = Vector3(-2.0, 0.0, 0.0)
	else:
		cam.position = Vector3(0.0, 3.2, 12.5)
		cam.rotation_degrees = Vector3(-12.0, 0.0, 0.0)

func _physics_process(delta: float) -> void:
	key_cooldown = max(0.0, key_cooldown - delta)
	if key_cooldown == 0.0:
		if Input.is_key_pressed(KEY_F):
			flaps_deployed = not flaps_deployed
			key_cooldown = 0.25
		elif Input.is_key_pressed(KEY_G):
			gear_deployed = not gear_deployed
			_update_visual_toggles()
			key_cooldown = 0.25
		elif Input.is_key_pressed(KEY_C):
			cockpit_view = not cockpit_view
			_update_visual_toggles()
			key_cooldown = 0.25
		elif Input.is_key_pressed(KEY_P):
			autopilot_on = not autopilot_on
			key_cooldown = 0.25

	if Input.is_action_pressed("throttle_up"):
		throttle = clamp(throttle + 0.45 * delta, 0.0, 1.0)
	if Input.is_action_pressed("throttle_down"):
		throttle = clamp(throttle - 0.45 * delta, 0.0, 1.0)

	var scramjet := Input.is_key_pressed(KEY_X) and not flaps_deployed
	var afterburner := (throttle > 0.85 or scramjet) and not flaps_deployed
	flame_left.visible = afterburner
	flame_right.visible = afterburner
	var pulse := randf_range(1.6, 2.4) if scramjet else randf_range(0.95, 1.45)
	flame_left.scale = Vector3(1.1, pulse, 1.1)
	flame_right.scale = Vector3(1.1, pulse, 1.1)

	var base_max := (afterburner_max_speed if afterburner else military_max_speed) * (1.45 if scramjet else 1.0)
	if flaps_deployed:
		base_max *= 0.50
	if gear_deployed:
		base_max *= 0.65

	var eff_stall := stall_speed * (0.70 if flaps_deployed else 1.0)
	var fwd := -global_transform.basis.z
	var target_spd := base_max if scramjet else (base_max * throttle)
	var accel := acceleration * (2.8 if scramjet else (1.8 if afterburner else 1.0))
	current_speed = clamp(move_toward(current_speed, target_spd, accel * delta) - fwd.y * 28.0 * delta, 0.0, 1875.0)

	var auth := clamp(current_speed / 60.0, 0.12, 1.0)
	var pitch_in := Input.get_axis("pitch_down", "pitch_up")
	var roll_in := Input.get_axis("roll_right", "roll_left")
	var yaw_in := Input.get_axis("yaw_right", "yaw_left")
	if abs(pitch_in) > 0.05 or abs(roll_in) > 0.05:
		autopilot_on = false

	if autopilot_on:
		rotation.x = move_toward(rotation.x, 0.0, 0.8 * delta)
		rotation.z = move_toward(rotation.z, 0.0, 1.2 * delta)
	else:
		rotate_object_local(Vector3.RIGHT, pitch_in * pitch_speed * auth * delta)
		rotate_object_local(Vector3.FORWARD, roll_in * roll_speed * auth * delta)
		rotate_object_local(Vector3.UP, yaw_in * yaw_speed * auth * delta)
	rotate_y(sin(rotation.z) * 0.45 * auth * delta)

	var lift := clamp(current_speed / eff_stall, 0.0, 1.2) * 9.8 + (2.5 if (flaps_deployed and current_speed > eff_stall) else 0.0)
	if current_speed < eff_stall and global_position.y > 4.0:
		rotate_object_local(Vector3.RIGHT, -0.5 * delta)
	velocity = (fwd * current_speed) + Vector3.DOWN * max(0.0, 9.8 - lift)
	move_and_slide()

	var g_load := 1.0 + (((velocity - prev_velocity) / max(delta, 0.001)).dot(global_transform.basis.y) / 9.8)
	prev_velocity = velocity

	if global_position.y < 1.8:
		global_position.y = 1.8
		if rotation.x < 0:
			rotation.x = move_toward(rotation.x, 0.0, 2.5 * delta)
		if throttle < 0.15:
			current_speed = move_toward(current_speed, 0.0, 22.0 * delta)

	cam.fov = lerp(cam.fov, lerp(70.0, 102.0, current_speed / 1812.0), 5.0 * delta)
	var vs := int(((global_position.y - prev_altitude) / delta) * 196.85)
	prev_altitude = global_position.y
	var mach := current_speed / 343.0

	hud_left.text = "=== PFD ===\nIAS: %d KTS (MACH %.2f)\nALT: %d FT | V/S: %+d FPM\nHDG: %03d° | %.1f G\nPITCH: %+d° | ROLL: %+d°\nHOME: %.1f NM" % [int(current_speed * 1.94384), mach, int(global_position.y * 3.28084), vs, int(fposmod(-rad_to_deg(rotation.y), 360.0)), g_load, int(rad_to_deg(rotation.x)), int(rad_to_deg(rotation.z)), global_position.length() / 1852.0]
	hud_right.text = "=== SYSTEMS ===\nTHR: %d%% (%s)\nGEAR [G]: %s | FLAPS [F]: %s\nAUTOPILOT [P]: %s | VIEW [C]: %s\n[W/S] Pitch [A/D] Roll [Q/E] Yaw\n[Shift/Ctrl] Thr [Hold X] Scramjet" % [int(throttle * 100), "SCRAMJET" if scramjet else ("AB" if afterburner else "MIL"), "DN" if gear_deployed else "UP", "DN" if flaps_deployed else "UP", "ON" if autopilot_on else "OFF", "PIT" if cockpit_view else "EXT"]

	if current_speed < eff_stall and global_position.y > 6.0:
		hud_warning.text = "⚠ STALL WARNING ⚠"
	elif global_position.y < 65.0 and vs < -1500:
		hud_warning.text = "⚠ TERRAIN PULL UP ⚠"
	elif global_position.y < 15.0 and not gear_deployed and current_speed > 20.0:
		hud_warning.text = "⚠ DEPLOY GEAR [G] ⚠"
	elif scramjet:
		hud_warning.text = ">>> HYPERSONIC MACH %.2f <<<" % mach
	elif afterburner and mach >= 1.0:
		hud_warning.text = ">> SUPERSONIC MACH %.2f <<" % mach
	else:
		hud_warning.text = ""
