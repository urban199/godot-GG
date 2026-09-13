extends CharacterBody3D

signal health_changed(value: int)
signal ammo_changed(current: int, reserve: int)
signal fired

@export var walk_speed := 4.0
@export var sprint_speed := 6.5
@export var jump_velocity := 5.5
@export var max_health := 100
@export var damage := 35
var health := 100
var ammo := 6
var reserve_ammo := 24
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pitch := -0.18
var can_shoot := true
var flashlight_on := true
var walk_time := 0.0
var weapon_recoil := 0.0
var reload_animation := 0.0

@onready var camera: Camera3D = $Camera3D
@onready var muzzle: Marker3D = $Muzzle
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
@onready var player_model: Node3D = $PlayerModel
@onready var weapon_view: Node3D = $Camera3D/WeaponView
var weapon_home_position := Vector3.ZERO

func _ready() -> void:
    add_to_group("player")
    health = max_health
    weapon_home_position = weapon_view.position
    if not DisplayServer.is_touchscreen_available():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    health_changed.emit(health)
    ammo_changed.emit(ammo, reserve_ammo)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * 0.0025)
        pitch = clamp(pitch - event.relative.y * 0.002, -0.9, 0.25)
        camera.rotation.x = pitch
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    weapon_recoil = move_toward(weapon_recoil, 0.0, delta * 0.9)
    reload_animation = move_toward(reload_animation, 0.0, delta * 2.4)
    weapon_view.position = weapon_home_position + Vector3(0, reload_animation * 0.08, weapon_recoil)
    weapon_view.rotation.x = -0.02 - reload_animation * 0.55
    if not is_on_floor(): velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = jump_velocity
    if Input.is_action_just_pressed("reload"): reload_weapon()
    if Input.is_action_just_pressed("flashlight"):
        flashlight_on = not flashlight_on
        flashlight.visible = flashlight_on
    if Input.is_action_just_pressed("fire"): shoot()
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
    var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * delta * 6.0)
        velocity.z = move_toward(velocity.z, 0.0, speed * delta * 6.0)
    move_and_slide()
    var movement_amount := Vector2(velocity.x, velocity.z).length()
    if movement_amount > 0.15:
        walk_time += delta * 9.0
        player_model.position.y = sin(walk_time) * 0.045
        player_model.rotation.z = sin(walk_time * 0.5) * 0.025
    else:
        player_model.position.y = move_toward(player_model.position.y, 0.0, delta * 0.18)
        player_model.rotation.z = move_toward(player_model.rotation.z, 0.0, delta * 0.15)

func shoot() -> void:
    if not can_shoot or ammo <= 0: return
    can_shoot = false
    weapon_recoil = 0.13
    get_tree().create_timer(0.22).timeout.connect(func(): can_shoot = true)
    ammo -= 1
    ammo_changed.emit(ammo, reserve_ammo)
    fired.emit()
    var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + -camera.global_transform.basis.z * 32.0)
    query.exclude = [self]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit and hit.collider.has_method("take_damage"): hit.collider.take_damage(damage)

func reload_weapon() -> void:
    if ammo >= 6 or reserve_ammo <= 0: return
    reload_animation = 1.0
    var needed := 6 - ammo
    var loaded := min(needed, reserve_ammo)
    ammo += loaded
    reserve_ammo -= loaded
    ammo_changed.emit(ammo, reserve_ammo)

func take_damage(amount: int) -> void:
    health = max(health - amount, 0)
    health_changed.emit(health)
    if health == 0: get_tree().call_group("game", "player_died")

func collect_ammo(amount: int) -> void:
    reserve_ammo += amount
    ammo_changed.emit(ammo, reserve_ammo)

func heal(amount: int) -> void:
    health = min(health + amount, max_health)
    health_changed.emit(health)
