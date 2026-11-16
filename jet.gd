extends CharacterBody3D

var spd := 180.0
var thr := 0.75
var flaps := false
var gear := false
var cockpit := false
var ap := false
var prev_alt := 800.0
var prev_vel := Vector3.ZERO
var cd := 0.0

var cam: Camera3D
var dash: Node3D
var gear_grp: Node3D
var fl_l: MeshInstance3D
var fl_r: MeshInstance3D
var hud_l: Label
var hud_r: Label
var hud_w: Label

func _ready() -> void:
	global_position = Vector3(0, 800, 800)
	_build_jet()
	_build_world()
	_sync_vis()

func _m(c: Color, met := 0.0, em := false, alpha := 1.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.metallic = met
	if em:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 3.0
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _add_box(p: Node, sz: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	p.add_child(mi)
	return mi

func _add_prism(p: Node, sz: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var pm = PrismMesh.new()
	pm.size = sz
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	p.add_child(mi)
	return mi

func _lbl(hl: CanvasLayer, anc: int, off: Vector4, col: Color, sz: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.set_anchors_preset(anc)
	l.offset_left = off.x
	l.offset_top = off.y
	l.offset_right = off.z
	l.offset_bottom = off.w
	l.horizontal_alignment = align
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", sz)
	hl.add_child(l)
	return l

func _build_jet() -> void:
	var col = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(4.5, 1.4, 7.5)
	col.shape = bs
	add_child(col)

	var mb = _m(Color(0.34, 0.39, 0.45), 0.45)
	var mc = _m(Color(0.08, 0.22, 0.42), 0.85)
	var mf = _m(Color(1.0, 0.5, 0.08), 0.0, true)
	var md = _m(Color(0.13, 0.14, 0.16))

	_add_prism(self, Vector3(1.6, 8.2, 1.1), Vector3.ZERO, mb, Vector3(-90, 0, 0))
	_add_prism(self, Vector3(0.9, 3.7, 0.65), Vector3(0, 0.55, -1.2), mc, Vector3(-90, 0, 0))
	_add_box(self, Vector3(10.2, 0.14, 2.8), Vector3(0, 0, 0.7), mb)
	_add_box(self, Vector3(4.6, 0.1, 1.2), Vector3(0, 0, 3.2), mb)
	for s in [-1.0, 1.0]:
		_add_box(self, Vector3(0.14, 1.9, 1.6), Vector3(0.8 * s, 0.85, 3.0), mb, Vector3(0, 0, -23 * s))

	gear_grp = Node3D.new()
	add_child(gear_grp)
	for gp in [Vector3(0, -0.85, -2.2), Vector3(-1.6, -0.85, 1.1), Vector3(1.6, -0.85, 1.1)]:
		_add_box(gear_grp, Vector3(0.35, 1.1, 0.5), gp, md)

	fl_l = _add_prism(self, Vector3(0.55, 2.8, 0.55), Vector3(-0.45, 0, 5.2), mf, Vector3(90, 0, 0))
	fl_r = _add_prism(self, Vector3(0.55, 2.8, 0.55), Vector3(0.45, 0, 5.2), mf, Vector3(90, 0, 0))

	dash = Node3D.new()
	add_child(dash)
	_add_box(dash, Vector3(1.1, 0.4, 0.5), Vector3(0, 0.25, -1.85), md)

	cam = Camera3D.new()
	cam.far = 65000.0
	add_child(cam)

	var hl = CanvasLayer.new()
	add_child(hl)
	var grn = Color(0.15, 1.0, 0.35)
	hud_l = _lbl(hl, Control.PRESET_TOP_LEFT, Vector4(20, 20, 460, 260), grn, 17)
	hud_r = _lbl(hl, Control.PRESET_TOP_RIGHT, Vector4(-380, 20, -20, 280), grn, 16, HORIZONTAL_ALIGNMENT_RIGHT)
	var ch = _lbl(hl, Control.PRESET_CENTER, Vector4(-60, -20, 60, 20), grn, 24, HORIZONTAL_ALIGNMENT_CENTER)
	ch.text = "---( + )---"
	hud_w = _lbl(hl, Control.PRESET_CENTER_TOP, Vector4(-300, 36, 300, 85), Color(1, 0.25, 0.2), 20, HORIZONTAL_ALIGNMENT_CENTER)

func _build_world() -> void:
	var wr = get_parent()
	var rng = RandomNumberGenerator.new()
	rng.seed = 1337

	var sm = ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.08, 0.28, 0.72)
	sm.sky_horizon_color = Color(0.66, 0.82, 0.96)
	var sky = Sky.new()
	sky.sky_material = sm
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.fog_enabled = true
	env.fog_light_color = Color(0.68, 0.83, 0.96)
	env.fog_density = 0.00008
	var we = WorldEnvironment.new()
	we.environment = env
	wr.add_child(we)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.25
	wr.add_child(sun)

	for cfg in [[160000.0, -0.5, Color(0.06, 0.24, 0.48)], [100000.0, 0.0, Color(0.2, 0.4, 0.22)]]:
		var pl = MeshInstance3D.new()
		var pm = PlaneMesh.new()
		pm.size = Vector2(cfg[0], cfg[0])
		pl.mesh = pm
		pl.material_override = _m(cfg[2])
		pl.position.y = cfg[1]
		wr.add_child(pl)

	var mr = _m(Color(0.13, 0.14, 0.16))
	_add_box(wr, Vector3(50, 0.5, 2400), Vector3(0, 0.25, -900), mr)
	_add_box(wr, Vector3(50, 0.5, 2400), Vector3(14000, 0.25, -22000), mr, Vector3(0, 45, 0))
	_add_box(wr, Vector3(18, 45, 18), Vector3(65, 22.5, -800), _m(Color(0.4, 0.45, 0.5)))

	var mm = _m(Color(0.28, 0.33, 0.30))
	var ms = _m(Color(0.92, 0.95, 0.98))
	for i in range(65):
		var mx = rng.randf_range(-42000, 42000)
		var mz = rng.randf_range(-42000, 42000)
		if abs(mx) < 1800 and abs(mz) < 3500: continue
		var h = rng.randf_range(600, 2600)
		var w = rng.randf_range(1600, 4200)
		var ry = rng.randf_range(0, 360)
		_add_prism(wr, Vector3(w, h, w), Vector3(mx, h * 0.48, mz), mm, Vector3(0, ry, 0))
		if h > 1200:
			_add_prism(wr, Vector3(w * 0.42, h * 0.42, w * 0.42), Vector3(mx, h * 0.76, mz), ms, Vector3(0, ry, 0))

	var mc = _m(Color(1, 1, 1), 0.0, false, 0.82)
	for i in range(90):
		_add_box(wr, Vector3(rng.randf_range(600, 2200), rng.randf_range(60, 180), rng.randf_range(600, 2200)), Vector3(rng.randf_range(-35000, 35000), rng.randf_range(1400, 3200), rng.randf_range(-35000, 35000)), mc)

	var ml = _m(Color(0.2, 1.0, 0.4), 0.0, true)
	for z in range(-2100, 350, 150):
		for x in [-26.0, 26.0]:
			_add_box(wr, Vector3(2.5, 2.5, 2.5), Vector3(x, 1.5, float(z)), ml)

func _sync_vis() -> void:
	gear_grp.visible = gear
	dash.visible = cockpit
	cam.position = Vector3(0, 0.72, -1.15) if cockpit else Vector3(0, 3.0, 11.5)
	cam.rotation_degrees = Vector3(-2 if cockpit else -12, 0, 0)

func _physics_process(delta: float) -> void:
	cd = max(0.0, cd - delta)
	if cd == 0.0:
		if Input.is_key_pressed(KEY_F): flaps = !flaps; cd = 0.25
		elif Input.is_key_pressed(KEY_G): gear = !gear; _sync_vis(); cd = 0.25
		elif Input.is_key_pressed(KEY_C): cockpit = !cockpit; _sync_vis(); cd = 0.25
		elif Input.is_key_pressed(KEY_P): ap = !ap; cd = 0.25

	if Input.is_action_pressed("throttle_up"): thr = clamp(thr + 0.45 * delta, 0.0, 1.0)
	if Input.is_action_pressed("throttle_down"): thr = clamp(thr - 0.45 * delta, 0.0, 1.0)

	var scram = Input.is_key_pressed(KEY_X) and not flaps
	var ab = (thr > 0.85 or scram) and not flaps
	fl_l.visible = ab
	fl_r.visible = ab
	var pulse = randf_range(1.6, 2.4) if scram else randf_range(0.95, 1.45)
	fl_l.scale = Vector3(1.1, 1.1, pulse)
	fl_r.scale = Vector3(1.1, 1.1, pulse)

	var max_s = (1250.0 if ab else 520.0) * (1.45 if scram else 1.0)
	if flaps: max_s *= 0.50
	if gear: max_s *= 0.65
	var stall = 48.0 * (0.70 if flaps else 1.0)

	var fwd = -global_transform.basis.z
	var tgt = max_s if scram else (max_s * thr)
	var acc = 95.0 * (2.8 if scram else (1.8 if ab else 1.0))
	spd = clamp(move_toward(spd, tgt, acc * delta) - fwd.y * 28.0 * delta, 0.0, 1875.0)

	var auth = clamp(spd / 60.0, 0.12, 1.0)
	var pi = Input.get_axis("pitch_down", "pitch_up")
	var ri = Input.get_axis("roll_right", "roll_left")
	var yi = Input.get_axis("yaw_right", "yaw_left")
	if abs(pi) > 0.05 or abs(ri) > 0.05: ap = false

	if ap:
		rotation.x = move_toward(rotation.x, 0.0, 0.8 * delta)
		rotation.z = move_toward(rotation.z, 0.0, 1.2 * delta)
	else:
		rotate_object_local(Vector3.RIGHT, pi * 1.45 * auth * delta)
		rotate_object_local(Vector3.FORWARD, ri * 2.4 * auth * delta)
		rotate_object_local(Vector3.UP, yi * 0.75 * auth * delta)
	rotate_y(sin(rotation.z) * 0.45 * auth * delta)

	var lift = clamp(spd / stall, 0.0, 1.2) * 9.8 + (2.5 if (flaps and spd > stall) else 0.0)
	if spd < stall and global_position.y > 4.0: rotate_object_local(Vector3.RIGHT, -0.5 * delta)
	velocity = (fwd * spd) + Vector3.DOWN * max(0.0, 9.8 - lift)
	move_and_slide()

	var g_load = 1.0 + (((velocity - prev_vel) / max(delta, 0.001)).dot(global_transform.basis.y) / 9.8)
	prev_vel = velocity
	if global_position.y < 1.8:
		global_position.y = 1.8
		if rotation.x < 0: rotation.x = move_toward(rotation.x, 0.0, 2.5 * delta)
		if thr < 0.15: spd = move_toward(spd, 0.0, 22.0 * delta)

	cam.fov = lerp(cam.fov, lerp(70.0, 102.0, spd / 1812.0), 5.0 * delta)
	var vs = int(((global_position.y - prev_alt) / delta) * 196.85)
	prev_alt = global_position.y
	var mach = spd / 343.0

	hud_l.text = "=== PFD ===\nIAS: %d KTS (MACH %.2f)\nALT: %d FT | V/S: %+d FPM\nHDG: %03d° | %.1f G\nPITCH: %+d° | ROLL: %+d°\nHOME: %.1f NM" % [int(spd * 1.94384), mach, int(global_position.y * 3.28084), vs, int(fposmod(-rad_to_deg(rotation.y), 360.0)), g_load, int(rad_to_deg(rotation.x)), int(rad_to_deg(rotation.z)), global_position.length() / 1852.0]
	hud_r.text = "=== SYSTEMS ===\nTHR: %d%% (%s)\nGEAR [G]: %s | FLAPS [F]: %s\nAUTOPILOT [P]: %s | VIEW [C]: %s\n[W/S] Pitch [A/D] Roll [Q/E] Yaw\n[Shift/Ctrl] Thr [Hold X] Scramjet" % [int(thr * 100), "SCRAMJET" if scram else ("AB" if ab else "MIL"), "DN" if gear else "UP", "DN" if flaps else "UP", "ON" if ap else "OFF", "PIT" if cockpit else "EXT"]

	if spd < stall and global_position.y > 6.0: hud_w.text = "⚠ STALL WARNING ⚠"
	elif global_position.y < 65.0 and vs < -1500: hud_w.text = "⚠ TERRAIN PULL UP ⚠"
	elif global_position.y < 15.0 and not gear and spd > 20.0: hud_w.text = "⚠ DEPLOY GEAR [G] ⚠"
	elif scram: hud_w.text = ">>> HYPERSONIC MACH %.2f <<<" % mach
	elif ab and mach >= 1.0: hud_w.text = ">> SUPERSONIC MACH %.2f <<" % mach
	else: hud_w.text = ""
