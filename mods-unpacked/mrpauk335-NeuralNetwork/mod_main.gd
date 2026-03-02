extends Node

const MOD_DIR: = "mrpauk335-NeuralNetwork"
const LOG_NAME: = "mrpauk335-NeuralNetwork:Main"

func _init() -> void :
    ModLoaderLog.info("Init", LOG_NAME)

    ModLoaderMod.add_hook(_on_round_manager_ready, "res://multiplayer/scripts/global scripts/MP_RoundManager.gd", "_ready")

func _on_round_manager_ready(chain: ModLoaderHookChain) -> void :
    var rm = chain.reference_object
    chain.execute_next()

    if !rm.bot_turn_started.is_connected(_on_bot_turn_started):
        rm.bot_turn_started.connect(_on_bot_turn_started)
        ModLoaderLog.info("Connected to bot_turn_started signal.", LOG_NAME)

func _on_bot_turn_started(properties: MP_UserInstanceProperties) -> void :
    var rm = properties.intermediary.roundManager
    var game_state = properties.intermediary.game_state

    var bot_think_delay1 = 0.4
    if GlobalVariables.mp_auto_battler_enabled: bot_think_delay1 = 0.1
    await get_tree().create_timer(bot_think_delay1, false).timeout


    var bot_health = properties.health_current
    var sequence = game_state.MAIN_active_sequence_dict.get("sequence_in_shotgun", [])
    var live_count = 0
    var blank_count = 0
    for s in sequence:
        if s == "live": live_count += 1
        else: blank_count += 1


    var alive_opponents = []
    for prop in properties.intermediary.instance_handler.instance_property_array:
        if prop.socket_number != properties.socket_number and prop.health_current > 0:
            alive_opponents.append(prop)

    if alive_opponents.size() == 0:
        properties.is_bot_thinking = false
        return

    var random_opponent = alive_opponents[randi() % alive_opponents.size()]
    var opponent_socket = random_opponent.socket_number
    var opponent_health = random_opponent.health_current

    var item_counts = properties.item_manager.GetAllItemCounts()
    var saw_active = 1 if game_state.get("MAIN_barrel_sawed_off") else 0

    var opponent_handcuffs = random_opponent.item_manager.GetItemCount(3)
    var opponent_jammed = 1 if random_opponent.is_jammed else 0


    var exec_args = [
        ProjectSettings.globalize_path("res://ai_bridge.py"), 
        str(opponent_health), 
        str(bot_health), 
        str(live_count), 
        str(blank_count), 
        "0", 
        str(saw_active), 
        str(item_counts["beer"]), 
        str(item_counts["handcuffs"]), 
        str(item_counts["cigarettes"]), 
        str(item_counts["magnifying glass"]), 
        str(item_counts["handsaw"]), 
        str(item_counts["burner phone"]), 
        str(opponent_jammed)
    ]

    var output = []
    OS.execute("python", exec_args, output, true)

    var selected_action = 0
    if output.size() > 0:
        var result_str = output[0].strip_edges()
        if result_str.is_valid_int():
            selected_action = result_str.to_int()

    await get_tree().create_timer(0.4, false).timeout

    if selected_action == 0:
        await rm._bot_simulate_shoot(properties, opponent_socket)
    elif selected_action == 1:
        await rm._bot_simulate_shoot(properties, properties.socket_number)
    else:
        var item_id_map = {2: 5, 3: 3, 4: 4, 5: 2, 6: 1, 7: 6, 8: 8, 9: 9, 10: 10}
        var target_item_id = item_id_map.get(selected_action, -1)
        var found_index = -1

        if target_item_id != -1:
            for i in range(properties.user_inventory.size()):
                var item_dict = properties.user_inventory[i]
                if item_dict != {} and item_dict.get("item_id") == target_item_id:
                    found_index = i
                    break

        if found_index != -1:
            await rm._bot_simulate_item_use(properties, target_item_id, found_index)
        else:
            await rm._bot_simulate_shoot(properties, opponent_socket)

    properties.is_bot_thinking = false
