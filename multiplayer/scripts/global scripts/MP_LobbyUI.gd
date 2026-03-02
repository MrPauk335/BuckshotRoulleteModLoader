class_name MP_LobbyUI extends Node

@export var packets: PacketManager
@export var cursor: MP_CursorManager
@export var lobby: LobbyManager
@export var match_customization: MP_MatchCustomization
@export var matchmaking: MP_Matchmaking
@export var ui_host: Array[Control]
@export var ui_member: Array[Control]
@export var cl_disable_on_steam_deck: Array[CanvasLayer]

@export_group("lobby scene intermediary")
@export var speaker_button_press: AudioStreamPlayer2D
@export var speaker_button_hover: AudioStreamPlayer2D
@export var lobby_manager: LobbyManager
@export_group("")

@export var ui_parent_lobby_home: Control
@export var ui_parent_match_customization: Control

@export var ui_button_host: Control
@export var ui_button_leave: Control
@export var ui_button_start_game: Control
@export var ui_copy_id: Control
@export var ui_join_with_id: Control
@export var ui_invite_friends: Control
@export var ui_skip_intro: Control
@export var ui_skip_intro_checkbox: Control
@export var ui_number_of_rounds: Label
@export var ui_checkbox_number_of_rounds_plus: Control
@export var ui_checkbox_number_of_rounds_minus: Control
@export var ui_checkbox_button_skip_intro: Button
@export var ui_check_skip_intro: Control
@export var ui_checking_animation: Control
@export var ui_parent_popup_window: Control
@export var ui_label_popup: Label
@export var ui_match_customization: Label
@export var ui_match_customization_first_focus: Control
@export var ui_search_for_lobbies: Control
@export var ui_friends_only_toggle: Control
@export var ui_friends_only_checkbox: Control
@export var ui_player_limit: Control
@export var ui_player_limit_label: Label
@export var parent_lobby_search: Control
@export var first_focus_lobby_search: Control

@export var button_class_popup_close: Control
@export var button_class_host: Control
@export var button_class_leave: Control
@export var button_class_start: Control

@export var pos_number_of_rounds_client: Vector2
@export var pos_number_of_rounds_host: Vector2
@export var pos_lobby_id_console_client: Vector2
@export var pos_lobby_id_console_host: Vector2
@export var ui_label_lobby_id_console: Control

@export var array_members: Array[Label]
@export var array_kick: Array[Control]
@export var array_circles: Array[Control]

@export var animator_popup: AnimationPlayer
@export var animator_intro: AnimationPlayer
@export var speaker_music: AudioStreamPlayer2D
@export var speaker_intro: AudioStreamPlayer2D
@export var speaker_info_change: AudioStreamPlayer2D
@export var speaker_enter_main: AudioStreamPlayer2D
@export var speaker_exit: AudioStreamPlayer2D
@export var viewblocker_main: Control
@export var animator_game_start: AnimationPlayer
@export var debug_timeouts_enabled: Control

func _ready():
	if _ModLoaderHooks.any_mod_hooked:
		await _ModLoaderHooks.call_hooks_async(self.vanilla__ready, [], _ModLoaderHooks.get_hook_hash("res://multiplayer/scripts/global scripts/MP_LobbyUI.gd", "_ready"))
	else:
		await vanilla__ready()

func vanilla__ready():
	GlobalVariables.cursor_state_after_toggle = false
	cursor.SetCursor(false, false)
	_create_bot_buttons()
	UpdatePlayerList()

	if GlobalVariables.running_short_intro_in_lobby_scene:
		ShortIntro()
		if GlobalSteam.LOBBY_ID != 0:
			if GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
				Steam.setLobbyJoinable(GlobalSteam.LOBBY_ID, true)
	else:
		LongIntro()
	GlobalVariables.running_short_intro_in_lobby_scene = false
	SetWidth()

	if GlobalSteam.LOBBY_ID == 0:
		match_customization.ClearMatchCustomizationUI()
	else:
		match_customization.UpdateMatchCustomizationUI(GlobalVariables.previous_match_customization_differences)

func _process(delta):
	if _ModLoaderHooks.any_mod_hooked:
		_ModLoaderHooks.call_hooks(self.vanilla__process, [delta], _ModLoaderHooks.get_hook_hash("res://multiplayer/scripts/global scripts/MP_LobbyUI.gd", "_process"))
	else:
		vanilla__process(delta)

func vanilla__process(delta):
	CheckHostLeave()
	CheckLobbyCopyPaste()
	CheckHostUI()
	CheckStartButton()
	FailsafeFocusUI()
	DebugLabel()
	_check_bot_buttons()
	CheckLowerConsolePosition()
	CheckSearchForLobbies()
	CheckFriendsOnlyToggle()
	_check_auto_battler()

func DebugLabel():
	debug_timeouts_enabled.visible = GlobalVariables.timeouts_enabled

func CheckLowerConsolePosition():
	if GlobalSteam.LOBBY_ID != 0:
		if GlobalSteam.HOST_ID == GlobalSteam.STEAM_ID:
			ui_label_lobby_id_console.position = pos_lobby_id_console_host
		else:
			ui_label_lobby_id_console.position = pos_lobby_id_console_client
	else:
		ui_label_lobby_id_console.position = pos_lobby_id_console_client

func CheckSearchForLobbies():
	ui_search_for_lobbies.visible = GlobalSteam.LOBBY_ID == 0

func CheckFriendsOnlyToggle():
	if GlobalSteam.LOBBY_ID != 0:
		ui_friends_only_toggle.visible = GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID
		ui_player_limit.visible = GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID
		if GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
			ui_player_limit_label.text = "PLAYER LIMIT: %s" % str(GlobalSteam.lobby_player_limit)
		ui_friends_only_checkbox.visible = GlobalSteam.is_lobby_friends_only
	else:
		ui_friends_only_toggle.visible = false
		ui_player_limit.visible = false

func GetFirstUIFocus():
	var first_focus: Control
	if GlobalSteam.LOBBY_ID == 0:
		first_focus = button_class_host
	else:
		first_focus = button_class_leave
	return first_focus

var fs_focus_ui = false
func FailsafeFocusUI():
	if !fs_focus_ui:
		if cursor.controller.previousFocus == button_class_start && button_class_start.get_parent().visible == false:
			if GlobalVariables.controllerEnabled or cursor.controller_active:
				GetFirstUIFocus().grab_focus()
			cursor.controller.previousFocus = GetFirstUIFocus()
			fs_focus_ui = true

func EnterMatchCustomization():
	ui_parent_lobby_home.visible = false
	ui_parent_match_customization.visible = true
	match_customization.OnMatchCustomizationEnter()
	if GlobalVariables.controllerEnabled or cursor.controller_active:
		ui_match_customization_first_focus.grab_focus()
	cursor.controller.previousFocus = ui_match_customization_first_focus

func EnterLobbySearch():
	ui_parent_lobby_home.visible = false
	parent_lobby_search.visible = true
	if GlobalVariables.controllerEnabled or cursor.controller_active:
		first_focus_lobby_search.grab_focus()
	cursor.controller.previousFocus = first_focus_lobby_search
	matchmaking.OnLobbySearchEnter()

func ExitLobbySearch():
	parent_lobby_search.visible = false
	ui_parent_lobby_home.visible = true
	if GlobalVariables.controllerEnabled or cursor.controller_active:
		GetFirstUIFocus().grab_focus()
	cursor.controller.previousFocus = GetFirstUIFocus()

func ExitMatchCustomization():
	ui_parent_match_customization.visible = false
	ui_parent_lobby_home.visible = true
	if GlobalVariables.controllerEnabled or cursor.controller_active:
		GetFirstUIFocus().grab_focus()
	cursor.controller.previousFocus = GetFirstUIFocus()

func ShortIntro():
	var intro_delay = 0.1
	if GlobalVariables.mp_auto_battler_enabled: intro_delay = 0.01
	await get_tree().create_timer(intro_delay, false).timeout
	animator_intro.play("short intro")
	speaker_music.play()
	var wait_delay = 2.5
	if GlobalVariables.mp_auto_battler_enabled: wait_delay = 0.1
	await get_tree().create_timer(wait_delay, false).timeout
	GlobalVariables.cursor_state_after_toggle = true
	cursor.SetCursor(true, true)
	if !lobby.viewing_popup:
		if GlobalVariables.controllerEnabled:
			GetFirstUIFocus().grab_focus()
		cursor.controller.previousFocus = GetFirstUIFocus()
	await get_tree().create_timer(0.3, false).timeout
	if GlobalVariables.lobby_id_found_in_command_line != 0:
		lobby.join_lobby(GlobalVariables.lobby_id_found_in_command_line)

func LongIntro():
	var intro_delay = 0.1
	if GlobalVariables.mp_auto_battler_enabled: intro_delay = 0.01
	await get_tree().create_timer(intro_delay, false).timeout
	animator_intro.play("intro1")
	speaker_music.play()
	speaker_intro.play()
	var wait_delay = 7.0
	if GlobalVariables.mp_auto_battler_enabled: wait_delay = 0.1
	await get_tree().create_timer(wait_delay, false).timeout
	GlobalVariables.cursor_state_after_toggle = true
	cursor.SetCursor(true, true)
	if GlobalVariables.controllerEnabled:
		GetFirstUIFocus().grab_focus()
	cursor.controller.previousFocus = GetFirstUIFocus()

var prev_members = []
var fs = false
var playing_info_change_sound = true
func UpdatePlayerList():
	if _ModLoaderHooks.any_mod_hooked:
		await _ModLoaderHooks.call_hooks_async(self.vanilla_UpdatePlayerList, [], _ModLoaderHooks.get_hook_hash("res://multiplayer/scripts/global scripts/MP_LobbyUI.gd", "UpdatePlayerList"))
	else:
		await vanilla_UpdatePlayerList()

func vanilla_UpdatePlayerList():
	CheckAllVersions()
	var members = GlobalSteam.LOBBY_MEMBERS.duplicate()
	if members.size() != prev_members.size() && fs:
		speaker_info_change.pitch_scale = randf_range(0.2, 0.3)
		if playing_info_change_sound: speaker_info_change.play()
	prev_members = members
	for i in range(array_members.size()):
		array_members[i].text = ""
		array_kick[i].visible = false
		array_circles[i].visible = false
	for i in range(members.size()):
		array_members[i].text = GlobalSteam.LOBBY_MEMBERS[i]["steam_name"]
		array_circles[i].visible = true
		if i != 0 && GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
			array_kick[i].visible = true
			array_kick[i].get_child(0).get_child(0).sub_alias = str(members[i].steam_id)

	var bot_names = ["Alex", "John", "David", "Mike"]
	for b in range(GlobalVariables.mp_bot_count):
		var slot = members.size() + b
		if slot < array_members.size():
			array_members[slot].text = bot_names[b] if b < bot_names.size() else "Player"
			array_circles[slot].visible = true
	fs = true

func ShowPopupWindow(with_message: String):
	await get_tree().create_timer(0.1, false).timeout
	lobby.viewing_popup = true
	animator_popup.play("show")
	ui_label_popup.text = with_message
	ui_parent_popup_window.visible = true
	if GlobalVariables.controllerEnabled or cursor.controller_active:
		button_class_popup_close.grab_focus()
	cursor.controller.previousFocus = button_class_popup_close

func ClosePopupWindow():
	if GlobalVariables.returning_to_main_menu_on_popup_close:
		ExitAfterClosingPopupWindow()
		GlobalVariables.returning_to_main_menu_on_popup_close = false
	lobby.viewing_popup = false
	animator_popup.play("hide")
	await get_tree().create_timer(0.26, false).timeout
	ui_parent_popup_window.visible = false
	if GlobalVariables.controllerEnabled or cursor.controller_active:
		GetFirstUIFocus().grab_focus()
	cursor.controller.previousFocus = GetFirstUIFocus()

func ExitAfterClosingPopupWindow():
	await get_tree().create_timer(0.2, false).timeout
	ExitToMainMenu()

func OpenDiscordLink():
	OS.shell_open(GlobalVariables.discord_link)

func SetWidth():
	var x = 94
	match TranslationServer.get_locale():
		"TR":
			x = 111
		"EE":
			x = 126
		"EN":
			x = 94
		"RU":
			x = 104
	for k in array_kick:
		k.size = Vector2(x, k.size.y)

var all_versions_matching = false
func CheckAllVersions():
	var steam_ids_currently_connected = []
	for member in GlobalSteam.LOBBY_MEMBERS:
		steam_ids_currently_connected.append(member.steam_id)
	var c = 0
	for steam_id in steam_ids_currently_connected:
		if steam_id in GlobalVariables.steam_id_version_checked_array:
			c += 1
	if c == steam_ids_currently_connected.size():
		all_versions_matching = true
	else:
		all_versions_matching = false

func CheckStartButton():
	var total_players = GlobalSteam.LOBBY_MEMBERS.size() + GlobalVariables.mp_bot_count
	if GlobalSteam.LOBBY_ID != 0 && GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
		if all_versions_matching && total_players > 1:
			ui_button_start_game.visible = true
			ui_checking_animation.visible = false
		if all_versions_matching && total_players <= 1:
			ui_button_start_game.visible = false
			ui_checking_animation.visible = false
			fs_focus_ui = false
		if !all_versions_matching && total_players > 1:
			ui_button_start_game.visible = false
			ui_checking_animation.visible = true
			fs_focus_ui = false
	else:
		ui_button_start_game.visible = false
		ui_checking_animation.visible = false
		fs_focus_ui = false

func CheckHostLeave():
	if GlobalSteam.LOBBY_ID == 0:
		ui_button_host.visible = true
		ui_button_leave.visible = false
	else:
		ui_button_host.visible = false
		ui_button_leave.visible = true

func CheckHostUI():
	if GlobalVariables.mp_debugging:
		ui_match_customization.visible = true
		return
	if GlobalSteam.LOBBY_ID == 0:
		ui_match_customization.visible = false
	else:
		if GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
			ui_match_customization.visible = true
		else:
			ui_match_customization.visible = false

func SetupMainSceneLoad():
	GlobalVariables.cursor_state_after_toggle = false
	cursor.SetCursor(false, false)
	speaker_music.stop()
	speaker_enter_main.play()
	animator_intro.play("outro fade in effect")
	animator_game_start.play("show")
	await get_tree().create_timer(3, false).timeout
	speaker_exit.play()
	animator_intro.play("outro cut out")
	await get_tree().create_timer(0.6, false).timeout
	viewblocker_main.visible = true

func ExitToMainMenu():
	playing_info_change_sound = false
	lobby.leave_lobby()
	speaker_music.stop()
	GlobalVariables.cursor_state_after_toggle = false
	cursor.SetCursor(false, false)
	speaker_exit.play()
	animator_intro.play("outro cut out")
	await get_tree().create_timer(0.6, false).timeout
	viewblocker_main.visible = true
	await get_tree().create_timer(0.2, false).timeout
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func CheckLobbyCopyPaste():
	if GlobalSteam.LOBBY_ID == 0:
		ui_copy_id.visible = false
		ui_join_with_id.visible = true
		ui_invite_friends.visible = false
	else:
		ui_copy_id.visible = true
		ui_join_with_id.visible = false
		ui_invite_friends.visible = true

var btn_add_bot: Button
var btn_remove_bot: Button
var btn_player_ai_toggle: Button
var _btn_ai_target_toggle: Button

func _create_bot_buttons():
	var parent = ui_parent_lobby_home
	if parent == null: return

	var font = load("res://fonts/fake receipt.otf")
	var theme_res = load("res://misc/button_theme1.tres")

	btn_add_bot = Button.new()
	btn_add_bot.text = "⊕ ADD BOT"
	if theme_res: btn_add_bot.theme = theme_res
	if font:
		btn_add_bot.add_theme_font_override("font", font)
		btn_add_bot.add_theme_font_size_override("font_size", 16)
	btn_add_bot.add_theme_color_override("font_color", Color("00ff00"))
	btn_add_bot.add_theme_color_override("font_hover_color", Color("88ff88"))
	btn_add_bot.custom_minimum_size = Vector2(170, 35)
	btn_add_bot.position = Vector2(430, 155)
	btn_add_bot.pressed.connect( func(): lobby_manager.Pipe("add bot"))
	parent.add_child(btn_add_bot)

	btn_remove_bot = Button.new()
	btn_remove_bot.text = "⊖ REMOVE BOT"
	if theme_res: btn_remove_bot.theme = theme_res
	if font:
		btn_remove_bot.add_theme_font_override("font", font)
		btn_remove_bot.add_theme_font_size_override("font_size", 16)
	btn_remove_bot.add_theme_color_override("font_color", Color("ff4444"))
	btn_remove_bot.add_theme_color_override("font_hover_color", Color("ff8888"))
	btn_remove_bot.custom_minimum_size = Vector2(170, 35)
	btn_remove_bot.position = Vector2(430, 195)
	btn_remove_bot.pressed.connect( func(): lobby_manager.Pipe("remove bot"))
	parent.add_child(btn_remove_bot)

	btn_player_ai_toggle = Button.new()
	btn_player_ai_toggle.text = "AI PLAYER: OFF"
	if theme_res: btn_player_ai_toggle.theme = theme_res
	if font:
		btn_player_ai_toggle.add_theme_font_override("font", font)
		btn_player_ai_toggle.add_theme_font_size_override("font_size", 16)
	btn_player_ai_toggle.custom_minimum_size = Vector2(170, 35)
	btn_player_ai_toggle.position = Vector2(430, 235)
	btn_player_ai_toggle.pressed.connect(_on_ai_player_toggle)
	parent.add_child(btn_player_ai_toggle)

	_btn_ai_target_toggle = Button.new()
	_btn_ai_target_toggle.text = "TARGET: DEALER"
	if theme_res: _btn_ai_target_toggle.theme = theme_res
	if font:
		_btn_ai_target_toggle.add_theme_font_override("font", font)
		_btn_ai_target_toggle.add_theme_font_size_override("font_size", 16)
	_btn_ai_target_toggle.custom_minimum_size = Vector2(170, 35)
	_btn_ai_target_toggle.position = Vector2(430, 275)
	_btn_ai_target_toggle.pressed.connect(_on_ai_target_toggle)
	parent.add_child(_btn_ai_target_toggle)

func _on_ai_target_toggle():
	if GlobalVariables.mp_bot_target == "dealer":
		GlobalVariables.mp_bot_target = "all"
	else:
		GlobalVariables.mp_bot_target = "dealer"
	_update_ai_target_button_text()

func _update_ai_target_button_text():
	if _btn_ai_target_toggle == null: return
	if GlobalVariables.mp_bot_target == "dealer":
		_btn_ai_target_toggle.text = "TARGET: DEALER"
	else:
		_btn_ai_target_toggle.text = "TARGET: ALL"

func _on_ai_player_toggle():
	GlobalVariables.mp_player_ai_enabled = !GlobalVariables.mp_player_ai_enabled
	_update_ai_toggle_button_text()

	_apply_ai_to_local_player()

func _update_ai_toggle_button_text():
	if btn_player_ai_toggle == null: return
	if GlobalVariables.mp_player_ai_enabled:
		btn_player_ai_toggle.text = "AI PLAYER: ON"
		btn_player_ai_toggle.add_theme_color_override("font_color", Color("ffff00"))
	else:
		btn_player_ai_toggle.text = "AI PLAYER: OFF"
		btn_player_ai_toggle.add_theme_color_override("font_color", Color("ffffff"))

func _apply_ai_to_local_player():
	if lobby_manager == null or lobby_manager.instance_handler == null: return
	for prop in lobby_manager.instance_handler.instance_property_array:
		if prop.user_id == GlobalSteam.STEAM_ID:
			prop.cpu_enabled = GlobalVariables.mp_player_ai_enabled
			print("[AI] Player AI set to: ", prop.cpu_enabled)

func _check_bot_buttons():
	if btn_add_bot == null or btn_remove_bot == null: return
	var show_bot_buttons = GlobalSteam.LOBBY_ID != 0 and GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID
	var total = GlobalSteam.LOBBY_MEMBERS.size() + GlobalVariables.mp_bot_count
	btn_add_bot.visible = show_bot_buttons and total < 4
	btn_remove_bot.visible = show_bot_buttons and GlobalVariables.mp_bot_count > 0
	_update_ai_toggle_button_text()
	btn_player_ai_toggle.visible = GlobalSteam.LOBBY_ID != 0
	_update_ai_target_button_text()
	if _btn_ai_target_toggle: _btn_ai_target_toggle.visible = GlobalSteam.LOBBY_ID != 0 and GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID

var is_starting_auto = false
func _check_auto_battler():
	if !GlobalVariables.mp_auto_battler_enabled: return


	if GlobalSteam.LOBBY_ID == 0:
		if !lobby_manager.updating_list:
			print("[AUTO] No lobby, creating...")
			lobby_manager.CreateLobby()
		return


	if GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
		_apply_ai_to_local_player()
		var total = GlobalSteam.LOBBY_MEMBERS.size() + GlobalVariables.mp_bot_count
		if total < 4:
			print("[AUTO] Adding bot for full lobby...")
			lobby_manager.Pipe("add bot")
		elif ui_button_start_game.visible:
			if !is_starting_auto:
				_start_auto_timer()

func _start_auto_timer():
	is_starting_auto = true
	print("[AUTO] Lobby ready. Starting in 1 second...")
	await get_tree().create_timer(1.0, false).timeout
	if GlobalVariables.mp_auto_battler_enabled and ui_button_start_game.visible:
		print("[AUTO] Starting game!")
		lobby_manager.Pipe("start game")
	is_starting_auto = false
