extends Control

# 編輯特徵卡場景控制腳本

# 特徵卡資料結構
class TraitCard:
	var id: int
	var position: String  # 部位
	var food_amount: int  # 食物數量
	var image_path: String  # 圖片路徑

	func _init(p_id: int, p_position: String, p_food_amount: int, p_image_path: String = ""):
		id = p_id
		position = p_position
		food_amount = p_food_amount
		image_path = p_image_path

# 部位選項
const POSITIONS = ["頭飾", "眼睛", "首飾", "身體", "手", "腳", "尾", "背", "其他"]

# 特徵卡列表
var trait_cards: Array[TraitCard] = []
var next_id: int = 1
var selected_card: TraitCard = null

# UI 節點引用
@onready var trait_list: ItemList = $MarginContainer/VBoxContainer/HBoxContainer/LeftPanel/VBoxContainer/TraitList
@onready var image_preview: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/RightPanel/VBoxContainer/FormContainer/ImagePreviewContainer/ImagePreview
@onready var image_path_input: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/RightPanel/VBoxContainer/FormContainer/ImagePathContainer/ImagePathInput
@onready var position_option: OptionButton = $MarginContainer/VBoxContainer/HBoxContainer/RightPanel/VBoxContainer/FormContainer/PositionOption
@onready var food_amount_input: SpinBox = $MarginContainer/VBoxContainer/HBoxContainer/RightPanel/VBoxContainer/FormContainer/FoodAmountInput
@onready var add_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RightPanel/VBoxContainer/ButtonContainer/AddButton
@onready var update_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RightPanel/VBoxContainer/ButtonContainer/UpdateButton
@onready var delete_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RightPanel/VBoxContainer/ButtonContainer/DeleteButton

var file_dialog: FileDialog = null
var current_image_path: String = ""

func _ready():
	print("編輯特徵卡場景已載入")
	_setup_file_dialog()
	_initialize_ui()
	_load_data()
	_update_trait_list()

func _setup_file_dialog():
	# 創建檔案選擇對話框
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png ; PNG Images", "*.jpg ; JPG Images", "*.jpeg ; JPEG Images"])
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	add_child(file_dialog)

func _initialize_ui():
	# 初始化部位選項
	for pos in POSITIONS:
		position_option.add_item(pos)

	# 設置食物數量範圍
	food_amount_input.min_value = 0
	food_amount_input.max_value = 9999
	food_amount_input.step = 1
	food_amount_input.value = 0

	# 初始狀態
	update_button.disabled = true
	delete_button.disabled = true

func _update_trait_list():
	trait_list.clear()
	for card in trait_cards:
		var display_text = "ID:%d | %s | 食物:%d" % [card.id, card.position, card.food_amount]
		trait_list.add_item(display_text)

func _clear_form():
	position_option.selected = 0
	food_amount_input.value = 0
	current_image_path = ""
	image_path_input.text = ""
	image_preview.texture = null
	selected_card = null
	update_button.disabled = true
	delete_button.disabled = true
	trait_list.deselect_all()

func _on_trait_list_item_selected(index: int):
	if index >= 0 and index < trait_cards.size():
		selected_card = trait_cards[index]
		# 填充表單
		var pos_index = POSITIONS.find(selected_card.position)
		if pos_index >= 0:
			position_option.selected = pos_index
		food_amount_input.value = selected_card.food_amount

		# 載入圖片
		current_image_path = selected_card.image_path
		image_path_input.text = selected_card.image_path
		_load_image_preview(selected_card.image_path)

		# 啟用更新和刪除按鈕
		update_button.disabled = false
		delete_button.disabled = false

func _on_browse_button_pressed():
	file_dialog.popup_centered_ratio(0.6)

func _on_file_selected(path: String):
	current_image_path = path
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

func _on_add_button_pressed():
	var position = POSITIONS[position_option.selected]
	var food_amount = int(food_amount_input.value)

	var new_card = TraitCard.new(next_id, position, food_amount, current_image_path)
	trait_cards.append(new_card)
	next_id += 1

	_update_trait_list()
	_save_data()
	_clear_form()
	print("新增特徵卡: ID=%d, 部位=%s, 食物=%d, 圖片=%s" % [new_card.id, new_card.position, new_card.food_amount, new_card.image_path])

func _on_update_button_pressed():
	if selected_card == null:
		return

	selected_card.position = POSITIONS[position_option.selected]
	selected_card.food_amount = int(food_amount_input.value)
	selected_card.image_path = current_image_path

	_update_trait_list()
	_save_data()
	print("更新特徵卡: ID=%d, 部位=%s, 食物=%d, 圖片=%s" % [selected_card.id, selected_card.position, selected_card.food_amount, selected_card.image_path])
	_clear_form()

func _on_delete_button_pressed():
	if selected_card == null:
		return

	var card_id = selected_card.id
	trait_cards.erase(selected_card)

	_update_trait_list()
	_save_data()
	_clear_form()
	print("刪除特徵卡: ID=%d" % card_id)

func _save_data():
	var save_data = []
	for card in trait_cards:
		save_data.append({
			"id": card.id,
			"position": card.position,
			"food_amount": card.food_amount,
			"image_path": card.image_path
		})

	var save_path = "user://trait_cards.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"cards": save_data, "next_id": next_id}))
		file.close()
		print("資料已儲存: %s" % save_path)

func _load_data():
	var save_path = "user://trait_cards.json"
	if not FileAccess.file_exists(save_path):
		print("無儲存檔案")
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
				for card_data in data.cards:
					var img_path = card_data.get("image_path", "")
					var card = TraitCard.new(
						card_data.id,
						card_data.position,
						card_data.food_amount,
						img_path
					)
					trait_cards.append(card)
			if data.has("next_id"):
				next_id = data.next_id
			print("資料已載入: %d 張特徵卡" % trait_cards.size())

func _on_back_button_pressed():
	print("返回編輯模式")
	get_tree().change_scene_to_file("res://Scenes/EditMode/EditMode.tscn")
