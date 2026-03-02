class_name MP_ItemInteraction extends Node

@export var properties: MP_UserInstanceProperties
@export var pos_pickup_item: Node3D
@export var hands: MP_HandManager

@export var animator_items_firstperson: AnimationPlayer
@export var animator_items_thirdperson: AnimationPlayer
@export var shotgun: MP_ShotgunInteraction
@export var shell_branch_inspection: MP_ShellBranch
@export var jammer: MP_Jammer

var active_item_parent: Node3D
var active_pickup_indicator: MP_PickupIndicator
var active_interaction_branch: MP_InteractionBranch
var active_separate_lerp: MP_SeparateLerp
var active_id: int
var active_item_has_secondary_interaction: bool

var debug_index = -1
func _unhandled_input(event):
    if GlobalVariables.mp_debugging:
        if event.is_action_pressed("8") && properties.socket_number == properties.intermediary.game_state.MAIN_active_current_turn_socket:
            debug_index += 1
            InteractWithItemRequest(properties.user_inventory_instance_array[debug_index])
        if event.is_action_pressed("2"):
            if properties.socket_number == 1:
                var packet = {
                "packet category": "MP_PacketVerification", 
                "packet alias": "interact with item request", 
                "sent_from": "client", 
                "packet_id": 22, 
                "item_socket_number": 2, 
                "local_grid_index": 0, 
                "item_id": 2, 
                "stealing_item": true, 
                "sent_from_socket": 1, 
                }
                properties.intermediary.packets.PipeData(packet)

func InteractWithItemRequest(item_object_parent: Node3D, stealing_item: bool = false):
    properties.permissions.SetMainPermission(false)
    GetItemVariables(item_object_parent)
    var packet = {
    "packet category": "MP_PacketVerification", 
    "packet alias": "interact with item request", 
    "sent_from": "client", 
    "packet_id": 22, 
    "item_socket_number": active_interaction_branch.socket_number, 
    "local_grid_index": active_interaction_branch.local_grid_index, 
    "item_id": active_id, 
    "stealing_item": stealing_item, 
    "sent_from_socket": properties.socket_number, 
    }
    properties.intermediary.packets.send_p2p_packet_directly_to_host(GlobalSteam.STEAM_ID, packet)
    if GlobalVariables.mp_debugging: properties.intermediary.packets.PipeData(packet)

func RevertJammer():
    jammer.speaker_fp_jammer_bootup_idle.stop()
    jammer.speaker_tp_jammer_bootup_idle.stop()
    animator_items_firstperson.play("RESET")
    animator_items_thirdperson.play("RESET")

func ResetAnimations():
    animator_items_firstperson.play("RESET")
    animator_items_thirdperson.play("RESET")
    properties.is_interacting_with_item = false
    properties.is_on_secondary_interaction = false
    properties.is_viewing_jammer = false
    properties.is_on_jammer_selection = false
    jammer.looping = false
    jammer.Reset()

func InteractWIthItemRequest_Secondary(secondary_interaction_dictionary: Dictionary):
    var item_id = secondary_interaction_dictionary.values()[0]
    var packet = {
    "packet category": "MP_PacketVerification", 
    "packet alias": "secondary item interaction request", 
    "sent_from": "client", 
    "packet_id": 24, 
    "sent_from_socket": properties.socket_number, 
    "item_id": secondary_interaction_dictionary.item_id, 
    "has_exit_animation": false, 
    "item_selected_socket_number": 0, 
    "item_selected_local_grid_index": 0, 
    }
    match item_id:
        3:
            packet.item_selected_socket_number = secondary_interaction_dictionary.item_selected_socket_number
            packet.has_exit_animation = true
        8:
            packet.item_selected_local_grid_index = secondary_interaction_dictionary.item_selected_local_grid_index
            packet.has_exit_animation = false
    properties.intermediary.packets.send_p2p_packet_directly_to_host(GlobalSteam.STEAM_ID, packet)
    if GlobalVariables.mp_debugging: properties.intermediary.packets.PipeData(packet)

func ReceivePacket_InteractWithItem(packet: Dictionary):
    if packet.socket_number == properties.socket_number:
        properties.has_turn = false
        if packet.item_id == 8 or packet.item_id == 3:
            properties.has_turn = true
        properties.intermediary.game_state.MAIN_phone_verbal_shell = packet.phone_verbal_shell
        properties.intermediary.game_state.MAIN_phone_verbal_index = packet.phone_verbal_index
        properties.intermediary.game_state.MAIN_shell_to_eject = packet.current_shell_in_chamber
        properties.is_interacting_with_item = true
        if packet.stealing_item:
            properties.intermediary.game_state.StopTimeoutForSocket("adrenaline", properties.socket_number)
        if properties.is_active:
            InteractWithItem_FirstPerson(packet)
        else:
            InteractWithItem_ThirdPerson(packet)

func ReceivePacket_InteractWithItem_Secondary(packet: Dictionary):
    if packet.socket_number == properties.socket_number:
        properties.has_turn = false
        if packet.item_id == 3:
            properties.intermediary.game_state.StopTimeoutForSocket("jammer", properties.socket_number)
        if properties.is_active:
            InteractWithItem_FirstPerson_Secondary(packet)
        else:
            InteractWithItem_ThirdPerson_Secondary(packet)

func InteractWithItem_FirstPerson(packet: Dictionary):
    properties.permissions.SetMainPermission(false)
    if packet.stealing_item:
        properties.SetAdrenalineControllerPrompts(false)
        properties.permissions.SetItemPermissions(false, true)
        properties.is_stealing_item = false
        properties.is_on_secondary_interaction = false
    var local_grid_index = packet.local_grid_index
    var item_object: Node3D




    item_object = properties.intermediary.game_state.MAIN_inventory_by_socket[packet.item_socket_number][local_grid_index].item_instance
    RemoveItemFromInventory(local_grid_index, packet.item_socket_number)
    GetItemVariables(item_object)
    ChangeGameStateWithItem(active_id, packet)
    if !packet.stealing_item:
        animator_items_firstperson.play("RESET")
    else:
        properties.intermediary.filter.PanLowPass_In()
        PanCameraBack()
    await (PickupItem(active_item_parent))
    match active_id:
        1:
            shotgun.SetShotgunVisible_Global(false)
            properties.intermediary.game_state.MAIN_is_shotgun_held = true
            shotgun.SetShotgunVisible_Local(true)
        2:
            shotgun.SetShotgunVisible_Global(false)
            properties.intermediary.game_state.MAIN_is_shotgun_held = true
            shotgun.SetShotgunVisible_Local(true)
        3:
            properties.cam.moving = false
        4:
            pass
        5:
            shotgun.SetShotgunVisible_Global(false)
            properties.intermediary.game_state.MAIN_is_shotgun_held = true
            shotgun.SetShotgunVisible_Local(true)
        6:
            pass
        9:
            pass

    var active_stream: AudioStream
    for res in properties.intermediary.game_state.MAIN_item_resource_array:
        if res.id == active_id:
            active_stream = res.sound_initial_interaction_fp
    properties.item_manager.speaker_fp_initial_interaction.stream = active_stream
    properties.item_manager.speaker_fp_initial_interaction.play()

    var animation_name = "use item id " + str(active_id) + " first person"
    animator_items_firstperson.play(animation_name)
    if active_item_has_secondary_interaction: return
    await get_tree().create_timer(animator_items_firstperson.get_animation(animation_name).length, false).timeout
    match active_id:
        1:
            shotgun.SetShotgunVisible_Local(false)
            properties.intermediary.game_state.MAIN_is_shotgun_held = false
            shotgun.SetShotgunVisible_Global(true)
        2:
            shotgun.SetShotgunVisible_Local(false)
            properties.intermediary.game_state.MAIN_is_shotgun_held = false
            shotgun.SetShotgunVisible_Global(true)
        5:
            shotgun.SetShotgunVisible_Local(false)
            properties.intermediary.game_state.MAIN_is_shotgun_held = false
            shotgun.SetShotgunVisible_Global(true)
    await get_tree().create_timer(0.2, false).timeout
    EndItemInteraction(packet)

func InteractWithItem_ThirdPerson(packet: Dictionary):
    var local_grid_index = packet.local_grid_index
    var item_object: Node3D




    item_object = properties.intermediary.game_state.MAIN_inventory_by_socket[packet.item_socket_number][local_grid_index].item_instance
    if packet.stealing_item:
        properties.is_stealing_item = false
        properties.is_on_secondary_interaction = false
    RemoveItemFromInventory(local_grid_index, packet.item_socket_number)
    GetItemVariables(item_object)
    ChangeGameStateWithItem(active_id, packet)
    animator_items_thirdperson.play("RESET")
    await (hands.Hand_PickupItem(local_grid_index, active_id, active_interaction_branch.which_hand_to_grab_with, item_object))
    match active_id:
        1:
            shotgun.SetShotgunVisible_Global(false)
            properties.intermediary.game_state.MAIN_is_shotgun_held = true
            shotgun.SetShotgunVisible_Local(true)
        3:
            jammer.speaker_tp_jammer_bootup_idle.play()
        5:
            shotgun.SetShotgunVisible_Global(false)
            properties.intermediary.game_state.MAIN_is_shotgun_held = true
            shotgun.SetShotgunVisible_Local(true)

    var active_stream: AudioStream
    for res in properties.intermediary.game_state.MAIN_item_resource_array:
        if res.id == active_id:
            active_stream = res.sound_initial_interaction_tp
    properties.item_manager.speaker_tp_initial_interaction.stream = active_stream
    properties.item_manager.speaker_tp_initial_interaction.play()

    var animation_name = "use item id " + str(active_id) + " third person"
    animator_items_thirdperson.play(animation_name)
    if active_item_has_secondary_interaction && packet.item_id != 8:
        await get_tree().create_timer(animator_items_thirdperson.get_animation(animation_name).length, false).timeout
        var animation_name_idle = "use item id " + str(active_id) + " third person_secondary idle"
        animator_items_thirdperson.play(animation_name_idle)

        if properties.cpu_enabled:
            print("[BOT] Auto-concluding secondary interaction for item ", active_id)
            await get_tree().create_timer(1.0, false).timeout
            if active_id == 3:
                var valid_sockets = []
                for prop in properties.intermediary.instance_handler.instance_property_array:
                    if prop.socket_number != properties.socket_number and !prop.is_jammed and prop.health_current > 0:
                        valid_sockets.append(prop.socket_number)
                if valid_sockets.size() > 0:
                    var target = valid_sockets[randi() % valid_sockets.size()]
                    print("[BOT] TP Jammer auto-target socket: ", target)
                    var secondary_interact_dict = {
                        "item_id": 3, 
                        "item_selected_socket_number": target
                    }
                    InteractWIthItemRequest_Secondary(secondary_interact_dict)
                    return
            elif active_id == 8:

                pass
            EndItemInteraction(packet)
        return
    await get_tree().create_timer(animator_items_thirdperson.get_animation(animation_name).length, false).timeout
    match active_id:
        1:
            shotgun.SetShotgunVisible_Local(false)
            properties.intermediary.game_state.MAIN_is_shotgun_held = false
            shotgun.SetShotgunVisible_Global(true)
        5:
            shotgun.SetShotgunVisible_Local(false)
            properties.intermediary.game_state.MAIN_is_shotgun_held = false
            shotgun.SetShotgunVisible_Global(true)
    await get_tree().create_timer(0.2, false).timeout
    EndItemInteraction(packet)

func InteractWithItem_FirstPerson_Secondary(packet: Dictionary):
    if packet.has_exit_animation:
        var animation_name_exit = "use item id " + str(packet.item_id) + " first person_secondary exit"
        animator_items_firstperson.play(animation_name_exit)
    print("first person secondary packet item id: ", packet.item_id)
    match packet.item_id:
        3:
            properties.is_viewing_jammer = false
            var previous_camerw_socket = properties.cam.activeSocket
            var property_to_jam: MP_UserInstanceProperties = properties.GetSocketProperties(packet.item_selected_socket_number)
            if property_to_jam != null:
                var direction = properties.GetDirection(properties.socket_number, packet.item_selected_socket_number)
                jammer.speaker_fp_jammer_bootup_idle.stop()
                properties.cam.BeginLerp("opponent " + direction)
                await get_tree().create_timer(0.4, false).timeout
                property_to_jam.jammer_manager.Jammer_Enable()
                await get_tree().create_timer(0.4, false).timeout
                if !packet.ending_turn_after_item_use:
                    properties.cam.BeginLerp(previous_camerw_socket)
                properties.jammer_manager.looping = false
            EndItemInteraction(packet)
        8:
            var item_parent_to_steal: Node3D = properties.intermediary.game_state.MAIN_inventory_by_socket[packet.item_selected_socket_number][packet.item_selected_local_grid_index].item_instance
            print("item to steal: ", item_parent_to_steal.get_child(1).itemName)

func InteractWithItem_ThirdPerson_Secondary(packet: Dictionary):
    if packet.has_exit_animation:
        var animation_name_exit = "use item id " + str(packet.item_id) + " third person_secondary exit"
        animator_items_thirdperson.play(animation_name_exit)
    match packet.item_id:
        3:
            jammer.speaker_tp_jammer_bootup_idle.stop()
            properties.is_viewing_jammer = false
            var active_property: MP_UserInstanceProperties
            for property in properties.intermediary.instance_handler.instance_property_array:
                if property.is_active:
                    active_property = property
                    break
            var previous_camera_socket = active_property.cam.activeSocket
            var property_to_jam: MP_UserInstanceProperties = properties.GetSocketProperties(packet.item_selected_socket_number)
            if property_to_jam != null:
                var direction = properties.GetDirection(active_property.socket_number, packet.item_selected_socket_number)
                active_property.cam.BeginLerp("opponent " + direction)
                await get_tree().create_timer(0.4, false).timeout
                property_to_jam.jammer_manager.Jammer_Enable()
                await get_tree().create_timer(0.4, false).timeout
                if !packet.ending_turn_after_item_use:
                    active_property.cam.BeginLerp(previous_camera_socket)
            EndItemInteraction(packet)

func EndItemInteraction(with_packet: Dictionary):
    print("end item interaction with packet: ", with_packet)
    if with_packet.item_id == 3:
        properties.is_on_secondary_interaction = false
    properties.is_interacting_with_item = false
    if with_packet.ending_turn_after_item_use:
        if GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
            var shotgun_empty = properties.intermediary.game_state.MAIN_active_sequence_dict.sequence_in_shotgun.size() == 0
            var passing_turn_to_next_player = true
            properties.intermediary.roundManager.UserEndTurn_Packet(properties.socket_number, passing_turn_to_next_player, shotgun_empty, -1)
        return
    properties.has_turn = true
    if properties.is_active:
        properties.permissions.SetMainPermission(true)
        properties.SetTurnControllerPrompts(true)


    if (properties.cpu_enabled and GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID) or (properties.user_id == GlobalSteam.STEAM_ID and GlobalVariables.mp_player_ai_enabled):
        print("[BOT] Turn continues, re-triggering AI logic.")
        properties.intermediary.roundManager.BeginBotTurn(properties)

func ReturnJammerAfterTimeout():
    if properties.is_active:
        properties.is_interacting_with_item = false
        jammer.speaker_fp_jammer_bootup_idle.stop()
        properties.jammer_manager.looping = false
        animator_items_firstperson.play("use item id 3 first person_secondary exit")
    else:
        properties.is_interacting_with_item = false
        jammer.speaker_tp_jammer_bootup_idle.stop()
        properties.jammer_manager.looping = false
        animator_items_thirdperson.play("use item id 3 third person_secondary exit")

func ChangeGameStateWithItem(item_id: int, packet: Dictionary = {}):
    properties.stat_number_of_items_used += 1
    match active_id:
        2:

            var shell_in_chamber = packet.current_shell_in_chamber
            shell_branch_inspection.SetState_Inspecting(shell_in_chamber)
        3:
            properties.is_viewing_jammer = true
            properties.is_on_secondary_interaction = true
            properties.intermediary.game_state.BeginTimeoutForSocket("jammer", properties.intermediary.game_state.MAIN_timeout_duration_jammer, properties.socket_number)
        4:
            properties.stat_number_of_cigarettes_smoked += 1
            print("health current: ", properties.health_current, " health on round start: ", properties.health_on_round_start)
            if properties.health_current < properties.health_on_round_start:
                print("health before heal: ", properties.health_current)
                properties.health_current += 1
                await get_tree().create_timer(3.8, false).timeout
                properties.health_counter.healing_health = true
                properties.health_counter.UpdateDisplay()
                print("health after heal: ", properties.health_current)
        5:
            shotgun.RemoveFirstShellFromSequence()
        8:
            await get_tree().create_timer(1.2, false).timeout
            properties.is_stealing_item = true
            properties.is_on_secondary_interaction = true
            properties.intermediary.game_state.BeginTimeoutForSocket("adrenaline", properties.intermediary.game_state.MAIN_timeout_duration_adrenaline, properties.socket_number)
            for property in properties.intermediary.instance_handler.instance_property_array:
                if property.socket_number != properties.socket_number:
                    property.cam.BeginLerp("home", true)
        9:
            if GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
                var shell_in_chamber = properties.intermediary.game_state.MAIN_active_sequence_dict.sequence_in_shotgun[0]
                if shell_in_chamber == "live": properties.intermediary.game_state.MAIN_active_sequence_dict.sequence_in_shotgun[0] = "blank"
                else: properties.intermediary.game_state.MAIN_active_sequence_dict.sequence_in_shotgun[0] = "live"
        10:
            properties.intermediary.game_state.turn_order.FlipTurnOrder()

func RemoveItemFromInventory(at_local_grid_index: int, item_at_socket_number: int):
    for user_property in properties.intermediary.instance_handler.instance_property_array:
        if user_property.socket_number == item_at_socket_number:
            properties.intermediary.game_state.Global_RemoveItemFromInventory(user_property.socket_number, at_local_grid_index)
            user_property.user_inventory[at_local_grid_index] = {}
            user_property.user_inventory_instance_array[at_local_grid_index] = null
            return

    properties.intermediary.game_state.Global_RemoveItemFromInventory(item_at_socket_number, at_local_grid_index)

func PickupItem(item_object_parent: Node3D):
    var active_stream: AudioStream
    for res in properties.intermediary.game_state.MAIN_item_resource_array:
        if res.id == active_id:
            active_stream = res.sound_pick_up_fp
    properties.item_manager.speaker_fp_grab_item_on_table.stream = active_stream
    properties.item_manager.speaker_fp_grab_item_on_table.play()

    var active_socket_number = active_interaction_branch.socket_number
    var pickup_duration = 0.6
    active_pickup_indicator.lerpEnabled = false

    var original_transform = item_object_parent.global_transform
    item_object_parent.get_parent().remove_child(item_object_parent)
    pos_pickup_item.get_parent().add_child(item_object_parent)
    item_object_parent.global_transform = original_transform
    active_separate_lerp.StartLerp(item_object_parent.transform.origin, pos_pickup_item.transform.origin, item_object_parent.rotation_degrees, pos_pickup_item.rotation_degrees, -2, pickup_duration)
    await get_tree().create_timer(pickup_duration, false).timeout
    active_item_parent.queue_free()

func GetItemVariables(item_object_parent: Node3D):
    active_item_parent = item_object_parent
    active_pickup_indicator = item_object_parent.get_child(0)
    active_interaction_branch = item_object_parent.get_child(1)
    active_separate_lerp = item_object_parent.get_child(2)
    active_id = active_interaction_branch.item_id
    active_item_has_secondary_interaction = active_interaction_branch.has_secondary_interaction

func TurnOrderSwapVisuals():
    for user_property in properties.intermediary.instance_handler.instance_property_array:
        if user_property.is_active:
            print("running")
            var previous_socket = user_property.cam.activeSocket
            user_property.cam.BeginLerp("tabletop centerpiece", true)
            await get_tree().create_timer(0.6, false).timeout
            user_property.intermediary.game_state.turn_order.StartIndicator(user_property.intermediary.game_state.MAIN_active_turn_order)
            await get_tree().create_timer(1.2, false).timeout
            user_property.cam.BeginLerp(previous_socket, true)

func PanCameraBack():
    await get_tree().create_timer(0.2, false).timeout
    properties.cam.BeginLerp("home")
