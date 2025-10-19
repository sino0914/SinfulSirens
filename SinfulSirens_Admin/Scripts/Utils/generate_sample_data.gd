extends Node

# 範例資料生成器
# 用於生成初始的敵人、關卡和特徵卡範例資料

func _ready():
	print("=== 開始生成範例資料 ===")
	generate_sample_enemies()
	generate_sample_stages()
	generate_sample_traits()
	print("=== 範例資料生成完成 ===")
	print("請關閉此場景，範例資料已儲存")


# 生成敵人範例資料 (20筆)
func generate_sample_enemies():
	print("\n生成敵人範例資料...")

	var sample_enemies = [
		{"name": "野豬", "hp": 120, "strength": 15, "defense": 8, "speed": 6, "description": "兇猛的野豬，具有強大的衝撞能力"},
		{"name": "森林狼", "hp": 100, "strength": 18, "defense": 5, "speed": 12, "description": "敏捷的掠食者，擅長快速攻擊"},
		{"name": "巨熊", "hp": 200, "strength": 25, "defense": 12, "speed": 4, "description": "體型龐大的熊類，力量驚人"},
		{"name": "毒蛇", "hp": 60, "strength": 10, "defense": 3, "speed": 15, "description": "劇毒的爬行動物，速度極快"},
		{"name": "山地獅", "hp": 150, "strength": 22, "defense": 10, "speed": 10, "description": "山地之王，攻守兼備"},
		{"name": "巨鷹", "hp": 90, "strength": 14, "defense": 6, "speed": 18, "description": "翱翔天際的猛禽，速度驚人"},
		{"name": "劍齒虎", "hp": 180, "strength": 28, "defense": 8, "speed": 11, "description": "史前猛獸，尖牙利齒"},
		{"name": "巨型蜘蛛", "hp": 80, "strength": 12, "defense": 7, "speed": 9, "description": "有毒的節肢動物，善於設陷"},
		{"name": "石頭巨人", "hp": 300, "strength": 30, "defense": 20, "speed": 2, "description": "行動緩慢但防禦驚人的巨人"},
		{"name": "火焰狐", "hp": 85, "strength": 16, "defense": 4, "speed": 16, "description": "能操控火焰的神秘狐狸"},
		{"name": "冰霜狼", "hp": 110, "strength": 17, "defense": 9, "speed": 13, "description": "來自極北之地的冰霜狼群"},
		{"name": "雷電鳥", "hp": 70, "strength": 20, "defense": 5, "speed": 20, "description": "掌控雷電之力的神鳥"},
		{"name": "地穴巨蟲", "hp": 160, "strength": 19, "defense": 15, "speed": 5, "description": "地底深處的巨型蠕蟲"},
		{"name": "暗影刺客", "hp": 95, "strength": 24, "defense": 6, "speed": 17, "description": "隱藏於暗處的致命殺手"},
		{"name": "荒野獵犬", "hp": 75, "strength": 13, "defense": 5, "speed": 14, "description": "成群結隊的野犬，團隊作戰"},
		{"name": "沼澤巨鱷", "hp": 220, "strength": 26, "defense": 18, "speed": 3, "description": "沼澤之主，咬合力驚人"},
		{"name": "毒霧蟾蜍", "hp": 130, "strength": 11, "defense": 14, "speed": 4, "description": "能噴射劇毒霧氣的巨蟾"},
		{"name": "迅猛龍", "hp": 105, "strength": 21, "defense": 7, "speed": 19, "description": "聰明且迅速的恐龍獵手"},
		{"name": "岩漿蠑螈", "hp": 140, "strength": 23, "defense": 11, "speed": 7, "description": "棲息於火山的熔岩生物"},
		{"name": "風暴元素", "hp": 100, "strength": 27, "defense": 8, "speed": 15, "description": "由純粹風暴能量構成的元素生物"}
	]

	for enemy_data in sample_enemies:
		var enemy = Enemy.new()
		enemy.name = enemy_data.name
		enemy.hp = enemy_data.hp
		enemy.strength = enemy_data.strength
		enemy.defense = enemy_data.defense
		enemy.speed = enemy_data.speed
		enemy.description = enemy_data.description
		enemy.food_requirement = 0

		DataManager.add_enemy(enemy)

	print("已生成 %d 個敵人" % sample_enemies.size())


# 生成關卡範例資料 (10筆)
func generate_sample_stages():
	print("\n生成關卡範例資料...")

	var all_enemies = DataManager.get_all_enemies()
	if all_enemies.is_empty():
		print("警告: 沒有敵人資料，無法生成關卡")
		return

	var stage_configs = [
		{"name": "森林入口", "desc": "踏入危險森林的第一步", "enemies": [0, 1]},
		{"name": "狼群領地", "desc": "森林狼的聚集地", "enemies": [1, 1, 4]},
		{"name": "熊窟深處", "desc": "巨熊的棲息之所", "enemies": [2, 0, 3]},
		{"name": "毒蛇巢穴", "desc": "劇毒蛇類盤踞的危險區域", "enemies": [3, 3, 3, 7]},
		{"name": "猛獸平原", "desc": "各種猛獸混戰的平原", "enemies": [4, 5, 6, 14]},
		{"name": "古代遺跡", "desc": "石頭巨人守護的神秘遺跡", "enemies": [8, 7, 12]},
		{"name": "元素之地", "desc": "元素生物聚集的魔法領域", "enemies": [9, 10, 11, 19]},
		{"name": "沼澤禁地", "desc": "危險的沼澤區域", "enemies": [15, 16, 12, 7, 3]},
		{"name": "火山口", "desc": "熔岩與火焰的世界", "enemies": [18, 9, 2, 8]},
		{"name": "終極試煉", "desc": "最強猛獸齊聚的終極挑戰", "enemies": [6, 13, 17, 19, 8, 11]}
	]

	for i in range(stage_configs.size()):
		var config = stage_configs[i]
		var stage = Stage.new()
		stage.name = config.name
		stage.description = config.desc

		# 添加敵人
		for j in range(config.enemies.size()):
			var enemy_index = config.enemies[j]
			if enemy_index < all_enemies.size():
				var x_pos = 50 + (j % 4) * 150
				var y_pos = 50 + int(j / 4) * 120
				stage.add_enemy(all_enemies[enemy_index].id, Vector2(x_pos, y_pos))

		DataManager.add_stage(stage)

	print("已生成 %d 個關卡" % stage_configs.size())


# 生成特徵卡範例資料 (40筆)
func generate_sample_traits():
	print("\n生成特徵卡範例資料...")

	var available_images = [
		"res://Assets/Ex/Card_智力.png",
		"res://Assets/Ex/Card_警報信號.png",
		"res://Assets/Ex/Card_硬殼.png",
		"res://Assets/Ex/Card_攀爬.png",
		"res://Assets/Ex/card_覓食.png",
		"res://Assets/Ex/Card_長頸.png",
		"res://Assets/Ex/Card_脂肪組織.png",
		"res://Assets/Ex/Card_食肉.png",
		"res://Assets/Ex/Card_多產.png",
		"res://Assets/Ex/Card_成群狩獵.png",
		"res://Assets/Ex/Card_伏擊.png",
		"res://Assets/Ex/Card_共生.png",
		"res://Assets/Ex/Card_群聚防禦.png"
	]

	var positions = ["頭飾", "眼睛", "首飾", "身體", "手", "腳", "尾", "背", "其他"]

	var sample_traits = []

	# 生成40張特徵卡
	for i in range(40):
		var pos_index = i % positions.size()
		var img_index = i % available_images.size()
		var food_value = (i % 4) + 1  # 1-4 循環

		var trait_data = {}
		trait_data["position"] = positions[pos_index]
		trait_data["food_amount"] = food_value
		trait_data["image_path"] = available_images[img_index]

		sample_traits.append(trait_data)

	# 準備特徵卡資料
	var trait_cards_data = []
	var next_id = 1

	for trait_data in sample_traits:
		trait_cards_data.append({
			"id": next_id,
			"position": trait_data.position,
			"food_amount": trait_data.food_amount,
			"image_path": trait_data.image_path
		})
		next_id += 1

	# 儲存特徵卡資料
	var save_path = "user://trait_cards.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"cards": trait_cards_data, "next_id": next_id}))
		file.close()
		print("已生成 %d 張特徵卡，儲存至: %s" % [sample_traits.size(), save_path])
	else:
		print("錯誤: 無法儲存特徵卡資料")
