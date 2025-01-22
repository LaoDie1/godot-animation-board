#============================================================
#    Export Panel
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-24 11:31:26
# - version: 4.2.1
#============================================================
## 导出文件面板
class_name ExportPanel
extends Control


# 关闭信号
signal close_requested()


enum ExportType {
	CURRENT_IMAGE,
	SINGLE_IMAGE,
	SPRITE_FRAMES,
	SPRITE_SHEET,
}


@onready var export_file_dialog: FileDialog = %ExportFileDialog
@onready var type_option_button: OptionButton = %TypeOptionButton
@onready var export_setting_tab_container: TabContainer = %ExportSettingTabContainer
@onready var export_file_path_line_edit: LineEdit = %ExportFilePathLineEdit
@onready var current_frame_texture_rect: TextureRect = %CurrentFrameTextureRect


#============================================================
#  内置
#============================================================
func _ready() -> void:
	for key:String in ExportType.keys():
		type_option_button.add_item(key.capitalize())
	type_option_button.selected = 0
	export_setting_tab_container.current_tab = ExportType.SPRITE_FRAMES



#============================================================
#  自定义
#============================================================
func get_texture(frame_id) -> ImageTexture:
	var new_image = Image.new()
	for layer_id in ProjectData.get_layer_ids():
		var texture = ProjectData.get_image_texture(layer_id, frame_id)
		var image = texture.get_image()
		new_image.blend_rect(image, Rect2i(Vector2i(),image.get_size()), Vector2i())
	return ImageTexture.create_from_image(new_image)


## 弹出窗口时更新
func update_content():
	_on_type_option_button_item_selected( type_option_button.selected )



#============================================================
#  连接信号
#============================================================
func _on_close_button_pressed() -> void:
	close_requested.emit()


func _on_type_option_button_item_selected(index: int) -> void:
	export_setting_tab_container.current_tab = index
	match index:
		ExportType.CURRENT_IMAGE:
			if ProjectData.get_frame_count() == 0:
				return
			var image = ProjectData.get_current_frame_image()
			var texture = ImageTexture.create_from_image(image)
			current_frame_texture_rect.texture = texture
		
		ExportType.SPRITE_FRAMES:
			pass
		
		ExportType.SINGLE_IMAGE:
			pass
			
		ExportType.SPRITE_SHEET:
			pass
		

func _on_export_pressed() -> void:
	match type_option_button.selected:
		ExportType.CURRENT_IMAGE:
			var file_path = export_file_path_line_edit.text
			var image = ProjectData.get_current_frame_image()
			var err = image.save_png(file_path)
			if err == OK:
				print("保存完成")
			else:
				push_error( "保存时出现错误：", error_string(err) )
				return
		
		ExportType.SPRITE_FRAMES:
			pass
			
		ExportType.SINGLE_IMAGE:
			pass
			
		ExportType.SPRITE_SHEET:
			pass
		
	close_requested.emit()


func _on_export_file_dialog_file_selected(path: String) -> void:
	export_file_path_line_edit.text = path
