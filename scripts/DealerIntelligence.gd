class_name DealerIntelligence extends Node



@export var medicine: Medicine
@export var hands: HandManager
@export var itemManager: ItemManager
@export var shellSpawner: ShellSpawner
@export var shellLoader: ShellLoader
@export var shotgunShooting: ShotgunShooting
@export var roundManager: RoundManager
@export var animator_shotgun: AnimationPlayer
@export var animator_dealerHands: AnimationPlayer
@export var camera: CameraManager
@export var ejectManager: ShellEjectManager
@export var healthCounter: HealthCounter
@export var death: DeathManager
@export var cameraShaker: CameraShaker
@export var smoke: SmokeController
@export var shellEject_dealer: ShellEjectManager
@export var speaker_dealerarrive: AudioStreamPlayer2D
@export var speaker_handCrack: AudioStreamPlayer2D
@export var soundArray_cracks: Array[AudioStream]
@export var speaker_checkHandcuffs: AudioStreamPlayer2D
@export var speaker_breakHandcuffs: AudioStreamPlayer2D
@export var speaker_giveHandcuffs: AudioStreamPlayer2D
@export var sound_dealerarrive: AudioStream
@export var sound_dealerarriveCuffed: AudioStream
@export var dealermesh_normal: VisualInstance3D
@export var dealermesh_crushed: VisualInstance3D
@export var sequenceArray_knownShell: Array[bool]
@export var amounts: Amounts

var dealerItemStringArray: Array[String]
var dealerAboutToBreakFree = false
var dealerCanGoAgain = false
var dealerHoldingShotgun = false

func DealerCheckHandCuffs():
	var brokeFree = false
	camera.BeginLerp("enemy cuffs close")
	if ( !dealerAboutToBreakFree):
		await get_tree().create_timer(0.3, false).timeout
		speaker_checkHandcuffs.play()
		animator_dealerHands.play("dealer check handcuffs")
		await get_tree().create_timer(0.7, false).timeout
		brokeFree = false
	else:
		await get_tree().create_timer(0.3, false).timeout
		animator_dealerHands.play("dealer break cuffs")
		speaker_breakHandcuffs.play()

		brokeFree = true
		roundManager.dealerCuffed = false
		dealerAboutToBreakFree = false
	dealerAboutToBreakFree = true
	roundManager.ReturnFromCuffCheck(brokeFree)

func Animator_CheckHandcuffs():
	speaker_checkHandcuffs.play()

func Animator_GiveHandcuffs():
	speaker_giveHandcuffs.play()

func BeginDealerTurn():
	mainLoopFinished = false
	usingHandsaw = false
	usingMedicine = false
	DealerChoice()

var dealerTarget = ""
var knownShell = ""
var dealerKnowsShell = false
var mainLoopFinished = false
var usingHandsaw = false
var dealerUsedItem = false
var usingMedicine = false

var adrenalineSetup = false
var stealing = false
var adrenaline_itemSlot = ""
var inv_playerside = []
var inv_dealerside = []

func DealerChoice():
	var dealerWantsToUse = ""
	var dealerFinishedUsingItems = false
	var hasHandsaw = false
	var hasCigs = false

	if (roundManager.requestedWireCut):
		await (roundManager.defibCutter.CutWire(roundManager.wireToCut))
	if (shellSpawner.sequenceArray.size() == 0):
		roundManager.StartRound(true)
		return


	var known_shell_val = 0
	if dealerKnowsShell:
		if knownShell == "live": known_shell_val = 1
		else: known_shell_val = -1


	var live_count = 0
	var blank_count = 0
	for s in iter_shells():
		if s == "live": live_count += 1
		else: blank_count += 1


	if live_count == 0 and blank_count == 0:
		for shell in roundManager.shellSpawner.sequenceArray:
			if shell == "live": live_count += 1
			elif shell == "blank": blank_count += 1


	var item_counts = {"beer": 0, "handcuffs": 0, "cigarettes": 0, "magnifying glass": 0, "handsaw": 0, "burner phone": 0}

	inv_dealerside = []
	itemManager.itemArray_dealer = []
	itemManager.itemArray_instances_dealer = []

	var ch = itemManager.itemSpawnParent.get_children()
	for c in ch.size():
		if (ch[c].get_child(0) is PickupIndicator):
			var temp_interaction: InteractionBranch = ch[c].get_child(1)
			if ( !temp_interaction.isPlayerSide):
				inv_dealerside.append(temp_interaction.itemName)
				itemManager.itemArray_dealer.append(temp_interaction.itemName)
				itemManager.itemArray_instances_dealer.append(ch[c])
				if temp_interaction.itemName in item_counts:
					item_counts[temp_interaction.itemName] += 1

	var p_cuffed_val = 1 if roundManager.playerCuffed else 0
	var saw_active_val = 1 if roundManager.barrelSawedOff else 0


	var exec_args = [
		"ai_bridge.py", 
		str(roundManager.health_opponent), 
		str(roundManager.health_player), 
		str(live_count), 
		str(blank_count), 
		str(known_shell_val), 
		str(saw_active_val), 
		str(item_counts["beer"]), 
		str(item_counts["handcuffs"]), 
		str(item_counts["cigarettes"]), 
		str(item_counts["magnifying glass"]), 
		str(item_counts["handsaw"]), 
		str(item_counts["burner phone"]), 
		str(p_cuffed_val)
	]

	var output = []
	var script_path = ProjectSettings.globalize_path("res://ai_bridge.py")
	print("Calling AI Bridge with args:", exec_args)
	exec_args[0] = script_path
	OS.execute("python", exec_args, output, true)

	var selected_action = 0
	if output.size() > 0:
		var result_str = output[0].strip_edges()
		print("AI returned:", result_str)
		if result_str.is_valid_int():
			selected_action = result_str.to_int()


	if selected_action == 0:
		dealerTarget = "player"
		mainLoopFinished = true
	elif selected_action == 1:
		dealerTarget = "self"
		mainLoopFinished = true
	elif selected_action == 2:
		dealerWantsToUse = "beer"
	elif selected_action == 3:
		dealerWantsToUse = "handcuffs"
	elif selected_action == 4:
		dealerWantsToUse = "cigarettes"
	elif selected_action == 5:
		dealerWantsToUse = "magnifying glass"
	elif selected_action == 6:
		dealerWantsToUse = "handsaw"
	elif selected_action == 7:
		dealerWantsToUse = "burner phone"
	else:

		ChooseWhoToShootRandomly()
		mainLoopFinished = true
		dealerTarget = ""

	if (dealerWantsToUse == ""): mainLoopFinished = true


	if (dealerWantsToUse != ""):
		if (dealerHoldingShotgun):
			animator_shotgun.play("enemy put down shotgun")
			shellLoader.DealerHandsDropShotgun()
			dealerHoldingShotgun = false
			await get_tree().create_timer(0.45, false).timeout
		dealerUsedItem = true
		if (roundManager.waitingForDealerReturn):
			await get_tree().create_timer(1.8, false).timeout
			roundManager.waitingForDealerReturn = false

		var returning = false
		var amountArray: Array[AmountResource] = amounts.array_amounts
		for res in amountArray:
			if (dealerWantsToUse == res.itemName):
				res.amount_dealer -= 1
				break


		if dealerWantsToUse == "handsaw":
			usingHandsaw = true
			roundManager.barrelSawedOff = true
			roundManager.currentShotgunDamage = 2
		elif dealerWantsToUse == "magnifying glass":
			if (shellSpawner.sequenceArray[0] == "live"): knownShell = "live"
			else: knownShell = "blank"
			dealerKnowsShell = true
		elif dealerWantsToUse == "handcuffs":
			roundManager.playerCuffed = true
		elif dealerWantsToUse == "beer":
			shellEject_dealer.FadeOutShell()
			dealerKnowsShell = false
			knownShell = ""
		elif dealerWantsToUse == "burner phone":
			var sequence = roundManager.shellSpawner.sequenceArray
			var len = sequence.size()
			if len > 1:
				var randindex = randi_range(1, len - 1)
				sequenceArray_knownShell[randindex] = true

		await (hands.PickupItemFromTable(dealerWantsToUse))
		if (dealerWantsToUse == "cigarettes"): await get_tree().create_timer(1.1, false).timeout

		itemManager.itemArray_dealer.erase(dealerWantsToUse)
		itemManager.numberOfItemsGrabbed_enemy -= 1

		if (returning): return
		DealerChoice()
		return

	if (dealerWantsToUse == ""): dealerFinishedUsingItems = true
	if (roundManager.waitingForDealerReturn):
		await get_tree().create_timer(1.8, false).timeout
	if ( !dealerHoldingShotgun && dealerFinishedUsingItems):
		GrabShotgun()
		await get_tree().create_timer(1.4 + 0.5 - 1, false).timeout
	await get_tree().create_timer(1, false).timeout

	if (dealerTarget == ""): ChooseWhoToShootRandomly()
	else: Shoot(dealerTarget)

	dealerTarget = ""
	knownShell = ""
	dealerKnowsShell = false

func iter_shells():
	return []

func FigureOutShell():
	if (sequenceArray_knownShell[0] == true): return true

	var seq = shellSpawner.sequenceArray
	var mem = sequenceArray_knownShell

	var c_live = 0
	var c_blank = 0
	for shell in seq:
		if (shell == "blank"): c_blank += 1
		if (shell == "live"): c_live += 1
	if (c_live == 0): return true
	if (c_blank == 0): return true

	for c in mem.size():
		if (mem[c] == true):
			if (seq[c] == "live"): c_live -= 1
			else: c_blank -= 1
	if (c_live == 0): return true
	if (c_blank == 0): return true

	return false

func EndDealerTurn(canDealerGoAgain: bool):
	dealerCanGoAgain = canDealerGoAgain


	var outOfHealth_player = roundManager.health_player == 0
	var outOfHealth_enemy = roundManager.health_opponent == 0
	var outOfHealth = outOfHealth_player or outOfHealth_enemy
	if (outOfHealth):

		if (outOfHealth_enemy): roundManager.OutOfHealth("dealer")
		return

	if ( !dealerCanGoAgain):
		EndTurnMain()
	else:
		if (shellSpawner.sequenceArray.size()):
			BeginDealerTurn()
		else:
			EndTurnMain()
	pass

func ChooseWhoToShootRandomly():
	var decision = CoinFlip()
	if (decision == 0): Shoot("self")
	else: Shoot("player")

func GrabShotgun():



	await (shellLoader.DealerHandsGrabShotgun())
	await get_tree().create_timer(0.2, false).timeout
	animator_shotgun.play("grab shotgun_pointing enemy")
	dealerHoldingShotgun = true
	pass

func EndTurnMain():
	await get_tree().create_timer(0.5, false).timeout
	camera.BeginLerp("home")
	if (dealerHoldingShotgun):
		animator_shotgun.play("enemy put down shotgun")
		shellLoader.DealerHandsDropShotgun()
	dealerHoldingShotgun = false
	roundManager.EndTurn(true)

func Shoot(who: String):
	var currentRoundInChamber = shellSpawner.sequenceArray[0]
	dealerCanGoAgain = false
	var playerDied = false
	var dealerDied = false
	ejectManager.FadeOutShell()

	match (who):
		"self":
			await get_tree().create_timer(0.2, false).timeout
			animator_shotgun.play("enemy shoot self")
			await get_tree().create_timer(2, false).timeout
			shotgunShooting.whoshot = "dealer"
			shotgunShooting.PlayShootingSound()
			pass
		"player":
			animator_shotgun.play("enemy shoot player")
			await get_tree().create_timer(2, false).timeout
			shotgunShooting.whoshot = "player"
			shotgunShooting.PlayShootingSound()
			pass

	if (currentRoundInChamber == "live" && who == "self"):
		roundManager.health_opponent -= roundManager.currentShotgunDamage
		if (roundManager.health_opponent < 0): roundManager.health_opponent = 0
		smoke.SpawnSmoke("barrel")
		cameraShaker.Shake()
		dealerCanGoAgain = false
		death.Kill("dealer", false, true)
		return
	if (currentRoundInChamber == "live" && who == "player"):
		roundManager.health_player -= roundManager.currentShotgunDamage
		if (roundManager.health_player < 0): roundManager.health_player = 0
		cameraShaker.Shake()
		smoke.SpawnSmoke("barrel")
		await (death.Kill("player", false, false))
		playerDied = true
	if (currentRoundInChamber == "blank" && who == "self"): dealerCanGoAgain = true

	await get_tree().create_timer(0.4, false).timeout
	if (who == "player"): animator_shotgun.play("enemy eject shell_from player")
	if (who == "self"): animator_shotgun.play("enemy eject shell_from self")
	await get_tree().create_timer(1.7, false).timeout

	EndDealerTurn(dealerCanGoAgain)

func Speaker_DealerArrive():
	var p = randf_range(0.9, 1.0)
	speaker_dealerarrive.pitch_scale = p
	speaker_dealerarrive.stream = sound_dealerarrive
	speaker_dealerarrive.play()

func Speaker_DealerArrive_Cuffed():
	var p = randf_range(0.9, 1.0)
	speaker_dealerarrive.pitch_scale = p
	speaker_dealerarrive.stream = sound_dealerarriveCuffed
	speaker_dealerarrive.play()

func Speaker_HandCrack():
	var randindex = randi_range(0, soundArray_cracks.size() - 1)
	speaker_handCrack.stream = soundArray_cracks[randindex]
	speaker_handCrack.play()

var swapped = false
func SwapDealerMesh():
	if ( !swapped):
		dealermesh_normal.set_layer_mask_value(1, false)
		dealermesh_crushed.set_layer_mask_value(1, true)
		swapped = true
	pass

func CoinFlip():
	var result
	if ( !roundManager.endless):
		result = randi_range(0, 1)
	else:
		var c_live = shellSpawner.sequenceArray.count("live")
		var c_blank = shellSpawner.sequenceArray.count("blank")
		if (c_live == c_blank): result = randi_range(0, 1)
		if (c_live > c_blank): result = 1
		if (c_live < c_blank): result = 0
	return result
