extends Panel

const BINGO_GRID_BOX_SCENE: PackedScene = preload("uid://cvk583gc6c57w")

const QualityLevel = {
	STANDARD = 64,
	HIGH = 128,
	VERY_HIGH = 256,
	ULTRA = 512,
	BEYOND_ULTRA = 1024
}

@onready var grid_aspect_container: AspectRatioContainer = %GridAspectContainer
@onready var bingo_grid: GridContainer = %BingoGrid
@onready var bingo_viewport_container: SubViewportContainer = %BingoViewportContainer
@onready var bingo_viewport: SubViewport = %BingoViewport
@onready var bingo_margin_container: MarginContainer = %BingoMarginContainer
@onready var size_label: Label = %SizeLabel

# grid size control buttons
@onready var decrease_up_button: Button = %DecreaseUpButton
@onready var increase_up_button: Button = %IncreaseUpButton
@onready var decrease_left_button: Button = %DecreaseLeftButton
@onready var increase_left_button: Button = %IncreaseLeftButton
@onready var decrease_right_button: Button = %DecreaseRightButton
@onready var increase_right_button: Button = %IncreaseRightButton
@onready var decrease_down_button: Button = %DecreaseDownButton
@onready var increase_down_button: Button = %IncreaseDownButton

@onready var popup_menu: PopupMenu = $PopupMenu
@onready var file_dialog: FileDialog = $ImageFileDialog
@onready var tooltip_dialog: ConfirmationDialog = $TooltipDialog
@onready var tooltip_text_exit: TextEdit = %TooltipTextExit
@onready var create_image_dialog: ConfirmationDialog = $CreateImageDialog
@onready var create_image_option: OptionButton = $CreateImageDialog/OptionButton
@onready var save_image_dialog: FileDialog = $SaveImageDialog


var grid_size: Vector2i
var grid_items: Array[BingoGridBox]

var _selected_box: BingoGridBox

func _ready() -> void:
	grid_size = Vector2i(5,5)
	
	_create_grid()
	
	popup_menu.id_pressed.connect(_on_popup_item_selected)
	file_dialog.file_selected.connect(_on_image_file_selected)
	tooltip_dialog.confirmed.connect(_on_tooltip_confirmed)
	create_image_dialog.confirmed.connect(_on_quality_selected)
	save_image_dialog.file_selected.connect(_on_image_path_selected)


func update_aspect_ratio() -> void:
	bingo_grid.columns = grid_size.x
	
	decrease_left_button.disabled = grid_size.x == 1
	decrease_right_button.disabled = grid_size.x == 1
	decrease_up_button.disabled = grid_size.y == 1
	decrease_down_button.disabled = grid_size.y == 1
	
	grid_aspect_container.ratio = grid_size.aspect()
	
	size_label.text = "%d x %d" % [grid_size.x, grid_size.y]


func _create_grid() -> void:
	for item in bingo_grid.get_children():
		item.queue_free()
	grid_items.clear()
	
	for i in grid_size.x * grid_size.y:
		_add_box(i)
	
	update_aspect_ratio()


#region Grid Size Control
func _on_decrease_up_button_pressed() -> void:
	for i in range(grid_size.x -1, -1, -1):
		_remove_box(i)
	
	grid_size.y -= 1
	update_aspect_ratio()


func _on_increase_up_button_pressed() -> void:
	for i in range(0, grid_size.x, 1):
		_add_box(i)
	
	grid_size.y += 1
	update_aspect_ratio()


func _on_decrease_left_button_pressed() -> void:
	for i in range(grid_size.x * grid_size.y - grid_size.x, -1, -grid_size.x):
		_remove_box(i)
	
	grid_size.x -= 1
	update_aspect_ratio()


func _on_increase_left_button_pressed() -> void:
	var offset: int = 0
	
	grid_size.x += 1
	for i in range(offset, grid_size.x * grid_size.y, grid_size.x):
		_add_box(i)
	
	update_aspect_ratio()


func _on_decrease_right_button_pressed() -> void:
	for i in range(grid_size.x * grid_size.y - 1, -1, -grid_size.x):
		_remove_box(i)
	
	grid_size.x -= 1
	update_aspect_ratio()


func _on_increase_right_button_pressed() -> void:
	var offset: int = grid_size.x
	
	grid_size.x += 1
	for i in range(offset, grid_size.x * grid_size.y, grid_size.x):
		_add_box(i)
	
	update_aspect_ratio()


func _on_decrease_down_button_pressed() -> void:
	grid_size.y -= 1
	var offset: int = grid_size.x * grid_size.y - 1
	for i in range(grid_size.x - 1, -1, -1):
		_remove_box(offset + i)
	
	update_aspect_ratio()


func _on_increase_down_button_pressed() -> void:
	var offset: int = grid_size.x * grid_size.y
	
	grid_size.y += 1
	for i in grid_size.x:
		_add_box(offset + i)
	
	update_aspect_ratio()
#endregion


func _add_box(index: int) -> void:
	var box := BINGO_GRID_BOX_SCENE.instantiate() as BingoGridBox
	var aspect_container := AspectRatioContainer.new()
	aspect_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspect_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	box.requesting_context_menu.connect(func ():
		popup_menu.position = get_global_mouse_position()
		popup_menu.show()
		_selected_box = box
	)
	
	grid_items.insert(index, box)
	aspect_container.add_child(box)
	bingo_grid.add_child(aspect_container)
	bingo_grid.move_child(aspect_container, index)


func _on_popup_item_selected(id: int) -> void:
	const EDIT_IMAGE: int = 0
	const EDIT_TOOLTIP: int = 1
	const RESET: int = 2
	
	if id == EDIT_IMAGE:
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.use_native_dialog = true
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.filters = ["*.png,*.jpg,*.jpeg;Image Files"]
		file_dialog.show()
	elif id == EDIT_TOOLTIP:
		tooltip_text_exit.text = _selected_box.tooltip_text
		tooltip_dialog.popup_centered()
	elif id == RESET:
		_selected_box.image = null


func _on_image_file_selected(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Invalid path: ", path)
	
	_selected_box.image = Image.load_from_file(path)


func _on_tooltip_confirmed() -> void:
	_selected_box.tooltip_text = tooltip_text_exit.text


func _remove_box(index: int) -> void:
	var box := grid_items.pop_at(index) as BingoGridBox
	box.get_parent().queue_free()


func _on_create_picture_button_pressed() -> void:
	create_image_dialog.popup_centered()


func _on_quality_selected() -> void:
	save_image_dialog.popup_centered()


func _on_image_path_selected(path: String) -> void:
	bingo_viewport_container.stretch = false
	
	var original_margin: int = bingo_margin_container.get(&"theme_override_constants/margin_left")
	var original_separator_size: int = bingo_grid.get(&"theme_override_constants/h_separation")
	
	var box_size: int = QualityLevel.values()[create_image_option.get_selected_id()]
	var margin_size: int = original_margin * (box_size >> 6)
	var separator_size: int = 2 * (box_size >> 6)
	
	bingo_margin_container.set(&"theme_override_constants/margin_left", margin_size)
	bingo_margin_container.set(&"theme_override_constants/margin_top", margin_size)
	bingo_margin_container.set(&"theme_override_constants/margin_right", margin_size)
	bingo_margin_container.set(&"theme_override_constants/margin_bottom", margin_size)
	
	bingo_grid.set(&"theme_override_constants/h_separation", separator_size)
	bingo_grid.set(&"theme_override_constants/v_separation", separator_size)
	
	bingo_viewport.size = grid_size * box_size + Vector2i(margin_size * 2, margin_size * 2) + Vector2i(separator_size * (grid_size.x - 1), separator_size * (grid_size.y - 1))
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	
	var error: int = bingo_viewport.get_texture().get_image().save_png(path)
	if error:
		print("Error ", error,":	",error_string(error))
	print("saved to: ", path)
	
	bingo_margin_container.set(&"theme_override_constants/margin_left", original_margin)
	bingo_margin_container.set(&"theme_override_constants/margin_top", original_margin)
	bingo_margin_container.set(&"theme_override_constants/margin_right", original_margin)
	bingo_margin_container.set(&"theme_override_constants/margin_bottom", original_margin)
	
	bingo_grid.set(&"theme_override_constants/h_separation", original_separator_size)
	bingo_grid.set(&"theme_override_constants/v_separation", original_separator_size)
	
	bingo_viewport_container.stretch = true


func _on_import_grid_button_pressed() -> void:
	$ImportDialog.popup_centered()


func _on_export_grid_button_pressed() -> void:
	$ExportDialog.popup_centered()


func _on_import_dialog_file_selected(path: String) -> void:
	var reader := ZIPReader.new()
	reader.open(path)
	var data = JSON.parse_string(reader.read_file("data.json").get_string_from_utf8())
	
	grid_size = Vector2i(data[&"size_x"], data[&"size_y"])
	_create_grid()
	
	var items: Array = data[&"items"]
	for i in items.size():
		var item: Dictionary = items[i]
		var box: BingoGridBox = grid_items[i]
		
		if not box.is_node_ready():
			await box.ready
		
		box.checked = item[&"checked"]
		box.tooltip_text = item[&"tooltip"]
		
		var image_path = item[&"image_path"] as String
		if not image_path.is_empty():
			var image = Image.new()
			image.load_png_from_buffer(reader.read_file(image_path))
			box.image = image


func _on_export_dialog_file_selected(path: String) -> void:
	var writer := ZIPPacker.new()
	writer.open(path)
	
	var data: Dictionary = {
		size_x=grid_size.x,
		size_y=grid_size.y,
		items=[],
	}
	
	for i in grid_items.size():
		var item: BingoGridBox = grid_items[i]
		data[&"items"].append({
			image_path="" if item.image == null else "%d.png" % i,
			tooltip=item.tooltip_text,
			checked=item.checked,
		})
		
		if item.image:
			writer.start_file("%d.png" % i)
			writer.write_file(item.image.save_png_to_buffer())
			writer.close_file()
	
	writer.start_file("data.json")
	writer.write_file(JSON.stringify(data).to_utf8_buffer())
	writer.close_file()
