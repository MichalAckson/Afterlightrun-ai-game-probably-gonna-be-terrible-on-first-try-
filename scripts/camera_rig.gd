extends Node3D

var target: Node3D
var camera: Camera3D

func _ready() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 72.0
	camera.near = 0.12
	camera.far = 500.0
	add_child(camera)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var back := target.global_transform.basis.z.normalized()
	var desired := target.global_position + back * 7.4 + Vector3.UP * 3.2
	global_position = global_position.lerp(desired, 1.0 - exp(-5.5 * delta))
	look_at(target.global_position + Vector3.UP * 0.9 - back * 1.8, Vector3.UP)
	var speed := (target as RigidBody3D).linear_velocity.length() if target is RigidBody3D else 0.0
	camera.fov = lerpf(70.0, 80.0, clampf(speed / 48.0, 0.0, 1.0))
