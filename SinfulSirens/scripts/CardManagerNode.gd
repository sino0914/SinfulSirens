extends Node

# 卡牌堆疊
var deck: Array = []
var hand: Array = []
var discard_pile: Array = []
var removed_cards: Array = []

# 手牌上限
var max_hand_size: int = 7

# 信號
signal card_drawn(card)
signal hand_size_changed(new_size: int)

func _ready():
	print("CardManagerNode 初始化完成")

func initialize_with_test_deck():
	# 創建簡單測試卡牌
	for i in range(10):
		var card = {
			"name": "測試卡牌 " + str(i + 1),
			"type": "basic",
			"id": i,
			"description": "基本測試卡牌"
		}
		deck.append(card)
	deck.shuffle()
	print("創建了 ", deck.size(), " 張測試卡牌")

func draw_card() -> bool:
	if hand.size() >= max_hand_size:
		print("手牌已滿")
		return false

	if deck.is_empty():
		print("牌庫為空")
		return false

	var card = deck.pop_front()
	hand.append(card)
	card_drawn.emit(card)
	hand_size_changed.emit(hand.size())

	print("抽到卡牌: ", card.get("name", ""))
	return true

func draw_to_hand_limit() -> int:
	var cards_to_draw = max_hand_size - hand.size()
	var drawn = 0
	for i in range(cards_to_draw):
		if draw_card():
			drawn += 1
		else:
			break
	return drawn

func get_hand_cards() -> Array:
	return hand.duplicate()

func convert_cards_to_food(cards: Array) -> int:
	var food_gained = 0
	for card in cards:
		if card in hand:
			var index = hand.find(card)
			hand.remove_at(index)
			removed_cards.append(card)
			food_gained += 1
	hand_size_changed.emit(hand.size())
	return food_gained

func get_hand_size() -> int:
	return hand.size()