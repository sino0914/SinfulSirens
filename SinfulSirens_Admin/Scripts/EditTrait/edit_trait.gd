extends Control

# 編輯特徵卡場景控制腳本

func _ready():
	print("編輯特徵卡場景已載入")


func _on_back_button_pressed():
	print("返回編輯模式")
	get_tree().change_scene_to_file("res://Scenes/EditMode/EditMode.tscn")
