extends Node

# 角色基本屬性
var character_name: String = ""
var max_hp: int = 100
var current_hp: int = 100
var base_attack: int = 10
var base_defense: int = 5
var base_speed: int = 10
var base_food_requirement: int = 3

# 角色狀態
var is_alive: bool = true
var is_stunned: bool = false
var shield_points: int = 0

# 特徵卡掛載（簡化版）
var equipped_traits: Dictionary = {}
var misc_traits: Array = []

# 信號
signal hp_changed(old_hp: int, new_hp: int)
signal died()
signal revived()

func initialize(name: String, hp: int = 100, attack: int = 10, defense: int = 5, speed: int = 10, food_req: int = 3):
	character_name = name
	max_hp = hp
	current_hp = hp
	base_attack = attack
	base_defense = defense
	base_speed = speed
	base_food_requirement = food_req
	self.name = name

# 簡化的屬性計算
func get_total_attack() -> int:
	return base_attack

func get_total_defense() -> int:
	return base_defense

func get_total_speed() -> int:
	return base_speed

func get_total_food_requirement() -> int:
	return base_food_requirement

# HP 管理
func take_damage(amount: int):
	if not is_alive:
		return

	var old_hp = current_hp
	if shield_points > 0:
		var shield_absorbed = min(shield_points, amount)
		shield_points -= shield_absorbed
		amount -= shield_absorbed

	current_hp = max(0, current_hp - amount)
	hp_changed.emit(old_hp, current_hp)

	if current_hp <= 0 and is_alive:
		die()

func heal(amount: int):
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(old_hp, current_hp)

func gain_shield(amount: int):
	shield_points += amount

func die():
	is_alive = false
	died.emit()
	print(character_name, " 倒下了")

func revive(hp_amount: int = 0):
	if hp_amount <= 0:
		hp_amount = max_hp / 4

	is_alive = true
	current_hp = min(max_hp, hp_amount)
	shield_points = 0
	revived.emit()
	print(character_name, " 復活了")

# 簡化的特徵管理
func equip_trait(slot: String, trait_data: Dictionary) -> bool:
	equipped_traits[slot] = trait_data
	print("裝備特徵: ", trait_data.get("name", "未知特徵"))
	return true

func remove_trait(slot: String) -> Dictionary:
	if slot in equipped_traits:
		var removed_trait = equipped_traits[slot]
		equipped_traits.erase(slot)
		return removed_trait
	return {}

func add_misc_trait(trait_data: Dictionary):
	misc_traits.append(trait_data)

# 簡化的特徵退化
func degrade_random_trait():
	print(character_name, " 的特徵退化了")

func restore_all_traits():
	print(character_name, " 的特徵恢復了")