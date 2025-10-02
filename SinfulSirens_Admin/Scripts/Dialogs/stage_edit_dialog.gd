extends Window

# 關卡編輯對話框

signal stage_saved(stage: Stage)

@onready var name_input = $MarginContainer/VBoxContainer/NameContainer/NameInput
@onready var desc_input = $MarginContainer/VBoxContainer/DescContainer/DescInput
@onready var enemy_grid = $MarginContainer/VBoxContainer/EnemyContainer/ContentContainer/LeftPanel/EnemyListContainer/ScrollContainer/EnemyGrid
@onready var count_label = $MarginContainer/VBoxContainer/EnemyContainer/HeaderContainer/CountLabel
@onready var preview_panel = $MarginContainer/VBoxContainer/EnemyContainer/ContentContainer/RightPanel/PreviewContainer/ScrollContainer/PreviewContent

var current_stage: Stage = null
var editing_stage: Stage = null  # 編輯中的暫存副本
var is_new_stage: bool = true
var all_enemies: Array[Enemy] = []


func _ready():
	close_requested.connect(_on_cancel_button_pressed)
	preview_panel.enemy_removed.connect(_on_remove_enemy_from_stage)


func setup_new_stage():
	is_new_stage = true
	current_stage = null
	editing_stage = Stage.new()
	title = "新增關卡"
	_clear_inputs()
	_load_enemy_list()
	_refresh_stage_enemy_list()
	preview_panel.display_stage(editing_stage)


func setup_edit_stage(stage: Stage):
	is_new_stage = false
	current_stage = stage
	# 創建副本以避免直接修改原始物件
	editing_stage = _clone_stage(stage)
	title = "編輯關卡"
	_load_stage_data()
	_load_enemy_list()
	_refresh_stage_enemy_list()
	preview_panel.display_stage(editing_stage)


func _clear_inputs():
	name_input.text = ""
	desc_input.text = ""


func _load_stage_data():
	if editing_stage:
		name_input.text = editing_stage.name
		desc_input.text = editing_stage.description


func _clone_stage(stage: Stage) -> Stage:
	var clone = Stage.new()
	clone.id = stage.id
	clone.name = stage.name
	clone.description = stage.description
	clone.enemy_ids = stage.enemy_ids.duplicate()
	clone.enemy_positions = stage.enemy_positions.duplicate()
	return clone


func _load_enemy_list():
	# 清空網格
	for child in enemy_grid.get_children():
		child.queue_free()

	# 載入所有敵人
	all_enemies = DataManager.get_all_enemies()

	if all_enemies.is_empty():
		var empty_label = Label.new()
		empty_label.text = "沒有可用的敵人\n請先新增敵人"
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enemy_grid.add_child(empty_label)
	else:
		# 為每個敵人創建卡片
		for enemy in all_enemies:
			_create_enemy_card(enemy)


func _refresh_stage_enemy_list():
	# 更新計數
	count_label.text = str(editing_stage.enemy_ids.size()) + "/8"


func _create_enemy_card(enemy: Enemy):
	# 卡片容器
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 0)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)

	# 敵人圖片
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(180, 180)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if not enemy.image_path.is_empty() and FileAccess.file_exists(enemy.image_path):
		var image = Image.new()
		var error = image.load(enemy.image_path)
		if error == OK:
			texture_rect.texture = ImageTexture.create_from_image(image)

	vbox.add_child(texture_rect)

	# 敵人名稱
	var name_label = Label.new()
	name_label.text = enemy.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# 屬性資訊
	var stats_label = Label.new()
	stats_label.text = "HP:%d 力:%d\n防:%d 速:%d" % [enemy.hp, enemy.strength, enemy.defense, enemy.speed]
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)

	# 新增按鈕
	var add_btn = Button.new()
	add_btn.text = "新增到關卡"
	add_btn.add_theme_font_size_override("font_size", 14)
	add_btn.pressed.connect(_on_add_enemy_to_stage.bind(enemy.id))
	vbox.add_child(add_btn)

	card.add_child(vbox)
	enemy_grid.add_child(card)


func _on_add_enemy_to_stage(enemy_id: String):
	# 檢查是否已達上限
	if editing_stage.enemy_ids.size() >= 8:
		_show_message("已達敵人數量上限(8隻)!")
		return

	# 檢查是否已存在
	if editing_stage.has_enemy(enemy_id):
		_show_message("此敵人已存在於關卡中!")
		return

	# 添加敵人
	editing_stage.add_enemy(enemy_id)
	_refresh_stage_enemy_list()
	preview_panel.display_stage(editing_stage)


func _on_remove_enemy_from_stage(enemy_id: String):
	editing_stage.remove_enemy(enemy_id)
	_refresh_stage_enemy_list()
	preview_panel.display_stage(editing_stage)


func _on_save_button_pressed():
	# 驗證輸入
	if name_input.text.strip_edges().is_empty():
		_show_message("請輸入關卡名稱!")
		return

	if editing_stage.enemy_ids.is_empty():
		_show_message("請至少添加一個敵人!")
		return

	# 更新編輯中的關卡資料
	editing_stage.name = name_input.text.strip_edges()
	editing_stage.description = desc_input.text

	# 如果是編輯現有關卡，將修改複製回原始物件
	if not is_new_stage and current_stage:
		current_stage.name = editing_stage.name
		current_stage.description = editing_stage.description
		current_stage.enemy_ids = editing_stage.enemy_ids.duplicate()
		current_stage.enemy_positions = editing_stage.enemy_positions.duplicate()
		# 發送原始物件
		stage_saved.emit(current_stage)
	else:
		# 新增關卡，直接發送編輯中的物件
		stage_saved.emit(editing_stage)

	# 關閉視窗
	hide()


func _on_cancel_button_pressed():
	hide()


func _show_message(message: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	add_child(dialog)
	dialog.popup_centered()
