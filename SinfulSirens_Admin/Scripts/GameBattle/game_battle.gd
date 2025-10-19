extends Control

# 遊戲戰鬥場景控制腳本

# UI 節點引用
@onready var stage_name_label: Label = $MarginContainer/VBoxContainer/TopBar/StageNameLabel
@onready var deck_info_label: Label = $MarginContainer/VBoxContainer/TopBar/DeckInfoLabel
@onready var discard_info_label: Label = $MarginContainer/VBoxContainer/TopBar/DiscardInfoLabel
@onready var player_character_list: VBoxContainer = $MarginContainer/VBoxContainer/BattleArea/PlayerArea/PlayerCharacterList
@onready var enemy_list: VBoxContainer = $MarginContainer/VBoxContainer/BattleArea/EnemyArea/EnemyList
@onready var hand_card_container: HBoxContainer = $MarginContainer/VBoxContainer/BottomArea/HandCardArea/HandCardContainer
@onready var action_panel: PanelContainer = $MarginContainer/VBoxContainer/BottomArea/ActionPanel
@onready var action_info_label: Label = $MarginContainer/VBoxContainer/BottomArea/ActionPanel/MarginContainer/HBoxContainer/InfoLabel

# 遊戲資料
var stage_data: Stage = null
var player_characters: Array[PlayerCharacter] = []
var enemies: Array[Enemy] = []
var trait_cards: Array = []  # 所有特徵卡資料

# 卡牌系統
var deck: Array[int] = []  # 牌庫 (儲存卡牌ID)
var hand: Array[int] = []  # 手牌 (儲存卡牌ID)
var discard_pile: Array[int] = []  # 棄牌堆 (儲存卡牌ID)
const HAND_SIZE: int = 5  # 手牌數量

# 選擇狀態
var selected_character: PlayerCharacter = null
var selected_card_id: int = -1
var selected_card_index: int = -1


func _ready():
	print("戰鬥場景已載入")
	_load_battle_data()
	_initialize_deck()
	_setup_battle_field()
	_draw_cards(HAND_SIZE)
	_update_deck_info()


# ==================== 資料載入 ====================

func _load_battle_data():
	# 從全局資料中獲取戰鬥資料
	if GlobalGameData.current_stage:
		stage_data = GlobalGameData.current_stage
		stage_name_label.text = stage_data.name
		print("載入關卡: %s" % stage_data.name)

	if not GlobalGameData.player_characters.is_empty():
		player_characters = GlobalGameData.player_characters.duplicate()
		print("載入 %d 個我方角色" % player_characters.size())

	if not GlobalGameData.trait_cards.is_empty():
		trait_cards = GlobalGameData.trait_cards.duplicate()
		print("載入 %d 張特徵卡資料" % trait_cards.size())

	# 載入敵人資料
	if stage_data:
		for enemy_id in stage_data.enemy_ids:
			var enemy = DataManager.get_enemy(enemy_id)
			if enemy:
				enemies.append(enemy)
		print("載入 %d 個敵人" % enemies.size())


func _initialize_deck():
	# 初始化牌庫
	deck.clear()
	hand.clear()
	discard_pile.clear()

	# 從 GameSetup 獲取選擇的特徵卡
	if GlobalGameData.current_game_setup:
		deck = GlobalGameData.current_game_setup.trait_card_ids.duplicate()
		deck.shuffle()
		print("初始化牌庫: %d 張牌" % deck.size())


# ==================== 戰場設置 ====================

func _setup_battle_field():
	_setup_player_characters()
	_setup_enemies()


func _setup_player_characters():
	# 清空列表
	for child in player_character_list.get_children():
		child.queue_free()

	# 添加我方角色
	for character in player_characters:
		_add_player_character_ui(character)


func _add_player_character_ui(character: PlayerCharacter):
	var character_panel = PanelContainer.new()
	character_panel.custom_minimum_size = Vector2(0, 120)

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.3, 0.4, 1)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.5, 0.6, 1)
	character_panel.add_theme_stylebox_override("panel", style_box)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	character_panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# 圖片區域
	var image_container = PanelContainer.new()
	image_container.custom_minimum_size = Vector2(100, 100)
	hbox.add_child(image_container)

	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if not character.image_path.is_empty() and FileAccess.file_exists(character.image_path):
		var image = Image.new()
		var error = image.load(character.image_path)
		if error == OK:
			texture_rect.texture = ImageTexture.create_from_image(image)

	image_container.add_child(texture_rect)

	# 資訊區域
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = character.name
	name_label.add_theme_font_size_override("font_size", 22)
	info_vbox.add_child(name_label)

	var hp_label = Label.new()
	hp_label.text = "HP: %d/%d" % [character.hp, character.hp]
	hp_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(hp_label)

	var stats_label = Label.new()
	stats_label.text = "力:%d 防:%d 速:%d" % [character.strength, character.defense, character.speed]
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.modulate = Color(0.9, 0.9, 0.9)
	info_vbox.add_child(stats_label)

	# 按鈕
	var select_button = Button.new()
	select_button.text = "選擇"
	select_button.custom_minimum_size = Vector2(80, 0)
	select_button.add_theme_font_size_override("font_size", 18)
	select_button.pressed.connect(_on_character_selected.bind(character))
	hbox.add_child(select_button)

	player_character_list.add_child(character_panel)


func _setup_enemies():
	# 清空列表
	for child in enemy_list.get_children():
		child.queue_free()

	# 添加敵人
	for enemy in enemies:
		_add_enemy_ui(enemy)


func _add_enemy_ui(enemy: Enemy):
	var enemy_panel = PanelContainer.new()
	enemy_panel.custom_minimum_size = Vector2(0, 120)

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.4, 0.2, 0.2, 1)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.6, 0.3, 0.3, 1)
	enemy_panel.add_theme_stylebox_override("panel", style_box)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	enemy_panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# 圖片區域
	var image_container = PanelContainer.new()
	image_container.custom_minimum_size = Vector2(100, 100)
	hbox.add_child(image_container)

	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if not enemy.image_path.is_empty() and FileAccess.file_exists(enemy.image_path):
		var image = Image.new()
		var error = image.load(enemy.image_path)
		if error == OK:
			texture_rect.texture = ImageTexture.create_from_image(image)

	image_container.add_child(texture_rect)

	# 資訊區域
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = enemy.name
	name_label.add_theme_font_size_override("font_size", 22)
	info_vbox.add_child(name_label)

	var hp_label = Label.new()
	hp_label.text = "HP: %d/%d" % [enemy.hp, enemy.hp]
	hp_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(hp_label)

	var stats_label = Label.new()
	stats_label.text = "力:%d 防:%d 速:%d" % [enemy.strength, enemy.defense, enemy.speed]
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.modulate = Color(0.9, 0.9, 0.9)
	info_vbox.add_child(stats_label)

	enemy_list.add_child(enemy_panel)


# ==================== 卡牌系統 ====================

func _draw_cards(count: int):
	var drawn = 0

	for i in range(count):
		if deck.is_empty():
			# 牌庫空了，從棄牌堆重洗
			if discard_pile.is_empty():
				print("牌庫和棄牌堆都空了，無法抽牌")
				break
			_shuffle_discard_into_deck()

		if not deck.is_empty():
			var card_id = deck.pop_front()
			hand.append(card_id)
			drawn += 1

	print("抽了 %d 張牌" % drawn)
	_refresh_hand_ui()
	_update_deck_info()


func _shuffle_discard_into_deck():
	print("重洗棄牌堆")
	deck = discard_pile.duplicate()
	discard_pile.clear()
	deck.shuffle()


func _refresh_hand_ui():
	# 清空手牌UI
	for child in hand_card_container.get_children():
		child.queue_free()

	# 顯示手牌
	for i in range(hand.size()):
		var card_id = hand[i]
		_add_hand_card_ui(card_id, i)


func _add_hand_card_ui(card_id: int, index: int):
	var card_button = Button.new()
	card_button.custom_minimum_size = Vector2(140, 180)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 5)
	card_button.add_child(vbox)

	# 找到卡牌資料
	var card_data = _get_card_data(card_id)

	if card_data:
		# 圖片
		var texture_rect = TextureRect.new()
		texture_rect.custom_minimum_size = Vector2(120, 120)
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var img_path = card_data.get("image_path", "")
		if not img_path.is_empty() and FileAccess.file_exists(img_path):
			var image = Image.new()
			var error = image.load(img_path)
			if error == OK:
				texture_rect.texture = ImageTexture.create_from_image(image)

		vbox.add_child(texture_rect)

		# 資訊
		var info_label = Label.new()
		info_label.text = "%s\n食物:%d" % [card_data.get("position", ""), card_data.get("food_amount", 0)]
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_label.add_theme_font_size_override("font_size", 14)
		info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(info_label)
	else:
		var label = Label.new()
		label.text = "卡片 #%d" % card_id
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)

	card_button.pressed.connect(_on_card_selected.bind(card_id, index))
	hand_card_container.add_child(card_button)


func _get_card_data(card_id: int):
	for card in trait_cards:
		if card.get("id", 0) == card_id:
			return card
	return null


func _update_deck_info():
	deck_info_label.text = "牌庫: %d" % deck.size()
	discard_info_label.text = "棄牌堆: %d" % discard_pile.size()


# ==================== 事件處理 ====================

func _on_character_selected(character: PlayerCharacter):
	selected_character = character
	print("選擇角色: %s" % character.name)
	_update_action_panel()


func _on_card_selected(card_id: int, index: int):
	selected_card_id = card_id
	selected_card_index = index
	print("選擇卡牌 ID: %d, Index: %d" % [card_id, index])
	_update_action_panel()


func _update_action_panel():
	if selected_character and selected_card_id >= 0:
		action_panel.visible = true
		var card_data = _get_card_data(selected_card_id)
		var card_name = "卡片 #%d" % selected_card_id
		if card_data:
			card_name = card_data.get("position", "未知")
		action_info_label.text = "已選擇: %s + %s" % [selected_character.name, card_name]
	else:
		action_panel.visible = false


func _on_attach_button_pressed():
	if selected_character and selected_card_id >= 0:
		print("附加特徵: %s 使用卡牌 #%d" % [selected_character.name, selected_card_id])
		# TODO: 實作附加特徵邏輯
		_complete_action()


func _on_play_button_pressed():
	if selected_character and selected_card_id >= 0:
		print("打出: %s 使用卡牌 #%d" % [selected_character.name, selected_card_id])
		# TODO: 實作打出卡牌邏輯
		_complete_action()


func _on_cancel_button_pressed():
	_clear_selection()


func _complete_action():
	# 將卡牌從手牌移到棄牌堆
	if selected_card_index >= 0 and selected_card_index < hand.size():
		var card_id = hand[selected_card_index]
		hand.remove_at(selected_card_index)
		discard_pile.append(card_id)

	_clear_selection()
	_refresh_hand_ui()
	_update_deck_info()


func _clear_selection():
	selected_character = null
	selected_card_id = -1
	selected_card_index = -1
	action_panel.visible = false
