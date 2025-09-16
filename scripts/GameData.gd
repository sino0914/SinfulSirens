extends Node

# 當前戰鬥關卡資料
var current_battle_level: Dictionary = {}

# 玩家資料
var player_data: Dictionary = {
	"name": "玩家",
	"level": 1,
	"experience": 0,
	"deck": []
}

# 重置戰鬥資料
func reset_battle_data():
	current_battle_level.clear()

# 載入玩家資料
func load_player_data():
	var file = FileAccess.open("user://player_data.save", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			player_data = json.data

# 儲存玩家資料
func save_player_data():
	var file = FileAccess.open("user://player_data.save", FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(player_data)
		file.store_string(json_string)
		file.close()