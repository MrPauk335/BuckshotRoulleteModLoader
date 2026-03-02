class_name MenuManager extends Node

@export var parent_main: Control
@export var parent_creds: Control
@export var parent_audiovideo: Control
@export var parent_language: Control
@export var parent_controller: Control
@export var parent_suboptions: Control
@export var parent_rebinding: Control

@export var title: Control
@export var animator_intro: AnimationPlayer
@export var speaker_music: AudioStreamPlayer2D
@export var speaker_start: AudioStreamPlayer2D
@export var mouseblocker: Control

@export var buttons: Array[ButtonClass]
@export var screens: Array[Control]
@export var waterfalls: Array[AnimationPlayer]

@export var cursor: Node
@export var controller: Node
@export var optionmanager: Node
@export var savefile: Node
@export var anim_creds: AnimationPlayer

var parent_mods: Control
var mods_container: Control
var mod_template_btn: Control
var mod_template_label: Label
var mods_restart_btn: ButtonClass
var mods_folder_btn: ButtonClass

var viewing_intro = false

func _ready():
    CheckCommandLine()
    if GlobalVariables.lobby_id_found_in_command_line != 0 && !GlobalVariables.command_line_checked:
        print("lobby id found in command line. skipping intro")
        FinishIntro()
        GlobalVariables.command_line_checked = true
    else:
        Intro()


    for b in buttons:
        if b == null: continue
        print("[MENU] Found button with alias: ", b.alias)
        if b.alias == "start":
            if b.is_connected("is_pressed", Start): b.disconnect("is_pressed", Start)
            b.connect("is_pressed", Start)
        if b.alias == "multiplayer" or b.alias == "start multiplayer":
            if b.is_connected("is_pressed", StartMultiplayer): b.disconnect("is_pressed", StartMultiplayer)
            b.connect("is_pressed", StartMultiplayer)
        if b.alias == "sub options" or b.alias == "options":
            if b.is_connected("is_pressed", SubOptions): b.disconnect("is_pressed", SubOptions)
            b.connect("is_pressed", SubOptions)
        if b.alias == "credits":
            if b.is_connected("is_pressed", Credits): b.disconnect("is_pressed", Credits)
            b.connect("is_pressed", Credits)
        if b.alias == "exit":
            if b.is_connected("is_pressed", Exit): b.disconnect("is_pressed", Exit)
            b.connect("is_pressed", Exit)


    _setup_ai_mode_button()
    _setup_mods_button()

var ai_mode_btn: Label
func _setup_ai_mode_button():


    pass

func _on_ai_mode_pressed():
    GlobalVariables.ai_mode += 1
    if GlobalVariables.ai_mode > 2:
        GlobalVariables.ai_mode = 0
    _update_ai_mode_text()

func _update_ai_mode_text():
    var mode_text = "AI: OFF"
    if GlobalVariables.ai_mode == 1: mode_text = "AI: ONLY DEALER"
    elif GlobalVariables.ai_mode == 2: mode_text = "AI: DEALER & PLAYER"
    if ai_mode_btn: ai_mode_btn.text = mode_text

var _mods_btn_ref: Control
var _mods_label_ref: Control
var _options_btn_ref: Control
var _options_label_ref: Control

func _process(_delta):
    T()
    if viewing_intro:
        if is_instance_valid(_mods_btn_ref) and is_instance_valid(_options_btn_ref):
            _mods_btn_ref.modulate.a = _options_btn_ref.modulate.a
        if is_instance_valid(_mods_label_ref) and is_instance_valid(_options_label_ref):
            _mods_label_ref.modulate.a = _options_label_ref.modulate.a
    else:
        # Ensure buttons are visible after intro
        if is_instance_valid(_mods_btn_ref): _mods_btn_ref.modulate.a = 0 # Hide the pill background
        if is_instance_valid(_mods_label_ref): _mods_label_ref.modulate.a = 1 # Show the text

func _force_opacity(node: Node):
    if node is CanvasItem:
        node.modulate = Color(1, 1, 1, 1)
        node.self_modulate = Color(1, 1, 1, 1)
        node.visible = true
    for child in node.get_children():
        _force_opacity(child)

func CheckCommandLine():
    var arguments = OS.get_cmdline_args()
    for argument in arguments:
        if (arguments.size() > 0):


            pass

        if argument == "+connect_lobby":
            GlobalSteam.LOBBY_INVITE_ARG = true

var failsafed = true
var fs2 = false
func _input(event):
    if (event.is_action_pressed("ui_cancel") && failsafed):
        if (currentScreen != "main"): ReturnToLastScreen()
    if (event.is_action_pressed("exit game") && failsafed):
        if (currentScreen != "main"): ReturnToLastScreen()
    if (event.is_action_pressed("exit game") && !fs2 && viewing_intro):
        SkipIntro()
        fs2 = true

func Intro():
    cursor.SetCursor(false, false)
    if GlobalVariables.lobby_id_found_in_command_line != 0 && !GlobalVariables.command_line_checked:
        print("lobby id found in command line. dont run the menu intro")
        return
    viewing_intro = true
    speaker_music.play()
    animator_intro.play("splash screen")
    c = true

func SkipIntro():
    c = false
    animator_intro.stop()
    animator_intro.play("skip intro")
    FinishIntro()

func FinishIntro():
    viewing_intro = false
    mouseblocker.visible = false
    cursor.SetCursor(true, false)
    controller.settingFilter = true
    controller.SetMainControllerState(controller.controller_currently_enabled)
    if (cursor.controller_active): firstFocus_main.grab_focus()
    controller.previousFocus = firstFocus_main
    assigningFocus = true

var t = 0
var c = false
var fs = false
func T():
    if c: t += get_process_delta_time()
    if t > 9 && !fs:
        FinishIntro()
        fs = true

func Buttons(state: bool):
    if ( !state):
        for i in buttons:
            if i:
                i.isActive = false
                i.SetFilter("ignore")
    else:
        for i in buttons:
            if i:
                i.isActive = true
                i.SetFilter("stop")

@export var firstFocus_main: Control
@export var firstFocus_subOptions: Control
@export var firstFocus_credits: Control
@export var firstFocus_audioVideo: Control
@export var firstFocus_language: Control
@export var firstFocus_controller: Control
@export var firstFocus_rebinding: Control

var assigningFocus = false
var lastScreen = "main"
var currentScreen = "main"
func Show(what: String):
    lastScreen = currentScreen
    currentScreen = what
    var focus
    if title: title.visible = false
    var parent_menu = get_node_or_null("/root/menu")
    if parent_menu:
        var logo = parent_menu.find_child("title", true, false)
        if logo: logo.visible = false
        var logo2 = parent_menu.find_child("title screen", true, false)
        if logo2: logo2.visible = false
    for screen in screens:
        if screen: screen.visible = false
    if (what == "main" or what == "sub options"):
        if title: title.visible = true
        if parent_menu:
            var logo = parent_menu.find_child("title", true, false)
            if logo: logo.visible = true
            var logo2 = parent_menu.find_child("title screen", true, false)
            if logo2: logo2.visible = true
    match (what):
        "main":
            parent_main.visible = true
            focus = firstFocus_main
        "sub options":
            parent_suboptions.visible = true
            focus = firstFocus_subOptions
        "credits":
            parent_creds.visible = true
            focus = firstFocus_credits
            anim_creds.play("RESET")
            anim_creds.play("show credits")
        "audio video":
            parent_audiovideo.visible = true
            focus = firstFocus_audioVideo
        "language":
            parent_language.visible = true
            focus = firstFocus_language
        "controller":
            parent_controller.visible = true
            focus = firstFocus_controller
        "rebind controls":
            parent_rebinding.visible = true
            focus = firstFocus_rebinding
        "mods":
            if parent_mods: parent_mods.visible = true
            focus = firstFocus_credits
    if (assigningFocus):
        if (cursor.controller_active and focus): focus.grab_focus()
        controller.previousFocus = focus

func ReturnToLastScreen():
    print("return to last screen")
    if currentScreen == "credits": anim_creds.play("RESET")
    if (currentScreen) == "sub options": lastScreen = "main"
    if (currentScreen) == "mods": lastScreen = "main"
    if (currentScreen) == "rebind controls": lastScreen = "sub options"
    if (currentScreen == "audio video" or currentScreen == "language" or currentScreen == "controller" or currentScreen == "rebind controls"): optionmanager.SaveSettings()
    Show(lastScreen)
    ResetButtons()

func ResetButtons():


    cursor.SetCursorImage("point")

func Start():
    Buttons(false)
    ResetButtons()
    for screen in screens:
        if screen: screen.visible = false
    if is_instance_valid(title): title.visible = false
    controller.previousFocus = null
    speaker_music.stop()
    animator_intro.play("snap")
    for w in waterfalls: w.pause()
    speaker_start.play()
    cursor.SetCursor(false, false)
    savefile.ClearSave()
    await get_tree().create_timer(4, false).timeout
    print("changing scene to: main")
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func StartMultiplayer():
    if !GlobalSteam.ONLINE:
        print("[MENU] Multiplayer Error: Steam is not ONLINE. Showing popup.")
        GlobalVariables.message_to_forward = tr("MP_UI LOBBY NO CONNECTION")
        GlobalVariables.returning_to_main_menu_on_popup_close = true
        GlobalVariables.running_short_intro_in_lobby_scene = true

        return

    print("[MENU] Starting multiplayer transition...")
    Buttons(false)
    ResetButtons()
    for screen in screens:
        if screen: screen.visible = false
    if is_instance_valid(title): title.visible = false
    controller.previousFocus = null
    speaker_music.stop()
    animator_intro.play("snap")
    for w in waterfalls:
        if is_instance_valid(w): w.pause()
    speaker_start.play()
    cursor.SetCursor(false, false)
    savefile.ClearSave()
    var mp_start_delay = 4.0
    if GlobalVariables.mp_auto_battler_enabled: mp_start_delay = 0.1
    print("[MENU] Waiting for timer: ", mp_start_delay)
    await get_tree().create_timer(mp_start_delay, false).timeout
    print("[MENU] Timer finished. Changing scene to lobby...")
    var result = get_tree().change_scene_to_file("res://multiplayer/scenes/mp_lobby.tscn")
    print("[MENU] Scene change result: ", result)

func _setup_mods_button():
    print("[MODS] Starting setup...")

    var options_wrapper: ButtonClass = null
    for b in buttons:
        if b and b.alias == "sub options":
            options_wrapper = b
            break

    if not options_wrapper:
        print("[MODS] Error: Could not find Options button")
        return

    var options_btn = options_wrapper.get_parent()
    var options_label = options_wrapper.ui
    var parent_container = options_btn.get_parent()


    var menu_items = []
    for b in buttons:
        if b and is_instance_valid(b) and b.get_parent() and b.get_parent().get_parent() == parent_container:
            var btn = b.get_parent()
            var lbl = b.ui
            menu_items.append({"btn": btn, "lbl": lbl, "wrapper": b})


    menu_items.sort_custom( func(a, b): return a.btn.position.y < b.btn.position.y)


    var gap = 38.0
    if menu_items.size() >= 2:
        gap = menu_items[1].btn.position.y - menu_items[0].btn.position.y


    var mods_btn = options_btn.duplicate()
    mods_btn.name = "MODS_BUTTON"
    parent_container.add_child(mods_btn)

    var mods_label = options_label.duplicate()
    mods_label.name = "MODS_LABEL"
    parent_container.add_child(mods_label)
    mods_label.text = "MODS"


    var insert_idx = -1
    for i in range(menu_items.size()):
        if menu_items[i].wrapper == options_wrapper:
            insert_idx = i
            break


    var start_y = menu_items[0].btn.position.y
    var current_pos_y = start_y

    for i in range(menu_items.size()):
        var item = menu_items[i]
        item.btn.position.y = current_pos_y
        if item.lbl: item.lbl.position.y = current_pos_y
        current_pos_y += gap


        if i == insert_idx:
            mods_btn.position = options_btn.position
            mods_btn.position.y = current_pos_y
            mods_label.position = options_label.position
            mods_label.position.y = current_pos_y
            current_pos_y += gap


    mods_btn.self_modulate.a = 0
    mods_btn.mouse_filter = Control.MOUSE_FILTER_STOP
    mods_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    _mods_btn_ref = mods_btn
    _mods_label_ref = mods_label
    _options_btn_ref = options_btn
    _options_label_ref = options_label


    var mods_wrapper = _find_button_wrapper_recursive(mods_btn)
    if mods_wrapper:
        mods_wrapper.ui = mods_label
        mods_wrapper.t = mods_label if mods_label is Label else null
        mods_wrapper.adding_cursor = true
        mods_wrapper.alias = "mods"
        mods_wrapper.isActive = true
        mods_wrapper.isDynamic = true
        mods_wrapper.playing = true
        mods_btn.modulate.a = 0

        for connection in mods_wrapper.get_signal_connection_list("is_pressed"):
            mods_wrapper.disconnect("is_pressed", connection["callable"])
        mods_wrapper.connect("is_pressed", ShowMods)

        if mods_wrapper.t:
            mods_wrapper.t.text = "MODS"
            mods_wrapper.orig = "MODS"

        if not mods_wrapper in buttons:
            buttons.append(mods_wrapper)
        
        # Initial visibility
        mods_btn.modulate.a = 0
        mods_label.modulate.a = 0

    mods_btn.visible = true
    mods_label.visible = true


    var version_node = parent_container.get_node_or_null("version")
    if version_node and version_node is Label:
        var base_version = GlobalVariables.currentVersion_nr + "." + str(GlobalVariables.currentVersion_hotfix)
        version_node.text = base_version + " (MOD LOADER)"
        version_node.modulate = Color(0.7, 0.9, 1.0)


    _setup_mods_screen()
    print("[MODS] Setup complete.")

func _find_label_recursive(node: Node) -> Label:
    if node is Label: return node
    for child in node.get_children():
        var found = _find_label_recursive(child)
        if found: return found
    return null

func _get_text_width(label: Label) -> float:
    if not label: return 200.0
    var font = label.get_theme_font("font")
    var font_size = label.get_theme_font_size("font_size")
    if not font: return 200.0


    var width = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


    if label.has_theme_constant_override("letter_spacing"):
        var spacing = label.get_theme_constant("letter_spacing")
        width += spacing * (label.text.length() - 1)

    return width

func _setup_mods_screen():

    if parent_creds and not parent_mods:

        parent_mods = Control.new()
        parent_mods.name = "parent_mods"
        parent_mods.custom_minimum_size = Vector2(960, 540)
        parent_mods.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        var bg_color = ColorRect.new()
        bg_color.color = Color(0, 0, 0, 0.45)
        bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        parent_mods.add_child(bg_color)
        parent_main.get_parent().add_child(parent_mods)

        if not parent_mods in screens:
            screens.append(parent_mods)

        parent_mods.visible = false


        var template_wrapper: ButtonClass = null
        for child in parent_main.get_children():
            var wrapper = _find_button_wrapper_recursive(child)
            if wrapper and not child.name.to_lower().contains("mods"):
                template_wrapper = wrapper
                mod_template_btn = child.duplicate()
                parent_mods.add_child(mod_template_btn)

                if wrapper.ui:
                    mod_template_label = wrapper.ui.duplicate()
                    parent_mods.add_child(mod_template_label)
                break

        if mod_template_btn:

            mod_template_btn.position = Vector2(-9999, -9999)
            if mod_template_label: mod_template_label.position = Vector2(-9999, -9999)


            mods_container = Control.new()
            mods_container.name = "MODS_LIST_CONTAINER"
            parent_mods.add_child(mods_container)
            mods_container.position = mod_template_btn.position

            RefreshModList()
            _setup_mods_utility_buttons()


        _connect_back_button(parent_mods)

func _find_button_wrapper_recursive(node: Node) -> ButtonClass:
    if node is ButtonClass: return node
    for child in node.get_children():
        var found = _find_button_wrapper_recursive(child)
        if found: return found
    return null

func RefreshModList():
    if not mods_container: return


    if mods_container.has_meta("list_items"):
        for child in mods_container.get_meta("list_items"):
            if is_instance_valid(child):
                child.queue_free()
    mods_container.set_meta("list_items", [])

    var step = 28
    var current_y = 0

    var mod_loader_store = get_node_or_null("/root/ModLoaderStore")
    if not mod_loader_store: return

    var mods_data = mod_loader_store.mod_data
    var current_profile = ModLoaderUserProfile.get_current()

    for mod_id in mods_data:
        var mod = mods_data[mod_id]
        var is_active = mod.is_active


        var mod_is_internal = mod_id == "mrpauk335-AI_Bot" or mod_id == "mrpauk335-NeuralNetwork"
        if mod_is_internal and current_profile and not current_profile.mod_list.has(mod_id):
            is_active = false
            mod.is_active = false
            print("[MODS] Defaulting internal mod to OFF: ", mod_id)


        var mod_btn = mod_template_btn.duplicate()
        var mod_label = mod_template_label.duplicate() if mod_template_label else null


        var start_x = 60
        var start_y = 120


        var text_width = _get_text_width(mod_label)
        mod_btn.custom_minimum_size = Vector2(text_width, 22)
        mod_btn.size = Vector2(text_width, 22)

        mod_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
        mod_btn.position = Vector2(start_x, start_y + current_y)

        if mod_label:
            mod_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
            mod_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
            mod_label.position = Vector2(start_x, start_y + current_y)
            mod_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

            mod_label.add_theme_constant_override("letter_spacing", -1)


        var wrapper = _find_button_wrapper_recursive(mod_btn)
        if wrapper and mod_label:
            var state_text = " [ON]" if is_active else " [OFF]"
            mod_label.text = mod_id + state_text

            wrapper.ui = mod_label
            wrapper.t = mod_label
            wrapper.orig = mod_label.text
            wrapper.adding_cursor = true

            wrapper.alias = "toggle_" + mod_id
            wrapper.isActive = true
            wrapper.isDynamic = true
            wrapper.playing = true

            for connection in wrapper.get_signal_connection_list("is_pressed"):
                wrapper.disconnect("is_pressed", connection["callable"])
            wrapper.connect("is_pressed", func(): ToggleMod(mod_id))

            if not wrapper in buttons:
                buttons.append(wrapper)

        parent_mods.add_child(mod_btn)
        if mod_label: parent_mods.add_child(mod_label)


        mod_btn.modulate.a = 0
        if mod_label:
            mod_label.modulate.a = 1
            mod_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


        if not mods_container.has_meta("list_items"):
            mods_container.set_meta("list_items", [])
        var list = mods_container.get_meta("list_items")
        list.append(mod_btn)
        if mod_label: list.append(mod_label)
        mods_container.set_meta("list_items", list)

        current_y += step

func ToggleMod(mod_id: String):
    print("[MODS] Toggling mod: ", mod_id)


    var current_profile = ModLoaderUserProfile.get_current()
    if not current_profile or not current_profile.mod_list.has(mod_id):
        print("[MODS] Error: Profile or mod not found")
        return

    var is_active = current_profile.mod_list[mod_id].is_active
    var new_state = !is_active

    if is_active:
        ModLoaderUserProfile.disable_mod(mod_id)
    else:
        ModLoaderUserProfile.enable_mod(mod_id)


    var mod_loader_store = get_node_or_null("/root/ModLoaderStore")
    if mod_loader_store and mod_loader_store.mod_data.has(mod_id):
        mod_loader_store.mod_data[mod_id].is_active = new_state



    for b in buttons:
        if b.alias == "toggle_" + mod_id:
            var state_text = " [ON]" if new_state else " [OFF]"
            var new_label_text = mod_id + state_text
            b.orig = new_label_text
            if b.t: b.t.text = "<  " + new_label_text + "  >"
            break


    if mods_restart_btn and mods_restart_btn.ui:
        mods_restart_btn.ui.text = "RESTART REQUIRED!"
        mods_restart_btn.ui.modulate = Color(1, 0.5, 0.5)

func _setup_mods_utility_buttons():

    var restart_node = mod_template_btn.duplicate()
    var restart_label = mod_template_label.duplicate() if mod_template_label else null

    var folder_node = mod_template_btn.duplicate()
    var folder_label = mod_template_label.duplicate() if mod_template_label else null

    var exit_node = mod_template_btn.duplicate()
    var exit_label = mod_template_label.duplicate() if mod_template_label else null

    mods_restart_btn = _find_button_wrapper_recursive(restart_node)
    mods_folder_btn = _find_button_wrapper_recursive(folder_node)
    var mods_exit_btn = _find_button_wrapper_recursive(exit_node)


    var setup_util = func(wrapper: ButtonClass, label: Node, label_text: String, alias: String, callback: Callable):
        if not wrapper: return
        if label:
            label.text = label_text
            label.mouse_filter = Control.MOUSE_FILTER_IGNORE
            label.add_theme_constant_override("letter_spacing", -1)
            wrapper.ui = label
            wrapper.t = label
            wrapper.orig = label_text
            wrapper.adding_cursor = true
        wrapper.alias = alias
        wrapper.isActive = true
        wrapper.isDynamic = true
        wrapper.connect("is_pressed", callback)
        if not wrapper in buttons:
            buttons.append(wrapper)

    setup_util.call(mods_restart_btn, restart_label, "RESTART GAME", "restart", func(): get_tree().quit())
    setup_util.call(mods_folder_btn, folder_label, "OPEN MOD FOLDER", "open_folder", func(): OS.shell_open(ProjectSettings.globalize_path("res://mods-unpacked")))
    setup_util.call(mods_exit_btn, exit_label, "BACK TO MENU", "exit_mods", ReturnToLastScreen)


    var vbox = VBoxContainer.new()
    vbox.name = "UTILITY_VBOX"
    parent_mods.add_child(vbox)


    vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    vbox.offset_bottom = -30
    vbox.offset_top = -180
    vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
    vbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
    vbox.add_theme_constant_override("separation", 15)


    var add_row = func(btn: Control, lbl: Label):
        var row = CenterContainer.new()
        vbox.add_child(row)


        var w = _get_text_width(lbl)
        btn.custom_minimum_size = Vector2(w, 22)
        btn.size = Vector2(w, 22)
        lbl.custom_minimum_size = Vector2(w, 22)
        lbl.size = Vector2(w, 22)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


        row.add_child(btn)
        row.add_child(lbl)


        btn.modulate.a = 0
        btn.mouse_filter = Control.MOUSE_FILTER_STOP
        lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        lbl.visible = true
        btn.visible = true
        _force_opacity(lbl)

    add_row.call(restart_node, restart_label)
    add_row.call(folder_node, folder_label)
    add_row.call(exit_node, exit_label)

func _connect_back_button(node: Node):
    if node is ButtonClass:
        if node.alias == "exit credits" or node.name.to_lower().contains("back") or node.name.to_lower().contains("exit"):
            for connection in node.get_signal_connection_list("is_pressed"):
                node.disconnect("is_pressed", connection["callable"])
            node.connect("is_pressed", ReturnToLastScreen)
    for child in node.get_children():
        _connect_back_button(child)

func ShowMods():
    Show("mods")
    ResetButtons()

func Credits():
    Show("credits")
    ResetButtons()

func Exit():
    get_tree().quit()

func DisableMenu():
    Buttons(false)
    cursor.SetCursor(false, false)

func ResetControls():
    optionmanager.ResetControls()
    ResetButtons()

func ToggleMusic():
    optionmanager.AdjustSettings_music()
func ToggleColorblind():
    optionmanager.ToggleColorblind()
func ToggleGreyscaleDeath():
    optionmanager.ToggleGreyscaleDeath()
func DiscordLink():
    OS.shell_open(GlobalVariables.discord_link)
func RebindControls():
    Show("rebind controls")
    ResetButtons()
func SubOptions():
    Show("sub options")
    ResetButtons()
func Options_AudioVideo():
    Show("audio video")
    ResetButtons()
func Options_Language():
    Show("language")
    ResetButtons()
func Options_Controller():
    Show("controller")
    ResetButtons()
    pass
func IncreaseVol():
    optionmanager.Adjust("increase")
func DecreaseVol():
    optionmanager.Adjust("decrease")
func SetWindowed():
    optionmanager.Adjust("windowed")
func SetFull():
    optionmanager.Adjust("fullscreen")
func ControllerEnable():
    optionmanager.Adjust("controller enable")
func ControllerDisable():
    optionmanager.Adjust("controller disable")
