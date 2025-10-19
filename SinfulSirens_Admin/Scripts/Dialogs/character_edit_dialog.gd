extends Window

# 我方角色編輯對話框
# 參考 EnemyEditDialog 的設計

signal character_saved(character: PlayerCharacter)

# UI 節點
@onready var name_input: LineEdit = $MarginContainer/VBoxContainer/FormContainer/NameInput
@onready var hp_input: SpinBox = $MarginContainer/VBoxContainer/FormContainer/HPInput
@onready var strength_input: SpinBox = $MarginContainer/VBoxContainer/FormContainer/StrengthInput
@onready var defense_input: SpinBox = $MarginContainer/VBoxContainer/FormContainer/DefenseInput
@onready var speed_input: SpinBox = $MarginContainer/VBoxContainer/FormContainer/SpeedInput
@onready var food_input: SpinBox = $MarginContainer/VBoxContainer/FormContainer/FoodInput
@onready var image_path_input: LineEdit = $MarginContainer/VBoxContainer/FormContainer/ImagePathContainer/ImagePathInput
@onready var image_preview: TextureRect = $MarginContainer/VBoxContainer/FormContainer/ImagePreview
@onready var desc_input: TextEdit = $MarginContainer/VBoxContainer/FormContainer/DescInput

# 當前編輯的角色
var current_character: PlayerCharacter = null
var is_new: bool = true

# 檔案選擇對話框
var file_dialog: FileDialog = null


func _ready():
	_setup_file_dialog()
	_setup_inputs()


func _setup_file_dialog():
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png ; PNG Images", "*.jpg ; JPG Images", "*.jpeg ; JPEG Images"])
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	add_child(file_dialog)


func _setup_inputs():
	# 設置屬性輸入範圍
	hp_input.min_value = 1
	hp_input.max_value = 9999
	hp_input.step = 1

	strength_input.min_value = 0
	strength_input.max_value = 999
	strength_input.step = 1

	defense_input.min_value = 0
	defense_input.max_value = 999
	defense_input.step = 1

	speed_input.min_value = 0
	speed_input.max_value = 999
	speed_input.step = 1

	food_input.min_value = 0
	food_input.max_value = 999
	food_input.step = 1


func setup_new_character():
	is_new = true
	title = "新增我方角色"
	current_character = PlayerCharacter.new()

	# 清空表單
	name_input.text = "新角色"
	hp_input.value = 100
	strength_input.value = 10
	defense_input.value = 5
	speed_input.value = 5
	food_input.value = 0
	image_path_input.text = ""
	desc_input.text = ""
	image_preview.texture = null


func setup_edit_character(character: PlayerCharacter):
	is_new = false
	title = "編輯我方角色"
	current_character = character

	# 填充表單
	name_input.text = character.name
	hp_input.value = character.hp
	strength_input.value = character.strength
	defense_input.value = character.defense
	speed_input.value = character.speed
	food_input.value = character.food_requirement
	image_path_input.text = character.image_path
	desc_input.text = character.description

	# 載入圖片
	_load_image_preview(character.image_path)


func _on_browse_button_pressed():
	file_dialog.popup_centered_ratio(0.6)


func _on_file_selected(path: String):
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
		print("載入圖片失敗: ", path)


func _on_save_button_pressed():
	# 驗證輸入
	if name_input.text.strip_edges().is_empty():
		print("請輸入角色名稱")
		return

	# 更新角色資料
	current_character.name = name_input.text
	current_character.hp = int(hp_input.value)
	current_character.strength = int(strength_input.value)
	current_character.defense = int(defense_input.value)
	current_character.speed = int(speed_input.value)
	current_character.food_requirement = int(food_input.value)
	current_character.image_path = image_path_input.text
	current_character.description = desc_input.text

	# 發送信號
	character_saved.emit(current_character)

	# 關閉對話框
	hide()


func _on_cancel_button_pressed():
	hide()
