extends Control

@onready var start_game_button: Button = $MenuButtons/StartGameButton
@onready var battle_test_button: Button = $MenuButtons/BattleTestButton
@onready var level_editor_button: Button = $MenuButtons/LevelEditorButton
@onready var exit_button: Button = $MenuButtons/ExitButton

func _ready():
	# 連接按鈕信號
	start_game_button.pressed.connect(_on_start_game_pressed)
	battle_test_button.pressed.connect(_on_battle_test_pressed)
	level_editor_button.pressed.connect(_on_level_editor_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_game_pressed():
	SceneManager.goto_main_game()

func _on_battle_test_pressed():
	SceneManager.goto_battle_test()

func _on_level_editor_pressed():
	SceneManager.goto_level_editor()

func _on_exit_pressed():
	get_tree().quit()