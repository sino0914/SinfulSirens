extends Node

# 全局遊戲資料管理器
# 用於在場景之間傳遞資料

var current_game_setup: GameSetup = null
var current_stage: Stage = null
var player_characters: Array[PlayerCharacter] = []
var trait_cards: Array = []  # 特徵卡資料


func set_battle_data(setup: GameSetup, stage: Stage, characters: Array[PlayerCharacter], cards: Array):
	current_game_setup = setup
	current_stage = stage
	player_characters = characters.duplicate()
	trait_cards = cards.duplicate()
	print("全局資料已設定")


func clear_battle_data():
	current_game_setup = null
	current_stage = null
	player_characters.clear()
	trait_cards.clear()
