class_name BingoGridBox extends PanelContainer


signal requesting_context_menu


@onready var item_texture_rect: TextureRect = $ItemTextureRect


var image: Image: set = set_image
var checked: bool: set = set_checked, get = get_checked

func _on_button_toggled(toggled_on: bool) -> void:
	theme_type_variation = &"BingoCheckedPanelContainer" if toggled_on else &"BingoUncheckedPanelContainer"
	$Button.theme_type_variation = &"BingoCheckedButton" if toggled_on else &""


func _gui_input(event: InputEvent) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event:
		if mouse_event.is_pressed() and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			requesting_context_menu.emit()


func set_image(img: Image) -> void:
	if img == image:
		return
	
	image = img
	item_texture_rect.texture = ImageTexture.create_from_image(img) if img else null


func set_checked(c: bool) -> void:
	$Button.button_pressed = c


func get_checked() -> bool:
	return $Button.button_pressed
