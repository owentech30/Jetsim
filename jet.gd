extends CharacterBody3D

@export var max_speed := 180.0
@export var min_speed := 25.0
@export var acceleration := 45.0
@export var pitch_speed := 1.6
@export var roll_speed := 2.4
@export var yaw_speed := 0.8

var current_speed := 65.0
var throttle := 0.5

@onready var hud_label: Label = $"../HUD/InfoLabel"

func _physics_process(delta: float) -> void:
	# Throttle control (Shift / Ctrl)
	if Input.is_action_pressed("throttle_up"):
		throttle = clamp(throttle + 0.4 * delta, 0.0, 1.0)
	if Input.is_action_pressed("throttle_down"):
		throttle = clamp(throttle - 0.4 * delta, 0.0, 1.0)

	var target_speed = lerp(min_speed, max_speed, throttle)
	current_speed = move_toward(current_speed, target_speed, acceleration * delta)

	# Flight rotation controls
	var pitch_input = Input.get_axis("pitch_down", "pitch_up")
	var roll_input = Input.get_axis("roll_right", "roll_left")
	var yaw_input = Input.get_axis("yaw_right", "yaw_left")

	rotate_object_local(Vector3.RIGHT, pitch_input * pitch_speed * delta)
	rotate_object_local(Vector3.FORWARD, roll_input * roll_speed * delta)
	rotate_object_local(Vector3.UP, yaw_input * yaw_speed * delta)

	# Forward thrust + simple gravity/lift balance
	var forward_dir = -global_transform.basis.z
	var lift = clamp(current_speed / 60.0, 0.0, 1.0) * 9.8
	var gravity_pull = Vector3.DOWN * (9.8 - lift)

	velocity = (forward_dir * current_speed) + gravity_pull
	move_and_slide()

	# Keep above ground
	if global_position.y < 1.5:
		global_position.y = 1.5

	# Update HUD
	if hud_label:
		var knots = int(current_speed * 1.94)
		var alt = int(global_position.y * 3.28)
		var thr = int(throttle * 100)
		hud_label.text = "THROTTLE: %d%%\nSPEED: %d KTS\nALTITUDE: %d FT\n\n[W/S] Pitch  [A/D] Roll  [Q/E] Yaw  [Shift/Ctrl] Throttle" % [thr, knots, alt]
