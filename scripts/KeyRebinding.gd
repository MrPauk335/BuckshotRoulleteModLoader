class_name Rebinding extends Node

@export var options: OptionsManager
@export var mouseblocker: Control
@export var cursor: CursorManager
@export var controller: ControllerManager
@export var rebindKeyArray: Array[Label]
@export var menu: Node


func UpdateBindList():
	var _map = InputMap
	for action in InputMap.get_actions():
		var action_bindname = action
		var bindkeys = InputMap.action_get_events(action)
		if (bindkeys.size() < 2): continue
		var bindkey_keyboard = bindkeys[0].as_text()
		var bindkey_controller = bindkeys[1].as_text()
		for ui in rebindKeyArray:
			if (ui.name == action_bindname):
				var keylabel = ui.get_parent().get_child(1)
				var bindbranch: RebindBranch = ui.get_parent().get_child(2)
				bindbranch.originalBind_keyboard = bindkeys[0]
				bindbranch.originalBind_controller = bindkeys[1]



				var firstindex = bindkey_controller.rfind("(")
				bindkey_keyboard = bindkey_keyboard.trim_suffix("(Physical)")
				bindkey_keyboard = bindkey_keyboard.replace(" ", "")
				bindkey_controller = bindkey_controller.left(firstindex)
				bindkey_controller = bindkey_controller.replace("Joypad Motion on", "")
				keylabel.text = bindkey_keyboard + ", " + bindkey_controller
		options.ParseInputMapDictionary()

var globalparent
var previousKey
func GetRebind(parent: Node):
	menu.failsafed = false
	globalparent = parent
	controller.checkingForInput = false
	controller.SetRebindFocus(false)
	var _ui_inputName = parent.get_child(0)
	var ui_inputKey = parent.get_child(1)
	previousKey = ui_inputKey.text
	mouseblocker.visible = true
	cursor.SetCursor(false, false)
	ui_inputKey.text = tr("PRESS ANY BUTTON REMAP")
	checkingForCancel = true
	waitingForAnyInput = true

var waitingForAnyInput
func _input(event):



	if (waitingForAnyInput and !event is InputEventMouseMotion and event.is_pressed()):
		if (event is InputEventMouseButton && event.double_click): event.double_click = false




		var newEventToBind = event
		var parent = globalparent
		var ui_inputName = parent.get_child(0).name
		var branch = parent.get_child(2)
		var originalkey_keyboard = branch.originalBind_keyboard
		var originalkey_controller = branch.originalBind_controller
		var _activeKeyName = originalkey_controller
		var _actionIndex = 1
		var assigningKeyboard = !event is InputEventJoypadButton and !event is InputEventJoypadMotion
		var _checkingMouse = event is InputEventMouseButton
		if (assigningKeyboard):
			_activeKeyName = originalkey_keyboard
			_actionIndex = 0
		var _binds = InputMap.action_get_events(ui_inputName)
		var firstEvent = originalkey_keyboard
		var secondEvent = originalkey_controller
		if (assigningKeyboard): firstEvent = newEventToBind
		else: secondEvent = newEventToBind
		InputMap.action_erase_events(ui_inputName)
		InputMap.action_add_event(ui_inputName, firstEvent)
		InputMap.action_add_event(ui_inputName, secondEvent)


		var currentAction = ui_inputName
		var currentBind = newEventToBind
		var bindIndex = 1
		if (assigningKeyboard): bindIndex = 0

		for action in InputMap.get_actions():
			if (action != currentAction):
				var bindkeys = InputMap.action_get_events(action)
				if (bindkeys.size() < 2): continue

				if (bindkeys[bindIndex].as_text() == currentBind.as_text()):
					SwapBind(bindkeys[0], bindkeys[1], action, assigningKeyboard, originalkey_keyboard, originalkey_controller)

		UpdateBindList()
		ReturnFromRebind()

func SwapBind(firstevent: InputEvent, secondevent: InputEvent, _action: String, _assigningKeyboard: bool, original_keyboard: InputEvent, original_cntrl: InputEvent):
	InputMap.action_erase_events(_action)
	if (_assigningKeyboard): firstevent = original_keyboard
	else: secondevent = original_cntrl
	InputMap.action_add_event(_action, firstevent)
	InputMap.action_add_event(_action, secondevent)

func ReturnFromRebind():
	waitingForAnyInput = false
	await get_tree().create_timer(0.1, false).timeout
	var parent = globalparent
	controller.checkingForInput = true
	controller.SetRebindFocus(true)
	mouseblocker.visible = false
	cursor.SetCursor(true, false)
	menu.failsafed = true

var checkingForCancel
func CancelRebind():
	var parent = globalparent
	parent.get_child(1).text = previousKey
	controller.checkingForInput = true
	controller.SetRebindFocus(true)
	mouseblocker.visible = false
	cursor.SetCursor(true, false)
	checkingForCancel = false

	menu.failsafed = true

var cancelAllowed = false
func _unhandled_input(event):
	if (event.is_action_pressed("ui_cancel") && checkingForCancel && cancelAllowed):
		CancelRebind()
