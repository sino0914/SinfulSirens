extends Window

# 敵人編輯對話框

signal enemy_saved(enemy: Enemy)

@onready var name_input = $MarginContainer/VBoxContainer/NameContainer/NameInput
@onready var hp_input = $MarginContainer/VBoxContainer/HpContainer/HpInput
@onready var strength_input = $MarginContainer/VBoxContainer/StrengthContainer/StrengthInput
@onready var defense_input = $MarginContainer/VBoxContainer/DefenseContainer/DefenseInput
@onready var speed_input = $MarginContainer/VBoxContainer/SpeedContainer/SpeedInput
@onready var image_path_input = $MarginContainer/VBoxContainer/ImageContainer/ImagePathInput
@onready var image_preview = $MarginContainer/VBoxContainer/ImagePreviewContainer/ImagePreview
@onready var desc_input = $MarginContainer/VBoxContainer/DescContainer/DescInput
@onready var file_dialog = $FileDialog

var current_enemy: Enemy = null
var is_new_enemy: bool = true


func _ready():
	close_requested.connect(_on_cancel_button_pressed)


func setup_new_enemy():
	is_new_enemy = true
	current_enemy = Enemy.new()
	title = "新增敵人"
	_clear_inputs()


func setup_edit_enemy(enemy: Enemy):
	is_new_enemy = false
	current_enemy = enemy
	title = "編輯敵人"
	_load_enemy_data()


func _clear_inputs():
	name_input.text = ""
	hp_input.value = 100
	strength_input.value = 10
	defense_input.value = 5
	speed_input.value = 5
	image_path_input.text = ""
	image_preview.texture = null
	desc_input.text = ""


func _load_enemy_data():
	if current_enemy:
		name_input.text = current_enemy.name
		hp_input.value = current_enemy.hp
		strength_input.value = current_enemy.strength
		defense_input.value = current_enemy.defense
		speed_input.value = current_enemy.speed
		image_path_input.text = current_enemy.image_path
		desc_input.text = current_enemy.description
		_load_image_preview(current_enemy.image_path)


func _on_browse_button_pressed():
	file_dialog.popup_centered()


func _on_file_dialog_file_selected(path: String):
	image_path_input.text = path
	_load_image_preview(path)


func _load_image_preview(path: String):
	if path.is_empty() or not FileAccess.file_exists(path):
		image_preview.texture = null
		return

	var image = Image.new()
	var error = image.load(path)
	if error == OK:
		image_preview.texture = ImageTexture.create_from_image(image)
	else:
		image_preview.texture = null


func _on_save_button_pressed():
	# 驗證輸入
	if name_input.text.strip_edges().is_empty():
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "請輸入敵人名稱!"
		dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		add_child(dialog)
		dialog.popup_centered()
		return

	# 確保 current_enemy 已初始化
	if current_enemy == null:
		current_enemy = Enemy.new()

	# 更新敵人資料
	current_enemy.name = name_input.text.strip_edges()
	current_enemy.hp = int(hp_input.value)
	current_enemy.strength = int(strength_input.value)
	current_enemy.defense = int(defense_input.value)
	current_enemy.speed = int(speed_input.value)
	current_enemy.image_path = image_path_input.text
	current_enemy.description = desc_input.text

	# 發送信號
	enemy_saved.emit(current_enemy)

	# 關閉視窗
	hide()


func _on_cancel_button_pressed():
	hide()
