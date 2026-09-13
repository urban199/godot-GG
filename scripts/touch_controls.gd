extends CanvasLayer

var held_actions: Dictionary = {}

func _ready() -> void:
    _style_round($Fire, Color(0.78, 0.12, 0.10, 0.9))
    _style_round($Reload, Color(0.12, 0.34, 0.68, 0.9))
    _style_round($Flashlight, Color(0.72, 0.42, 0.08, 0.9))
    _bind_hold("MoveUp", "move_forward")
    _bind_hold("MoveLeft", "move_left")
    _bind_hold("MoveDown", "move_backward")
    _bind_hold("MoveRight", "move_right")
    $Fire.pressed.connect(_one_shot.bind("fire"))
    $Reload.pressed.connect(_one_shot.bind("reload"))
    $Flashlight.pressed.connect(_one_shot.bind("flashlight"))

func _style_round(button: Button, color: Color) -> void:
    var normal := StyleBoxFlat.new()
    normal.bg_color = color
    normal.corner_radius_top_left = 60
    normal.corner_radius_top_right = 60
    normal.corner_radius_bottom_left = 60
    normal.corner_radius_bottom_right = 60
    normal.border_width_left = 2
    normal.border_width_top = 2
    normal.border_width_right = 2
    normal.border_width_bottom = 2
    normal.border_color = Color(0.8, 0.9, 1.0, 0.85)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", normal)
    button.add_theme_stylebox_override("pressed", normal)

func _bind_hold(button_name: String, action: String) -> void:
    var button: Button = get_node(button_name)
    button.button_down.connect(_press.bind(action))
    button.button_up.connect(_release.bind(action))

func _press(action: String) -> void:
    held_actions[action] = true
    Input.action_press(action)

func _release(action: String) -> void:
    held_actions.erase(action)
    Input.action_release(action)

func _process(_delta: float) -> void:
    for action in held_actions:
        Input.action_press(action)

func _one_shot(action: String) -> void:
    Input.action_press(action)
    await get_tree().process_frame
    Input.action_release(action)
