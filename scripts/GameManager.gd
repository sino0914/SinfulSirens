extends Control
class_name GameManager

# 遊戲狀態枚舉
enum GamePhase {
	TURN_START,
	PLAYER_ACTION,
	CHARACTER_PHASES,
	FEEDING_PHASE,
	TURN_END
}

# 遊戲狀態
var current_turn: int = 1
var current_phase: GamePhase = GamePhase.TURN_START
var available_food: int = 0
var action_selected: bool = false

# 管理器實例（節點類型，不使用 class_name）
var character_manager: Node
var card_manager: Node

# UI 引用
@onready var turn_label: Label = $UI/GameUI/GameInfo/TurnLabel
@onready var phase_label: Label = $UI/GameUI/GameInfo/PhaseLabel
@onready var food_label: Label = $UI/GameUI/GameInfo/FoodLabel
@onready var equip_trait_button: Button = $UI/GameUI/ActionButtons/EquipTraitButton
@onready var use_action_button: Button = $UI/GameUI/ActionButtons/UseActionButton
@onready var character_area: VBoxContainer = $UI/GameUI/CharacterArea
@onready var hand_area: HBoxContainer = $UI/GameUI/HandArea

func _ready():
	# 初始化管理器（使用腳本載入，不依賴 class_name）
	var character_script = load("res://scripts/CharacterManagerNode.gd")
	var card_script = load("res://scripts/CardManagerNode.gd")

	character_manager = Node.new()
	character_manager.set_script(character_script)
	character_manager.name = "CharacterManager"
	add_child(character_manager)

	card_manager = Node.new()
	card_manager.set_script(card_script)
	card_manager.name = "CardManager"
	add_child(card_manager)

	# 連接按鈕信號
	equip_trait_button.pressed.connect(_on_equip_trait_pressed)
	use_action_button.pressed.connect(_on_use_action_pressed)

	# 連接管理器信號
	character_manager.party_wiped_out.connect(_on_party_wiped_out)
	character_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)

	# 初始化卡牌系統
	card_manager.initialize_with_test_deck()

	# 初始化遊戲
	start_new_turn()

func start_new_turn():
	current_phase = GamePhase.TURN_START
	action_selected = false

	# 抽牌到手牌上限
	card_manager.draw_to_hand_limit()

	# 恢復所有角色的特徵（移除退化狀態）
	character_manager.restore_all_character_traits()

	update_ui()
	update_hand_display()
	update_character_display()
	print("回合 ", current_turn, " 開始")

func _on_equip_trait_pressed():
	if current_phase == GamePhase.TURN_START and not action_selected:
		action_selected = true
		current_phase = GamePhase.PLAYER_ACTION
		print("選擇裝備特徵卡")
		equip_trait_button.disabled = true
		use_action_button.disabled = true
		# TODO: 實作特徵卡裝備邏輯
		_continue_to_character_phases()

func _on_use_action_pressed():
	if current_phase == GamePhase.TURN_START and not action_selected:
		action_selected = true
		current_phase = GamePhase.PLAYER_ACTION
		print("選擇使用行動卡")
		equip_trait_button.disabled = true
		use_action_button.disabled = true
		# TODO: 實作行動卡使用邏輯
		_continue_to_character_phases()

func _continue_to_character_phases():
	# 延遲一點時間，讓玩家看到選擇結果
	await get_tree().create_timer(1.0).timeout
	current_phase = GamePhase.CHARACTER_PHASES
	update_ui()
	print("進入角色階段")

	# TODO: 實作角色行動邏輯
	_continue_to_feeding_phase()

func _continue_to_feeding_phase():
	await get_tree().create_timer(2.0).timeout
	current_phase = GamePhase.FEEDING_PHASE
	update_ui()
	print("進入餵食階段")

	# 實作餵食邏輯
	perform_feeding()
	_continue_to_turn_end()

func _continue_to_turn_end():
	await get_tree().create_timer(1.0).timeout
	current_phase = GamePhase.TURN_END
	update_ui()
	print("回合結束")

	# 準備下一回合
	current_turn += 1
	equip_trait_button.disabled = false
	use_action_button.disabled = false
	start_new_turn()

func update_ui():
	turn_label.text = "回合: " + str(current_turn)
	food_label.text = "食物: " + str(available_food)

	match current_phase:
		GamePhase.TURN_START:
			phase_label.text = "階段: 回合開始"
		GamePhase.PLAYER_ACTION:
			phase_label.text = "階段: 玩家行動"
		GamePhase.CHARACTER_PHASES:
			phase_label.text = "階段: 角色階段"
		GamePhase.FEEDING_PHASE:
			phase_label.text = "階段: 餵食階段"
		GamePhase.TURN_END:
			phase_label.text = "階段: 回合結束"

# 餵食系統
func perform_feeding():
	var unused_cards = card_manager.get_hand_cards()
	if unused_cards.size() > 0:
		# 將未使用的手牌轉換為食物
		var food_gained = card_manager.convert_cards_to_food(unused_cards)
		available_food += food_gained
		print("轉換 ", food_gained, " 張手牌為食物")

	# 餵食角色
	available_food = character_manager.feed_characters(available_food)
	update_ui()

# 添加食物
func add_food(amount: int):
	available_food += amount

# 手牌顯示更新
func update_hand_display():
	# 清除現有顯示
	for child in hand_area.get_children():
		child.queue_free()

	# 顯示當前手牌
	var hand_cards = card_manager.get_hand_cards()
	for card in hand_cards:
		var card_ui = preload("res://scenes/ui/CardUI.tscn").instantiate()
		hand_area.add_child(card_ui)

		# 處理基本字典格式的卡牌
		var card_data = {}
		if typeof(card) == TYPE_DICTIONARY:
			card_data = {
				"name": card.get("name", "未知卡牌"),
				"description": "基本測試卡牌",
				"type": CardUI.CardType.ACTION,
				"cost": 0
			}
		else:
			card_data = {
				"name": "未知卡牌",
				"description": "",
				"type": CardUI.CardType.ACTION,
				"cost": 0
			}

		card_ui.setup_card(card_data)

# 角色顯示更新
func update_character_display():
	# 清除現有顯示
	for child in character_area.get_children():
		child.queue_free()

	# 顯示隊伍角色
	var characters = character_manager.get_party_characters()
	for character in characters:
		var character_label = Label.new()
		var status = "存活" if character.is_alive else "倒地"
		var text = character.character_name + " (HP: " + str(character.current_hp) + "/" + str(character.max_hp) + ") - " + status
		character_label.text = text
		character_area.add_child(character_label)

# 勝敗條件處理
func _on_party_wiped_out():
	print("隊伍全滅！遊戲失敗")
	# TODO: 顯示失敗畫面

func _on_all_enemies_defeated():
	print("所有敵人被擊敗！戰鬥勝利")
	# TODO: 顯示勝利畫面和獎勵