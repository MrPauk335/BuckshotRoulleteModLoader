extends CanvasLayer
class_name MP_ModMenu

var panel_main: Panel
var panel_sidebar: VBoxContainer
var panel_content: Control
var btn_toggle: Button
var is_open: bool = false
var game_state: MP_GameStateManager
var intermed: Node

var current_category: String = ""

func _init(p_game_state: MP_GameStateManager):
	game_state = p_game_state
	layer = 100

func _ready():
	var access = GlobalVariables.active_match_customization_dictionary.get("mod_menu_access", 0)
	if access == 0:
		queue_free()
		return
	if access == 1 and GlobalSteam.STEAM_ID != GlobalSteam.HOST_ID:
		queue_free()
		return

	intermed = get_node("/root/mp_main/standalone managers/interactions/interaction intermediary")


	btn_toggle = Button.new()
	btn_toggle.text = "[MOD MENU]"
	btn_toggle.position = Vector2(10, 10)
	btn_toggle.size = Vector2(100, 30)
	btn_toggle.pressed.connect(_on_toggle_pressed)
	add_child(btn_toggle)


	panel_main = Panel.new()
	panel_main.position = Vector2(10, 50)
	panel_main.size = Vector2(600, 450)
	panel_main.visible = false
	add_child(panel_main)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_main.add_child(hbox)


	panel_sidebar = VBoxContainer.new()
	panel_sidebar.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(panel_sidebar)


	panel_content = Control.new()
	panel_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(panel_content)

	_create_sidebar_button("God Mode", "god_mode")
	_create_sidebar_button("Revive Self", "revive")
	_create_sidebar_button("Spawn Shotgun", "shotgun")
	_create_sidebar_button("Give Item", "items")
	_create_sidebar_button("Bullet List", "bullets")
	_create_sidebar_button("Replace Bullets", "replace_bullets")

func _create_sidebar_button(text_str: String, category: String):
	var b = Button.new()
	b.text = text_str
	b.custom_minimum_size = Vector2(0, 40)
	b.pressed.connect( func(): _on_category_selected(category))
	panel_sidebar.add_child(b)

func _on_category_selected(category: String):
	current_category = category

	for child in panel_content.get_children():
		child.queue_free()

	match category:
		"god_mode":
			_on_god_mode()
		"revive":
			_on_revive_self()
		"shotgun":
			_on_spawn_shotgun()
		"items":
			_show_item_list()
		"bullets":
			_show_bullet_list()
		"replace_bullets":
			_show_replace_bullets()

func _input(event):
	if event.is_action_pressed("ui_menu") or (event is InputEventKey and event.keycode == KEY_F1 and event.pressed):
		_on_toggle_pressed()

func _on_toggle_pressed():
	is_open = !is_open
	panel_main.visible = is_open



func _show_item_list():
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_content.add_child(scroll)

	var grid = VBoxContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	var items = {
		1: "Hand Saw", 
		2: "Magnifying Glass", 
		3: "Jammer", 
		4: "Cigarettes", 
		5: "Beer", 
		6: "Burner Phone", 
		8: "Adrenaline", 
		9: "Inverter", 
		10: "Remote"
	}

	for id in items:
		var b = Button.new()
		b.text = "Give " + items[id]
		b.pressed.connect( func(): _on_give_item(id))
		grid.add_child(b)

func _show_bullet_list():
	var label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_content.add_child(label)

	var sequence = game_state.MAIN_active_sequence_dict.get("sequence_in_shotgun", [])
	var live_count = sequence.count("live")
	var blank_count = sequence.count("blank")

	var text = "Total Shells: " + str(sequence.size()) + "\n"
	text += "Live: " + str(live_count) + " | Blank: " + str(blank_count) + "\n\n"
	text += "Sequence (Next is Top):\n"

	for i in range(sequence.size()):
		var prefix = "   "
		if i == 0:
			prefix = "> "
		text += prefix + str(i + 1) + ": " + sequence[i].to_upper() + "\n"

	label.text = text

func _show_replace_bullets():
	var sequence = game_state.MAIN_active_sequence_dict.get("sequence_in_shotgun", [])
	if sequence.size() == 0:
		var label = Label.new()
		label.text = "Shotgun is empty."
		panel_content.add_child(label)
		return

	var grid = VBoxContainer.new()
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_content.add_child(grid)

	var label = Label.new()
	label.text = "Click to toggle current shell type:"
	grid.add_child(label)

	var current = sequence[0]
	var b = Button.new()
	b.text = "Current: " + current.to_upper()
	b.pressed.connect( func():
		_on_invert_shell()
		_on_category_selected("replace_bullets")
	)
	grid.add_child(b)



func _on_god_mode():
	for prop in game_state.instance_handler.instance_property_array:
		if prop.user_id == GlobalSteam.STEAM_ID:
			prop.health_current = 999
			if prop.health_counter:
				prop.health_counter.UpdateDisplay()
			print("MOD MENU: God Mode activated for self")

func _on_revive_self():
	for prop in game_state.instance_handler.instance_property_array:
		if prop.user_id == GlobalSteam.STEAM_ID:
			if prop.health_current <= 0:
				prop.health_current = 2
				if prop.health_counter:
					prop.health_counter.UpdateDisplay()
				print("MOD MENU: Revived self")

func _on_spawn_shotgun():
	for prop in game_state.instance_handler.instance_property_array:
		if prop.user_id == GlobalSteam.STEAM_ID:
			game_state.MAIN_active_current_turn_socket = prop.socket_number
			prop.has_turn = true
			print("MOD MENU: Hijacked shotgun turn")

func _on_give_item(item_id: int):
	for prop in game_state.instance_handler.instance_property_array:
		if prop.user_id == GlobalSteam.STEAM_ID:
			var free_slot = -1
			for i in range(8):
				if prop.user_inventory[i] == {}:
					free_slot = i
					break
			if free_slot != -1:
				var packet_grab = {
					"packet category": "MP_UserInstanceProperties", 
					"packet alias": "grab item", 
					"sent_from": "host", 
					"packet_id": 18, 
					"socket_number": prop.socket_number, 
					"item_id": item_id, 
				}
				game_state.packets.send_p2p_packet(0, packet_grab)
				game_state.packets.PipeData(packet_grab)

				await get_tree().create_timer(1.2, false).timeout

				var packet_place = {
					"packet category": "MP_UserInstanceProperties", 
					"packet alias": "place item", 
					"sent_from": "host", 
					"packet_id": 20, 
					"socket_number": prop.socket_number, 
					"local_grid_index": free_slot, 
					"is_last_item": false, 
					"sockets_ending_item_grabbing": [], 
				}
				game_state.packets.send_p2p_packet(0, packet_place)
				game_state.packets.PipeData(packet_place)
				print("MOD MENU: Gave item ", item_id)

func _on_invert_shell():
	var active_shell_list = game_state.MAIN_active_sequence_dict.get("sequence_in_shotgun", [])
	if active_shell_list.size() > 0:
		var current = active_shell_list[0]
		if current == "live":
			active_shell_list[0] = "blank"
		else:
			active_shell_list[0] = "live"




		print("MOD MENU: Inverted first shell type")
