extends Node

var currentVersion_nr = "v2.2.0"
var currentVersion_hotfix = 7
var using_steam = true
var mp_bot_count = 0
var mp_player_ai_enabled = false
var mp_auto_battler_enabled = false
var ai_mode = 1

var currentVersion = ""
var versuffix_steam = " (STEAM)"
var versuffix_itch = " (ITCH.IO)"

var discord_link = "https://discord.gg/UdjMNaKkQe"

var using_gl = false
var controllerEnabled = false
var music_enabled = true
var current_button_hovered_over: Control

var colorblind = false
var colorblind_color = Color(1, 1, 0)
var greyscale_death = false
var looping_input_main = false
var looping_input_secondary = false
var cursor_state_after_toggle = false

var default_color_live = Color(1, 0.28, 0.29)
var default_color_blank = Color(0.29, 0.5, 1)
var colorblind_color_live = Color(1, 1, 1)
var colorblind_color_blank = Color(0.34, 0.34, 0.34)

var mp_debugging = false
var mp_printing_to_console = true
var mp_debug_keys_enabled = false
var printing_packets = true
var sending_lobby_change_alerts_to_console = false
var forcing_lobby_enter_from_main_menu = false
var message_to_forward = ""
var original_volume_linear_interaction
var original_volume_linear_music
var debug_round_index_to_end_game_at: int
var disband_lobby_after_exiting_main_scene = false
var exiting_to_lobby_after_inactivity = false
var timeouts_enabled = false
var skipping_intro = false
var lobby_id_found_in_command_line = 0
var running_short_intro_in_lobby_scene: bool = false
var command_line_checked = false
var version_to_check: String = ""
var steam_id_version_checked_array: Array[int]
var returning_to_main_menu_on_popup_close: bool
var active_match_customization_dictionary: Dictionary
var stashed_match_customization_dictionary: Dictionary
var previous_match_customization_differences: Dictionary

var debug_match_customization = {
    "number_of_rounds": 3, 
    "skipping_intro": false, 
    "round_property_array": [
        {
            "round_index": 0, 
            "starting_health": -1, 
            "item_properties": [
                {
                    "item_id": 1, 
                    "max_per_player": 2, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 2, 
                    "max_per_player": 2, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 3, 
                    "max_per_player": 1, 
                    "max_on_table": 1, 
                    "is_ingame": true}, 
                {
                    "item_id": 4, 
                    "max_per_player": 1, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 5, 
                    "max_per_player": 8, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 6, 
                    "max_per_player": 8, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 8, 
                    "max_per_player": 4, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 9, 
                    "max_per_player": 4, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 10, 
                    "max_per_player": 1, 
                    "max_on_table": 2, 
                    "is_ingame": true}], 
            "shell_load_properties": [
                {
                    "sequence_index": 0, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, 
                {
                    "sequence_index": 1, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, 
                {
                    "sequence_index": 2, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, 
                {
                    "sequence_index": 3, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, ]}, 
        {
            "round_index": 1, 
            "starting_health": -1, 
            "item_properties": [
                {
                    "item_id": 1, 
                    "max_per_player": 2, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 2, 
                    "max_per_player": 2, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 3, 
                    "max_per_player": 1, 
                    "max_on_table": 1, 
                    "is_ingame": true}, 
                {
                    "item_id": 4, 
                    "max_per_player": 1, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 5, 
                    "max_per_player": 8, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 6, 
                    "max_per_player": 8, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 8, 
                    "max_per_player": 4, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 9, 
                    "max_per_player": 4, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 10, 
                    "max_per_player": 1, 
                    "max_on_table": 2, 
                    "is_ingame": true}], 
            "shell_load_properties": [
                {
                    "sequence_index": 0, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, 
                {
                    "sequence_index": 1, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, 
                {
                    "sequence_index": 2, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, 
                {
                    "sequence_index": 3, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, ]
        }, 
        {
            "round_index": 2, 
            "starting_health": -1, 
            "item_properties": [
                {
                    "item_id": 1, 
                    "max_per_player": 2, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 2, 
                    "max_per_player": 2, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 3, 
                    "max_per_player": 1, 
                    "max_on_table": 1, 
                    "is_ingame": true}, 
                {
                    "item_id": 4, 
                    "max_per_player": 1, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 5, 
                    "max_per_player": 8, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 6, 
                    "max_per_player": 8, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 8, 
                    "max_per_player": 4, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 9, 
                    "max_per_player": 4, 
                    "max_on_table": 32, 
                    "is_ingame": true}, 
                {
                    "item_id": 10, 
                    "max_per_player": 1, 
                    "max_on_table": 2, 
                    "is_ingame": true}], 
            "shell_load_properties": [
                {
                    "sequence_index": 0, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, 
                {
                    "sequence_index": 1, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, 
                {
                    "sequence_index": 2, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, 
                {
                    "sequence_index": 3, 
                    "number_of_blanks": -1, 
                    "number_of_lives": -1, 
                    "number_of_items": -1, }, ]
        }
        ]
}

func _ready():
    if using_steam: currentVersion = currentVersion_nr + versuffix_steam
    else: currentVersion = currentVersion_nr + versuffix_itch
    debug_round_index_to_end_game_at = 2
    original_volume_linear_interaction = db_to_linear(AudioServer.get_bus_volume_db(3))
    original_volume_linear_music = db_to_linear(AudioServer.get_bus_volume_db(1))
    version_to_check = currentVersion_nr + "." + str(currentVersion_hotfix)
    print("running full version name: ", version_to_check)
    if GlobalVariables.mp_debugging:
        TranslationServer.set_locale("EN")
        active_match_customization_dictionary = debug_match_customization

func _unhandled_input(event):
    if mp_debugging or mp_debug_keys_enabled:
        if event.is_action_pressed("debug_q"):
            SwapLanguage(false)
        if event.is_action_pressed("debug_e"):
            SwapLanguage(true)
        if event.is_action_pressed("-"):
            Engine.time_scale = 0.05
        if event.is_action_pressed(","):
            Engine.time_scale = 1
        if event.is_action_pressed("."):
            Engine.time_scale = 10
        if event.is_action_pressed("end"):
            Engine.time_scale = 0

var language_array = ["EN", "EE", "RU", "ES LATAM", "ES", "FR", "IT", "JA", "KO", "PL", "PT", "DE", "TR", "UA", "ZHS", "ZHT"]
var index = 0
func SwapLanguage(dir: bool):
    if dir:
        if index == language_array.size() - 1:
            index = 0
        else:
            index += 1
    else:
        if index == 0:
            index = language_array.size() - 1
        else:
            index -= 1
    TranslationServer.set_locale(language_array[index])
    print("setting locale to: ", language_array[index])

func LogAnalytics(winner_name: String, rounds: int, winner_socket: int):
    var path = "user://game_analytics.log"
    var file = FileAccess.open(path, FileAccess.READ_WRITE)
    if file == null:
        file = FileAccess.open(path, FileAccess.WRITE)
    else:
        file.seek_end()

    var time = Time.get_datetime_dict_from_system()
    var time_str = "%04d-%02d-%02d %02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
    var log_line = "[%s] WINNER: %s (Socket %d) | ROUNDS: %d\n" % [time_str, winner_name, winner_socket, rounds + 1]

    file.store_string(log_line)
    file.close()
    print("[ANALYTICS] Result logged: ", log_line)
