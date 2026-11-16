extends CharacterBody3D

const PLANES = [
	{"name": "F-22 RAPTOR STEALTH", "mil": 520.0, "ab": 1250.0, "stall": 48.0, "acc": 95.0, "turn": 1.45, "roll": 2.4, "col": Color(0.36, 0.4, 0.45), "type": "f22"},
	{"name": "SR-71 BLACKBIRD", "mil": 850.0, "ab": 1950.0, "stall": 75.0, "acc": 120.0, "turn": 1.0, "roll": 1.7, "col": Color(0.11, 0.12, 0.15), "type": "sr71"},
	{"name": "CESSNA 172 SKYHAWK", "mil": 115.0, "ab": 145.0, "stall": 26.0, "acc": 35.0, "turn": 1.25, "roll": 1.8, "col": Color(0.92, 0.92, 0.94), "type": "cessna"},
	{"name": "A-10 THUNDERBOLT II", "mil": 280.0, "ab": 420.0, "stall": 38.0, "acc": 65.0, "turn": 1.65, "roll": 2.1, "col": Color(0.33, 0.37, 0.32), "type": "a10"}
]

var state := "MENU"
var sel := 0
var spd := 0.0
var thr := 0.0
var flaps := false
var gear := true
var pit := false
var ap := false
var p_alt := 1.8
var p_vel := Vector3.ZERO
var cd := 0.0
var tod := 0.25
var score := 0
var orbit := 0.0

var body_root: Node3D
var prop: MeshInstance3D
var cam: Camera3D
var dash: Node3D
var g_grp: Node3D
var fl: Array[MeshInstance3D] = []
var rings: Array[Node3D] = []
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var menu_ui: Control
var flight_ui: Control
var menu_lbl: Label
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

func _lb(p: Node, anc: int, off: Vector4, col: Color, sz: int, al := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.set_anchors_preset(anc)
	l.offset_left = off.x
	l.offset_top = off.y
	l.offset_right = off.z
	l.offset_bottom = off.w
	l.horizontal_alignment = al
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", sz)
	p.add_child(l)
	return l
func _build_aircraft(idx: int) -> void:
	if body_root:
		body_root.queue_free()
	fl.clear()
	prop = null
	body_root = Node3D.new()
	add_child(body_root)

	var p = PLANES[idx]
	var hull = _mat(p["col"], 0.55)
	var trim = _mat(Color(0.2, 0.22, 0.26), 0.65)
	var gls = _mat(Color(0.85, 0.62, 0.18), 0.9, false, 0.85)
	var drk = _mat(Color(0.11, 0.12, 0.14), 0.3)
	var flame = _mat(Color(1.0, 0.5, 0.08), 0.0, true)

	if p["type"] == "cessna":
		_bx(body_root, Vector3(1.1, 1.1, 4.6), Vector3(0, 0.1, 0.2), hull)
		_pr(body_root, Vector3(0.9, 2.8, 0.9), Vector3(0, 0.1, 3.6), hull, Vector3(90, 0, 0))
		_bx(body_root, Vector3(1.05, 0.55, 1.8), Vector3(0, 0.45, -0.6), _mat(Color(0.2, 0.45, 0.7), 0.5, false, 0.8))
		_bx(body_root, Vector3(10.8, 0.12, 1.5), Vector3(0, 0.85, -0.2), hull)
		_bx(body_root, Vector3(3.6, 0.1, 0.9), Vector3(0, 0.2, 4.4), trim)
		_pr(body_root, Vector3(1.4, 1.5, 0.12), Vector3(0, 0.95, 4.3), _mat(Color(0.85, 0.2, 0.2)), Vector3(0, 90, 0))
		prop = _bx(body_root, Vector3(2.1, 0.18, 0.06), Vector3(0, 0.1, -2.25), drk)
	else:
		var len_m = 1.35 if p["type"] == "sr71" else 1.0
		_cy(body_root, 0.65, 0.82, 6.2 * len_m, Vector3(0, 0, 0.4), hull, Vector3(90, 0, 0))
		_cy(body_root, 0.02, 0.65, 3.4 * len_m, Vector3(0, -0.05, -4.4 * len_m), trim, Vector3(90, 0, 0))
		_cy(body_root, 0.32, 0.48, 2.6, Vector3(0, 0.55, -1.7), gls, Vector3(84, 0, 0))
		_pr(body_root, Vector3(1.5, 3.8, 0.85), Vector3(0, 0.25, -2.2), hull, Vector3(-90, 0, 0))
		for s in [-1.0, 1.0]:
			_bx(body_root, Vector3(0.65, 0.72, 3.2), Vector3(0.88 * s, -0.08, -0.6), trim)
			_cy(body_root, 0.36, 0.44, 0.9, Vector3(0.45 * s, 0, 3.85), drk, Vector3(90, 0, 0))
			if p["type"] == "a10":
				_bx(body_root, Vector3(5.6, 0.15, 1.8), Vector3(3.1 * s, 0.05, 0.4), hull)
				_cy(body_root, 0.45, 0.45, 2.2, Vector3(1.1 * s, 0.65, 2.2), trim, Vector3(90, 0, 0))
			else:
				_pr(body_root, Vector3(3.4, 4.4 * len_m, 0.14), Vector3(2.9 * s, 0.02, 0.9), hull, Vector3(90, 90 * s, 0))
			_bx(body_root, Vector3(0.16, 0.16, 0.25), Vector3(5.1 * s, 0.05, 0.35), _mat(Color(1, 0.15, 0.15) if s < 0 else Color(0.15, 1, 0.25), 0, true))
			_pr(body_root, Vector3(1.8, 2.2, 0.1), Vector3(1.7 * s, 0, 3.4), trim, Vector3(90, 90 * s, 0))
			_pr(body_root, Vector3(1.9, 1.8, 0.12), Vector3(0.95 * s, 0.9, 3.1), hull, Vector3(0, 90, -24 * s))
			fl.append(_cy(body_root, 0.05, 0.34, 3.2, Vector3(0.45 * s, 0, 5.7), flame, Vector3(90, 0, 0)))

	g_grp = Node3D.new()
	body_root.add_child(g_grp)
	for gp in [Vector3(0, -0.85, -2.5), Vector3(-1.4, -0.85, 1.2), Vector3(1.4, -0.85, 1.2)]:
		_cy(g_grp, 0.08, 0.08, 0.95, gp, trim)
		_cy(g_grp, 0.32, 0.32, 0.22, gp + Vector3(0, -0.45, 0), drk, Vector3(0, 0, 90))
	_sync()

func _sync() -> void:
	if g_grp:
		g_grp.visible = gear
	if dash:
		dash.visible = pit and state == "FLY"
	if cam and state == "FLY":
		cam.position = Vector3(0, 0.78, -1.35) if pit else Vector3(0, 3.2, 12.5)
		cam.rotation_degrees = Vector3(-2 if pit else -12, 0, 0)

func _enter_menu() -> void:
	state = "MENU"
	spd = 0.0
	thr = 0.0
	gear = true
	pit = false
	ap = false
	global_position = Vector3(0, 1.8, 120)
	rotation = Vector3.ZERO
	menu_ui.visible = true
	flight_ui.visible = false
	_build_aircraft(sel)

func _start_flight() -> void:
	state = "FLY"
	menu_ui.visible = false
	flight_ui.visible = true
	global_position = Vector3(0, 1.8, 120)
	rotation = Vector3.ZERO
	thr = 0.0
	spd = 0.0
	gear = true
	_sync()
func _ready() -> void:
	var col = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(5, 1.5, 9)
	col.shape = bs
	add_child(col)

	dash = Node3D.new()
	add_child(dash)
	_bx(dash, Vector3(0.95, 0.35, 0.6), Vector3(0, 0.32, -2.1), _mat(Color(0.11, 0.12, 0.14)))
	cam = Camera3D.new()
	cam.far = 15000.0
	add_child(cam)

	var cv = CanvasLayer.new()
	add_child(cv)
	var grn = Color(0.15, 1, 0.35)
	var gold = Color(1.0, 0.85, 0.25)

	menu_ui = Control.new()
	menu_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	cv.add_child(menu_ui)
	_lb(menu_ui, Control.PRESET_CENTER_TOP, Vector4(-450, 30, 450, 95), gold, 32, HORIZONTAL_ALIGNMENT_CENTER).text = "SKYWARD FLIGHT SIMULATOR"
	menu_lbl = _lb(menu_ui, Control.PRESET_CENTER_BOTTOM, Vector4(-480, -210, 480, -30), Color.WHITE, 20, HORIZONTAL_ALIGNMENT_CENTER)

	flight_ui = Control.new()
	flight_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	cv.add_child(flight_ui)
	hl = _lb(flight_ui, Control.PRESET_TOP_LEFT, Vector4(20, 20, 480, 280), grn, 17)
	hr = _lb(flight_ui, Control.PRESET_TOP_RIGHT, Vector4(-420, 20, -20, 290), grn, 16, HORIZONTAL_ALIGNMENT_RIGHT)
	_lb(flight_ui, Control.PRESET_CENTER, Vector4(-60, -20, 60, 20), grn, 24, HORIZONTAL_ALIGNMENT_CENTER).text = "---( + )---"
	hw = _lb(flight_ui, Control.PRESET_CENTER_TOP, Vector4(-320, 36, 320, 85), Color(1, 0.25, 0.2), 20, HORIZONTAL_ALIGNMENT_CENTER)

	var wr = get_tree().root
	var rng = RandomNumberGenerator.new()
	rng.seed = 2026
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.08, 0.28, 0.72)
	sky_mat.sky_horizon_color = Color(0.66, 0.82, 0.96)
	var sky = Sky.new()
	sky.sky_material = sky_mat
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

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.25
	wr.add_child(sun)

	var pm1 = PlaneMesh.new()
	pm1.size = Vector2(160000, 160000)
	_mk(wr, pm1, Vector3(0, -0.5, 0), _mat(Color(0.06, 0.24, 0.48)))
	var pm2 = PlaneMesh.new()
	pm2.size = Vector2(100000, 100000)
	_mk(wr, pm2, Vector3.ZERO, _mat(Color(0.2, 0.4, 0.22)))

	var drk = _mat(Color(0.13, 0.14, 0.16))
	var wht = _mat(Color(0.95, 0.95, 0.95), 0, true)
	_bx(wr, Vector3(50, 0.5, 2400), Vector3(0, 0.25, -900), drk)
	_bx(wr, Vector3(50, 0.5, 2400), Vector3(14000, 0.25, -22000), drk, Vector3(0, 45, 0))
	_bx(wr, Vector3(18, 45, 18), Vector3(65, 22.5, -800), _mat(Color(0.4, 0.45, 0.5)))
	for z in range(-2050, 250, 90):
		_bx(wr, Vector3(1.5, 0.6, 35), Vector3(0, 0.3, float(z)), wht)

	for i in range(55):
		var bx_x = rng.randf_range(900.0, 4500.0)
		var bx_z = rng.randf_range(-6500.0, -1800.0)
		var bh = rng.randf_range(80.0, 460.0)
		var bw = rng.randf_range(65.0, 160.0)
		_bx(wr, Vector3(bw, bh, bw), Vector3(bx_x, bh * 0.5, bx_z), _mat(Color(0.25, 0.32, 0.42), 0.7))

	var mm = _mat(Color(0.28, 0.33, 0.3))
	var ms = _mat(Color(0.92, 0.95, 0.98))
	var mc = _mat(Color(1, 1, 1), 0, false, 0.82)
	for i in range(70):
		var mx = rng.randf_range(-42000, 42000)
		var mz = rng.randf_range(-42000, 42000)
		if abs(mx) < 5200 and abs(mz) < 7500:
			continue
		var h = rng.randf_range(600, 2600)
		var w = rng.randf_range(1600, 4200)
		var ry = rng.randf_range(0, 360)
		_pr(wr, Vector3(w, h, w), Vector3(mx, h * 0.48, mz), mm, Vector3(0, ry, 0))
		if h > 1200:
			_pr(wr, Vector3(w * 0.42, h * 0.42, w * 0.42), Vector3(mx, h * 0.76, mz), ms, Vector3(0, ry, 0))

	for i in range(95):
		_bx(wr, Vector3(rng.randf_range(600, 2200), rng.randf_range(60, 180), rng.randf_range(600, 2200)), Vector3(rng.randf_range(-35000, 35000), rng.randf_range(1400, 3200), rng.randf_range(-35000, 35000)), mc)

	var ring_mat = _mat(gold, 0, true)
	for i in range(20):
		var rg = Node3D.new()
		rg.position = Vector3(sin(i * 0.6) * 1800.0, 280.0 + i * 55.0, -1600.0 - i * 1100.0)
		_bx(rg, Vector3(95, 6, 6), Vector3(0, 45, 0), ring_mat)
		_bx(rg, Vector3(95, 6, 6), Vector3(0, -45, 0), ring_mat)
		_bx(rg, Vector3(6, 95, 6), Vector3(-45, 0, 0), ring_mat)
		_bx(rg, Vector3(6, 95, 6), Vector3(45, 0, 0), ring_mat)
		wr.add_child(rg)
		rings.append(rg)

	_enter_menu()

func _physics_process(delta: float) -> void:
	cd = max(0.0, cd - delta)
	if prop:
		prop.rotate_z(25.0 * delta * max(0.2, thr))

	if state == "MENU":
		orbit += 0.55 * delta
		cam.position = Vector3(sin(orbit) * 14.0, 4.2, cos(orbit) * 14.0)
		cam.look_at(global_position + Vector3(0, 0.8, 0), Vector3.UP)
		if cd == 0.0:
			if Input.is_action_just_pressed("ui_right") or Input.is_key_pressed(KEY_D):
				sel = (sel + 1) % PLANES.size()
				_build_aircraft(sel)
				cd = 0.22
			elif Input.is_action_just_pressed("ui_left") or Input.is_key_pressed(KEY_A):
				sel = (sel - 1 + PLANES.size()) % PLANES.size()
				_build_aircraft(sel)
				cd = 0.22
			elif Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
				_start_flight()
				cd = 0.3
		var p = PLANES[sel]
		menu_lbl.text = "< [A / D] SELECT AIRCRAFT (%d/%d) >\n\n%s\nTOP SPEED: %d KTS   |   STALL: %d KTS\n\nPRESS [ENTER] OR [SPACE] TO LAUNCH ON RUNWAY" % [sel + 1, PLANES.size(), p["name"], int(p["ab"] * 1.94), int(p["stall"] * 1.94)]
		return

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
		elif Input.is_key_pressed(KEY_M):
			_enter_menu()
			cd = 0.3
			return
		elif Input.is_key_pressed(KEY_T):
			tod = fmod(tod + 0.25, 1.0)
			sun.rotation_degrees.x = lerp(-15.0, -165.0, tod)
			sun.light_energy = 0.25 if tod > 0.7 else 1.25
			sky_mat.sky_top_color = Color(0.02, 0.04, 0.14) if tod > 0.7 else Color(0.08, 0.28, 0.72)
			cd = 0.25

	for rg in rings:
		if rg.visible and global_position.distance_to(rg.position) < 62.0:
			rg.visible = false
			score += 1

	var p = PLANES[sel]
	if Input.is_action_pressed("throttle_up"):
		thr = clamp(thr + 0.45 * delta, 0.0, 1.0)
	if Input.is_action_pressed("throttle_down"):
		thr = clamp(thr - 0.45 * delta, 0.0, 1.0)

	var scram = Input.is_key_pressed(KEY_X) and not flaps and p["type"] != "cessna"
	var ab = (thr > 0.85 or scram) and not flaps
	for f in fl:
		f.visible = ab
		f.scale = Vector3(1.1, randf_range(1.6, 2.4) if scram else randf_range(0.95, 1.45), 1.1)

	var max_s = (p["ab"] if ab else p["mil"]) * (1.45 if scram else 1.0) * (0.5 if flaps else 1.0) * (0.65 if gear else 1.0)
	var stall = p["stall"] * (0.7 if flaps else 1.0)
	var fwd = -global_transform.basis.z
	spd = clamp(move_toward(spd, max_s if scram else max_s * thr, p["acc"] * (2.8 if scram else (1.8 if ab else 1.0)) * delta) - fwd.y * 28.0 * delta, 0.0, 2800.0)

	var auth = clamp(spd / max(20.0, stall), 0.12, 1.0)
	var pi = Input.get_axis("pitch_down", "pitch_up")
	var ri = Input.get_axis("roll_right", "roll_left")
	var yi = Input.get_axis("yaw_right", "yaw_left")
	if abs(pi) > 0.05 or abs(ri) > 0.05:
		ap = false

	if ap:
		rotation.x = move_toward(rotation.x, 0.0, 0.8 * delta)
		rotation.z = move_toward(rotation.z, 0.0, 1.2 * delta)
	else:
		rotate_object_local(Vector3.RIGHT, pi * p["turn"] * auth * delta)
		rotate_object_local(Vector3.FORWARD, ri * p["roll"] * auth * delta)
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

	cam.fov = lerp(cam.fov, lerp(70.0, 102.0, spd / 2000.0), 5.0 * delta)
	var vs = int(((global_position.y - p_alt) / delta) * 196.85)
	p_alt = global_position.y
	var mach = spd / 343.0

	hl.text = "=== %s ===\nIAS: %d KTS (MACH %.2f)\nALT: %d FT | V/S: %+d FPM\nHDG: %03d° | %.1f G\nRINGS: %d / 20" % [p["name"], int(spd * 1.94384), mach, int(global_position.y * 3.28084), vs, int(fposmod(-rad_to_deg(rotation.y), 360.0)), gl, score]
	hr.text = "=== SYSTEMS ===\nTHR: %d%% | GEAR [G]: %s | FLAPS [F]: %s\nAUTOPILOT [P]: %s | VIEW [C]: %s\n[T] Time of Day | [M] Hangar Menu\n[Shift/Ctrl] Thr | [Hold X] Boost" % [int(thr * 100), "DN" if gear else "UP", "DN" if flaps else "UP", "ON" if ap else "OFF", "PIT" if pit else "EXT"]
	hw.text = "⚠ STALL WARNING ⚠" if (spd < stall and global_position.y > 6.0) else ("⚠ TERRAIN PULL UP ⚠" if (global_position.y < 65.0 and vs < -1500) else ("⚠ DEPLOY GEAR [G] ⚠" if (global_position.y < 15.0 and not gear and spd > 20.0) else (">>> HYPERSONIC MACH %.2f <<<" % mach if scram else "")))
