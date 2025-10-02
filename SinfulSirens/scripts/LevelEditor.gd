extends Control

# UI 組件引用
@onready var level_name_input: LineEdit = $MainContainer/LeftPanel/LevelInfo/LevelNameContainer/LevelNameInput
@onready var enemy_list: VBoxContainer = $MainContainer/LeftPanel/EnemySection/EnemyScrollContainer/EnemyList
@onready var player_list: VBoxContainer = $MainContainer/LeftPanel/PlayerSection/PlayerScrollContainer/PlayerList
@onready var preview_area: Panel = $MainContainer/RightPanel/PreviewArea

# 按鈕引用
@onready var save_button: Button = $TopPanel/SaveButton
@onready var load_button: Button = $TopPanel/LoadButton
@onready var new_button: Button = $TopPanel/NewButton
@onready var back_button: Button = $TopPanel/BackButton
@onready var enemy_add_button: Button = $MainContainer/LeftPanel/EnemySection/EnemyAddButton
@onready var player_add_button: Button = $MainContainer/LeftPanel/PlayerSection/PlayerAddButton

# 對話框引用
@onready var save_dialog: FileDialog = $SaveDialog
@onready var load_dialog: FileDialog = $LoadDialog

# 關卡資料
var current_level: Dictionary = {
	"name": "新關卡",
	"enemies": [],
	"player_characters": []
}

var enemy_counter: int = 1
var player_counter: int = 1

# 數量限制
const MAX_ENEMIES = 8
const MAX_PLAYERS = 4

# 視覺化節點引用
var enemy_visual_nodes: Array = []
var player_visual_nodes: Array = []

# RPG 陣形位置配置 (開發者可維護調整)
# 友方陣形 (左側) - 相對於預覽區域左側的位置偏移
const PLAYER_POSITIONS = [
	Vector2(80, 120),    # 前排左
	Vector2(60, 180),    # 後排左
	Vector2(140, 100),   # 前排右
	Vector2(120, 200)    # 後排右
]

# 敵方陣形 (右側) - 相對於預覽區域右側的位置偏移
const ENEMY_POSITIONS = [
	Vector2(-120, 110),  # 前排右 (相對右側)
	Vector2(-80, 160),   # 中排右
	Vector2(-160, 140),  # 前排左
	Vector2(-100, 210),  # 後排右
	Vector2(-200, 120),  # 最前排
	Vector2(-140, 250),  # 最後排
	Vector2(-180, 180),  # 中排左
	Vector2(-60, 280)    # 後衛
]

func _ready():
	# 連接按鈕信號
	save_button.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	new_button.pressed.connect(_on_new_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	enemy_add_button.pressed.connect(_on_enemy_add_button_pressed)
	player_add_button.pressed.connect(_on_player_add_button_pressed)

	# 連接對話框信號
	save_dialog.file_selected.connect(_on_save_file_selected)
	load_dialog.file_selected.connect(_on_load_file_selected)

	# 設定對話框預設路徑
	var levels_dir = OS.get_user_data_dir() + "/levels/"
	save_dialog.current_dir = levels_dir
	load_dialog.current_dir = levels_dir

	# 初始化
	new_level()

func _on_back_button_pressed():
	SceneManager.goto_main_menu()

func _on_new_button_pressed():
	new_level()

func _on_save_button_pressed():
	save_dialog.popup_centered_ratio(0.8)

func _on_load_button_pressed():
	load_dialog.popup_centered_ratio(0.8)

func new_level():
	current_level = {
		"name": "新關卡",
		"enemies": [],
		"player_characters": []
	}
	enemy_counter = 1
	player_counter = 1
	refresh_ui()

func refresh_ui():
	level_name_input.text = current_level.get("name", "新關卡")

	# 清除現有UI元素
	clear_container(enemy_list)
	clear_container(player_list)

	# 重新建立敵人列表
	for i in range(current_level.enemies.size()):
		create_enemy_ui(i)

	# 重新建立角色列表
	for i in range(current_level.player_characters.size()):
		create_player_ui(i)

	# 更新視覺預覽
	update_visual_preview()

func clear_container(container: Container):
	for child in container.get_children():
		child.queue_free()

func _on_enemy_add_button_pressed():
	if current_level.enemies.size() >= MAX_ENEMIES:
		print("敵人數量已達上限 (" + str(MAX_ENEMIES) + ")")
		return

	var new_enemy = {
		"name": "敵人" + str(enemy_counter),
		"hp": 50,
		"attack": 10,
		"defense": 5,
		"position": {"x": 400, "y": 300}
	}
	current_level.enemies.append(new_enemy)
	enemy_counter += 1
	create_enemy_ui(current_level.enemies.size() - 1)
	update_visual_preview()

func _on_player_add_button_pressed():
	if current_level.player_characters.size() >= MAX_PLAYERS:
		print("我方角色數量已達上限 (" + str(MAX_PLAYERS) + ")")
		return

	var new_player = {
		"name": "角色" + str(player_counter),
		"hp": 100,
		"attack": 15,
		"defense": 8,
		"position": {"x": 200, "y": 300}
	}
	current_level.player_characters.append(new_player)
	player_counter += 1
	create_player_ui(current_level.player_characters.size() - 1)
	update_visual_preview()

func create_enemy_ui(index: int):
	var enemy_data = current_level.enemies[index]
	var container = VBoxContainer.new()
	container.add_theme_stylebox_override("panel", create_panel_style())

	# 敵人標題
	var title_container = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "敵人 " + str(index + 1)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var delete_button = Button.new()
	delete_button.text = "刪除"
	delete_button.pressed.connect(func(): delete_enemy(index))

	title_container.add_child(title_label)
	title_container.add_child(delete_button)
	container.add_child(title_container)

	# 名稱輸入
	var name_container = HBoxContainer.new()
	name_container.add_child(create_label("名稱:"))
	var name_input = LineEdit.new()
	name_input.text = enemy_data.name
	name_input.text_changed.connect(func(text):
		current_level.enemies[index].name = text
		update_visual_preview()
	)
	name_container.add_child(name_input)
	container.add_child(name_container)

	# HP輸入
	var hp_container = HBoxContainer.new()
	hp_container.add_child(create_label("HP:"))
	var hp_input = SpinBox.new()
	hp_input.min_value = 1
	hp_input.max_value = 9999
	hp_input.value = enemy_data.hp
	hp_input.value_changed.connect(func(value): current_level.enemies[index].hp = int(value))
	hp_container.add_child(hp_input)
	container.add_child(hp_container)

	# 攻擊力輸入
	var attack_container = HBoxContainer.new()
	attack_container.add_child(create_label("攻擊:"))
	var attack_input = SpinBox.new()
	attack_input.min_value = 1
	attack_input.max_value = 999
	attack_input.value = enemy_data.attack
	attack_input.value_changed.connect(func(value): current_level.enemies[index].attack = int(value))
	attack_container.add_child(attack_input)
	container.add_child(attack_container)

	# 防禦力輸入
	var defense_container = HBoxContainer.new()
	defense_container.add_child(create_label("防禦:"))
	var defense_input = SpinBox.new()
	defense_input.min_value = 0
	defense_input.max_value = 999
	defense_input.value = enemy_data.defense
	defense_input.value_changed.connect(func(value): current_level.enemies[index].defense = int(value))
	defense_container.add_child(defense_input)
	container.add_child(defense_container)

	# 分隔線
	var separator = HSeparator.new()
	container.add_child(separator)

	enemy_list.add_child(container)

func create_player_ui(index: int):
	var player_data = current_level.player_characters[index]
	var container = VBoxContainer.new()
	container.add_theme_stylebox_override("panel", create_panel_style())

	# 角色標題
	var title_container = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "角色 " + str(index + 1)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var delete_button = Button.new()
	delete_button.text = "刪除"
	delete_button.pressed.connect(func(): delete_player(index))

	title_container.add_child(title_label)
	title_container.add_child(delete_button)
	container.add_child(title_container)

	# 名稱輸入
	var name_container = HBoxContainer.new()
	name_container.add_child(create_label("名稱:"))
	var name_input = LineEdit.new()
	name_input.text = player_data.name
	name_input.text_changed.connect(func(text):
		current_level.player_characters[index].name = text
		update_visual_preview()
	)
	name_container.add_child(name_input)
	container.add_child(name_container)

	# HP輸入
	var hp_container = HBoxContainer.new()
	hp_container.add_child(create_label("HP:"))
	var hp_input = SpinBox.new()
	hp_input.min_value = 1
	hp_input.max_value = 9999
	hp_input.value = player_data.hp
	hp_input.value_changed.connect(func(value): current_level.player_characters[index].hp = int(value))
	hp_container.add_child(hp_input)
	container.add_child(hp_container)

	# 攻擊力輸入
	var attack_container = HBoxContainer.new()
	attack_container.add_child(create_label("攻擊:"))
	var attack_input = SpinBox.new()
	attack_input.min_value = 1
	attack_input.max_value = 999
	attack_input.value = player_data.attack
	attack_input.value_changed.connect(func(value): current_level.player_characters[index].attack = int(value))
	attack_container.add_child(attack_input)
	container.add_child(attack_container)

	# 防禦力輸入
	var defense_container = HBoxContainer.new()
	defense_container.add_child(create_label("防禦:"))
	var defense_input = SpinBox.new()
	defense_input.min_value = 0
	defense_input.max_value = 999
	defense_input.value = player_data.defense
	defense_input.value_changed.connect(func(value): current_level.player_characters[index].defense = int(value))
	defense_container.add_child(defense_input)
	container.add_child(defense_container)

	# 分隔線
	var separator = HSeparator.new()
	container.add_child(separator)

	player_list.add_child(container)

func create_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(50, 0)
	return label

func create_panel_style() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.5)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.5, 0.5, 0.6, 1)
	return style

func delete_enemy(index: int):
	current_level.enemies.remove_at(index)
	refresh_ui()

func delete_player(index: int):
	current_level.player_characters.remove_at(index)
	refresh_ui()

# 更新視覺預覽
func update_visual_preview():
	# 清除現有的視覺節點
	clear_visual_nodes()

	# 確保預覽區域已經準備好
	if not preview_area or preview_area.size.x <= 0:
		# 如果預覽區域還沒準備好，延遲更新
		call_deferred("_delayed_visual_update")
		return

	# 載入角色圖片
	var character_texture = load("res://assets/C.png")

	# 新增敵人視覺化 (右側，鏡像翻轉)
	for i in range(current_level.enemies.size()):
		var enemy_visual = create_character_visual(character_texture, true, i, false)  # 敵人鏡像
		var position = Vector2(preview_area.size.x, 0) + ENEMY_POSITIONS[i]  # 相對於右側
		enemy_visual.position = position
		preview_area.add_child(enemy_visual)
		enemy_visual_nodes.append(enemy_visual)

	# 新增我方角色視覺化 (左側，不鏡像)
	for i in range(current_level.player_characters.size()):
		var player_visual = create_character_visual(character_texture, false, i, true)  # 友方不鏡像
		var position = PLAYER_POSITIONS[i]  # 相對於左側
		player_visual.position = position
		preview_area.add_child(player_visual)
		player_visual_nodes.append(player_visual)

func _delayed_visual_update():
	update_visual_preview()

func create_character_visual(texture: Texture2D, flip_h: bool, index: int, is_player: bool) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(64, 64)

	# 角色圖片
	var sprite = TextureRect.new()
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.flip_h = flip_h
	sprite.custom_minimum_size = Vector2(48, 48)
	sprite.anchors_preset = Control.PRESET_CENTER
	container.add_child(sprite)

	# 名稱標籤
	var label = Label.new()
	if is_player:
		label.text = current_level.player_characters[index].name
	else:
		label.text = current_level.enemies[index].name

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	label.offset_top = -20
	label.add_theme_font_size_override("font_size", 10)
	container.add_child(label)

	return container

func clear_visual_nodes():
	# 清除敵人視覺節點
	for node in enemy_visual_nodes:
		if is_instance_valid(node):
			node.queue_free()
	enemy_visual_nodes.clear()

	# 清除我方角色視覺節點
	for node in player_visual_nodes:
		if is_instance_valid(node):
			node.queue_free()
	player_visual_nodes.clear()

func _on_save_file_selected(path: String):
	current_level.name = level_name_input.text
	save_level_to_file(path)

func _on_load_file_selected(path: String):
	load_level_from_file(path)

func save_level_to_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(current_level)
		file.store_string(json_string)
		file.close()
		print("關卡已儲存到：", file_path)

	# 同時儲存到 user://levels/ 目錄供測試戰鬥使用
	var levels_dir = "user://levels/"
	if not DirAccess.dir_exists_absolute(levels_dir):
		DirAccess.open("user://").make_dir_recursive("levels")

	var level_name = current_level.name if current_level.name != "" else "未命名關卡"
	var user_file_path = levels_dir + level_name + ".json"
	var user_file = FileAccess.open(user_file_path, FileAccess.WRITE)
	if user_file:
		var json_string = JSON.stringify(current_level)
		user_file.store_string(json_string)
		user_file.close()

func load_level_from_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			current_level = json.data
			refresh_ui()
			print("關卡已載入：", file_path)
		else:
			print("載入關卡失敗：JSON 格式錯誤")