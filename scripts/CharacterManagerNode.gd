extends Node

# 最大角色數量
const MAX_CHARACTERS = 4

# 信號
signal character_died(character)
signal character_revived(character)
signal party_wiped_out()
signal all_enemies_defeated()

func _ready():
	print("CharacterManagerNode 初始化完成")
	# 延遲創建角色，避免初始化順序問題
	call_deferred("_create_test_characters")

# 獲取隊伍角色
func get_party_characters() -> Array:
	var characters = []
	for child in get_children():
		if child.has_method("get_total_attack") and child.character_name != "":
			if not child.character_name.begins_with("敵人"):
				characters.append(child)
	return characters

func get_living_party_characters() -> Array:
	var living = []
	for character in get_party_characters():
		if character.is_alive:
			living.append(character)
	return living

# 獲取敵人
func get_enemy_characters() -> Array:
	var enemies = []
	for child in get_children():
		if child.has_method("get_total_attack") and child.character_name.begins_with("敵人"):
			enemies.append(child)
	return enemies

func get_living_enemies() -> Array:
	var living = []
	for enemy in get_enemy_characters():
		if enemy.is_alive:
			living.append(enemy)
	return living

# 創建角色
func create_character(name: String, hp: int = 100, attack: int = 10, defense: int = 5, speed: int = 10, food_req: int = 3):
	var character_script = load("res://scripts/CharacterNodeSimple.gd")
	var character = Node.new()
	character.set_script(character_script)
	add_child(character)
	character.initialize(name, hp, attack, defense, speed, food_req)

	# 連接信號
	character.died.connect(_on_character_died.bind(character))
	character.revived.connect(_on_character_revived.bind(character))

	return character

# 信號處理
func _on_character_died(character):
	character_died.emit(character)
	print(character.character_name, " 死亡")

	# 檢查隊伍是否全滅
	if not character.character_name.begins_with("敵人"):
		if get_living_party_characters().size() == 0:
			party_wiped_out.emit()

func _on_character_revived(character):
	character_revived.emit(character)
	print(character.character_name, " 復活")

# 戰鬥相關
func get_turn_order() -> Array:
	var all_characters = []
	all_characters.append_array(get_living_party_characters())
	all_characters.append_array(get_living_enemies())

	# 按速度排序
	all_characters.sort_custom(_compare_speed)
	return all_characters

func _compare_speed(a, b) -> bool:
	return a.get_total_speed() > b.get_total_speed()

# 餵食相關
func feed_characters(available_food: int) -> int:
	var remaining_food = available_food

	for character in get_party_characters():
		if not character.is_alive:
			continue

		var requirement = character.get_total_food_requirement()
		if remaining_food >= requirement:
			remaining_food -= requirement
			print(character.character_name, " 獲得充足食物")
		else:
			var shortage = requirement - remaining_food
			remaining_food = 0

			if shortage >= requirement / 2:
				character.take_damage(shortage)
				character.degrade_random_trait()
				print(character.character_name, " 食物嚴重不足！")
			else:
				character.degrade_random_trait()
				print(character.character_name, " 食物輕微不足")

	return remaining_food

# 恢復所有角色特徵
func restore_all_character_traits():
	for character in get_party_characters():
		character.restore_all_traits()

# 測試數據創建
func _create_test_characters():
	# 創建測試角色
	create_character("莉莉絲", 80, 12, 8, 15, 2)
	create_character("艾米莉", 100, 10, 10, 12, 3)

	# 創建測試敵人
	create_character("敵人哥布林", 50, 8, 3, 10, 1)
	create_character("敵人獸人", 80, 15, 5, 8, 1)

	print("測試角色創建完成")