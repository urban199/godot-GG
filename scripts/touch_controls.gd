extends CanvasLayer

var held_actions: Dictionary = {}

func _ready() -> void:
    _bind_hold("MoveUp", "move_forward")
    _bind_hold("MoveLeft", "move_left")
    _bind_hold("MoveDown", "move_backward")
    _bind_hold("MoveRight", "move_right")
    $Fire.pressed.connect(_one_shot.bind("fire"))
    $Reload.pressed.connect(_one_shot.bind("reload"))
    $Flashlight.pressed.connect(_one_shot.bind("flashlight"))

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