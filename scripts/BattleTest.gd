extends Control

@onready var level_button_container: VBoxContainer = $LevelList/LevelScrollContainer/LevelButtonContainer
@onready var back_button: Button = $BackButton
@onready var refresh_button: Button = $RefreshButton

var saved_levels: Array = []

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	load_saved_levels()

func _on_back_pressed():
	SceneManager.goto_main_menu()

func _on_refresh_pressed():
	load_saved_levels()

func load_saved_levels():
	# 清除現有按鈕
	for child in level_button_container.get_children():
		child.queue_free()

	# 載入儲存的關卡
	saved_levels.clear()
	var save_dir = "user://levels/"

	# 確保目錄存在
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.open("user://").make_dir_recursive("levels")
		create_default_level()
		return

	var dir = DirAccess.open(save_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".json"):
				var level_name = file_name.get_basename()
				saved_levels.append(level_name)
				create_level_button(level_name)
			file_name = dir.get_next()

	# 如果沒有關卡，建立預設關卡
	if saved_levels.size() == 0:
		create_default_level()

func create_level_button(level_name: String):
	var button = Button.new()
	button.text = level_name
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func(): start_battle(level_name))
	level_button_container.add_child(button)

func start_battle(level_name: String):
	# 載入關卡資料並開始戰鬥
	var level_data = load_level_data(level_name)
	if level_data:
		# 將關卡資料傳給遊戲管理器
		GameData.current_battle_level = level_data
		SceneManager.goto_main_game()

func load_level_data(level_name: String) -> Dictionary:
	var file_path = "user://levels/" + level_name + ".json"
	var file = FileAccess.open(file_path, FileAccess.READ)

	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			return json.data

	return {}

func create_default_level():
	# 建立一個預設的測試關卡
	var default_level = {
		"name": "測試關卡1",
		"enemies": [
			{
				"name": "史萊姆",
				"hp": 50,
				"attack": 10,
				"defense": 5,
				"position": {"x": 400, "y": 300}
			}
		],
		"player_characters": [
			{
				"name": "主角",
				"hp": 100,
				"attack": 15,
				"defense": 8,
				"position": {"x": 200, "y": 300}
			}
		]
	}

	save_level_data("測試關卡1", default_level)
	create_level_button("測試關卡1")
	saved_levels.append("測試關卡1")

func save_level_data(level_name: String, data: Dictionary):
	var save_dir = "user://levels/"
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.open("user://").make_dir_recursive("levels")

	var file_path = save_dir + level_name + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if file:
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		file.close()