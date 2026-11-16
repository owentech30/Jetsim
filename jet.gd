extends CharacterBody3D

var spd := 180.0
var thr := 0.75
var flaps := false
var gear := false
var pit := false
var ap := false
var p_alt := 800.0
var p_vel := Vector3.ZERO
var cd := 0.0

var cam: Camera3D
var dash: Node3D
var g_grp: Node3D
var fl: Array[MeshInstance3D] = []
var hl: Label
var hr: Label
var hw: Label

func _mat(c: Color, met := 0.0, em := false, a := 1.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, a)
	m.metallic = met
	m.roughness = 0.32
	if em:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 3.0
	if a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _mk(p: Node, m: Mesh, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	p.add_child(mi)
	return mi

func _bx(p: Node, sz: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var b = BoxMesh.new()
	b.size = sz
	return _mk(p, b, pos, mat, rot)

func _pr(p: Node, sz: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var pr = PrismMesh.new()
	pr.size = sz
	return _mk(p, pr, pos, mat, rot)

func _cy(p: Node, r1: float, r2: float, h: float, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var c = CylinderMesh.new()
	c.top_radius = r1
	c.bottom_radius = r2
	c.height = h
	c.radial_segments = 10
	return _mk(p, c, pos, mat, rot)

func _lb(cv: CanvasLayer, anc: int, off: Vector4, col: Color, sz: int, al := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.set_anchors_preset(anc)
	l.offset_left = off.x
	l.offset_top = off.y
	l.offset_right = off.z
	l.offset_bottom = off.w
	l.horizontal_alignment = al
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", sz)
	cv.add_child(l)
	return l

func _sync() -> void:
	g_grp.visible = gear
	dash.visible = pit
	cam.position = Vector3(0, 0.75, -1.55) if pit else Vector3(0, 3.2, 12.5)
	cam.rotation_degrees = Vector3(-2 if pit else -12, 0, 0)
func _ready() -> void:
	global_position = Vector3(0, 800, 800)
	var col = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(5, 1.5, 9)
	col.shape = bs
	add_child(col)

	var hull = _mat(Color(0.36, 0.4, 0.45), 0.55)
	var trim = _mat(Color(0.24, 0.27, 0.31), 0.65)
	var gls = _mat(Color(0.85, 0.62, 0.18), 0.9, false, 0.85)
	var drk = _mat(Color(0.11, 0.12, 0.14), 0.3)

	_cy(self, 0.65, 0.82, 6.2, Vector3(0, 0, 0.4), hull, Vector3(90, 0, 0))
	_cy(self, 0.02, 0.65, 3.4, Vector3(0, -0.05, -4.4), trim, Vector3(90, 0, 0))
	_cy(self, 0.32, 0.48, 2.6, Vector3(0, 0.55, -1.7), gls, Vector3(84, 0, 0))
	_pr(self, Vector3(1.5, 3.8, 0.85), Vector3(0, 0.25, -2.2), hull, Vector3(-90, 0, 0))
	_bx(self, Vector3(0.75, 0.45, 3.8), Vector3(0, 0.45, 1.1), hull)

	for s in [-1.0, 1.0]:
		_bx(self, Vector3(0.65, 0.72, 3.2), Vector3(0.88 * s, -0.08, -0.6), trim, Vector3(0, -6 * s, 0))
		_bx(self, Vector3(0.52, 0.58, 0.2), Vector3(0.94 * s, -0.08, -2.22), drk)
		_cy(self, 0.36, 0.44, 0.9, Vector3(0.45 * s, 0, 3.85), drk, Vector3(90, 0, 0))
		_pr(self, Vector3(3.4, 4.4, 0.14), Vector3(2.9 * s, 0.02, 0.9), hull, Vector3(90, 90 * s, 0))
		_bx(self, Vector3(2.8, 0.14, 0.9), Vector3(2.2 * s, 0.02, 1.8), trim)
		_cy(self, 0.08, 0.08, 2.6, Vector3(5.1 * s, 0.02, 1.6), trim, Vector3(90, 0, 0))
		_bx(self, Vector3(0.16, 0.16, 0.25), Vector3(5.1 * s, 0.05, 0.35), _mat(Color(1, 0.15, 0.15) if s < 0 else Color(0.15, 1, 0.25), 0, true))
		_pr(self, Vector3(1.8, 2.2, 0.1), Vector3(1.7 * s, 0, 3.4), trim, Vector3(90, 90 * s, 0))
		_pr(self, Vector3(1.9, 1.8, 0.12), Vector3(0.95 * s, 0.9, 3.1), hull, Vector3(0, 90, -24 * s))
		fl.append(_cy(self, 0.05, 0.34, 3.2, Vector3(0.45 * s, 0, 5.7), _mat(Color(1, 0.5, 0.08), 0, true), Vector3(90, 0, 0)))

	g_grp = Node3D.new()
	add_child(g_grp)
	for gp in [Vector3(0, -0.85, -3.1), Vector3(-1.4, -0.85, 1.2), Vector3(1.4, -0.85, 1.2)]:
		_cy(g_grp, 0.08, 0.08, 0.95, gp, trim)
		_cy(g_grp, 0.32, 0.32, 0.22, gp + Vector3(0, -0.45, 0), drk, Vector3(0, 0, 90))

	dash = Node3D.new()
	add_child(dash)
	_bx(dash, Vector3(0.95, 0.35, 0.6), Vector3(0, 0.32, -2.3), drk)

	cam = Camera3D.new()
	cam.far = 65000.0
	add_child(cam)

	var cv = CanvasLayer.new()
	add_child(cv)
	var g = Color(0.15, 1, 0.35)
	hl = _lb(cv, Control.PRESET_TOP_LEFT, Vector4(20, 20, 460, 260), g, 17)
	hr = _lb(cv, Control.PRESET_TOP_RIGHT, Vector4(-380, 20, -20, 280), g, 16, HORIZONTAL_ALIGNMENT_RIGHT)
	_lb(cv, Control.PRESET_CENTER, Vector4(-60, -20, 60, 20), g, 24, HORIZONTAL_ALIGNMENT_CENTER).text = "---( + )---"
	hw = _lb(cv, Control.PRESET_CENTER_TOP, Vector4(-300, 36, 300, 85), Color(1, 0.25, 0.2), 20, HORIZONTAL_ALIGNMENT_CENTER)

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

	var pm1 = PlaneMesh.new()
	pm1.size = Vector2(160000, 160000)
	_mk(wr, pm1, Vector3(0, -0.5, 0), _mat(Color(0.06, 0.24, 0.48)))
	var pm2 = PlaneMesh.new()
	pm2.size = Vector2(100000, 100000)
	_mk(wr, pm2, Vector3.ZERO, _mat(Color(0.2, 0.4, 0.22)))
	_bx(wr, Vector3(50, 0.5, 2400), Vector3(0, 0.25, -900), drk)
	_bx(wr, Vector3(50, 0.5, 2400), Vector3(14000, 0.25, -22000), drk, Vector3(0, 45, 0))
	_bx(wr, Vector3(18, 45, 18), Vector3(65, 22.5, -800), hull)

	var mm = _mat(Color(0.28, 0.33, 0.3))
	var ms = _mat(Color(0.92, 0.95, 0.98))
	var mc = _mat(Color(1, 1, 1), 0, false, 0.82)
	for i in range(65):
		var mx = rng.randf_range(-42000, 42000)
		var mz = rng.randf_range(-42000, 42000)
		if abs(mx) < 1800 and abs(mz) < 3500:
			continue
		var h = rng.randf_range(600, 2600)
		var w = rng.randf_range(1600, 4200)
		var ry = rng.randf_range(0, 360)
		_pr(wr, Vector3(w, h, w), Vector3(mx, h * 0.48, mz), mm, Vector3(0, ry, 0))
		if h > 1200:
			_pr(wr, Vector3(w * 0.42, h * 0.42, w * 0.42), Vector3(mx, h * 0.76, mz), ms, Vector3(0, ry, 0))

	for i in range(90):
		_bx(wr, Vector3(rng.randf_range(600, 2200), rng.randf_range(60, 180), rng.randf_range(600, 2200)), Vector3(rng.randf_range(-35000, 35000), rng.randf_range(1400, 3200), rng.randf_range(-35000, 35000)), mc)

	for z in range(-2100, 350, 150):
		for x in [-26.0, 26.0]:
			_bx(wr, Vector3(2.5, 2.5, 2.5), Vector3(x, 1.5, float(z)), _mat(Color(0.2, 1, 0.4), 0, true))
	_sync()

func _physics_process(delta: float) -> void:
	cd = max(0.0, cd - delta)
	if cd == 0.0:
		if Input.is_key_pressed(KEY_F):
			flaps = !flaps
			cd = 0.25
		elif Input.is_key_pressed(KEY_G):
			gear = !gear
			_sync()
			cd = 0.25
		elif Input.is_key_pressed(KEY_C):
			pit = !pit
			_sync()
			cd = 0.25
		elif Input.is_key_pressed(KEY_P):
			ap = !ap
			cd = 0.25

	if Input.is_action_pressed("throttle_up"):
		thr = clamp(thr + 0.45 * delta, 0.0, 1.0)
	if Input.is_action_pressed("throttle_down"):
		thr = clamp(thr - 0.45 * delta, 0.0, 1.0)

	var scram = Input.is_key_pressed(KEY_X) and not flaps
	var ab = (thr > 0.85 or scram) and not flaps
	for f in fl:
		f.visible = ab
		f.scale = Vector3(1.1, randf_range(1.6, 2.4) if scram else randf_range(0.95, 1.45), 1.1)

	var max_s = (1250.0 if ab else 520.0) * (1.45 if scram else 1.0) * (0.5 if flaps else 1.0) * (0.65 if gear else 1.0)
	var stall = 48.0 * (0.7 if flaps else 1.0)
	var fwd = -global_transform.basis.z
	spd = clamp(move_toward(spd, max_s if scram else max_s * thr, 95.0 * (2.8 if scram else (1.8 if ab else 1.0)) * delta) - fwd.y * 28.0 * delta, 0.0, 1875.0)

	var auth = clamp(spd / 60.0, 0.12, 1.0)
	var pi = Input.get_axis("pitch_down", "pitch_up")
	var ri = Input.get_axis("roll_right", "roll_left")
	var yi = Input.get_axis("yaw_right", "yaw_left")
	if abs(pi) > 0.05 or abs(ri) > 0.05:
		ap = false

	if ap:
		rotation.x = move_toward(rotation.x, 0.0, 0.8 * delta)
		rotation.z = move_toward(rotation.z, 0.0, 1.2 * delta)
	else:
		rotate_object_local(Vector3.RIGHT, pi * 1.45 * auth * delta)
		rotate_object_local(Vector3.FORWARD, ri * 2.4 * auth * delta)
		rotate_object_local(Vector3.UP, yi * 0.75 * auth * delta)

	rotate_y(sin(rotation.z) * 0.45 * auth * delta)
	var lift = clamp(spd / stall, 0.0, 1.2) * 9.8 + (2.5 if (flaps and spd > stall) else 0.0)
	if spd < stall and global_position.y > 4.0:
		rotate_object_local(Vector3.RIGHT, -0.5 * delta)

	velocity = (fwd * spd) + Vector3.DOWN * max(0.0, 9.8 - lift)
	move_and_slide()

	var gl = 1.0 + (((velocity - p_vel) / max(delta, 0.001)).dot(global_transform.basis.y) / 9.8)
	p_vel = velocity
	if global_position.y < 1.8:
		global_position.y = 1.8
		if rotation.x < 0:
			rotation.x = move_toward(rotation.x, 0.0, 2.5 * delta)
		if thr < 0.15:
			spd = move_toward(spd, 0.0, 22.0 * delta)

	cam.fov = lerp(cam.fov, lerp(70.0, 102.0, spd / 1812.0), 5.0 * delta)
	var vs = int(((global_position.y - p_alt) / delta) * 196.85)
	p_alt = global_position.y
	var mach = spd / 343.0

	hl.text = "=== PFD ===\nIAS: %d KTS (MACH %.2f)\nALT: %d FT | V/S: %+d FPM\nHDG: %03d° | %.1f G\nPITCH: %+d° | ROLL: %+d°\nHOME: %.1f NM" % [int(spd * 1.94384), mach, int(global_position.y * 3.28084), vs, int(fposmod(-rad_to_deg(rotation.y), 360.0)), gl, int(rad_to_deg(rotation.x)), int(rad_to_deg(rotation.z)), global_position.length() / 1852.0]
	hr.text = "=== SYSTEMS ===\nTHR: %d%% (%s)\nGEAR [G]: %s | FLAPS [F]: %s\nAUTOPILOT [P]: %s | VIEW [C]: %s\n[W/S] Pitch [A/D] Roll [Q/E] Yaw\n[Shift/Ctrl] Thr [Hold X] Scramjet" % [int(thr * 100), "SCRAMJET" if scram else ("AB" if ab else "MIL"), "DN" if gear else "UP", "DN" if flaps else "UP", "ON" if ap else "OFF", "PIT" if pit else "EXT"]
	hw.text = "⚠ STALL WARNING ⚠" if (spd < stall and global_position.y > 6.0) else ("⚠ TERRAIN PULL UP ⚠" if (global_position.y < 65.0 and vs < -1500) else ("⚠ DEPLOY GEAR [G] ⚠" if (global_position.y < 15.0 and not gear and spd > 20.0) else (">>> HYPERSONIC MACH %.2f <<<" % mach if scram else (">> SUPERSONIC MACH %.2f <<" % mach if (ab and mach >= 1.0) else ""))))
