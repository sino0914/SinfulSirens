extends Resource
class_name GameSetup

# 遊戲設定資料類別
# 用於儲存玩家的遊戲配置（選擇的關卡、特徵卡、我方角色）

@export var stage_id: String = ""  # 選擇的關卡ID
@export var trait_card_ids: Array[int] = []  # 選擇的特徵卡ID列表（最多40張）
@export var player_character_ids: Array[String] = []  # 選擇的我方角色ID列表（1-4位）


func _init(
	p_stage_id: String = "",
	p_trait_card_ids: Array[int] = [],
	p_player_character_ids: Array[String] = []
):
	stage_id = p_stage_id
	trait_card_ids = p_trait_card_ids.duplicate()
	player_character_ids = p_player_character_ids.duplicate()


# 添加特徵卡
func add_trait_card(card_id: int) -> bool:
	if trait_card_ids.size() >= 40:
		return false
	trait_card_ids.append(card_id)
	return true


# 移除特徵卡
func remove_trait_card(card_id: int) -> bool:
	var index = trait_card_ids.find(card_id)
	if index >= 0:
		trait_card_ids.remove_at(index)
		return true
	return false


# 清空特徵卡
func clear_trait_cards():
	trait_card_ids.clear()


# 添加我方角色
func add_player_character(character_id: String) -> bool:
	if player_character_ids.size() >= 4:
		return false
	if not player_character_ids.has(character_id):
		player_character_ids.append(character_id)
		return true
	return false


# 移除我方角色
func remove_player_character(character_id: String) -> bool:
	var index = player_character_ids.find(character_id)
	if index >= 0:
		player_character_ids.remove_at(index)
		return true
	return false


# 檢查是否準備就緒
func is_ready() -> bool:
	return not stage_id.is_empty() and player_character_ids.size() > 0


func to_dict() -> Dictionary:
	return {
		"stage_id": stage_id,
		"trait_card_ids": trait_card_ids.duplicate(),
		"player_character_ids": player_character_ids.duplicate()
	}


static func from_dict(data: Dictionary) -> GameSetup:
	var setup = GameSetup.new()
	setup.stage_id = data.get("stage_id", "")

	var raw_traits = data.get("trait_card_ids", [])
	setup.trait_card_ids.clear()
	for trait_id in raw_traits:
		setup.trait_card_ids.append(int(trait_id))

	var raw_chars = data.get("player_character_ids", [])
	setup.player_character_ids.clear()
	for char_id in raw_chars:
		setup.player_character_ids.append(str(char_id))

	return setup
