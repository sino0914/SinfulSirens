extends Control

# 編輯關卡主場景控制腳本

@onready var enemy_list = $MarginContainer/VBoxContainer/ContentContainer/LeftPanel/EnemyListContainer/ScrollContainer/EnemyList
@onready var stage_list = $MarginContainer/VBoxContainer/ContentContainer/RightPanel/StageListContainer/ScrollContainer/StageList
@onready var preview_panel = $MarginContainer/VBoxContainer/ContentContainer/RightPanel/PreviewContainer/ScrollContainer/PreviewContent

# 預載入對話框場景
const ENEMY_EDIT_DIALOG_SCENE = preload("res://Scenes/Dialogs/EnemyEditDialog.tscn")
const STAGE_EDIT_DIALOG_SCENE = preload("res://Scenes/Dialogs/StageEditDialog.tscn")

var enemy_edit_dialog: Window = null
var stage_edit_dialog: Window = null
var current_preview_stage: Stage = null


func _ready():
	print("編輯關卡場景已載入")
	_setup_dialogs()
	_refresh_enemy_list()
	_refresh_stage_list()


func _setup_dialogs():
	# 創建敵人編輯對話框
	enemy_edit_dialog = ENEMY_EDIT_DIALOG_SCENE.instantiate()
	enemy_edit_dialog.enemy_saved.connect(_on_enemy_saved)
	enemy_edit_dialog.visible = false  # 初始隱藏
	add_child(enemy_edit_dialog)

	# 創建關卡編輯對話框
	stage_edit_dialog = STAGE_EDIT_DIALOG_SCENE.instantiate()
	stage_edit_dialog.stage_saved.connect(_on_stage_saved)
	stage_edit_dialog.visible = false  # 初始隱藏
	add_child(stage_edit_dialog)


# ==================== 敵人列表管理 ====================

func _refresh_enemy_list():
	# 清空列表
	for child in enemy_list.get_children():
		child.queue_free()

	# 載入所有敵人
	var enemies = DataManager.get_all_enemies()

	if enemies.is_empty():
		var label = Label.new()
		label.text = "尚無敵人資料"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		enemy_list.add_child(label)
	else:
		for enemy in enemies:
			_add_enemy_item(enemy)


func _add_enemy_item(enemy: Enemy):
	var item = PanelContainer.new()
	item.custom_minimum_size = Vector2(0, 120)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	item.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	# 左側: 敵人圖片
	var image_container = PanelContainer.new()
	image_container.custom_minimum_size = Vector2(100, 100)
	hbox.add_child(image_container)

	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(100, 100)

	# 載入圖片
	if not enemy.image_path.is_empty() and FileAccess.file_exists(enemy.image_path):
		var image = Image.new()
		var error = image.load(enemy.image_path)
		if error == OK:
			texture_rect.texture = ImageTexture.create_from_image(image)
		else:
			_set_placeholder_texture(texture_rect)
	else:
		_set_placeholder_texture(texture_rect)

	image_container.add_child(texture_rect)

	# 中間: 敵人資訊
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = enemy.name
	name_label.add_theme_font_size_override("font_size", 20)
	info_vbox.add_child(name_label)

	var stats_label = Label.new()
	stats_label.text = "HP: %d" % enemy.hp
	stats_label.add_theme_font_size_override("font_size", 15)
	stats_label.modulate = Color(0.9, 0.9, 0.9)
	info_vbox.add_child(stats_label)

	var stats_label2 = Label.new()
	stats_label2.text = "力量:%d 防禦:%d 速度:%d" % [enemy.strength, enemy.defense, enemy.speed]
	stats_label2.add_theme_font_size_override("font_size", 14)
	stats_label2.modulate = Color(0.8, 0.8, 0.8)
	info_vbox.add_child(stats_label2)

	# 右側: 操作按鈕
	var button_vbox = VBoxContainer.new()
	button_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(button_vbox)

	var edit_btn = Button.new()
	edit_btn.text = "編輯"
	edit_btn.custom_minimum_size = Vector2(70, 0)
	edit_btn.add_theme_font_size_override("font_size", 16)
	edit_btn.pressed.connect(_on_edit_enemy_button_pressed.bind(enemy))
	button_vbox.add_child(edit_btn)

	var delete_btn = Button.new()
	delete_btn.text = "刪除"
	delete_btn.custom_minimum_size = Vector2(70, 0)
	delete_btn.add_theme_font_size_override("font_size", 16)
	delete_btn.pressed.connect(_on_delete_enemy_button_pressed.bind(enemy))
	button_vbox.add_child(delete_btn)

	enemy_list.add_child(item)


func _set_placeholder_texture(texture_rect: TextureRect):
	# 創建佔位圖
	var placeholder_label = Label.new()
	placeholder_label.text = "無圖片"
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_label.add_theme_font_size_override("font_size", 14)
	placeholder_label.modulate = Color(0.5, 0.5, 0.5)
	texture_rect.add_child(placeholder_label)


func _on_add_enemy_button_pressed():
	enemy_edit_dialog.setup_new_enemy()
	enemy_edit_dialog.popup_centered()


func _on_edit_enemy_button_pressed(enemy: Enemy):
	enemy_edit_dialog.setup_edit_enemy(enemy)
	enemy_edit_dialog.popup_centered()


func _on_delete_enemy_button_pressed(enemy: Enemy):
	# 檢查是否有關卡使用此敵人
	var using_stages = DataManager.get_stages_using_enemy(enemy.id)

	if using_stages.size() > 0:
		var stage_names = []
		for stage in using_stages:
			stage_names.append(stage.name)

		var dialog = AcceptDialog.new()
		dialog.dialog_text = "無法刪除!\n此敵人正被以下關卡使用:\n\n" + "\n".join(stage_names)
		dialog.title = "無法刪除敵人"
		dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		add_child(dialog)
		dialog.popup_centered()
		return

	# 確認刪除
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "確定要刪除敵人「%s」嗎?" % enemy.name
	confirm_dialog.title = "確認刪除"
	confirm_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm_dialog.confirmed.connect(_delete_enemy_confirmed.bind(enemy))
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()


func _delete_enemy_confirmed(enemy: Enemy):
	if DataManager.delete_enemy(enemy.id):
		_refresh_enemy_list()
		# 如果當前預覽的關卡包含此敵人,刷新預覽
		if current_preview_stage and current_preview_stage.has_enemy(enemy.id):
			preview_panel.display_stage(current_preview_stage)
		print("敵人已刪除: ", enemy.name)


func _on_enemy_saved(enemy: Enemy):
	if enemy.id.is_empty():
		# 新增敵人
		DataManager.add_enemy(enemy)
	else:
		# 更新敵人
		DataManager.update_enemy(enemy)

	_refresh_enemy_list()
	# 如果當前預覽的關卡包含此敵人,刷新預覽
	if current_preview_stage and current_preview_stage.has_enemy(enemy.id):
		preview_panel.display_stage(current_preview_stage)


# ==================== 關卡列表管理 ====================

func _refresh_stage_list():
	# 清空列表
	for child in stage_list.get_children():
		child.queue_free()

	# 載入所有關卡
	var stages = DataManager.get_all_stages()

	if stages.is_empty():
		var label = Label.new()
		label.text = "尚無關卡資料"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		stage_list.add_child(label)
	else:
		for stage in stages:
			_add_stage_item(stage)


func _add_stage_item(stage: Stage):
	var item = PanelContainer.new()
	item.custom_minimum_size = Vector2(0, 90)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	item.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# 頂部: 關卡名稱和按鈕
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(top_hbox)

	var name_label = Label.new()
	name_label.text = stage.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 20)
	top_hbox.add_child(name_label)

	var preview_btn = Button.new()
	preview_btn.text = "預覽"
	preview_btn.custom_minimum_size = Vector2(70, 0)
	preview_btn.add_theme_font_size_override("font_size", 16)
	preview_btn.pressed.connect(_on_preview_stage_button_pressed.bind(stage))
	top_hbox.add_child(preview_btn)

	var edit_btn = Button.new()
	edit_btn.text = "編輯"
	edit_btn.custom_minimum_size = Vector2(70, 0)
	edit_btn.add_theme_font_size_override("font_size", 16)
	edit_btn.pressed.connect(_on_edit_stage_button_pressed.bind(stage))
	top_hbox.add_child(edit_btn)

	var delete_btn = Button.new()
	delete_btn.text = "刪除"
	delete_btn.custom_minimum_size = Vector2(70, 0)
	delete_btn.add_theme_font_size_override("font_size", 16)
	delete_btn.pressed.connect(_on_delete_stage_button_pressed.bind(stage))
	top_hbox.add_child(delete_btn)

	# 底部: 關卡資訊
	var info_label = Label.new()
	info_label.text = "敵人數量: %d" % stage.enemy_ids.size()
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(info_label)

	if not stage.description.is_empty():
		var desc_label = Label.new()
		desc_label.text = stage.description
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.modulate = Color(0.7, 0.7, 0.7)
		vbox.add_child(desc_label)

	stage_list.add_child(item)


func _on_preview_stage_button_pressed(stage: Stage):
	current_preview_stage = stage
	preview_panel.display_stage(stage)


func _on_add_stage_button_pressed():
	stage_edit_dialog.setup_new_stage()
	stage_edit_dialog.popup_centered()


func _on_edit_stage_button_pressed(stage: Stage):
	stage_edit_dialog.setup_edit_stage(stage)
	stage_edit_dialog.popup_centered()


func _on_delete_stage_button_pressed(stage: Stage):
	# 確認刪除
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "確定要刪除關卡「%s」嗎?" % stage.name
	confirm_dialog.title = "確認刪除"
	confirm_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm_dialog.confirmed.connect(_delete_stage_confirmed.bind(stage))
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()


func _delete_stage_confirmed(stage: Stage):
	if DataManager.delete_stage(stage.id):
		_refresh_stage_list()
		# 如果刪除的是當前預覽的關卡,清空預覽
		if current_preview_stage == stage:
			current_preview_stage = null
			preview_panel.clear_preview()
		print("關卡已刪除: ", stage.name)


func _on_stage_saved(stage: Stage):
	if stage.id.is_empty():
		# 新增關卡
		DataManager.add_stage(stage)
	else:
		# 更新關卡
		DataManager.update_stage(stage)

	_refresh_stage_list()
	# 如果是當前預覽的關卡,刷新預覽
	if current_preview_stage and current_preview_stage.id == stage.id:
		current_preview_stage = stage
		preview_panel.display_stage(stage)


# ==================== 關卡預覽 ====================
# 預覽功能已移至 StagePreviewPanel 元件


# ==================== 其他 ====================

func _on_back_button_pressed():
	print("返回編輯模式")
	get_tree().change_scene_to_file("res://Scenes/EditMode/EditMode.tscn")
