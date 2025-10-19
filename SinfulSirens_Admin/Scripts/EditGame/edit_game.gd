extends Control

# 編輯遊戲場景控制腳本

# UI 節點引用
@onready var stage_option: OptionButton = $MarginContainer/VBoxContainer/ContentContainer/LeftPanel/StageSection/StageOption
@onready var stage_info: Label = $MarginContainer/VBoxContainer/ContentContainer/LeftPanel/StageSection/StageInfo
@onready var character_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/LeftPanel/CharacterSection/CharacterListContainer/ScrollContainer/CharacterList
@onready var trait_grid: GridContainer = $MarginContainer/VBoxContainer/ContentContainer/RightPanel/TraitSection/TraitListContainer/ScrollContainer/TraitGrid
@onready var selected_traits_list: HBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/RightPanel/SelectedTraitsSection/SelectedTraitsContainer/ScrollContainer/SelectedTraitsList
@onready var selected_trait_count_label: Label = $MarginContainer/VBoxContainer/ContentContainer/RightPanel/SelectedTraitsSection/SelectedTraitsHeader/CountLabel
@onready var start_game_button: Button = $MarginContainer/VBoxContainer/BottomBar/StartGameButton

# 資料
var game_setup: GameSetup = GameSetup.new()
var all_stages: Array[Stage] = []
var all_traits: Array = []  # 特徵卡資料
var player_characters: Dictionary = {}  # key: character_id, value: PlayerCharacter
var next_player_id: int = 1

# 我方角色編輯對話框
const CHARACTER_EDIT_DIALOG_SCENE = preload("res://Scenes/Dialogs/CharacterEditDialog.tscn")
var character_edit_dialog: Window = null

func _ready():
	print("編輯遊戲場景已載入")
	_setup_dialogs()
	_load_player_characters()
	_load_stages()
	_load_traits()
	_refresh_stage_list()
	_refresh_trait_grid()
	_refresh_character_list()
	_update_start_button_state()


func _setup_dialogs():
	# 創建角色編輯對話框
	character_edit_dialog = CHARACTER_EDIT_DIALOG_SCENE.instantiate()
	character_edit_dialog.character_saved.connect(_on_character_saved)
	character_edit_dialog.visible = false
	add_child(character_edit_dialog)


# ==================== 資料載入 ====================

func _load_stages():
	all_stages = DataManager.get_all_stages()
	print("載入 %d 個關卡" % all_stages.size())


func _load_traits():
	var save_path = "user://trait_cards.json"
	if not FileAccess.file_exists(save_path):
		print("無特徵卡資料")
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			if data.has("cards"):
				all_traits = data.cards
				print("載入 %d 張特徵卡" % all_traits.size())


func _load_player_characters():
	var save_path = "user://player_characters.json"
	if not FileAccess.file_exists(save_path):
		print("無我方角色資料")
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			if data.has("characters"):
				player_characters.clear()
				for char_data in data.characters:
					var character = PlayerCharacter.from_dict(char_data)
					player_characters[character.id] = character
			if data.has("next_id"):
				next_player_id = data.next_id
			print("載入 %d 個我方角色" % player_characters.size())


func _save_player_characters():
	var save_data = []
	for character in player_characters.values():
		save_data.append(character.to_dict())

	var save_path = "user://player_characters.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"characters": save_data, "next_id": next_player_id}))
		file.close()
		print("我方角色已儲存")


# ==================== UI 更新 ====================

func _refresh_stage_list():
	stage_option.clear()
	for stage in all_stages:
		stage_option.add_item(stage.name)

	if all_stages.is_empty():
		stage_info.text = "沒有可用的關卡"
	else:
		stage_info.text = "請選擇一個關卡"


func _refresh_trait_grid():
	# 清空網格
	for child in trait_grid.get_children():
		child.queue_free()

	# 添加所有特徵卡
	for trait_data in all_traits:
		_add_trait_card_button(trait_data)

	_refresh_selected_traits_list()
	_update_trait_count()


func _add_trait_card_button(trait_data: Dictionary):
	var card_button = Button.new()
	card_button.custom_minimum_size = Vector2(120, 160)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_button.add_child(vbox)

	# 圖片預覽
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(100, 100)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var img_path = trait_data.get("image_path", "")
	if not img_path.is_empty() and FileAccess.file_exists(img_path):
		var image = Image.new()
		var error = image.load(img_path)
		if error == OK:
			texture_rect.texture = ImageTexture.create_from_image(image)

	vbox.add_child(texture_rect)

	# 資訊標籤
	var info_label = Label.new()
	info_label.text = "%s\n食物:%d" % [trait_data.get("position", ""), trait_data.get("food_amount", 0)]
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(info_label)

	var card_id = trait_data.get("id", 0)
	card_button.pressed.connect(_on_trait_card_selected.bind(card_id, trait_data))

	trait_grid.add_child(card_button)


func _update_trait_count():
	selected_trait_count_label.text = "%d/40" % game_setup.trait_card_ids.size()


func _refresh_selected_traits_list():
	# 清空已選擇清單
	for child in selected_traits_list.get_children():
		child.queue_free()

	# 添加已選擇的特徵卡
	for card_id in game_setup.trait_card_ids:
		# 找到對應的特徵卡資料
		var trait_data = null
		for trait_item in all_traits:
			if trait_item.get("id", 0) == card_id:
				trait_data = trait_item
				break

		if trait_data:
			_add_selected_trait_card(trait_data)


func _add_selected_trait_card(trait_data: Dictionary):
	var card_container = PanelContainer.new()
	card_container.custom_minimum_size = Vector2(100, 140)

	# 設置面板背景色
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.3, 0.3, 0.4, 1)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.5, 0.8, 0.5, 1)
	card_container.add_theme_stylebox_override("panel", style_box)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card_container.add_child(vbox)

	# 圖片預覽
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(90, 90)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var img_path = trait_data.get("image_path", "")
	if not img_path.is_empty() and FileAccess.file_exists(img_path):
		var image = Image.new()
		var error = image.load(img_path)
		if error == OK:
			texture_rect.texture = ImageTexture.create_from_image(image)

	vbox.add_child(texture_rect)

	# 資訊標籤
	var info_label = Label.new()
	info_label.text = "%s\n食物:%d" % [trait_data.get("position", ""), trait_data.get("food_amount", 0)]
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(info_label)

	# 移除按鈕
	var remove_btn = Button.new()
	remove_btn.text = "移除"
	remove_btn.custom_minimum_size = Vector2(0, 25)
	remove_btn.add_theme_font_size_override("font_size", 12)
	var card_id = trait_data.get("id", 0)
	remove_btn.pressed.connect(_on_remove_trait_card.bind(card_id))
	vbox.add_child(remove_btn)

	selected_traits_list.add_child(card_container)


func _on_remove_trait_card(card_id: int):
	game_setup.remove_trait_card(card_id)
	_refresh_selected_traits_list()
	_update_trait_count()
	print("已移除特徵卡 ID:%d" % card_id)


func _update_start_button_state():
	start_game_button.disabled = not game_setup.is_ready()


# ==================== 事件處理 ====================

func _on_stage_selected(index: int):
	if index >= 0 and index < all_stages.size():
		var stage = all_stages[index]
		game_setup.stage_id = stage.id
		stage_info.text = "關卡: %s\n%s\n敵人數量: %d" % [stage.name, stage.description, stage.enemy_ids.size()]
		_update_start_button_state()


func _on_trait_card_selected(card_id: int, card_data: Dictionary):
	if game_setup.trait_card_ids.size() >= 40:
		print("特徵卡已達上限")
		return

	game_setup.add_trait_card(card_id)
	_refresh_selected_traits_list()
	_update_trait_count()
	print("已選擇特徵卡 ID:%d, 部位:%s" % [card_id, card_data.get("position", "")])


func _on_clear_traits_button_pressed():
	game_setup.clear_trait_cards()
	_refresh_selected_traits_list()
	_update_trait_count()
	print("已清空特徵卡")


func _refresh_character_list():
	# 清空列表
	for child in character_list.get_children():
		child.queue_free()

	# 顯示已有角色
	for character in player_characters.values():
		_add_character_item(character)

	_update_start_button_state()


func _add_character_item(character: PlayerCharacter):
	var item = PanelContainer.new()
	item.custom_minimum_size = Vector2(0, 100)

	# 檢查是否已選擇，設置不同的背景色
	var is_selected = game_setup.player_character_ids.has(character.id)
	var style_box = StyleBoxFlat.new()
	if is_selected:
		style_box.bg_color = Color(0.2, 0.5, 0.3, 1)  # 綠色背景表示已選擇
		style_box.border_width_left = 3
		style_box.border_width_top = 3
		style_box.border_width_right = 3
		style_box.border_width_bottom = 3
		style_box.border_color = Color(0.3, 0.8, 0.4, 1)  # 亮綠色邊框
	else:
		style_box.bg_color = Color(0.25, 0.25, 0.3, 1)  # 普通背景
		style_box.border_width_left = 1
		style_box.border_width_top = 1
		style_box.border_width_right = 1
		style_box.border_width_bottom = 1
		style_box.border_color = Color(0.4, 0.4, 0.45, 1)
	item.add_theme_stylebox_override("panel", style_box)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	item.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	# 左側: 圖片
	var image_container = PanelContainer.new()
	image_container.custom_minimum_size = Vector2(80, 80)
	hbox.add_child(image_container)

	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(80, 80)

	# 載入圖片
	if not character.image_path.is_empty() and FileAccess.file_exists(character.image_path):
		var image = Image.new()
		var error = image.load(character.image_path)
		if error == OK:
			texture_rect.texture = ImageTexture.create_from_image(image)

	image_container.add_child(texture_rect)

	# 中間: 資訊
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	if is_selected:
		name_label.text = "✓ " + character.name
		name_label.modulate = Color(0.5, 1.0, 0.6, 1)  # 亮綠色文字
	else:
		name_label.text = character.name
		name_label.modulate = Color(1, 1, 1, 1)
	name_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(name_label)

	var stats_label = Label.new()
	stats_label.text = "HP:%d 力:%d 防:%d 速:%d" % [character.hp, character.strength, character.defense, character.speed]
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.modulate = Color(0.9, 0.9, 0.9)
	info_vbox.add_child(stats_label)

	# 右側: 按鈕
	var button_vbox = VBoxContainer.new()
	button_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(button_vbox)

	# 選擇按鈕
	var select_btn = Button.new()
	select_btn.custom_minimum_size = Vector2(60, 0)
	select_btn.add_theme_font_size_override("font_size", 14)

	if is_selected:
		select_btn.text = "移除"
		select_btn.modulate = Color(1.0, 0.7, 0.7, 1)  # 淡紅色
		select_btn.pressed.connect(_on_remove_character_button_pressed.bind(character))
	else:
		select_btn.text = "選擇"
		select_btn.modulate = Color(0.7, 1.0, 0.7, 1)  # 淡綠色
		select_btn.pressed.connect(_on_select_character_button_pressed.bind(character))

	button_vbox.add_child(select_btn)

	# 編輯按鈕
	var edit_btn = Button.new()
	edit_btn.text = "編輯"
	edit_btn.custom_minimum_size = Vector2(60, 0)
	edit_btn.add_theme_font_size_override("font_size", 14)
	edit_btn.pressed.connect(_on_edit_character_button_pressed.bind(character))
	button_vbox.add_child(edit_btn)

	# 刪除按鈕
	var delete_btn = Button.new()
	delete_btn.text = "刪除"
	delete_btn.custom_minimum_size = Vector2(60, 0)
	delete_btn.add_theme_font_size_override("font_size", 14)
	delete_btn.pressed.connect(_on_delete_character_button_pressed.bind(character))
	button_vbox.add_child(delete_btn)

	character_list.add_child(item)


func _on_add_char_button_pressed():
	character_edit_dialog.setup_new_character()
	character_edit_dialog.popup_centered()


func _on_edit_character_button_pressed(character: PlayerCharacter):
	character_edit_dialog.setup_edit_character(character)
	character_edit_dialog.popup_centered()


func _on_delete_character_button_pressed(character: PlayerCharacter):
	# 確認刪除
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "確定要刪除角色「%s」嗎?" % character.name
	confirm_dialog.title = "確認刪除"
	confirm_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm_dialog.confirmed.connect(_delete_character_confirmed.bind(character))
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()


func _delete_character_confirmed(character: PlayerCharacter):
	player_characters.erase(character.id)
	game_setup.remove_player_character(character.id)
	_save_player_characters()
	_refresh_character_list()
	print("已刪除角色: ", character.name)


func _on_select_character_button_pressed(character: PlayerCharacter):
	if game_setup.add_player_character(character.id):
		_refresh_character_list()
		_update_start_button_state()
		print("已選擇角色: ", character.name)
	else:
		print("角色選擇已達上限(最多4位)")


func _on_remove_character_button_pressed(character: PlayerCharacter):
	game_setup.remove_player_character(character.id)
	_refresh_character_list()
	_update_start_button_state()
	print("已移除角色: ", character.name)


func _on_character_saved(character: PlayerCharacter):
	if character.id.is_empty():
		# 新增角色
		character.id = "player_" + str(next_player_id)
		next_player_id += 1
		player_characters[character.id] = character
		print("新增角色: ", character.name)
	else:
		# 更新角色
		player_characters[character.id] = character
		print("更新角色: ", character.name)

	_save_player_characters()
	_refresh_character_list()


func _on_start_game_button_pressed():
	if not game_setup.is_ready():
		print("請先選擇關卡和至少一個我方角色")
		return

	# 自動補滿特徵卡到40張
	while game_setup.trait_card_ids.size() < 40 and all_traits.size() > 0:
		var random_index = randi() % all_traits.size()
		var random_trait = all_traits[random_index]
		game_setup.add_trait_card(random_trait.get("id", 0))

	print("=== 開始遊戲 ===")
	print("關卡: %s" % game_setup.stage_id)
	print("特徵卡數量: %d" % game_setup.trait_card_ids.size())
	print("我方角色: %s" % str(game_setup.player_character_ids))

	# 獲取關卡資料
	var stage: Stage = null
	for s in all_stages:
		if s.id == game_setup.stage_id:
			stage = s
			break

	if not stage:
		print("找不到關卡資料!")
		return

	# 獲取我方角色資料
	var selected_characters: Array[PlayerCharacter] = []
	for char_id in game_setup.player_character_ids:
		if player_characters.has(char_id):
			selected_characters.append(player_characters[char_id])

	# 設定全局遊戲資料
	GlobalGameData.set_battle_data(game_setup, stage, selected_characters, all_traits)

	# 切換到戰鬥場景
	get_tree().change_scene_to_file("res://Scenes/GameBattle/GameBattle.tscn")


func _on_back_button_pressed():
	print("返回編輯模式")
	get_tree().change_scene_to_file("res://Scenes/EditMode/EditMode.tscn")
