extends RigidBody3D
class_name AfterlightVehicle

signal damage_changed(amount: float)
const WHEEL_RADIUS := 0.34
const REST := 0.36
const TRAVEL := 0.30
const SPRING := 31000.0
const DAMPER := 4300.0
const ENGINE := 8200.0
const BRAKE := 7800.0
const GRIP := 7200.0
const MAX_STEER := 0.48

var throttle_input := 0.0
var brake_input := 0.0
var steer_input := 0.0
var damage := 0.0
var wheels: Array[Dictionary] = []
var paint: StandardMaterial3D
var last_speed := 0.0

func _ready() -> void:
	mass = 1280.0
	linear_damp = 0.08
	angular_damp = 1.15
	can_sleep = false
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)
	_create_vehicle_mesh()

func set_controls(throttle: float, brake: float, steer: float) -> void:
	throttle_input = clampf(throttle, -1.0, 1.0)
	brake_input = clampf(brake, 0.0, 1.0)
	steer_input = clampf(steer, -1.0, 1.0)

func get_speed_kmh() -> float:
	return linear_velocity.length() * 3.6

func get_damage() -> float:
	return damage

func _physics_process(_delta: float) -> void:
	var forward := -global_transform.basis.z.normalized()
	var right := global_transform.basis.x.normalized()
	var longitudinal := linear_velocity.dot(forward)
	last_speed = longitudinal
	if absf(longitudinal) > 0.1:
		apply_central_force(-forward * signf(longitudinal) * brake_input * BRAKE)
	apply_central_force(-right * linear_velocity.dot(right) * 1050.0)
	apply_torque(Vector3.UP * steer_input * clampf(absf(longitudinal) / 4.0, 0.0, 1.0) * 1550.0)
	_apply_suspension()

func _apply_suspension() -> void:
	var up := global_transform.basis.y.normalized()
	var forward := -global_transform.basis.z.normalized()
	var right := global_transform.basis.x.normalized()
	var steer := steer_input * MAX_STEER * clampf(1.0 - absf(last_speed) / 75.0, 0.35, 1.0)
	var anchors := [Vector3(-0.82,-0.12,-1.14),Vector3(0.82,-0.12,-1.14),Vector3(-0.82,-0.12,1.14),Vector3(0.82,-0.12,1.14)]
	for i in range(4):
		var origin := global_transform * anchors[i]
		var query := PhysicsRayQueryParameters3D.create(origin, origin - up * (REST + TRAVEL + WHEEL_RADIUS))
		query.exclude = [get_rid()]
		query.collision_mask = 1
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var point: Vector3 = hit.position
		var length_now := origin.distance_to(point) - WHEEL_RADIUS
		var compression := clampf(REST - length_now, 0.0, TRAVEL)
		var velocity_at_point := linear_velocity + angular_velocity.cross(point - global_position)
		var normal_force := maxf(0.0, compression * SPRING - velocity_at_point.dot(up) * DAMPER)
		apply_force(up * normal_force, point - global_position)
		var angle := -steer if i < 2 else 0.0
		var wheel_forward := forward.rotated(up, angle).normalized()
		var wheel_right := right.rotated(up, angle).normalized()
		var forward_speed := velocity_at_point.dot(wheel_forward)
		var side_speed := velocity_at_point.dot(wheel_right)
		var grip_force := clampf(-side_speed * GRIP, -normal_force * 1.25, normal_force * 1.25)
		apply_force(wheel_right * grip_force, point - global_position)
		if i >= 2:
			apply_force(wheel_forward * ENGINE * throttle_input * 0.5, point - global_position)
			if brake_input > 0.05:
				apply_force(wheel_forward * clampf(-forward_speed * 2500.0, -BRAKE, BRAKE) * brake_input, point - global_position)
		_update_wheel(i, origin, up, length_now, angle)

func _update_wheel(index: int, origin: Vector3, up: Vector3, length_now: float, angle: float) -> void:
	if index >= wheels.size():
		return
	var w: Dictionary = wheels[index]
	var pivot: Node3D = w["pivot"]
	pivot.global_position = origin - up * length_now
	pivot.rotation.y = angle
	var mesh: MeshInstance3D = w["mesh"]
	mesh.rotate_x(-last_speed * get_physics_process_delta_time() / WHEEL_RADIUS)

func _create_vehicle_mesh() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.88, 0.68, 4.05)
	collision.shape = shape
	collision.position = Vector3(0, 0.08, 0)
	add_child(collision)
	paint = _material(Color(0.10, 0.42, 0.58), 0.28, 0.54)
	_box(Vector3(1.95,0.48,4.0), Vector3(0,0.05,0), paint)
	_box(Vector3(1.70,0.56,1.70), Vector3(0,0.48,-0.48), _material(Color(0.025,0.075,0.105),0.15,0.22))
	_box(Vector3(1.80,0.16,0.60), Vector3(0,-0.17,-1.78), _material(Color(0.05,0.07,0.08),0.3,0.7))
	_box(Vector3(1.80,0.16,0.60), Vector3(0,-0.17,1.78), _material(Color(0.05,0.07,0.08),0.3,0.7))
	for i in range(4):
		var pivot := Node3D.new()
		pivot.position = Vector3(-0.88 if i % 2 == 0 else 0.88, -0.12, -1.18 if i < 2 else 1.18)
		add_child(pivot)
		var tire := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = WHEEL_RADIUS
		cylinder.bottom_radius = WHEEL_RADIUS
		cylinder.height = 0.24
		tire.mesh = cylinder
		tire.rotation.z = PI / 2.0
		tire.material_override = _material(Color(0.025,0.03,0.035),0.0,0.92)
		pivot.add_child(tire)
		wheels.append({"pivot":pivot,"mesh":tire})

func _box(size: Vector3, at: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

func _on_body_entered(_body: Node) -> void:
	var impact := linear_velocity.length()
	if impact > 9.0:
		damage = clampf(damage + (impact - 9.0) * 0.75, 0.0, 100.0)
		if paint:
			paint.albedo_color = Color(0.10,0.42,0.58).lerp(Color(0.30,0.20,0.18), damage/100.0)
		damage_changed.emit(damage)
