extends Node3D

var defeated := 0
var total_enemies := 3
var won := false
var lost := false
@onready var player = $Player
@onready var objective: Label = $HUD/Objective
@onready var health_label: Label = $HUD/Health
@onready var ammo_label: Label = $HUD/Ammo
@onready var message: Label = $HUD/Message
@onready var exit_door: MeshInstance3D = $ExitDoor

func _ready() -> void:
    add_to_group("game")
    player.health_changed.connect(_on_health_changed)
    player.ammo_changed.connect(_on_ammo_changed)
    player.fired.connect(_on_fired)
    objective.text = "Objective: survive and reach the exit"
    message.text = ""
    _build_city_district()

func _process(_delta: float) -> void:
    if won or lost: return
    if defeated >= total_enemies:
        objective.text = "Objective: the exit is unlocked — reach the blue door"
        exit_door.get_active_material(0).emission_enabled = true
        if player.global_position.distance_to(exit_door.global_position) < 2.2:
            won = true
            message.text = "YOU ESCAPED THE NIGHTFALL\nPress R to restart"
    if Input.is_key_pressed(KEY_R) and (won or lost): get_tree().reload_current_scene()

func enemy_defeated() -> void:
    defeated += 1
    objective.text = "Enemies remaining: %d" % (total_enemies - defeated)

func player_died() -> void:
    lost = true
    message.text = "YOU DID NOT MAKE IT OUT\nPress R to restart"

func collect_pickup(kind: String) -> void:
    if kind == "ammo": player.collect_ammo(12)
    if kind == "medkit": player.heal(35)

func _on_health_changed(value: int) -> void: health_label.text = "Health: %d" % value
func _on_ammo_changed(current: int, reserve: int) -> void: ammo_label.text = "Ammo: %d / %d" % [current, reserve]
func _on_fired() -> void: message.text = ""
func _build_city_district() -> void:
    var building_materials: Array[StandardMaterial3D] = []
    for color in [Color(0.16, 0.22, 0.32), Color(0.32, 0.18, 0.24), Color(0.16, 0.32, 0.30), Color(0.38, 0.25, 0.14), Color(0.24, 0.18, 0.38)]:
        var material := StandardMaterial3D.new()
        material.albedo_color = color
        material.roughness = 0.86
        building_materials.append(material)

    var blocks := [
        Vector3(-25, 3.5, -20), Vector3(-13, 4.5, -20), Vector3(13, 4.0, -20), Vector3(25, 3.0, -20),
        Vector3(-25, 3.0, 20), Vector3(-13, 4.0, 20), Vector3(13, 4.5, 20), Vector3(25, 3.5, 20),
        Vector3(-31, 3.0, -9), Vector3(31, 4.0, -10), Vector3(-31, 4.5, 10), Vector3(31, 3.0, 11)
    ]
    var sizes := [
        Vector3(9, 7, 7), Vector3(8, 9, 7), Vector3(8, 8, 7), Vector3(9, 6, 7),
        Vector3(9, 6, 7), Vector3(8, 8, 7), Vector3(8, 9, 7), Vector3(9, 7, 7),
        Vector3(6, 6, 10), Vector3(6, 8, 10), Vector3(6, 9, 10), Vector3(6, 6, 10)
    ]

    for index in blocks.size():
        var body := StaticBody3D.new()
        body.name = "CityBuilding_%02d" % index
        body.position = blocks[index]

        var building_names := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
        var building_path := "res://assets/environment/kenney_city_kit_suburban/Models/GLB format/building-type-%s.glb" % building_names[index % building_names.size()]
        var building_scene := load(building_path) as PackedScene
        if building_scene:
            var building_model := building_scene.instantiate()
            building_model.scale = Vector3(1.15, 1.15, 1.15)
            building_model.position.y = -size.y * 0.5
            body.add_child(building_model)
        else:
            var fallback_mesh := MeshInstance3D.new()
            var fallback_box := BoxMesh.new()
            fallback_box.size = sizes[index]
            fallback_box.material = building_materials[index % building_materials.size()]
            fallback_mesh.mesh = fallback_box
            body.add_child(fallback_mesh)

        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = sizes[index]
        collision.shape = shape
        body.add_child(collision)
        add_child(body)

        _add_window_strip(body, sizes[index], index)

func _add_window_strip(parent: Node3D, size: Vector3, index: int) -> void:
    var window_material := StandardMaterial3D.new()
    var window_colors := [Color(1.0, 0.27, 0.08), Color(0.10, 0.65, 1.0), Color(0.75, 0.20, 1.0), Color(1.0, 0.72, 0.12)]
    window_material.albedo_color = window_colors[index % window_colors.size()]
    window_material.emission_enabled = true
    window_material.emission = window_colors[index % window_colors.size()]
    window_material.emission_energy_multiplier = 1.4

    for row in range(2):
        var window := MeshInstance3D.new()
        var window_mesh := BoxMesh.new()
        window_mesh.size = Vector3(maxf(0.8, size.x * 0.55), 0.25, 0.08)
        window_mesh.material = window_material
        window.mesh = window_mesh
        window.position = Vector3(0, -size.y * 0.15 + row * 1.45, -size.z * 0.5 - 0.06)
        parent.add_child(window)
