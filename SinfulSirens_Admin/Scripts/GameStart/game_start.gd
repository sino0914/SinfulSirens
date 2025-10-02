extends Control

# 開始遊戲場景控制腳本

@onready var team_dropdown = $MarginContainer/VBoxContainer/SelectionContainer/TeamSelection/TeamDropdown
@onready var deck_dropdown = $MarginContainer/VBoxContainer/SelectionContainer/DeckSelection/DeckDropdown
@onready var stage_dropdown = $MarginContainer/VBoxContainer/SelectionContainer/StageSelection/StageDropdown
@onready var message_dialog = $MessageDialog

var selected_team_id = -1
var selected_deck_id = -1
var selected_stage_id = -1

func _ready():
	print("開始遊戲場景已載入")
	_load_teams()
	_load_decks()
	_load_stages()

	# 連接下拉選單的選擇信號
	team_dropdown.item_selected.connect(_on_team_selected)
	deck_dropdown.item_selected.connect(_on_deck_selected)
	stage_dropdown.item_selected.connect(_on_stage_selected)


func _load_teams():
	# TODO: 從資料庫載入隊伍列表
	team_dropdown.clear()
	team_dropdown.add_item("請選擇隊伍", -1)
	# 測試資料
	# team_dropdown.add_item("測試隊伍1", 0)


func _load_decks():
	# TODO: 從資料庫載入牌組列表
	deck_dropdown.clear()
	deck_dropdown.add_item("請選擇牌組", -1)
	# 測試資料
	# deck_dropdown.add_item("測試牌組1", 0)


func _load_stages():
	# TODO: 從資料庫載入關卡列表
	stage_dropdown.clear()
	stage_dropdown.add_item("請選擇關卡", -1)
	# 測試資料
	# stage_dropdown.add_item("測試關卡1", 0)


func _on_team_selected(index):
	selected_team_id = team_dropdown.get_item_id(index)
	print("選擇隊伍 ID: ", selected_team_id)


func _on_deck_selected(index):
	selected_deck_id = deck_dropdown.get_item_id(index)
	print("選擇牌組 ID: ", selected_deck_id)


func _on_stage_selected(index):
	selected_stage_id = stage_dropdown.get_item_id(index)
	print("選擇關卡 ID: ", selected_stage_id)


func _on_add_team_button_pressed():
	print("新增隊伍")
	# TODO: 開啟隊伍編輯器
	pass


func _on_add_deck_button_pressed():
	print("新增牌組")
	# TODO: 開啟牌組編輯器
	pass


func _on_add_stage_button_pressed():
	print("新增關卡")
	# TODO: 前往編輯關卡場景
	pass


func _on_back_button_pressed():
	print("返回主菜單")
	get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")


func _on_start_button_pressed():
	# 檢查是否都已選擇
	if selected_team_id == -1 or selected_deck_id == -1 or selected_stage_id == -1:
		message_dialog.dialog_text = "請選擇隊伍、牌組和關卡!"
		message_dialog.popup_centered()
		return

	print("開始遊戲!")
	print("隊伍 ID: ", selected_team_id)
	print("牌組 ID: ", selected_deck_id)
	print("關卡 ID: ", selected_stage_id)

	# TODO: 進入遊戲場景
	pass
