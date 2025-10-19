extends Control

# 主菜單控制腳本

func _ready():
	print("魔物娘 - 主菜單已載入")


func _on_start_button_pressed():
	print("開始遊戲")
	get_tree().change_scene_to_file("res://Scenes/GameStart/GameStart.tscn")


func _on_edit_button_pressed():
	print("編輯模式")
	get_tree().change_scene_to_file("res://Scenes/EditMode/EditMode.tscn")


func _on_generate_data_button_pressed():
	print("生成範例資料")
	get_tree().change_scene_to_file("res://Scenes/Utils/GenerateSampleData.tscn")


func _on_quit_button_pressed():
	print("離開遊戲")
	get_tree().quit()
