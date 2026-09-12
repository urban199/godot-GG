extends CharacterBody3D

@export var max_health := 70
@export var move_speed := 1.25
@export var attack_damage := 12
var health := 70
var attack_cooldown := 0.0
var target: Node3D

func _ready() -> void:
    health = max_health
    add_to_group("enemy")

func _physics_process(delta: float) -> void:
    if not target: target = get_tree().get_first_node_in_group("player")
    if not target: return
    attack_cooldown = max(attack_cooldown - delta, 0.0)
    var offset := target.global_position - global_position
    offset.y = 0
    var distance := offset.length()
    if distance > 1.45:
        velocity = offset.normalized() * move_speed
        look_at(global_position + Vector3(offset.x, 0, offset.z), Vector3.UP)
        move_and_slide()
    elif attack_cooldown <= 0:
        attack_cooldown = 1.1
        target.take_damage(attack_damage)

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        get_tree().call_group("game", "enemy_defeated")
        queue_free()