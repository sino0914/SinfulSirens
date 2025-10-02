extends Control

# 可拖曳角色卡片

var dragging = false
var drag_offset = Vector2.ZERO
var enemy_id: String = ""


func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_enemy_id(id: String):
	enemy_id = id


func _is_drag_enabled() -> bool:
	# 檢查預覽面板是否啟用拖曳模式
	if has_meta("preview_panel"):
		var preview_panel = get_meta("preview_panel")
		if preview_panel and preview_panel.has_method("is_drag_mode_enabled"):
			return preview_panel.is_drag_mode_enabled()
	return false


func _gui_input(event):
	# 檢查是否啟用拖曳模式
	if not _is_drag_enabled():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 開始拖曳
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
				# 提升到最上層
				var parent = get_parent()
				if parent:
					parent.move_child(self, parent.get_child_count() - 1)
			else:
				# 結束拖曳
				dragging = false
				# 保存位置
				_save_position()

	elif event is InputEventMouseMotion:
		if dragging:
			# 取得父容器（拖曳區域）
			var parent = get_parent()
			if parent:
				# 計算新位置（相對於父容器的本地座標）
				var new_local_pos = get_global_mouse_position() - drag_offset - parent.global_position

				# 限制在父容器範圍內
				new_local_pos.x = clamp(new_local_pos.x, 0, parent.size.x - size.x)
				new_local_pos.y = clamp(new_local_pos.y, 0, parent.size.y - size.y)

				# 設置限制後的位置
				position = new_local_pos


func _process(_delta):
	if dragging:
		queue_redraw()


func _save_position():
	# 拖曳結束時保存位置到 Stage
	if enemy_id.is_empty():
		return

	if has_meta("preview_panel"):
		var preview_panel = get_meta("preview_panel")
		if preview_panel and preview_panel.has_method("update_enemy_position"):
			preview_panel.update_enemy_position(enemy_id, position)
