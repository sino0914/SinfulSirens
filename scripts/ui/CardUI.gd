extends Control
class_name CardUI

# 卡牌類型枚舉
enum CardType {
	TRAIT,
	ACTION
}

# 卡牌數據
var card_data: Dictionary
var card_type: CardType
var is_selected: bool = false
var is_dragging: bool = false

# UI 組件
@onready var card_background: NinePatchRect = $CardBackground
@onready var card_name: Label = $CardContent/CardName
@onready var card_description: Label = $CardContent/CardDescription
@onready var card_cost: Label = $CardContent/CardCost
@onready var card_icon: TextureRect = $CardContent/CardIcon

# 信號
signal card_clicked(card: CardUI)
signal card_drag_started(card: CardUI)
signal card_drag_ended(card: CardUI)
signal card_hovered(card: CardUI)
signal card_unhovered(card: CardUI)

func _ready():
	# 連接滑鼠事件
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_card_pressed()
			else:
				_on_card_released()
	elif event is InputEventMouseMotion and is_dragging:
		global_position = event.global_position - size * 0.5

func setup_card(data: Dictionary):
	card_data = data
	card_type = data.get("type", CardType.ACTION)

	# 更新UI顯示
	if card_name:
		card_name.text = data.get("name", "未知卡牌")
	if card_description:
		card_description.text = data.get("description", "")
	if card_cost:
		card_cost.text = str(data.get("cost", 0))

	# 設置卡牌背景顏色
	if card_background:
		match card_type:
			CardType.TRAIT:
				card_background.modulate = Color(0.8, 1.0, 0.8)  # 淡綠色
			CardType.ACTION:
				card_background.modulate = Color(1.0, 0.8, 0.8)  # 淡紅色

func _on_card_pressed():
	card_clicked.emit(self)
	is_dragging = true
	card_drag_started.emit(self)

	# 視覺效果
	modulate = Color(1.1, 1.1, 1.1)
	z_index = 100

func _on_card_released():
	if is_dragging:
		is_dragging = false
		card_drag_ended.emit(self)

		# 重置視覺效果
		modulate = Color.WHITE
		z_index = 0

func _on_mouse_entered():
	card_hovered.emit(self)
	if not is_dragging:
		modulate = Color(1.05, 1.05, 1.05)

func _on_mouse_exited():
	card_unhovered.emit(self)
	if not is_dragging:
		modulate = Color.WHITE

func set_selected(selected: bool):
	is_selected = selected
	if card_background:
		if selected:
			card_background.modulate = Color(1.2, 1.2, 0.8)  # 黃色高亮
		else:
			# 重置為原本類型顏色
			setup_card(card_data)