extends Node3D

const VehicleScript = preload("res://scripts/vehicle_controller.gd")
const CameraRigScript = preload("res://scripts/camera_rig.gd")
const PRESETS := ["VERY LOW", "LOW", "MEDIUM", "HIGH", "ULTRA"]
const SCALES := [0.70, 0.80, 0.90, 1.0, 1.0]

var car
var camera_rig
var world_environment: Environment
var gates: Array[Node3D] = []
var gate_index := 0
var started := false
var finished := false
var preset := 2
var held := {"left":false,"right":false,"drive":false,"brake":false}
var controls: Array[Button] = []
var title_panel: PanelContainer
var hud_panel: PanelContainer
var mission: Label
var speed: Label
var condition: Label
var preset_label: Label
var engine_audio: AudioStreamPlayer3D
var dispatcher: AudioStreamPlayer

func _ready() -> void:
	_setup_input()
	_make_environment()
	_make_city()
	_make_gates()
	_make_vehicle()
	_make_ui()
	_set_preset(preset)

func _process(_delta: float) -> void:
	if car == null:
		return
	var steer := Input.get_action_strength("right") - Input.get_action_strength("left")
	if held.left: steer -= 1.0
	if held.right: steer += 1.0
	var throttle := Input.get_action_strength("drive")
	var brake := Input.get_action_strength("brake")
	if held.drive: throttle = 1.0
	if held.brake: brake = 1.0
	car.set_controls(throttle, brake, clampf(steer,-1.0,1.0))
	if engine_audio:
		engine_audio.pitch_scale = 0.78 + clampf(car.get_speed_kmh()/140.0,0.0,1.0)*0.72
	if started and not finished:
		_check_progress()
	speed.text = "%03d KM/H" % int(car.get_speed_kmh())
	condition.text = "BODY CONDITION  %02d%%" % int(100.0-car.get_damage())

func _setup_input() -> void:
	_key("drive",KEY_W); _key("drive",KEY_UP)
	_key("brake",KEY_S); _key("brake",KEY_DOWN)
	_key("left",KEY_A); _key("left",KEY_LEFT)
	_key("right",KEY_D); _key("right",KEY_RIGHT)

func _key(action: String, code: int) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = code
	InputMap.action_add_event(action,event)

func _make_environment() -> void:
	var node := WorldEnvironment.new()
	world_environment = Environment.new()
	world_environment.background_mode = Environment.BG_COLOR
	world_environment.background_color = Color(0.045,0.065,0.12)
	world_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_environment.ambient_light_color = Color(0.44,0.50,0.65)
	world_environment.ambient_light_energy = 0.8
	world_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.glow_enabled = true
	world_environment.glow_intensity = 0.3
	world_environment.fog_enabled = true
	world_environment.fog_light_color = Color(0.48,0.32,0.30)
	world_environment.fog_density = 0.0014
	node.environment = world_environment
	add_child(node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-24,-28,0)
	sun.light_color = Color(1.0,0.72,0.54)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	var ground := StaticBody3D.new()
	ground.collision_layer = 1
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(180,1,360)
	mesh.mesh = box
	mesh.position = Vector3(0,-0.55,-35)
	mesh.material_override = _mat(Color(0.10,0.20,0.15))
	ground.add_child(mesh)
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = box.size
	shape.shape = collider
	shape.position = mesh.position
	ground.add_child(shape)
	add_child(ground)

func _make_city() -> void:
	_static_box(Vector3(18,0.22,300),Vector3(0,-0.01,-35),Color(0.16,0.18,0.23),true)
	_static_box(Vector3(2.2,0.18,300),Vector3(-10,0.02,-35),Color(0.63,0.67,0.72),false)
	_static_box(Vector3(2.2,0.18,300),Vector3(10,0.02,-35),Color(0.63,0.67,0.72),false)
	for z in range(-178,112,12):
		_static_box(Vector3(0.18,0.025,4.4),Vector3(0,0.115,z),Color(0.88,0.82,0.67),false)
	for z in range(-175,105,28):
		for side in [-1.0,1.0]:
			var x: float = float(side) * randf_range(18.0,31.0)
			var h := randf_range(12.0,35.0)
			var dims := Vector3(randf_range(8.0,13.0),h,randf_range(10.0,18.0))
			var color := Color(randf_range(0.19,0.37),randf_range(0.23,0.38),randf_range(0.31,0.48))
			_static_box(dims,Vector3(x,h*0.5,z+randf_range(-5,5)),color,false)
	for z in range(-160,95,24):
		for side in [-1.0,1.0]:
			_static_box(Vector3(0.12,5.2,0.12),Vector3(side*11.3,2.6,z),Color(0.1,0.13,0.18),false)
	for z in [-50.0,-125.0]:
		_tree(14.5,z); _tree(-14.5,z-12.0)

func _make_gates() -> void:
	for p in [Vector3(0,2.1,8),Vector3(0,2.1,-48),Vector3(0,2.1,-104)]:
		var gate := Node3D.new()
		gate.position = p
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.7
		torus.outer_radius = 1.88
		ring.mesh = torus
		ring.material_override = _emission(Color(0.12,0.84,1.0),1.5)
		gate.add_child(ring)
		add_child(gate)
		gates.append(gate)
	var finish := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(13,0.12,1.1)
	finish.mesh = mesh
	finish.position = Vector3(0,0.22,-148)
	finish.material_override = _emission(Color(0.1,0.8,0.52),1.2)
	add_child(finish)

func _make_vehicle() -> void:
	car = VehicleScript.new()
	car.name = "PlayerVehicle"
	car.position = Vector3(0,0.92,54)
	car.collision_layer = 2
	car.collision_mask = 1
	add_child(car)
	camera_rig = CameraRigScript.new()
	camera_rig.target = car
	camera_rig.position = Vector3(0,3.2,7.4)
	add_child(camera_rig)
	car.damage_changed.connect(_damage_changed)
	for x in [-0.58,0.58]:
		var light := SpotLight3D.new()
		light.position = Vector3(x,0.16,-1.88)
		light.spot_range = 34
		light.spot_angle = 48
		light.light_energy = 1.65
		light.light_color = Color(1,0.86,0.68)
		light.shadow_enabled = false
		car.add_child(light)
	if ResourceLoader.exists("res://assets/audio/engine_loop.wav"):
		engine_audio = AudioStreamPlayer3D.new()
		engine_audio.stream = load("res://assets/audio/engine_loop.wav")
		engine_audio.volume_db = -13
		car.add_child(engine_audio)
		engine_audio.play()
	if ResourceLoader.exists("res://assets/audio/dispatcher_first_light.wav"):
		dispatcher = AudioStreamPlayer.new()
		dispatcher.stream = load("res://assets/audio/dispatcher_first_light.wav")
		add_child(dispatcher)

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	title_panel = PanelContainer.new()
	title_panel.anchor_left = 0.5; title_panel.anchor_right = 0.5
	title_panel.anchor_top = 0.5; title_panel.anchor_bottom = 0.5
	title_panel.offset_left = -250; title_panel.offset_right = 250
	title_panel.offset_top = -155; title_panel.offset_bottom = 155
	root.add_child(title_panel)
	var vbox := VBoxContainer.new()
	title_panel.add_child(vbox)
	var title := Label.new()
	title.text = "AFTERLIGHT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",38)
	title.add_theme_color_override("font_color",Color(0.6,0.91,1.0))
	vbox.add_child(title)
	var intro := Label.new()
	intro.text = "FIVE RUNS  /  A CINEMATIC DRIVING STORY\n\nFIRST LIGHT\nReconnect three city signal gates, then take the southern exit."
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	var start := Button.new()
	start.text = "START FIRST RUN"
	start.custom_minimum_size = Vector2(0,52)
	start.pressed.connect(_start)
	vbox.add_child(start)
	hud_panel = PanelContainer.new()
	hud_panel.anchor_left = 0.02; hud_panel.anchor_top = 0.025
	hud_panel.anchor_right = 0.40; hud_panel.anchor_bottom = 0.19
	root.add_child(hud_panel)
	var hud := VBoxContainer.new()
	hud_panel.add_child(hud)
	mission = Label.new(); mission.text = "MISSION 1 / FIRST LIGHT"; hud.add_child(mission)
	speed = Label.new(); speed.add_theme_font_size_override("font_size",24); hud.add_child(speed)
	condition = Label.new(); hud.add_child(condition)
	preset_label = Label.new()
	preset_label.anchor_left = 0.72; preset_label.anchor_top = 0.035
	preset_label.anchor_right = 0.98; preset_label.anchor_bottom = 0.09
	preset_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(preset_label)
	var quality := Button.new()
	quality.text = "GRAPHICS  ▸"
	quality.anchor_left = 0.82; quality.anchor_top = 0.10
	quality.anchor_right = 0.98; quality.anchor_bottom = 0.18
	quality.pressed.connect(_cycle_quality)
	root.add_child(quality)
	_touch(root,"◀",Vector2(28,-112),Vector2(88,78),"left")
	_touch(root,"▶",Vector2(124,-112),Vector2(88,78),"right")
	_touch(root,"BRAKE",Vector2(-250,-112),Vector2(108,78),"brake")
	_touch(root,"DRIVE",Vector2(-132,-112),Vector2(120,78),"drive")
	_set_controls(false)

func _touch(root: Control, caption: String, offset: Vector2, size: Vector2, action: String) -> void:
	var button := Button.new()
	button.text = caption; button.custom_minimum_size = size
	button.anchor_left = 0.0 if action in ["left","right"] else 1.0
	button.anchor_right = button.anchor_left
	button.anchor_top = 1.0; button.anchor_bottom = 1.0
	button.offset_left = offset.x; button.offset_right = offset.x+size.x
	button.offset_top = offset.y; button.offset_bottom = offset.y+size.y
	button.button_down.connect(func(): held[action] = true)
	button.button_up.connect(func(): held[action] = false)
	button.set_meta("drive_control",true)
	root.add_child(button)
	controls.append(button)

func _set_controls(showing: bool) -> void:
	for button in controls:
		button.visible = showing
		button.disabled = not showing
	hud_panel.visible = showing

func _start() -> void:
	started = true
	title_panel.visible = false
	_set_controls(true)
	mission.text = "MISSION 1 / FIRST LIGHT  •  Signal gate 1 of 3"
	if dispatcher: dispatcher.play()

func _cycle_quality() -> void:
	preset = (preset+1)%PRESETS.size()
	_set_preset(preset)

func _set_preset(level: int) -> void:
	preset_label.text = "GRAPHICS: "+PRESETS[level]
	world_environment.glow_enabled = level >= 3
	world_environment.fog_enabled = level >= 2
	var sun := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sun:
		sun.shadow_enabled = level >= 3
		sun.directional_shadow_max_distance = 65.0 if level == 3 else 95.0
	get_viewport().scaling_3d_scale = SCALES[level]

func _check_progress() -> void:
	if gate_index < gates.size():
		if car.global_position.distance_to(gates[gate_index].global_position) < 5.7:
			gates[gate_index].queue_free()
			gate_index += 1
			mission.text = "SIGNALS RESTORED  •  Reach the green finish" if gate_index == gates.size() else "MISSION 1 / FIRST LIGHT  •  Signal gate %d of 3" % (gate_index+1)
	elif car.global_position.z < -142.0 and absf(car.global_position.x) < 8.0:
		finished = true
		mission.text = "RUN COMPLETE  •  FIRST LIGHT CLEARED"

func _damage_changed(amount: float) -> void:
	condition.text = "BODY CONDITION  %02d%%" % int(100.0-amount)

func _static_box(size: Vector3, pos: Vector3, color: Color, solid: bool) -> void:
	var mesh := MeshInstance3D.new()
	var shape_mesh := BoxMesh.new()
	shape_mesh.size = size
	mesh.mesh = shape_mesh; mesh.position = pos
	mesh.material_override = _mat(color)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.add_child(mesh)
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new(); box.size = size
		collision.shape = box; collision.position = pos
		body.add_child(collision); add_child(body)
	else:
		add_child(mesh)

func _tree(x: float, z: float) -> void:
	_static_box(Vector3(0.32,2.4,0.32),Vector3(x,1.2,z),Color(0.19,0.12,0.09),false)
	for n in range(3):
		var crown := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.2-n*0.12; sphere.height = 2.2-n*0.16
		crown.mesh = sphere
		crown.position = Vector3(x,3.1+n*0.48,z)
		crown.material_override = _mat(Color(0.08,0.25,0.21))
		crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(crown)

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material

func _emission(color: Color, energy: float) -> StandardMaterial3D:
	var material := _mat(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
