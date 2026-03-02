extends Node

const MOD_DIR: = "mrpauk335-AI_Bot"
const LOG_NAME: = "mrpauk335-AI_Bot:Main"

func _init() -> void :
	ModLoaderLog.info("Init (Hooks Mode)", LOG_NAME)


	ModLoaderMod.add_hook(_on_lobby_ui_ready, "res://multiplayer/scripts/global scripts/MP_LobbyUI.gd", "_ready")
	ModLoaderMod.add_hook(_on_lobby_ui_process, "res://multiplayer/scripts/global scripts/MP_LobbyUI.gd", "_process")
	ModLoaderMod.add_hook(_on_lobby_ui_update_player_list, "res://multiplayer/scripts/global scripts/MP_LobbyUI.gd", "UpdatePlayerList")


	ModLoaderMod.add_hook(_on_packet_verify, "res://multiplayer/scripts/global scripts/MP_PacketVerification.gd", "VerifyPacket")

func _ready() -> void :
	ModLoaderLog.info("Ready", LOG_NAME)



func _on_lobby_ui_ready(chain: ModLoaderHookChain) -> void :
	var ui = chain.reference_object
	ModLoaderLog.info("LobbyUI Hook: Ready", LOG_NAME)


	chain.execute_next()


	_ext_create_bot_buttons(ui)

func _on_lobby_ui_process(chain: ModLoaderHookChain, delta: float) -> void :
	var ui = chain.reference_object
	chain.execute_next([delta])

	_ext_check_bot_buttons(ui)

func _on_lobby_ui_update_player_list(chain: ModLoaderHookChain) -> void :
	var ui = chain.reference_object
	chain.execute_next()






func _on_packet_verify(chain: ModLoaderHookChain, packet_data: Dictionary) -> bool:

	if packet_data.has("sender") and packet_data["sender"] == "bot":
		return true


	return chain.execute_next([packet_data])



func _ext_create_bot_buttons(ui):
	var parent = ui.get("ui_parent_lobby_home")
	if parent == null:
		ModLoaderLog.error("LobbyUI Hook: ui_parent_lobby_home is NULL", LOG_NAME)
		return

	var font = load("res://fonts/fake receipt.otf")
	var theme_res = load("res://misc/button_theme1.tres")

	var btn_add = Button.new()
	btn_add.text = "⊕ ADD BOT"
	if theme_res: btn_add.theme = theme_res
	if font:
		btn_add.add_theme_font_override("font", font)
		btn_add.add_theme_font_size_override("font_size", 16)
	btn_add.add_theme_color_override("font_color", Color("00ff00"))
	btn_add.add_theme_color_override("font_hover_color", Color("88ff88"))
	btn_add.custom_minimum_size = Vector2(170, 35)
	btn_add.position = Vector2(430, 155)
	btn_add.pressed.connect( func(): ui.lobby_manager.Pipe("add bot"))
	parent.add_child(btn_add)
	ui.set_meta("ext_btn_add_bot", btn_add)

	var btn_remove = Button.new()
	btn_remove.text = "⊖ REMOVE BOT"
	if theme_res: btn_remove.theme = theme_res
	if font:
		btn_remove.add_theme_font_override("font", font)
		btn_remove.add_theme_font_size_override("font_size", 16)
	btn_remove.add_theme_color_override("font_color", Color("ff4444"))
	btn_remove.add_theme_color_override("font_hover_color", Color("ff8888"))
	btn_remove.custom_minimum_size = Vector2(170, 35)
	btn_remove.position = Vector2(430, 195)
	btn_remove.pressed.connect( func(): ui.lobby_manager.Pipe("remove bot"))
	parent.add_child(btn_remove)
	ui.set_meta("ext_btn_remove_bot", btn_remove)

	ModLoaderLog.info("LobbyUI Hook: Buttons created successfully", LOG_NAME)

func _ext_check_bot_buttons(ui):
	var btn_add = ui.get_meta("ext_btn_add_bot", null)
	var btn_remove = ui.get_meta("ext_btn_remove_bot", null)
	if btn_add == null: return

	var show_bot_buttons = GlobalSteam.LOBBY_ID != 0 and GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID
	var total = GlobalSteam.LOBBY_MEMBERS.size() + GlobalVariables.mp_bot_count

	btn_add.visible = show_bot_buttons and total < 4
	btn_remove.visible = show_bot_buttons and GlobalVariables.mp_bot_count > 0
