extends Resource
class_name PlayerCharacter

# 我方角色資料類別
# 類似敵人，但代表玩家控制的角色

@export var id: String = ""  # 唯一識別碼
@export var name: String = ""  # 角色名稱
@export var hp: int = 100  # 生命值
@export var strength: int = 10  # 力量(攻擊力)
@export var defense: int = 5  # 防禦
@export var speed: int = 5  # 速度
@export var food_requirement: int = 0  # 食物需求
@export var image_path: String = ""  # 圖片路徑

# 可選屬性
@export var description: String = ""  # 角色描述


func _init(
	p_id: String = "",
	p_name: String = "新角色",
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


static func from_dict(data: Dictionary) -> PlayerCharacter:
	var character = PlayerCharacter.new()
	character.id = data.get("id", "")
	character.name = data.get("name", "新角色")
	character.hp = data.get("hp", 100)
	character.strength = data.get("strength", 10)
	character.defense = data.get("defense", 5)
	character.speed = data.get("speed", 5)
	character.food_requirement = data.get("food_requirement", 0)
	character.image_path = data.get("image_path", "")
	character.description = data.get("description", "")
	return character
