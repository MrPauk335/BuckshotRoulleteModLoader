class_name RoundManager extends Node

@export var sign: Signature
@export var brief: BriefcaseMachine
@export var defibCutter: DefibCutter
@export var segmentManager: SegmentManager
@export var handcuffs: HandcuffManager
@export var itemManager: ItemManager
@export var death: DeathManager
@export var playerData: PlayerData
@export var cursor: CursorManager
@export var controller: ControllerManager
@export var perm: PermissionManager
@export var health_player: int
@export var health_opponent: int
@export var batchArray: Array[Node]
@export var roundArray: Array[RoundClass]
@export var shellSpawner: ShellSpawner
@export var shellLoader: ShellLoader
@export var currentRound: int
var mainBatchIndex: int
@export var healthCounter: HealthCounter
@export var dealerAI: DealerIntelligence
@export var typingManager: TypingManager
@export var camera: CameraManager
@export var roundIndicatorPositions: Array[Vector3]
@export var roundIndicatorParent: Node3D
@export var roundIndicator: Node3D
@export var animator_roundIndicator: AnimationPlayer
@export var speaker_roundHum: AudioStreamPlayer3D
@export var speaker_roundShutDown: AudioStreamPlayer3D
@export var speaker_winner: AudioStreamPlayer3D
@export var ui_winner: Node3D
@export var animator_dealer: AnimationPlayer
@export var ejectManagers: Array[ShellEjectManager]
@export var animator_dealerHands: AnimationPlayer
@export var gameover: GameOverManager
@export var musicManager: MusicManager
@export var deficutter: DefibCutter
@export var anim_doubleor: AnimationPlayer
@export var anim_yes: AnimationPlayer
@export var anim_no: AnimationPlayer
@export var intbranch_yes: InteractionBranch
@export var intbranch_no: InteractionBranch
@export var speaker_slot: AudioStreamPlayer2D

var shotgun: ShotgunShooting
var itemInteraction: ItemInteraction

var playerIsAI = true
var playerKnowsShell = false
var playerKnownShell = ""

var endless = false
var shellLoadingSpedUp = false
var dealerItems: Array[String]
var currentShotgunDamage = 1
var dealerAtTable = false
var dealerHasGreeted = false
var dealerCuffed = false
var playerCuffed = false
var playerAboutToBreakFree = false
var waitingForDealerReturn = false
var barrelSawedOff = false
var defibCutterReady = false
var trueDeathActive = false
var playerCurrentTurnItemArray = []

func _ready():
	playerIsAI = (GlobalVariables.ai_mode == 2)
	dealerCuffed = false
	playerCuffed = false
	playerData.hasSignedWaiver = false
	Engine.time_scale = 1
	HideDealer()

	var root = get_tree().current_scene
	if root:
		var shotgun_nodes = root.find_children("*", "ShotgunShooting", true, false)
		if shotgun_nodes.size() > 0: shotgun = shotgun_nodes[0]
		var item_nodes = root.find_children("*", "ItemInteraction", true, false)
		if item_nodes.size() > 0: itemInteraction = item_nodes[0]

	if shotgun: print("[AI] Found ShotgunShooting: ", shotgun.name)
	if itemInteraction: print("[AI] Found ItemInteraction: ", itemInteraction.name)

func _process(delta):
	LerpScore()
	InitialTimer()

var counting = false
var initial_time = 0
func InitialTimer():
	if (counting): initial_time += get_process_delta_time()

func BeginMainGame():
	MainBatchSetup(true)

func HideDealer():
	animator_dealerHands.play("hide hands")
	animator_dealer.play("hide dealer")


var lerping = false
var enteringFromWaiver = false
func MainBatchSetup(dealerEnterAtStart: bool):
	if ( !enteringFromWaiver):
		if (lerping): camera.BeginLerp("enemy")
		currentRound = 0
		if ( !dealerAtTable && dealerEnterAtStart):
			await get_tree().create_timer(0.5, false).timeout
			if ( !dealerCuffed): animator_dealerHands.play("dealer hands on table")
			else: animator_dealerHands.play("dealer hands on table cuffed")
			animator_dealer.play("dealer return to table")
			await get_tree().create_timer(2, false).timeout
			var greeting = true
			if GlobalVariables.ai_mode != 2:
				playerData.hasSignedWaiver = false
				playerData.playerEnteringFromDeath = false
				playerData.numberOfDialogueRead = 0
				playerData.hasReadIntroduction = false
				playerIsAI = false

			if ( !playerData.hasSignedWaiver):
				if GlobalVariables.ai_mode == 2:
					playerData.hasSignedWaiver = true
					playerData.playername = "NEURAL NET"
				else:
					dealerCuffed = false
					playerCuffed = false
					shellLoader.dialogue.ShowText_Forever(tr("WAIVER"))
					await get_tree().create_timer(2.3, false).timeout
					shellLoader.dialogue.HideText()
					camera.BeginLerp("home")
					sign.AwaitPickup()
					return
			if ( !dealerHasGreeted && greeting):
				var tempstring
				if ( !playerData.enteringFromTrueDeath): tempstring = tr("WELCOME")
				else:
					shellSpawner.dialogue.dealerLowPitched = true
					tempstring = "..."
				if ( !playerData.playerEnteringFromDeath):
					shellLoader.dialogue.ShowText_Forever("...")
					await get_tree().create_timer(2.3, false).timeout
					shellLoader.dialogue.HideText()
					dealerHasGreeted = true
				else:
					shellLoader.dialogue.ShowText_Forever(tempstring)
					await get_tree().create_timer(2.3, false).timeout
					shellLoader.dialogue.HideText()
					dealerHasGreeted = true
			dealerAtTable = true
	enteringFromWaiver = false
	playerData.enteringFromTrueDeath = false
	mainBatchIndex = playerData.currentBatchIndex
	healthCounter.DisableCounter()
	SetupRoundArray()
	if (playerData.hasReadIntroduction): roundArray[0].hasIntroductoryText = false
	else: roundArray[0].hasIntroductoryText = true
	if (roundArray[0].showingIndicator): await (RoundIndicator())
	healthCounter.SetupHealth()
	lerping = true

	if ( !endless): ParseMainGameAmounts()
	StartRound(false)

@export var amounts: Amounts
func ParseMainGameAmounts():
	for res in amounts.array_amounts:
		res.amount_active = res.amount_main

var curhealth = 0
func GenerateRandomBatches():
	for b in batchArray:
		for i in range(b.roundArray.size()):
			b.roundArray[i].startingHealth = randi_range(2, 4)
			curhealth = b.roundArray[i].startingHealth

			var total_shells = randi_range(2, 8)
			var amount_live = max(1, total_shells / 2)
			var amount_blank = total_shells - amount_live
			b.roundArray[i].amountBlank = amount_blank
			b.roundArray[i].amountLive = amount_live

			b.roundArray[i].numberOfItemsToGrab = randi_range(2, 5)
			b.roundArray[i].usingItems = true
			var flip = randi_range(0, 1)
			if flip == 1: b.roundArray[i].shufflingArray = true


func SetupRoundArray():
	if (endless): GenerateRandomBatches()
	roundArray = []
	for i in range(batchArray.size()):
		if (batchArray[i].batchIndex == mainBatchIndex):
			var matched = batchArray[i]
			var limit = GlobalVariables.active_match_customization_dictionary.get("number_of_rounds", matched.roundArray.size())
			for z in range(min(matched.roundArray.size(), limit)):
				var r = matched.roundArray[z].duplicate() # Duplicate to avoid modifying global resources
				var hp_override = GlobalVariables.active_match_customization_dictionary.get("starting_health_override", -1)
				if hp_override != -1:
					r.startingHealth = hp_override
				roundArray.append(r)
				pass
	pass

@export var statue: Statue

func RoundIndicator():
	roundIndicator.visible = false

	animator_roundIndicator.play("RESET")
	camera.BeginLerp("health counter")
	await get_tree().create_timer(0.8, false).timeout
	statue.CheckStatus()
	var activePos = roundIndicatorPositions[roundArray[0].indicatorNumber]
	roundIndicator.transform.origin = activePos
	roundIndicatorParent.visible = true
	speaker_roundHum.play()
	await get_tree().create_timer(0.8, false).timeout
	roundIndicator.visible = true
	brief.ending.endless_roundsbeat += 1
	animator_roundIndicator.play("round blinking")
	await get_tree().create_timer(2, false).timeout
	roundIndicatorParent.visible = false
	speaker_roundHum.stop()
	speaker_roundShutDown.play()
	animator_roundIndicator.play("RESET")
	pass


func StartRound(gettingNext: bool):
	if (gettingNext && (currentRound + 1) != roundArray.size()): currentRound += 1


	await (handcuffs.RemoveAllCuffsRoutine())

	if (playerData.currentBatchIndex == 2 && !defibCutterReady && !endless):
		shellLoader.dialogue.dealerLowPitched = true
		camera.BeginLerp("enemy")
		await get_tree().create_timer(0.6, false).timeout


		if ( !playerData.cutterDialogueRead):
			shellLoader.dialogue.scaling = true
			shellLoader.dialogue.ShowText_Forever(tr("FINAL SHOW1"))
			await get_tree().create_timer(4, false).timeout
			shellLoader.dialogue.scaling = true
			shellLoader.dialogue.ShowText_Forever(tr("FINAL SHOW2"))
			await get_tree().create_timer(4, false).timeout
			shellLoader.dialogue.scaling = true
			shellLoader.dialogue.ShowText_Forever(tr("FINAL SHOW3"))
			await get_tree().create_timer(4.8, false).timeout
			shellLoader.dialogue.scaling = false
			shellLoader.dialogue.HideText()
			playerData.cutterDialogueRead = true
		else:
			shellLoader.dialogue.ShowText_Forever(tr("BETTER NOT"))
			await get_tree().create_timer(3, false).timeout
			shellLoader.dialogue.HideText()
		await (deficutter.InitialSetup())
		defibCutterReady = true
		trueDeathActive = true


	if (roundArray[currentRound].usingItems):
		itemManager.BeginItemGrabbing()
		return
	shellSpawner.MainShellRoutine()
	pass


func ReturnFromItemGrabbing():
	shellSpawner.MainShellRoutine()
	pass

func LoadShells():
	shellLoader.LoadShells()
	pass

func CheckIfOutOfHealth():

	var outOfHealth_player = health_player == 0
	var outOfHealth_enemy = health_opponent == 0
	var outOfHealth = outOfHealth_player or outOfHealth_enemy
	if (outOfHealth):
		if (outOfHealth_player): OutOfHealth("player")
		if (outOfHealth_enemy): OutOfHealth("dealer")
		return outOfHealth

var waitingForReturn = false
var waitingForHealthCheck = false
var waitingForHealthCheck2 = false
var requestedWireCut = false
var wireToCut = ""
var wireIsCut_dealer = false
var wireIsCut_player = false

var ignoring = false
func EndTurn(playerCanGoAgain: bool):




	if (barrelSawedOff):
		await get_tree().create_timer(0.6, false).timeout
		if (waitingForHealthCheck2): await get_tree().create_timer(2, false).timeout
		waitingForHealthCheck2 = false
		await (segmentManager.GrowBarrel())
	if (shellSpawner.sequenceArray.size() != 0):

		if (playerCanGoAgain):
			BeginPlayerTurn()
		else:

			if (dealerCuffed):
				if (waitingForReturn):
					await get_tree().create_timer(1.4, false).timeout
					waitingForReturn = false
				if (waitingForHealthCheck):
					await get_tree().create_timer(1.8, false).timeout
					waitingForHealthCheck = false
				dealerAI.DealerCheckHandCuffs()
			else:



				dealerAI.BeginDealerTurn()
	else:

		if (requestedWireCut):
			await (defibCutter.CutWire(wireToCut))
		if ( !ignoring):
			StartRound(true)

func ReturnFromCuffCheck(brokeFree: bool):
	if (brokeFree):
		await get_tree().create_timer(0.8, false).timeout
		camera.BeginLerp("enemy")
		dealerAI.BeginDealerTurn()
		pass
	else:
		camera.BeginLerp("home")
		BeginPlayerTurn()
	pass

func BeginPlayerTurn():
	if (playerCuffed):
		var returning = false
		if (playerAboutToBreakFree == false):
			handcuffs.CheckPlayerHandCuffs(false)
			await get_tree().create_timer(1.4, false).timeout
			camera.BeginLerp("enemy")
			dealerAI.BeginDealerTurn()
			returning = true
			playerAboutToBreakFree = true
		else:
			handcuffs.BreakPlayerHandCuffs(false)
			await get_tree().create_timer(1.4, false).timeout
			camera.BeginLerp("home")
			playerCuffed = false
			playerAboutToBreakFree = false
			returning = false
		if (returning): return
	if (requestedWireCut):
		await (defibCutter.CutWire(wireToCut))
	await get_tree().create_timer(0.6, false).timeout

	if GlobalVariables.ai_mode == 2:
		BeginAIPlayerTurn()
		return

	playerCurrentTurnItemArray = []
	perm.SetStackInvalidIndicators()
	cursor.SetCursor(true, true)
	perm.SetIndicators(true)
	perm.SetInteractionPermissions(true)
	SetupDeskUI()

func iter_shells():
	return []

func BeginAIPlayerTurn():
	playerCurrentTurnItemArray = []

	await get_tree().create_timer(1.0, false).timeout

	if (shellSpawner.sequenceArray.size() == 0):
		StartRound(true)
		return


	var known_shell_val = 0
	if playerKnowsShell:
		if playerKnownShell == "live": known_shell_val = 1
		else: known_shell_val = -1


	var live_count = 0
	var blank_count = 0
	for s in shellSpawner.sequenceArray:
		if s == "live": live_count += 1
		elif s == "blank": blank_count += 1


	var item_counts = {"beer": 0, "handcuffs": 0, "cigarettes": 0, "magnifying glass": 0, "handsaw": 0, "burner phone": 0}

	var active_items_on_desk = []
	var ch = itemManager.itemSpawnParent.get_children()
	for c in ch.size():
		if (ch[c].get_child(0) is PickupIndicator):
			var temp_interaction: InteractionBranch = ch[c].get_child(1)
			if (temp_interaction.isPlayerSide):
				active_items_on_desk.append({
					"name": temp_interaction.itemName, 
					"parent": ch[c]
				})
				if temp_interaction.itemName in item_counts:
					item_counts[temp_interaction.itemName] += 1

	var d_cuffed_val = 1 if dealerCuffed else 0
	var saw_active_val = 1 if barrelSawedOff else 0


	var exec_args = [
		"ai_bridge.py", 
		str(health_player), 
		str(health_opponent), 
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
		str(d_cuffed_val)
	]

	var output = []
	var script_path = ProjectSettings.globalize_path("res://ai_bridge.py")
	print("Calling AI Player Bridge with args:", exec_args)
	exec_args[0] = script_path
	OS.execute("python", exec_args, output, true)

	var selected_action = 0
	if output.size() > 0:
		var result_str = output[0].strip_edges()
		print("Player AI returned:", result_str)
		if result_str.is_valid_int():
			selected_action = result_str.to_int()


	playerKnowsShell = false
	playerKnownShell = ""

	if selected_action == 0:

		print("AI Player decides to shoot dealer")
		shotgun.ShotgunCollider(false)
		shotgun.animator_shotgun.play("player grab shotgun")
		shotgun.shotgunshaker.StartShaking()
		await get_tree().create_timer(1.0, false).timeout
		shotgun.Shoot("dealer")
		return
	elif selected_action == 1:

		print("AI Player decides to shoot self")
		shotgun.ShotgunCollider(false)
		shotgun.animator_shotgun.play("player grab shotgun")
		shotgun.shotgunshaker.StartShaking()
		await get_tree().create_timer(1.0, false).timeout
		shotgun.Shoot("self")
		return
	else:

		var want_item = ""
		if selected_action == 2: want_item = "beer"
		elif selected_action == 3: want_item = "handcuffs"
		elif selected_action == 4: want_item = "cigarettes"
		elif selected_action == 5: want_item = "magnifying glass"
		elif selected_action == 6: want_item = "handsaw"
		elif selected_action == 7: want_item = "burner phone"

		print("AI Player decides to use: ", want_item)
		if want_item != "":
			for item_dict in active_items_on_desk:
				if item_dict["name"] == want_item:

					if want_item == "magnifying glass" and shellSpawner.sequenceArray.size() > 0:
						playerKnowsShell = true
						playerKnownShell = shellSpawner.sequenceArray[0]


					itemInteraction.RemovePlayerItemFromGrid(item_dict["parent"])
					item_dict["parent"].queue_free()


					itemInteraction.InteractWith(want_item)

					return


		shotgun.ShotgunCollider(false)
		shotgun.animator_shotgun.play("player grab shotgun")
		shotgun.shotgunshaker.StartShaking()
		await get_tree().create_timer(1.0, false).timeout
		shotgun.Shoot("dealer")
		return

@export var deskUI_parent: Control
@export var deskUI_shotgun: Control
@export var deskUI_briefcase: Control
@export var deskUI_grids: Array[Control]
func SetupDeskUI():
	deskUI_parent.visible = true
	deskUI_shotgun.visible = true
	if (roundArray[currentRound].usingItems):
		for b in deskUI_grids: b.visible = true
	else: for b in deskUI_grids: b.visible = false

	if (cursor.controller_active): deskUI_shotgun.grab_focus()
	controller.previousFocus = deskUI_shotgun

func ClearDeskUI(includingParent: bool):
	if (includingParent): deskUI_parent.visible = false
	deskUI_shotgun.visible = false
	for b in deskUI_grids: b.visible = false
	controller.previousFocus = null
	pass

func OutOfHealth(who: String):
	if (who == "player"):
		death.MainDeathRoutine()
	else:
		await get_tree().create_timer(1, false).timeout
		EndMainBatch()

var doubling = false
var prevscore = 0
var mainscore = 0
var elapsed = 0
var dur = 3
var double_or_nothing_rounds_beat = 0
var double_or_nothing_score = 0
var double_or_nothing_initial_score = 0
var doubled = false

var lerpingscore = false
var startscore
var endscore = 0
@export var ui_score: Label3D
@export var ui_doubleornothing: Label3D
@export var speaker_key: AudioStreamPlayer2D
@export var speaker_show: AudioStreamPlayer2D
@export var speaker_hide: AudioStreamPlayer2D

@export var btnParent_doubleor: Control
@export var btn_yes: Control
func BeginScoreLerp():
	startscore = prevscore
	if ( !doubling):
		double_or_nothing_rounds_beat += 1
		var ten_minutes_seconds = 600
		var ten_minutes_score_loss = 40000
		var score_deduction = initial_time / ten_minutes_seconds * ten_minutes_score_loss
		endscore = 70000 - int(score_deduction)
		if (endscore < 10): endscore = 10
		prevscore = endscore
		double_or_nothing_score = prevscore
		double_or_nothing_initial_score = prevscore
	else:
		doubled = true
		endscore = prevscore * 2
		prevscore = endscore
		double_or_nothing_rounds_beat += 1
		double_or_nothing_score = prevscore
	doubling = true
	speaker_slot.play()
	camera.BeginLerp("yes no")
	await get_tree().create_timer(1.1, false).timeout
	ui_score.visible = true
	ui_score.text = str(startscore)
	await get_tree().create_timer(0.5, false).timeout
	elapsed = 0
	lerpingscore = true
	await get_tree().create_timer(3.08, false).timeout
	await get_tree().create_timer(0.46, false).timeout
	ui_score.visible = false
	ui_doubleornothing.visible = true
	anim_doubleor.play("show")
	speaker_show.play()
	await get_tree().create_timer(0.5, false).timeout
	await get_tree().create_timer(1, false).timeout
	cursor.SetCursor(true, true)
	intbranch_no.interactionAllowed = true
	intbranch_yes.interactionAllowed = true
	btnParent_doubleor.visible = true
	if (cursor.controller_active): btn_yes.grab_focus()
	controller.previousFocus = btn_yes
	pass

func RevertDoubleUI():
	btnParent_doubleor.visible = false

@export var ach: Achievement
func Response(rep: bool):
	RevertDoubleUI()
	intbranch_no.interactionAllowed = false
	intbranch_yes.interactionAllowed = false
	cursor.SetCursor(false, false)
	ui_doubleornothing.visible = false
	if (rep): anim_yes.play("press")
	else: anim_no.play("press")
	speaker_key.play()
	await get_tree().create_timer(0.4, false).timeout
	anim_doubleor.play("hide")
	speaker_hide.play()
	await get_tree().create_timer(0.4, false).timeout
	if ( !rep):
		speaker_slot.stop()
		await get_tree().create_timer(0.7, false).timeout
		brief.ending.endless_score = endscore
		brief.ending.endless_overwriting = true
		camera.BeginLerp("enemy")
		brief.MainRoutine()
	else:
		speaker_slot.stop()
		await get_tree().create_timer(0.7, false).timeout

		RestartBatch()
		pass

func LerpScore():
	if (lerpingscore):
		elapsed += get_process_delta_time()
		var c = clampf(elapsed / dur, 0.0, 1.0)
		var score = lerp(startscore, endscore, c)
		ui_score.text = str(int(score))

func RestartBatch():
	playerData.currentBatchIndex = 0
	if (barrelSawedOff):
		await get_tree().create_timer(0.6, false).timeout
		await (segmentManager.GrowBarrel())
	MainBatchSetup(false)
	if ( !dealerAtTable):
		if ( !dealerCuffed): animator_dealerHands.play("dealer hands on table")
		else: animator_dealerHands.play("dealer hands on table cuffed")
		animator_dealer.play("dealer return to table")
	for i in range(ejectManagers.size()):
		ejectManagers[i].FadeOutShell()

	await get_tree().create_timer(2, false).timeout
	musicManager.LoadTrack_FadeIn()

func EndMainBatch():

	ignoring = true
	playerData.currentBatchIndex += 1

	await get_tree().create_timer(0.8, false).timeout
	if (playerData.currentBatchIndex == 3):
		healthCounter.speaker_truedeath.stop()
		healthCounter.DisableCounter()
		defibCutter.BlipError_Both()
		if (endless): musicManager.EndTrack()
		await get_tree().create_timer(0.4, false).timeout
		if (endless):
			counting = false
			BeginScoreLerp()
			return

		camera.BeginLerp("enemy")
		await get_tree().create_timer(0.7, false).timeout
		brief.MainRoutine()
		return
	healthCounter.DisableCounter()
	speaker_roundShutDown.play()
	await get_tree().create_timer(1, false).timeout
	speaker_winner.play()
	ui_winner.visible = true
	itemManager.newBatchHasBegun = true
	await get_tree().create_timer(2.33, false).timeout
	speaker_roundShutDown.play()
	speaker_winner.stop()
	musicManager.EndTrack()
	ui_winner.visible = false

	if (barrelSawedOff):
		await get_tree().create_timer(0.6, false).timeout
		await (segmentManager.GrowBarrel())

	MainBatchSetup(false)
	if ( !dealerAtTable):
		if ( !dealerCuffed): animator_dealerHands.play("dealer hands on table")
		else: animator_dealerHands.play("dealer hands on table cuffed")
		animator_dealer.play("dealer return to table")
	for i in range(ejectManagers.size()):
		ejectManagers[i].FadeOutShell()

	await get_tree().create_timer(2, false).timeout
	musicManager.LoadTrack_FadeIn()
