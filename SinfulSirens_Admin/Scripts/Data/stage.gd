extends Resource
class_name Stage

# 關卡資料類別

@export var id: String = ""  # 唯一識別碼
@export var name: String = ""  # 關卡名稱
@export var description: String = ""  # 關卡描述
@export var enemy_ids: Array[String] = []  # 敵人ID列表(最多8隻)
@export var enemy_positions: Dictionary = {}  # 敵人位置 {enemy_id: Vector2}


func _init(
	p_id: String = "",
	p_name: String = "新關卡",
	p_description: String = "",
	p_enemy_ids: Array[String] = []
):
	id = p_id
	name = p_name
	description = p_description
	enemy_ids = p_enemy_ids.duplicate()


func add_enemy(enemy_id: String, position: Vector2 = Vector2.ZERO) -> bool:
	# 檢查是否已達上限(最多8隻)
	if enemy_ids.size() >= 8:
		return false

	# 添加敵人ID
	if not enemy_ids.has(enemy_id):
		enemy_ids.append(enemy_id)
		# 設置預設位置
		if position == Vector2.ZERO:
			# 自動計算預設位置（水平排列）
			var index = enemy_ids.size() - 1
			position = Vector2(10 + index * 110, 10)
		enemy_positions[enemy_id] = position
		return true
	return false


func remove_enemy(enemy_id: String) -> bool:
	var index = enemy_ids.find(enemy_id)
	if index >= 0:
		enemy_ids.remove_at(index)
		# 同時移除位置資訊
		enemy_positions.erase(enemy_id)
		return true
	return false


func update_enemy_position(enemy_id: String, position: Vector2):
	# 更新敵人位置
	if has_enemy(enemy_id):
		enemy_positions[enemy_id] = position


func get_enemy_position(enemy_id: String) -> Vector2:
	# 取得敵人位置，如果沒有則返回預設位置
	return enemy_positions.get(enemy_id, Vector2(10, 10))


func has_enemy(enemy_id: String) -> bool:
	return enemy_ids.has(enemy_id)


func to_dict() -> Dictionary:
	# 轉換 enemy_positions 為可序列化格式
	var positions_dict = {}
	for enemy_id in enemy_positions:
		var pos = enemy_positions[enemy_id]
		positions_dict[enemy_id] = {"x": pos.x, "y": pos.y}

	return {
		"id": id,
		"name": name,
		"description": description,
		"enemy_ids": enemy_ids.duplicate(),
		"enemy_positions": positions_dict
	}


static func from_dict(data: Dictionary) -> Stage:
	var stage = Stage.new()
	stage.id = data.get("id", "")
	stage.name = data.get("name", "新關卡")
	stage.description = data.get("description", "")

	# 轉換 enemy_ids 為 Array[String]
	var raw_ids = data.get("enemy_ids", [])
	stage.enemy_ids.clear()
	for enemy_id in raw_ids:
		stage.enemy_ids.append(str(enemy_id))

	# 轉換 enemy_positions 從字典格式恢復為 Vector2
	var positions_data = data.get("enemy_positions", {})
	stage.enemy_positions.clear()
	for enemy_id in positions_data:
		var pos_dict = positions_data[enemy_id]
		if pos_dict is Dictionary:
			stage.enemy_positions[enemy_id] = Vector2(pos_dict.get("x", 0), pos_dict.get("y", 0))

	return stage
