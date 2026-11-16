extends CharacterBody3D

@export var max_thrust_speed := 320.0   # ~620 knots max speed
@export var stall_speed := 42.0         # ~80 knots stall threshold
@export var acceleration := 38.0
@export var pitch_speed := 1.35
@export var roll_speed := 2.2
@export var yaw_speed := 0.65

var current_speed := 95.0
var throttle := 0.65
var flaps_deployed := false
var prev_altitude := 350.0
var flap_toggle_cooldown := 0.0

@onready var hud_left: Label = $"../HUD/TelemetryLabel"
@onready var hud_center: Label = $"../HUD/CrosshairLabel"
@onready var hud_warning: Label = $"../HUD/WarningLabel"
@onready var cam: Camera3D = $Camera3D

func _physics_process(delta: float) -> void:
	flap_toggle_cooldown = max(0.0, flap_toggle_cooldown - delta)

	# Toggle Flaps with F key
	if Input.is_key_pressed(KEY_F) and flap_toggle_cooldown == 0.0:
		flaps_deployed = not flaps_deployed
		flap_toggle_cooldown = 0.3

	# Throttle control (Shift / Ctrl)
	if Input.is_action_pressed("throttle_up"):
		throttle = clamp(throttle + 0.35 * delta, 0.0, 1.0)
	if Input.is_action_pressed("throttle_down"):
		throttle = clamp(throttle - 0.35 * delta, 0.0, 1.0)

	# Flaps add drag (lower top speed) but lower stall speed for landing
	var effective_max_speed = max_thrust_speed * (0.65 if flaps_deployed else 1.0)
	var effective_stall = stall_speed * (0.72 if flaps_deployed else 1.0)

	# Climb/dive affects airspeed realistically (diving speeds up, climbing slows down)
	var forward_dir = -global_transform.basis.z
	var climb_angle = forward_dir.y
	var gravity_speed_effect = -climb_angle * 18.0 * delta

	var target_speed = effective_max_speed * throttle
	current_speed = move_toward(current_speed, target_speed, acceleration * delta) + gravity_speed_effect
	current_speed = clamp(current_speed, 0.0, max_thrust_speed * 1.15)

	# Flight controls (scaled by airflow over control surfaces)
	var control_authority = clamp(current_speed / 55.0, 0.15, 1.0)
	var pitch_input = Input.get_axis("pitch_down", "pitch_up")
	var roll_input = Input.get_axis("roll_right", "roll_left")
	var yaw_input = Input.get_axis("yaw_right", "yaw_left")

	rotate_object_local(Vector3.RIGHT, pitch_input * pitch_speed * control_authority * delta)
	rotate_object_local(Vector3.FORWARD, roll_input * roll_speed * control_authority * delta)
	rotate_object_local(Vector3.UP, yaw_input * yaw_speed * control_authority * delta)

	# Realistic Bank-to-Turn physics (banking naturally curves your heading)
	var bank_angle = rotation.z
	rotate_y(sin(bank_angle) * 0.45 * control_authority * delta)

	# Aerodynamic Lift vs. Gravity & Stall drop
	var lift_ratio = clamp(current_speed / effective_stall, 0.0, 1.15)
	var vertical_lift = lift_ratio * 9.8
	if flaps_deployed and current_speed > effective_stall:
		vertical_lift += 2.2

	var gravity_pull = Vector3.DOWN * max(0.0, 9.8 - vertical_lift)
	if current_speed < effective_stall:
		# Nose drops gently during a stall
		rotate_object_local(Vector3.RIGHT, -0.45 * delta)

	velocity = (forward_dir * current_speed) + gravity_pull
	move_and_slide()

	# Runway & ground touchdown protection
	if global_position.y < 1.6:
		global_position.y = 1.6
		if rotation.x < 0:
			rotation.x = move_toward(rotation.x, 0.0, 2.0 * delta)

	# Dynamic FOV speed sensation
	if cam:
		cam.fov = lerp(70.0, 88.0, current_speed / max_thrust_speed)

	# Calculate MSFS-style flight telemetry
	var knots = int(current_speed * 1.94384)
	var altitude_ft = int(global_position.y * 3.28084)
	var vspeed_fpm = int(((global_position.y - prev_altitude) / delta) * 196.85)
	prev_altitude = global_position.y

	var heading = int(fposmod(-rad_to_deg(rotation.y), 360.0))
	var pitch_deg = int(rad_to_deg(rotation.x))
	var roll_deg = int(rad_to_deg(rotation.z))
	var thr_pct = int(throttle * 100.0)
	var flaps_txt = "DEPLOYED" if flaps_deployed else "UP"

	if hud_left:
		hud_left.text = (
			"=== FLIGHT INSTRUMENTS ===\n"
			+ "IAS:      %d KTS\n" % knots
			+ "ALT:      %d FT\n" % altitude_ft
			+ "V/S:      %+d FPM\n" % vspeed_fpm
			+ "HDG:      %03d°\n" % heading
			+ "PITCH:    %+d°   ROLL: %+d°\n" % [pitch_deg, roll_deg]
			+ "THROTTLE: %d%%   FLAPS: %s [F]\n\n" % [thr_pct, flaps_txt]
			+ "[W/S] Pitch  [A/D] Roll  [Q/E] Yaw\n[Shift/Ctrl] Throttle  [F] Flaps"
		)

	if hud_warning:
		if current_speed < effective_stall and global_position.y > 5.0:
			hud_warning.text = "⚠ STALL WARNING - LOWER NOSE / ADD THROTTLE ⚠"
		elif global_position.y < 45.0 and vspeed_fpm < -1200:
			hud_warning.text = "⚠ PULL UP - TERRAIN AHEAD ⚠"
		else:
			hud_warning.text = ""
