extends AspectRatioContainer

# 關卡預覽面板元件

signal enemy_removed(enemy_id: String)

@export var enemy_image_size: int = 90
@export var show_remove_buttons: bool = false
@export var auto_save_on_drag: bool = false  # 拖曳後是否自動保存

var current_stage: Stage = null
var content_container: VBoxContainer = null
var drag_mode: bool = false
var drag_toggle_button: Button = null


func _ready():
	content_container = $Content


func display_stage(stage: Stage):
	current_stage = stage

	if not content_container:
		return

	# 清空預覽區域
	for child in content_container.get_children():
		child.queue_free()

	if stage == null:
		_show_empty_message()
		return

	# 關卡標題
	var title_label = Label.new()
	title_label.text = stage.name
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(title_label)

	# 關卡描述
	if not stage.description.is_empty():
		var desc_label = Label.new()
		desc_label.text = stage.description
		desc_label.add_theme_font_size_override("font_size", 16)
		desc_label.modulate = Color(0.8, 0.8, 0.8)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_container.add_child(desc_label)

	# 分隔線
	var separator = HSeparator.new()
	content_container.add_child(separator)

	# 敵人列表標題和拖曳切換按鈕
	var header_container = HBoxContainer.new()
	header_container.add_theme_constant_override("separation", 15)
	content_container.add_child(header_container)

	var enemy_title = Label.new()
	enemy_title.text = "敵人配置 (%d/8)" % stage.enemy_ids.size()
	enemy_title.add_theme_font_size_override("font_size", 22)
	enemy_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(enemy_title)

	# 拖曳切換按鈕
	drag_toggle_button = Button.new()
	drag_toggle_button.text = "啟用拖曳模式"
	drag_toggle_button.custom_minimum_size = Vector2(120, 0)
	drag_toggle_button.add_theme_font_size_override("font_size", 16)
	drag_toggle_button.toggle_mode = true
	drag_toggle_button.toggled.connect(_on_drag_toggle)
	header_container.add_child(drag_toggle_button)

	# 創建可拖曳區域（使用 Control 而非 VBoxContainer）
	var draggable_area = Control.new()
	draggable_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	draggable_area.custom_minimum_size = Vector2(0, 300)

	# 添加邊框顯示
	var border_panel = Panel.new()
	border_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draggable_area.add_child(border_panel)

	# 創建自訂樣式盒來繪製邊框
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.15, 0.3)  # 半透明背景
	style_box.border_color = Color(0.5, 0.5, 0.6, 0.8)  # 邊框顏色
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	border_panel.add_theme_stylebox_override("panel", style_box)

	content_container.add_child(draggable_area)

	# 顯示敵人
	if stage.enemy_ids.is_empty():
		var no_enemy_label = Label.new()
		no_enemy_label.text = "此關卡尚無敵人"
		no_enemy_label.add_theme_font_size_override("font_size", 16)
		no_enemy_label.modulate = Color(0.7, 0.7, 0.7)
		draggable_area.add_child(no_enemy_label)
	else:
		for i in range(stage.enemy_ids.size()):
			var enemy_id = stage.enemy_ids[i]
			var enemy = DataManager.get_enemy(enemy_id)
			if enemy:
				# 使用儲存的位置，如果沒有則使用預設位置
				var pos = stage.get_enemy_position(enemy_id)
				_add_enemy_item(enemy, draggable_area, pos)
			else:
				var error_label = Label.new()
				error_label.text = "[錯誤] 敵人不存在: " + enemy_id
				error_label.add_theme_font_size_override("font_size", 14)
				error_label.modulate = Color(1, 0.3, 0.3)
				error_label.position = Vector2(10, 10 + i * 30)
				draggable_area.add_child(error_label)


func _add_enemy_item(enemy: Enemy, parent: Control, pos: Vector2):
	# 使用 Control 作為可拖曳的容器
	var draggable_container = Control.new()
	draggable_container.custom_minimum_size = Vector2(enemy_image_size, enemy_image_size + 50)
	draggable_container.position = pos
	draggable_container.set_script(preload("res://Scripts/Components/draggable_character.gd"))

	# 將預覽面板的引用和敵人ID傳給拖曳腳本
	draggable_container.set_meta("preview_panel", self)
	# 需要等待 _ready 後才能調用方法
	draggable_container.ready.connect(func(): draggable_container.set_enemy_id(enemy.id))

	# 角色卡片：垂直排列（圖片在上，名字在下）
	var character_card = VBoxContainer.new()
	character_card.add_theme_constant_override("separation", 5)
	draggable_container.add_child(character_card)

	# 敵人圖片（水平翻轉）
	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(enemy_image_size, enemy_image_size)
	texture_rect.flip_h = true  # 水平翻轉

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

	character_card.add_child(texture_rect)

	# 敵人名稱（圖片底下）
	var name_label = Label.new()
	name_label.text = enemy.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_card.add_child(name_label)

	# 移除按鈕（可選，放在名稱下方）
	if show_remove_buttons:
		var remove_btn = Button.new()
		remove_btn.text = "移除"
		remove_btn.custom_minimum_size = Vector2(70, 0)
		remove_btn.add_theme_font_size_override("font_size", 14)
		remove_btn.pressed.connect(_on_remove_button_pressed.bind(enemy.id))
		character_card.add_child(remove_btn)

	parent.add_child(draggable_container)


func _set_placeholder_texture(texture_rect: TextureRect):
	# 創建佔位圖
	var placeholder_label = Label.new()
	placeholder_label.text = "無圖片"
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_label.add_theme_font_size_override("font_size", 14)
	placeholder_label.modulate = Color(0.5, 0.5, 0.5)
	texture_rect.add_child(placeholder_label)


func _show_empty_message():
	if not content_container:
		return
	var label = Label.new()
	label.text = "請選擇一個關卡查看預覽"
	label.add_theme_font_size_override("font_size", 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content_container.add_child(label)


func _on_remove_button_pressed(enemy_id: String):
	enemy_removed.emit(enemy_id)


func clear_preview():
	current_stage = null
	_show_empty_message()


func _on_drag_toggle(button_pressed: bool):
	drag_mode = button_pressed
	if drag_toggle_button:
		if button_pressed:
			drag_toggle_button.text = "停用拖曳模式"
		else:
			drag_toggle_button.text = "啟用拖曳模式"


func is_drag_mode_enabled() -> bool:
	return drag_mode


func update_enemy_position(enemy_id: String, position: Vector2):
	# 更新關卡中敵人的位置
	if current_stage:
		current_stage.update_enemy_position(enemy_id, position)

		# 如果啟用自動保存，則立即保存到 DataManager
		if auto_save_on_drag:
			DataManager.update_stage(current_stage)
