extends Node

const MOD_DIR: = "mrpauk335-ModMenu"
const LOG_NAME: = "mrpauk335-ModMenu:Main"

func _init() -> void :
    ModLoaderLog.info("Init", LOG_NAME)

    ModLoaderMod.add_hook(_on_game_state_ready_hook, "res://multiplayer/scripts/global scripts/MP_GameStateManager.gd", "_ready")

func _on_game_state_ready_hook(chain: ModLoaderHookChain) -> void :
    var gsm = chain.reference_object
    chain.execute_next()



    _inject_mod_menu(gsm)

func _inject_mod_menu(gsm):


    var ModMenuClass = load("res://multiplayer/scripts/user scripts/MP_ModMenu.gd")
    if ModMenuClass:
        var menu_instance = ModMenuClass.new(gsm)
        gsm.add_child(menu_instance)
        gsm.mod_menu = menu_instance
        ModLoaderLog.info("Mod Menu injected successfully.", LOG_NAME)
    else:
        ModLoaderLog.error("Could not load MP_ModMenu.gd!", LOG_NAME)
