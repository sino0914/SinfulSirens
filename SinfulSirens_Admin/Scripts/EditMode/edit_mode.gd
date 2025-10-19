extends Control

# 編輯模式場景控制腳本

func _ready():
	print("編輯模式場景已載入")


func _on_edit_stage_button_pressed():
	print("進入編輯關卡")
	get_tree().change_scene_to_file("res://Scenes/EditStage/EditStage.tscn")


func _on_edit_trait_button_pressed():
	print("進入編輯特徵卡")
	get_tree().change_scene_to_file("res://Scenes/EditMode/EditTrait.tscn")


func _on_edit_game_button_pressed():
	print("進入編輯遊戲")
	get_tree().change_scene_to_file("res://Scenes/EditMode/EditGame.tscn")


func _on_back_button_pressed():
	print("返回主菜單")
	get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")
