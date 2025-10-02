extends Node

# 場景路徑常數
const MAIN_MENU = "res://scenes/MainMenu.tscn"
const MAIN_GAME = "res://scenes/MainGame.tscn"
const BATTLE_TEST = "res://scenes/BattleTest.tscn"
const LEVEL_EDITOR = "res://scenes/LevelEditor.tscn"

# 當前場景
var current_scene: Node

func _ready():
	current_scene = get_tree().current_scene

# 切換到指定場景
func change_to(scene_path: String):
	# 釋放當前場景
	if current_scene:
		current_scene.queue_free()

	# 載入新場景
	var new_scene = load(scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	current_scene = new_scene

	print("已切換到場景: ", scene_path)

# 便利方法
func goto_main_menu():
	change_to(MAIN_MENU)

func goto_main_game():
	change_to(MAIN_GAME)

func goto_battle_test():
	change_to(BATTLE_TEST)

func goto_level_editor():
	change_to(LEVEL_EDITOR)