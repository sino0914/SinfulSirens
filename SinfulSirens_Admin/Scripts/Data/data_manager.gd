extends Node

# 資料管理單例 - 負責管理所有遊戲資料的載入、儲存和存取

const DATA_DIR = "user://Data/"
const ENEMIES_FILE = "enemies.json"
const STAGES_FILE = "stages.json"

var enemies: Dictionary = {}  # key: enemy_id, value: Enemy
var stages: Dictionary = {}  # key: stage_id, value: Stage

var _next_enemy_id: int = 1
var _next_stage_id: int = 1


func _ready():
	print("DataManager 初始化")
	_ensure_data_directory()
	load_all_data()


func _ensure_data_directory():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("Data"):
		dir.make_dir("Data")


# ==================== 敵人管理 ====================

func add_enemy(enemy: Enemy) -> bool:
	if enemy.id.is_empty():
		enemy.id = _generate_enemy_id()

	if enemies.has(enemy.id):
		push_error("敵人 ID 已存在: " + enemy.id)
		return false

	enemies[enemy.id] = enemy
	save_enemies()
	print("新增敵人: ", enemy.name, " (ID: ", enemy.id, ")")
	return true


func update_enemy(enemy: Enemy) -> bool:
	if not enemies.has(enemy.id):
		push_error("敵人不存在: " + enemy.id)
		return false

	enemies[enemy.id] = enemy
	save_enemies()
	print("更新敵人: ", enemy.name, " (ID: ", enemy.id, ")")
	return true


func delete_enemy(enemy_id: String) -> bool:
	if not enemies.has(enemy_id):
		push_error("敵人不存在: " + enemy_id)
		return false

	# 檢查是否有關卡使用此敵人
	var using_stages = get_stages_using_enemy(enemy_id)
	if using_stages.size() > 0:
		var stage_names = []
		for stage in using_stages:
			stage_names.append(stage.name)
		push_warning("敵人正被以下關卡使用: " + ", ".join(stage_names))
		return false

	enemies.erase(enemy_id)
	save_enemies()
	print("刪除敵人: ", enemy_id)
	return true


func get_enemy(enemy_id: String) -> Enemy:
	return enemies.get(enemy_id, null)


func get_all_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy in enemies.values():
		result.append(enemy)
	return result


func get_stages_using_enemy(enemy_id: String) -> Array[Stage]:
	var result: Array[Stage] = []
	for stage in stages.values():
		if stage.has_enemy(enemy_id):
			result.append(stage)
	return result


func _generate_enemy_id() -> String:
	while enemies.has("enemy_" + str(_next_enemy_id)):
		_next_enemy_id += 1
	var id = "enemy_" + str(_next_enemy_id)
	_next_enemy_id += 1
	return id


# ==================== 關卡管理 ====================

func add_stage(stage: Stage) -> bool:
	if stage.id.is_empty():
		stage.id = _generate_stage_id()

	if stages.has(stage.id):
		push_error("關卡 ID 已存在: " + stage.id)
		return false

	stages[stage.id] = stage
	save_stages()
	print("新增關卡: ", stage.name, " (ID: ", stage.id, ")")
	return true


func update_stage(stage: Stage) -> bool:
	if not stages.has(stage.id):
		push_error("關卡不存在: " + stage.id)
		return false

	stages[stage.id] = stage
	save_stages()
	print("更新關卡: ", stage.name, " (ID: ", stage.id, ")")
	return true


func delete_stage(stage_id: String) -> bool:
	if not stages.has(stage_id):
		push_error("關卡不存在: " + stage_id)
		return false

	stages.erase(stage_id)
	save_stages()
	print("刪除關卡: ", stage_id)
	return true


func get_stage(stage_id: String) -> Stage:
	return stages.get(stage_id, null)


func get_all_stages() -> Array[Stage]:
	var result: Array[Stage] = []
	for stage in stages.values():
		result.append(stage)
	return result


func _generate_stage_id() -> String:
	while stages.has("stage_" + str(_next_stage_id)):
		_next_stage_id += 1
	var id = "stage_" + str(_next_stage_id)
	_next_stage_id += 1
	return id


# ==================== 資料儲存/載入 ====================

func save_enemies():
	var data = []
	for enemy in enemies.values():
		data.append(enemy.to_dict())

	var file = FileAccess.open(DATA_DIR + ENEMIES_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("敵人資料已儲存")
	else:
		push_error("無法儲存敵人資料")


func load_enemies():
	var file_path = DATA_DIR + ENEMIES_FILE
	if not FileAccess.file_exists(file_path):
		print("敵人資料檔不存在,使用空資料")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			if data is Array:
				enemies.clear()
				for enemy_data in data:
					var enemy = Enemy.from_dict(enemy_data)
					enemies[enemy.id] = enemy

					# 更新 ID 計數器
					if enemy.id.begins_with("enemy_"):
						var id_num = enemy.id.substr(6).to_int()
						if id_num >= _next_enemy_id:
							_next_enemy_id = id_num + 1

				print("載入 ", enemies.size(), " 個敵人")
		else:
			push_error("解析敵人資料失敗: " + json.get_error_message())
	else:
		push_error("無法開啟敵人資料檔")


func save_stages():
	var data = []
	for stage in stages.values():
		data.append(stage.to_dict())

	var file = FileAccess.open(DATA_DIR + STAGES_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("關卡資料已儲存")
	else:
		push_error("無法儲存關卡資料")


func load_stages():
	var file_path = DATA_DIR + STAGES_FILE
	if not FileAccess.file_exists(file_path):
		print("關卡資料檔不存在,使用空資料")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			if data is Array:
				stages.clear()
				for stage_data in data:
					var stage = Stage.from_dict(stage_data)
					stages[stage.id] = stage

					# 更新 ID 計數器
					if stage.id.begins_with("stage_"):
						var id_num = stage.id.substr(6).to_int()
						if id_num >= _next_stage_id:
							_next_stage_id = id_num + 1

				print("載入 ", stages.size(), " 個關卡")
		else:
			push_error("解析關卡資料失敗: " + json.get_error_message())
	else:
		push_error("無法開啟關卡資料檔")


func load_all_data():
	load_enemies()
	load_stages()


func save_all_data():
	save_enemies()
	save_stages()
