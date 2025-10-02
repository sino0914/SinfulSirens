extends Resource
class_name Enemy

# 敵人資料類別
# 根據遊戲規則書，敵人擁有基本屬性

@export var id: String = ""  # 唯一識別碼
@export var name: String = ""  # 敵人名稱
@export var hp: int = 100  # 生命值
@export var strength: int = 10  # 力量(攻擊力)
@export var defense: int = 5  # 防禦
@export var speed: int = 5  # 速度
@export var food_requirement: int = 0  # 食物需求(敵人通常為0)
@export var image_path: String = ""  # 圖片路徑

# 可選屬性
@export var description: String = ""  # 敵人描述


func _init(
	p_id: String = "",
	p_name: String = "新敵人",
	p_hp: int = 100,
	p_strength: int = 10,
	p_defense: int = 5,
	p_speed: int = 5,
	p_food_requirement: int = 0,
	p_image_path: String = "",
	p_description: String = ""
):
	id = p_id
	name = p_name
	hp = p_hp
	strength = p_strength
	defense = p_defense
	speed = p_speed
	food_requirement = p_food_requirement
	image_path = p_image_path
	description = p_description


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"hp": hp,
		"strength": strength,
		"defense": defense,
		"speed": speed,
		"food_requirement": food_requirement,
		"image_path": image_path,
		"description": description
	}


static func from_dict(data: Dictionary) -> Enemy:
	var enemy = Enemy.new()
	enemy.id = data.get("id", "")
	enemy.name = data.get("name", "新敵人")
	enemy.hp = data.get("hp", 100)
	enemy.strength = data.get("strength", 10)
	enemy.defense = data.get("defense", 5)
	enemy.speed = data.get("speed", 5)
	enemy.food_requirement = data.get("food_requirement", 0)
	enemy.image_path = data.get("image_path", "")
	enemy.description = data.get("description", "")
	return enemy
