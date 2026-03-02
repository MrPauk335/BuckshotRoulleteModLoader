class_name MP_RoundManager extends Node

func _ready():
	if _ModLoaderHooks.any_mod_hooked:
		await _ModLoaderHooks.call_hooks_async(self.vanilla__ready, [], _ModLoaderHooks.get_hook_hash("res://multiplayer/scripts/global scripts/MP_RoundManager.gd", "_ready"))
	else:
		await vanilla__ready()

func vanilla__ready():
	pass

@export var game_state: MP_GameStateManager
@export var intro: MP_Intro
@export var outro: MP_OutroManager
@export var centerpiece: MP_CenterPiece
@export var intermed: MP_InteractionIntermed
@export var packets: PacketManager
@export var instance_handler: MP_UserInstanceHandler
@export var shell_loader: MP_ShellLoader
@export var win_manager: MP_WinManager
@export var item_remover: MP_ItemRemover_Main
@export var animator_shell_sequence_machine: AnimationPlayer
@export var editor_debug: MP_EditorDebug
@export var animator_win_lose: AnimationPlayer

@export var speaker_sequence_machine: AudioStreamPlayer2D
@export var sound_show: AudioStream
@export var sound_hide: AudioStream

var active_round_dict: Dictionary
var active_sequence_dict: Dictionary
var active_first_turn_socket: int
var active_round_index: int = -1
var active_current_main_round_index: int
var active_current_sub_round_index: int

var intro_finished = false
var is_first_sequence = false
var bot_watchdog_timer: float = 0.0
var bot_watchdog_threshold: float = 4.0
var last_watchdog_socket: int = -1

var fs = false

@export_group("balance variables global")
@export var sequence_visible_duration: float
@export var adding_unknown_shells: bool

func PacketSort(dict: Dictionary):
	var value_category = dict.values()[0]
	var value_alias = dict.values()[1]
	match value_alias:
		"first round routine":
			if !intro_finished:
				if dict.running_intro:
					print("running intro sequence before the round starts ...")
					await (intro.MainIntroSetup())
					print("main intro sequence finished. beginning round ...")
					game_state.MAIN_active_running_intro = false
				else:
					print("skipping intro sequence before the round starts ...")
					await (intro.MainIntro_Skip())
					print("skip finished. beginning round ...")
			intro_finished = true

			game_state.MAIN_active_round_dict = dict.round_dictionary
			game_state.MAIN_active_first_turn_socket = dict.first_turn_socket
			game_state.MAIN_active_round_index = dict.active_round_index
			game_state.MAIN_active_socket_inventories_to_clear = dict.socket_inventories_to_remove
			game_state.MAIN_active_checking_for_first_death = true
			game_state.MAIN_active_turn_order = "CW"
			game_state.FreeLookCameraForAllUsers_Disable()
			await (UnJamAllUsers())
			await (ReviveAllDeadUsers())
			await (SetupRoundIndicators())
			await (SetupHealthIndicators())
			await (ClearUserInventories())
			BeginItemGrabbingForSockets(dict.sockets_to_begin_item_grabbing_on)
		"load shotgun routine":
			game_state.FreeLookCameraForAllUsers_Disable()
			if GlobalSteam.STEAM_ID != GlobalSteam.HOST_ID:
				game_state.MAIN_active_sequence_dict = dict.sequence_dictionary
			game_state.MAIN_active_first_turn_socket = dict.first_turn_socket
			for property in instance_handler.instance_property_array: property.running_fast_revival = false
			LoadShotgun()
		"pass turn":
			game_state.MAIN_active_first_turn_socket = dict.socket_to_pass_turn_to
			PassTurn(game_state.MAIN_active_first_turn_socket)
		"end turn":
			MainRoutine_UserEndTurn(dict)
		"game conclusion":
			game_state.FreeLookCameraForAllUsers_Disable()
			GameConclusion(dict)

func _process(delta):

	if GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
		var current_socket = game_state.MAIN_active_current_turn_socket


		if current_socket != last_watchdog_socket:
			last_watchdog_socket = current_socket
			bot_watchdog_timer = 0.0
			return

		if current_socket != -1:
			var active_prop: MP_UserInstanceProperties = null
			for p in instance_handler.instance_property_array:
				if p.socket_number == current_socket:
					active_prop = p
					break

			if active_prop != null and active_prop.has_turn:
				var ai_mode = GlobalVariables.ai_mode
				var is_ai = false

				if ai_mode == 1:
					is_ai = active_prop.cpu_enabled
				elif ai_mode == 2:
					is_ai = active_prop.cpu_enabled or (active_prop.user_id == GlobalSteam.STEAM_ID and GlobalVariables.mp_player_ai_enabled)

				if is_ai:

					var is_animating = active_prop.is_interacting_with_item or active_prop.is_shooting or active_prop.is_grabbing_items or active_prop.is_stealing_item or active_prop.is_on_jammer_selection or active_prop.is_viewing_jammer or active_prop.is_holding_item_to_place or active_prop.is_being_revived

					if !is_animating:
						bot_watchdog_timer += delta
					else:

						bot_watchdog_timer += delta * 0.05



					var actual_timeout = bot_watchdog_threshold if !active_prop.is_bot_thinking else 10.0
					if bot_watchdog_timer >= actual_timeout:
						print("[BOT] Watchdog TIMEOUT - Force re-triggering AI for socket: ", current_socket)
						active_prop.is_bot_thinking = false
						active_prop.is_interacting_with_item = false
						active_prop.is_shooting = false
						active_prop.is_grabbing_items = false
						bot_watchdog_timer = 0.0
						BeginBotTurn.call_deferred(active_prop)
				else:
					bot_watchdog_timer = 0.0
			else:
				bot_watchdog_timer = 0.0

func _unhandled_input(event):
	if GlobalVariables.mp_debug_keys_enabled:
		if event.is_action_pressed("7"):
			game_state.StopTimeoutForSocket("item distribution", game_state.MAIN_active_current_turn_socket)
			game_state.StopTimeoutForSocket("turn", game_state.MAIN_active_current_turn_socket)
			MainRoutine_PassTurn(GetNextTurn_Socket(game_state.MAIN_active_current_turn_socket))
			for property in intermed.instance_handler.instance_property_array:
				property.permissions.SetMainPermission(false)

func MainRoutine_StartRound():
	game_state.MAIN_is_start_of_new_round = true
	game_state.MAIN_active_first_turn_socket = GetFirstTurn_Socket()
	game_state.MAIN_active_round_index += 1
	game_state.MAIN_active_socket_inventories_to_clear = game_state.GetSocketInventoriesToClear()
	game_state.SetItemDistributionVariablesFromCustomization(game_state.MAIN_active_round_index)
	is_first_sequence = true
	GenerateRandomRound()
	GetRandomItemGrabAmount()
	var packet = {
	"packet category": "MP_RoundManager", 
	"packet alias": "first round routine", 
	"sent_from": "host", 
	"packet_id": 7, 
	"round_dictionary": game_state.MAIN_active_round_dict, 
	"first_turn_socket": game_state.MAIN_active_first_turn_socket, 
	"active_round_index": game_state.MAIN_active_round_index, 
	"socket_inventories_to_remove": game_state.MAIN_active_socket_inventories_to_clear, 
	"running_intro": !GlobalVariables.skipping_intro, 
	"sockets_to_begin_item_grabbing_on": game_state.GetSocketsToBeginItemGrabbingOn(true)
	}
	print("starting first round routine with")
	print("first turn socket: ", packet.first_turn_socket)
	print("socket inventories to remove: ", packet.socket_inventories_to_remove)
	print("sockets to begin item grabbing on: ", packet.sockets_to_begin_item_grabbing_on)
	game_state.MAIN_is_start_of_new_round = false
	packets.send_p2p_packet(0, packet)
	packets.PipeData(packet)

func LoopBackAfterWinRoutine():
	if (GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID) or GlobalVariables.mp_debugging:
		print("host started loop back after win routine")
		if game_state.MAIN_active_round_index == GlobalVariables.debug_round_index_to_end_game_at:
			print("final round index hit. all rounds are over. running game conclusion")
			GameConclusion_Packet()
		else:
			print("round index is not final. next round.")
			MainRoutine_StartRound()
	else:
		print("not the host - failed to loop back after win routine")

func GameConclusion_Packet():
	var conclusion_message = "The game has concluded. Exiting ..."
	game_state.MAIN_active_match_result_statistics = game_state.GetMatchResultStatistics()
	var packet = {
	"packet category": "MP_RoundManager", 
	"packet alias": "game conclusion", 
	"sent_from": "host", 
	"packet_id": 27, 
	"message": conclusion_message, 
	"match_result_statistics": game_state.MAIN_active_match_result_statistics, 
	}
	packets.send_p2p_packet(0, packet)
	packets.PipeData(packet)

func GameConclusion(packet: Dictionary):
	game_state.MAIN_active_match_result_statistics = packet.match_result_statistics

	if GlobalVariables.mp_auto_battler_enabled:

		var winner_name = "Unknown"
		var winner_socket = -1
		for prop in instance_handler.instance_property_array:
			if prop.health_current > 0:
				winner_name = prop.user_name
				winner_socket = prop.socket_number
				break
		GlobalVariables.LogAnalytics(winner_name, game_state.MAIN_active_round_index, winner_socket)
		print("[AUTO] Game concluded. Returning to lobby...")
		await get_tree().create_timer(2.0, false).timeout
		GlobalVariables.running_short_intro_in_lobby_scene = true
		get_tree().change_scene_to_file("res://multiplayer/scenes/mp_lobby.tscn")
		return

	await get_tree().create_timer(1.5, false).timeout
	intermed.intermed_properties.viewblocker.FadeIn(6, -1.8)
	await get_tree().create_timer(7, false).timeout
	outro.Outro()

func MainRoutine_BeginItemGrab():
	UnJamAllUsers()
	BeginItemGrabbingForAllUsers()

func MainRoutine_LoadShotgun():
	print("main routine loading shotgun ...")
	game_state.MAIN_shotgun_loading_in_progress = true
	if is_first_sequence:
		game_state.IncrementActiveSequenceIndex(0)
	else:
		game_state.IncrementActiveSequenceIndex()
	is_first_sequence = false
	GenerateRandomSequence()
	var packet = {
		"packet category": "MP_RoundManager", 
		"packet alias": "load shotgun routine", 
		"sent_from": "host", 
		"packet_id": 8, 
		"sequence_dictionary": game_state.MAIN_active_sequence_dict_send, 
		"first_turn_socket": game_state.MAIN_active_first_turn_socket, 
	}
	packets.send_p2p_packet(0, packet)
	packets.PipeData(packet)

func MainRoutine_PassTurn(socket_to_pass_turn_to: int):
	var packet = {
		"packet category": "MP_RoundManager", 
		"packet alias": "pass turn", 
		"sent_from": "host", 
		"packet_id": 9, 
		"socket_to_pass_turn_to": socket_to_pass_turn_to, 
	}
	packets.send_p2p_packet(0, packet)
	packets.PipeData(packet)

func UserEndTurn_Packet(from_socket: int = 0, passing_next_turn: bool = false, shotgun_empty: bool = false, user_has_won_game_at_socket: int = -1):
	GetRandomItemGrabAmount()
	if (GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID) or GlobalVariables.mp_debugging:
		var packet = {
			"packet category": "MP_RoundManager", 
			"packet alias": "end turn", 
			"sent_from": "host", 
			"packet_id": 14, 
			"from_socket": from_socket, 
			"passing_next_turn": passing_next_turn, 
			"next_turn_socket": GetNextTurn_Socket(from_socket), 
			"shotgun_empty": shotgun_empty, 
			"user_won_game_at_socket": user_has_won_game_at_socket, 
			"sockets_to_begin_item_grabbing_on": game_state.GetSocketsToBeginItemGrabbingOn(), 
		}
		packets.send_p2p_packet(0, packet)
		packets.PipeData(packet)
	else:
		print("user end turn request on non-host. returning (this should not even be able to print realistically)")

func MainRoutine_UserEndTurn(packet_dictionary: Dictionary = {}):
	game_state.ClearTimeouts()

	game_state.StopTimeoutForSocket("turn", packet_dictionary.from_socket)
	game_state.StopTimeoutForSocket("item distribution", packet_dictionary.from_socket)

	if packet_dictionary.user_won_game_at_socket != -1:
		print("user has won game. doing win shit & returning at mainroutine_userendturn")
		game_state.MAIN_running_win_routine = true
		win_manager.WinRoutine(packet_dictionary.user_won_game_at_socket)
		return
	if packet_dictionary.passing_next_turn: game_state.MAIN_active_first_turn_socket = packet_dictionary.next_turn_socket
	else: game_state.MAIN_active_first_turn_socket = packet_dictionary.from_socket

	if packet_dictionary.shotgun_empty:
		BeginItemGrabbingForSockets(packet_dictionary.sockets_to_begin_item_grabbing_on)
	else:
		PassTurn(game_state.MAIN_active_first_turn_socket)

func UnJamAllUsers():
	print("unjamming all users before next round ...")
	for instance_property in instance_handler.instance_property_array:
		instance_property.HardReset()
	ResetShotgunForAll()

func ResetShotgunForAll():
	print("resetting shotgun for all users ...")
	for property in instance_handler.instance_property_array:
		property.shotgun.ResetAnimations()
	game_state.MAIN_is_shotgun_held = false
	intermed.SetShotgunVisible_Global(true)

func ReviveAllDeadUsers():
	print("checking to revive all dead users before next round ...")
	var reviving = false
	for instance_property in instance_handler.instance_property_array:
		if instance_property.health_current == 0:
			instance_property.death.UserDeath_Revive(true)
			reviving = true
	if reviving: await get_tree().create_timer(2, false).timeout

func SetupRoundIndicators():
	print("setting up round indicators ...")
	for instance_property in instance_handler.instance_property_array: instance_property.health_counter.BootupDisplay_ShowCurrentRound()
	await get_tree().create_timer(2.9, false).timeout

func SetupHealthIndicators():
	print("setting up health indicators ...")
	for instance_property in instance_handler.instance_property_array: instance_property.health_counter.BootupDisplay_Health()
	await get_tree().create_timer(1.9, false).timeout

func LoadShotgun():
	print("loading shotgun ...")
	ResetShotgunForAll()
	game_state.FreeLookCameraForAllUsers_Disable()
	animator_shell_sequence_machine.play("RESET")
	centerpiece.MoveToLoadingDock()
	intermed.intermed_properties.cam.BeginLerp("sequence socket_" + str(intermed.intermed_properties.socket_number), true)
	await get_tree().create_timer(0.7, false).timeout
	shell_loader.SpawnShells()
	animator_shell_sequence_machine.play("move up")
	speaker_sequence_machine.stream = sound_show
	speaker_sequence_machine.play()
	await get_tree().create_timer(game_state.MAIN_sequence_visible_duration, false).timeout
	speaker_sequence_machine.stream = sound_hide
	speaker_sequence_machine.play()
	animator_shell_sequence_machine.play_backwards("move up")
	await get_tree().create_timer(1.3, false).timeout
	await get_tree().create_timer(0.4, false).timeout
	passing_turn_from_dock = true
	PassTurn(game_state.MAIN_active_first_turn_socket)
	game_state.MAIN_shotgun_loading_in_progress = false
	if !fs:
		if game_state.MAIN_active_environmental_event == "ice machine":
			intermed.environmental_event.StartIceMachine()

func ClearUserInventories():
	if game_state.MAIN_active_socket_inventories_to_clear == []: return
	print("clearing user inventories on sockets: ", game_state.MAIN_active_socket_inventories_to_clear)
	item_remover.RemoveItemsFromSockets(game_state.MAIN_active_socket_inventories_to_clear)
	await get_tree().create_timer(3.5, false).timeout

func BeginItemGrabbingForAllUsers():
	print("beginning item grabbing for all users ...")
	game_state.FreeLookCameraForAllUsers_Enable()
	game_state.item_grabbing_finished_for_all_users_checked = false
	game_state.MAIN_item_grabbing_in_progress = true
	game_state.MAIN_active_num_of_users_finished_item_grabbing = 0
	game_state.MAIN_active_num_of_users_grabbing_items = 0
	for i in range(intermed.instance_handler.instance_property_array.size()):
		if intermed.instance_handler.instance_property_array[i].health_current != 0:
			var number_of_items_in_inventory = 0
			for dict in intermed.instance_handler.instance_property_array[i].user_inventory:
				if dict != {}:
					number_of_items_in_inventory += 1
			if number_of_items_in_inventory != 8:
				intermed.instance_handler.instance_property_array[i].item_manager.BeginItemGrabbing()
				game_state.BeginTimeoutForSocket("item distribution", game_state.MAIN_timeout_duration_item_distribution, intermed.instance_handler.instance_property_array[i].socket_number)
				game_state.MAIN_active_num_of_users_grabbing_items += 1
			else:
				intermed.instance_handler.instance_property_array[i].cam.BeginLerp("home")
	print("num of users grabbing items: ", game_state.MAIN_active_num_of_users_grabbing_items)

func BeginItemGrabbingForSockets(socket_number_array):
	if socket_number_array == []:
		if GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
			MainRoutine_LoadShotgun()
			print("is host: none of the users are set to grab items. starting shell load and returning.")
			return
		else:
			print("is not host: none of the users are set to grab items. returning")
			return
	print("beginning item grabbing for sockets: ", socket_number_array)
	game_state.FreeLookCameraForAllUsers_Enable()
	game_state.item_grabbing_finished_for_all_users_checked = false
	game_state.MAIN_item_grabbing_in_progress = true
	game_state.MAIN_active_num_of_users_finished_item_grabbing = 0
	game_state.MAIN_active_num_of_users_grabbing_items = 0
	for property in instance_handler.instance_property_array:
		if property.socket_number in socket_number_array:
			property.item_manager.BeginItemGrabbing()
			game_state.BeginTimeoutForSocket("item distribution", game_state.MAIN_timeout_duration_item_distribution, property.socket_number)
			game_state.MAIN_active_num_of_users_grabbing_items += 1
		else:
			property.cam.BeginLerp("home")
	print("num of users grabbing items: ", game_state.MAIN_active_num_of_users_grabbing_items)

var passing_turn_from_dock = false
func PassTurn(to_socket: int):
	game_state.ClearTimeouts()
	game_state.FreeLookCameraForAllUsers_Enable()
	game_state.MAIN_is_shotgun_held = false
	intermed.SetShotgunVisible_Global(true)
	var previous_socket = game_state.MAIN_active_current_turn_socket

	for p in instance_handler.instance_property_array:
		p.has_turn = false
		if p.is_active:
			p.permissions.SetMainPermission(false)
			p.SetTurnControllerPrompts(false)

	game_state.MAIN_active_current_turn_socket = to_socket
	var direction_string = GetDirection(intermed.intermed_properties.socket_number, to_socket)
	var active_properties: MP_UserInstanceProperties
	for i in intermed.instance_handler.instance_property_array:
		if i.socket_number == to_socket:
			active_properties = i
			break

	if active_properties == null:
		print("attempted to pass turn to user that has disconnected. returning and passing to next user")
		if GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
			MainRoutine_PassTurn(GetNextTurn_Socket(game_state.MAIN_active_current_turn_socket))
		return
	print("passing turn to: ", active_properties.user_name)
	if direction_string == "self": direction_string = "home"
	else: direction_string = "opponent " + direction_string
	if previous_socket != to_socket or passing_turn_from_dock: centerpiece.MoveToSocket(to_socket)
	passing_turn_from_dock = false
	await get_tree().create_timer(0.2, false).timeout
	intermed.intermed_properties.cam.BeginLerp(direction_string, true)
	await get_tree().create_timer(0.7, false).timeout
	if active_properties.is_jammed:
		print(active_properties.user_name, " is jammed.")
		if !active_properties.jammer_checked:
			print(active_properties.user_name, " jam isn't checked - checking and skipping turn")
			var next_turn_socket = GetNextTurn_Socket(game_state.MAIN_active_current_turn_socket)
			active_properties.jammer_manager.Jammer_Check()
			await get_tree().create_timer(0.7, false).timeout
			PassTurn(next_turn_socket)
		else:
			print(active_properties.user_name, " jam is checked - disabling jammer and granting perms")
			active_properties.jammer_manager.Jammer_Disable()
			if active_properties.cpu_enabled and GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
				BeginBotTurn(active_properties)
			else:
				GiveTurnPermissions(active_properties)
			active_properties.has_turn = true
			game_state.BeginTimeoutForSocket("turn", game_state.MAIN_timeout_duration_turn, to_socket)
	else:
		print(active_properties.user_name, " is not jammed. granting perms")
		if (active_properties.cpu_enabled and GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID) or (active_properties.user_id == GlobalSteam.STEAM_ID and GlobalVariables.mp_player_ai_enabled):
			BeginBotTurn(active_properties)
		else:
			GiveTurnPermissions(active_properties)
		active_properties.has_turn = true
		game_state.BeginTimeoutForSocket("turn", game_state.MAIN_timeout_duration_turn, to_socket)
func GiveTurnPermissions(properties: MP_UserInstanceProperties):
	await get_tree().create_timer(0.3, false).timeout
	if properties.is_active:
		properties.SetTurnControllerPrompts(true)
		properties.permissions.SetMainPermission(true)

signal bot_turn_started(properties: MP_UserInstanceProperties)

func BeginBotTurn(properties: MP_UserInstanceProperties):

	properties.is_bot_thinking = false
	properties.is_interacting_with_item = false
	properties.is_grabbing_items = false
	properties.is_shooting = false
	properties.is_stealing_item = false

	if properties.is_interacting_with_item or properties.is_shooting or properties.is_grabbing_items or properties.is_bot_thinking:
		print("[BOT] Busy or already thinking, skipping AI check.")
		return

	properties.is_bot_thinking = true
	print("[BOT] Beginning bot turn for socket: ", properties.socket_number, " (", properties.user_name, "). Emitting signal for AI mods.")
	bot_turn_started.emit(properties)

func _bot_simulate_item_use(bot_properties: MP_UserInstanceProperties, item_id: int, index: int):
	var packet = {
		"packet category": "MP_PacketVerification", 
		"packet alias": "interact with item request", 
		"sent_from": "client", 
		"packet_id": 22, 
		"item_socket_number": bot_properties.socket_number, 
		"local_grid_index": index, 
		"item_id": item_id, 
		"sent_from_socket": bot_properties.socket_number, 
		"stealing_item": false, 
		"sender": "bot"
	}
	print("[BOT] Sending item use packet: ", packet)
	packets.PipeData(packet)
	await get_tree().create_timer(1.0, false).timeout

func _bot_simulate_shoot(bot_properties: MP_UserInstanceProperties, target_socket: int):

	if !bot_properties.is_holding_shotgun:
		print("[BOT] Not holding shotgun, picking up first.")
		var pickup_packet = {
			"packet category": "MP_PacketVerification", 
			"packet alias": "pickup shotgun request", 
			"sent_from": "client", 
			"packet_id": 10, 
			"sent_from_socket": bot_properties.socket_number, 
			"sender": "bot"
		}
		packets.PipeData(pickup_packet)
		var bot_pickup_delay = 1.5
		if GlobalVariables.mp_auto_battler_enabled: bot_pickup_delay = 1.5
		await get_tree().create_timer(bot_pickup_delay, false).timeout

	print("[BOT] Shooting opponent at socket: ", target_socket)

	var shoot_packet = {
		"packet category": "MP_PacketVerification", 
		"packet alias": "shoot user request", 
		"sent_from": "client", 
		"packet_id": 12, 
		"sent_from_socket": bot_properties.socket_number, 
		"socket_to_shoot": target_socket, 
		"sender": "bot"
	}
	print("[BOT] Sending shoot packet: ", shoot_packet)
	packets.PipeData(shoot_packet)
	await get_tree().create_timer(1.0, false).timeout

func GetFirstTurn_Socket():
	var socket_to_return
	if game_state.MAIN_active_first_socket_to_die != -1:
		var first_socket_to_die_is_ingame = false
		for property in instance_handler.instance_property_array:
			if property.socket_number == game_state.MAIN_active_first_socket_to_die:
				first_socket_to_die_is_ingame = true
				break
		if first_socket_to_die_is_ingame:
			socket_to_return = game_state.MAIN_active_first_socket_to_die
			print("get first turn socket: ", socket_to_return)
			return socket_to_return
		else:
			pass
	var randindex = randi_range(0, intermed.instance_handler.instance_property_array.size() - 1)
	socket_to_return = intermed.instance_handler.instance_property_array[randindex].socket_number
	print("get first turn socket: ", socket_to_return)
	return socket_to_return

func GetNextTurn_Socket(current_turn_socket: int, direction_string: String = "CW"):
	var socket_array = []
	for i in intermed.instance_handler.instance_property_array:
		var appended = false
		if i.health_current != 0:
			socket_array.append(i.socket_number)
			appended = true
		if i.socket_number == current_turn_socket:
			if !appended:
				socket_array.append(i.socket_number)
	socket_array.sort()
	print("socket array sorted: ", socket_array)
	var next_socket = 0
	var index = 0
	if game_state.MAIN_active_turn_order == "CW":
		for i in range(socket_array.size()):
			if socket_array[i] == current_turn_socket:
				index = i + 1
				if index > socket_array.size() - 1: index = 0
				break
	if game_state.MAIN_active_turn_order == "CCW":
		for i in range(socket_array.size()):
			if socket_array[i] == current_turn_socket:
				index = i - 1
				if index < 0: index = socket_array.size() - 1
				break
	print("pulled index: ", index)
	print("current turn socket: ", current_turn_socket, " next turn socket by index: ", socket_array[index])
	next_socket = socket_array[index]
	return next_socket

func GenerateRandomRound():
	var num_of_users = instance_handler.instance_property_array.size()
	print("instance property array size: ", instance_handler.instance_property_array.size())
	print("num of users: ", num_of_users)
	var health_r1; var health_r2
	match num_of_users:
		2:
			health_r1 = 3
			health_r2 = 4
		3:
			health_r1 = 4
			health_r2 = 5
		4:
			health_r1 = 3
			health_r2 = 5
		_:
			health_r1 = 1
			health_r2 = 1

	var starting_health = 0
	var setting_random = false
	var set = 0
	for round in GlobalVariables.active_match_customization_dictionary.round_property_array:
		if round.round_index == game_state.MAIN_active_round_index:
			if round.starting_health == -1:
				setting_random = true
			else:
				set = round.starting_health

	if setting_random:
		starting_health = randi_range(health_r1, health_r2)
	else:
		starting_health = set

	var dict = {
		"starting_health": starting_health, 
	}
	game_state.MAIN_active_round_dict = dict

func GenerateRandomSequence():
	var printing = true
	var num_of_users = instance_handler.instance_property_array.size()
	if printing: print("generating random sequence with number of users: ", num_of_users)
	var selected_sequence_batch_array_copy_in_use = GetSelectedSequenceCopy(num_of_users)

	if selected_sequence_batch_array_copy_in_use.is_empty():
		game_state.MakeSequenceCopies()
		selected_sequence_batch_array_copy_in_use = GetSelectedSequenceCopy(num_of_users)

	var randomly_selected_sequence = selected_sequence_batch_array_copy_in_use[randi_range(0, selected_sequence_batch_array_copy_in_use.size() - 1)]
	selected_sequence_batch_array_copy_in_use.erase(randomly_selected_sequence)

	var sequence = []
	var setting_random = false
	var blanks = 0
	var lives = 0
	for round in GlobalVariables.active_match_customization_dictionary.round_property_array:
		if round.round_index == game_state.MAIN_active_round_index:
			for shell_load in round.shell_load_properties:
				if shell_load.sequence_index == game_state.MAIN_active_sequence_index_to_pull:
					if shell_load.number_of_blanks == -1 or shell_load.number_of_lives == -1:
						setting_random = true
					else:
						blanks = shell_load.number_of_blanks
						lives = shell_load.number_of_lives

	if setting_random:
		for i in randomly_selected_sequence.amount_shell_live:
			sequence.append("live")
		for i in randomly_selected_sequence.amount_shell_blank:
			sequence.append("blank")
	else:
		for i in lives:
			sequence.append("live")
		for i in blanks:
			sequence.append("blank")

	var shuffling_sequence = false
	var flip = randi_range(0, 1)
	var sequence_visible_shuffled = sequence.duplicate()
	var sequence_in_shotgun = sequence.duplicate();sequence_in_shotgun.shuffle()
	var dict = {
		"sequence": sequence, 
		"sequence_visible": sequence_visible_shuffled, 
		"sequence_in_shotgun": sequence_in_shotgun, 
		"shuffling_visible_sequence": shuffling_sequence, 
	}
	var dict_send = dict.duplicate(true)
	dict_send.erase("sequence_in_shotgun")
	game_state.MAIN_active_sequence_dict = dict
	game_state.MAIN_active_sequence_dict_send = dict_send

func GetSelectedSequenceCopy(for_user_amount: int):
	var selected
	match for_user_amount:
		2:
			selected = game_state.MAIN_active_sequence_batch_array_copy_in_use_for_2
		3:
			selected = game_state.MAIN_active_sequence_batch_array_copy_in_use_for_3
		4:
			selected = game_state.MAIN_active_sequence_batch_array_copy_in_use_for_4
		_:
			selected = game_state.MAIN_active_sequence_batch_array_copy_in_use_for_2
	return selected

func GetRandomItemGrabAmount():
	var num_of_users = instance_handler.instance_property_array.size()

	var item_r1; var item_r2
	match num_of_users:
		2:
			item_r1 = 2
			item_r2 = 4
		3:
			item_r1 = 3
			item_r2 = 5
		4:
			item_r1 = 3
			item_r2 = 4
		_:
			item_r1 = 2
			item_r2 = 4

	var num_of_items_to_grab = 0
	var setting_random = false
	var set = 0

	for round in GlobalVariables.active_match_customization_dictionary.round_property_array:
		if round.round_index == game_state.MAIN_active_round_index:
			for shell_load in round.shell_load_properties:
				if shell_load.sequence_index == game_state.MAIN_active_sequence_index_to_pull:
					if shell_load.number_of_items == -1:
						setting_random = true
					else:
						set = shell_load.number_of_items

	if setting_random:
		num_of_items_to_grab = randi_range(item_r1, item_r2)
	else:
		num_of_items_to_grab = set
	game_state.MAIN_active_num_of_items_to_grab = num_of_items_to_grab

func GetDirection(self_socket, selected_socket):
	var direction = ""
	match self_socket:
		0:
			match selected_socket:
				0: direction = "self"
				1: direction = "left"
				2: direction = "forward"
				3: direction = "right"
		1:
			match selected_socket:
				0: direction = "right"
				1: direction = "self"
				2: direction = "left"
				3: direction = "forward"
		2:
			match selected_socket:
				0: direction = "forward"
				1: direction = "right"
				2: direction = "self"
				3: direction = "left"
		3:
			match selected_socket:
				0: direction = "left"
				1: direction = "forward"
				2: direction = "right"
				3: direction = "self"
	return direction
