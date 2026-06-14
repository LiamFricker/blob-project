extends CanvasLayer

@export var upgradeTab : PackedScene

const UPGRADE_CURRENCY_MAX = 3
var currency_array = PackedFloat32Array([100, 100, 100])
var maxedUpgradesHidden = false

#I'm pretty sure the upgrade tabs will likely have a container of itself, but let's just pretend they don't for simplicity.
#We could also just store their direct references in this array since they'll be used often
var tab_to_positionsDict = {}
var upgradeTabs = []
var currentTab = -1
var tabCount = 0

const UPGRADE_DATA_FILEPATH = "res://etc.json"

var bigIcon = false

@onready var fullUpgradePanel = $FullUpgradeContainer/Upgrades
@onready var fullUpgradeContainer = $FullUpgradeContainer
var upgrade_tween
var upgrade_state = false
var pending_up_state = false
signal upgrade_tab_toggled(state : bool)
const UPGRADE_TAB_MOVE_TIME : float = 1.0
const MARGIN = 16

@onready var panelContainer = $PanelContainer

@export var panelParticles : PackedScene
@export var upgradeText1 : Texture
@export var upgradeText2 : Texture
@export var upgradeText3 : Texture

@export var upgradePanel : PackedScene
@export var upgradeFrames1 : SpriteFrames
@export var upgradeFrames2 : SpriteFrames
@export var upgradeFrames3 : SpriteFrames

#@onready var panelCont = $PanelContainer
@onready var globalPosOffset = Vector2.ZERO#$PanelContainer.global_position - Vector2(MARGIN, MARGIN)  #Vector2(691.2,129.6) + Vector2(16, 16)

@export var upgradeTabButton : PackedScene
@export var upgradeTabContainer : PackedScene

@onready var tabButtons = []

var rng = RandomNumberGenerator.new()
var type = 0

func _ready() -> void:
	for i in range(5):
		addTab(-1, [0, 1, 2, 3, 4, 5, 6, 7], 0, [0, 1, 2, 3, 4, 5, 6, 7], true)

#I kinda want to ceiling all of this stuff to make it look more consistent. If it's bad you can remove it later. 
#Update the display to show current money
func updateCurrencyDisplay(currencyIndex : int, money : float) -> void:
	var ceilMoney = ceilf(money)
	pass

#Each update tick, process the new currency amounts
func updateTickMoneyChange(currencyIndexes : Array, currencyChanged : Array) -> void:
	var numChanged = currencyIndexes.size()
	for i in range(numChanged):
		var currencyIndex = currencyIndexes[i]
		#Check if currency amount changed or not
		if currencyChanged[i] < 0:
			currencyChanged[i] = 0
		currencyChanged[i] = ceilf(currencyChanged[i]) 
		if currency_array[currencyIndex] != currencyChanged[i]:
			var gain = currencyChanged[i] > currency_array[currencyIndex]
			currency_array[currencyIndex] = currencyChanged[i]
			for uT in upgradeTabs:
				uT.upgradeTabMoneyChange(currencyIndex, currencyChanged[i], gain)
				
#Each update tick, process the new currency amounts
func multChange(newMult: int, currentCurrencies : Array) -> void:
	for i in range(UPGRADE_CURRENCY_MAX):
		for uT in upgradeTabs:
			uT.upgradeTabMultChange(newMult, i, currentCurrencies[i])

func getTabData(tab = -1) -> Dictionary:
	if tab == -1:
		#0 : Upgrade's Currency, 1 : Path, 2 : Name, 3 : Description, 4: CurrencyIcon, 5: upgradeBase, 
		#6 : upgradeCoefficient, 7 : upgradeExponent, 8 : upgradeMax, 9 : currentMoney
		return {
			0 : [0, "res://Art/Cell/Orbs_Mini.png", "More Orbs", "Get More Orbs", "$", 0, 0, 0, 100],
			1 : [0, "res://Art/Cell/Orbs_Mini.png", "More Orbs", "Get More Orbs", "$", 0, 0, 0, 100],
			2 : [0, "res://Art/Cell/Orbs_Mini.png", "More Orbs", "Get More Orbs", "$", 0, 0, 0, 100],
			3 : [0, "res://Art/Cell/Orbs_Mini.png", "More Orbs", "Get More Orbs", "$", 0, 0, 0, 100],
			4 : [0, "res://Art/Cell/Orbs_Mini.png", "More Orbs", "Get More Orbs", "$", 0, 0, 0, 100],
			5 : [0, "res://Art/Cell/Orbs_Mini.png", "More Orbs", "Get More Orbs", "$", 0, 0, 0, 100],
			6 : [0, "res://Art/Cell/Orbs_Mini.png", "More Orbs", "Get More Orbs", "$", 0, 0, 0, 100],
			7 : [0, "res://Art/Cell/Orbs_Mini.png", "More Orbs", "Get More Orbs", "$", 0, 0, 0, 100]
			}
	return {}

func addTab(tab : int, upgradeIDs : Array, mult : int, upgradeLevels = [], setLevels = false) -> void:
	#helper function to access data file and such
	# > here
	var tempTabButton = upgradeTabButton.instantiate()
	var tempIconPath = "res://Art/Cell/DNA0.png"
	tempTabButton.icon = load(tempIconPath)
	tempTabButton.pressed.connect(changeTab.bind(tabCount))
	tabCount += 1
	
	$FullUpgradeContainer/UpgradeHeader/HBoxContainer.add_child(tempTabButton)
	tabButtons.append(tempTabButton)
	
	#NEED TO INITIALIZE THE TAB ITSELF TOO WITH ITS APPEARANCE AND SUCH 
	#THEN THE UPGRADE CONTAINTER CAN BE ADDED TO IT
	
	 
	var upgradeFullDict = getTabData(tab)
	var upgradeDict = {}
	for ID in upgradeIDs:
		var tempInfo = upgradeFullDict[ID]
		tempInfo.append(currency_array[tempInfo[0]])
		upgradeDict[ID] = tempInfo
	
	#var upgOffset = fullUpgradePanel.global_position - Vector2(MARGIN, MARGIN)
	
	var tempTabContainer = upgradeTabContainer.instantiate()
	#var containerRef
	if currentTab == -1:
		tempTabContainer.initializeTab("res://Art/Cell/HUD/DNA_Big_Paneling.png")
	else:
		tempTabContainer.initializeTab("res://Art/Cell/HUD/forest.png")
	tempTabContainer.upgradeSuccess.connect(_on_upgrade_success)
	fullUpgradePanel.add_child(tempTabContainer)
	
	#var tempTab = upgradeTab.instantiate()
	tempTabContainer.initializeUpgrades(tab, upgradeDict, mult, bigIcon, upgradeLevels, setLevels)
	if maxedUpgradesHidden:
		tempTabContainer.toggleMaxedUpgrades()
	upgradeTabs.append(tempTabContainer)
	
	if currentTab == -1:
		#tempTabButton.show()
		tempTabContainer.show()
		currentTab = 0
	
	#MAKE SURE TO ADD THIS TO THE CORRECT CONTAINER
	#containerRef.add_child(tempTab)
	
func addUpgrade(upgradeFullID : int, mult : int, upgradeLevel = 0) -> void:
	#@warning_ignore("integer_division")
	var tabPos = tab_to_positionsDict[upgradeFullID / 100]
	var upgID = upgradeFullID % 100
	
	#helper function to access data file and such
	# > here
	var upgradeFullDict = {}
	var tempInfo = upgradeFullDict[upgID]
	tempInfo.append(currency_array[tempInfo[0]])
	upgradeTabs[tabPos].addNewUpgrade(upgID, tempInfo, mult, bigIcon)

#Change Tab
func changeTab(newTab) -> void:
	#tabButtons[newTab].show()
	upgradeTabs[newTab].show()
	#tabButtons[currentTab].hide()
	upgradeTabs[currentTab].hide()
	
	print("tab changed ", newTab)
	
	currentTab = newTab

#Make sure to toggle this on a setting or something.
func toggleCompletedUpgrades() -> void:
	for uT in upgradeTabs:
		uT.toggleMaxedUpgrades()
	maxedUpgradesHidden = not maxedUpgradesHidden
	
#Placeholder code for finding the correct upgrade tab if I need this
func getUpgradeTab(pos : int) -> VBoxContainer:
	return $TabContainer/VBoxContainer2

func _on_upgrade_success(upgradeTab: int, upgradeID: int, upgradeCost: float, upgradeCount: int, off : Vector2, color : Color) -> void:
	print("Upgrade Success!")
	
	off = off - globalPosOffset
	_createPanel(off, color)
	if upgradeCount > 1:
		_createPanel(off, color)
		if upgradeCount > 3:
			_createPanel(off, color)
			if upgradeCount > 5:
				_createPanel(off, color)
				if upgradeCount > 10:
					_createPanel(off, color)
					for i in range(20, upgradeCount, 10):
						_createPanel(off, color)

func _createPanel(global_pos : Vector2, col : Color) -> void:
	var tempPanel = upgradePanel.instantiate()
	tempPanel.global_position = global_pos
	tempPanel.modulate = col
	type = (type + rng.randi_range(1, 2)) % 3
	match type:
		0:
			tempPanel.sprite_frames = upgradeFrames1
		1:
			tempPanel.sprite_frames = upgradeFrames2
		2:
			tempPanel.sprite_frames = upgradeFrames3
	
	#Couldn't I just connect this directly though? Am I an idiot or something?
	#panelCont.connect(tempPanel.crumpled, panelCont._crumpledCatch)
	tempPanel.crumpled.connect(_spawn)
	#panelCont.
	panelContainer.add_child(tempPanel)

#Run this based on the count 

#offset should be global pos of child
#should add a degree to it based on the ending pos
func _spawn(off : Vector2, col : Color) -> void:
	off -= globalPosOffset
	var tempPanel = panelParticles.instantiate()
	tempPanel.modulate = col
	var angle = rng.randf_range(-PI/4, -3*PI/4)
	var veloc = rng.randf_range(0.75, 1.75) * Vector2.from_angle(angle)
	angle = rng.randf_range(PI/4, 3*PI/4)
	var secVeloc = rng.randf_range(0.75, 1.75) * Vector2.from_angle(angle)
	match type:
		0:
			tempPanel.initialize(off - Vector2(5, -14), veloc, secVeloc, upgradeText1, Vector2(5, -14))
		1:
			tempPanel.initialize(off - Vector2(1, 11), veloc, secVeloc, upgradeText2, Vector2(1, 11))
		2:
			tempPanel.initialize(off - Vector2(13, 9), veloc, secVeloc, upgradeText3, Vector2(13, 9))
	add_child(tempPanel)

func _on_toggle_upgrades() -> void:
	fullUpgradeContainer.offset_left = 0.0
	
	if upgrade_tween:
		upgrade_tween.kill()
	
	upgrade_tween = create_tween()
	upgrade_tween.finished.connect(_on_transition_complete)
	
	if pending_up_state != upgrade_state:
		if pending_up_state:
			#0.0 = done, 0.4 = just started
			var remaining_percent = (0.4 - fullUpgradeContainer.anchor_left) * 2.5
			upgrade_tween.tween_property(fullUpgradeContainer, "anchor_left", 0.4, UPGRADE_TAB_MOVE_TIME * remaining_percent)
			upgrade_tween.parallel().tween_property(fullUpgradeContainer, "anchor_right", 1.4, UPGRADE_TAB_MOVE_TIME * remaining_percent)
		else:
			#0.4 = done, 0.0 = just started
			var remaining_percent = fullUpgradeContainer.anchor_left * 2.5   
			upgrade_tween.tween_property(fullUpgradeContainer, "anchor_left", 0.0, UPGRADE_TAB_MOVE_TIME * remaining_percent)
			upgrade_tween.parallel().tween_property(fullUpgradeContainer, "anchor_right", 1.0, UPGRADE_TAB_MOVE_TIME * remaining_percent)
		pending_up_state = not pending_up_state
	else:
		pending_up_state = not upgrade_state
		$FullUpgradeContainer/progress.show()
		if upgrade_state:
			$FullUpgradeContainer/off.hide()
			upgrade_tween.tween_property(fullUpgradeContainer, "anchor_left", 0.4, UPGRADE_TAB_MOVE_TIME)
			upgrade_tween.parallel().tween_property(fullUpgradeContainer, "anchor_right", 1.4, UPGRADE_TAB_MOVE_TIME)
			
			upgrade_tab_toggled.emit(false)
		else:
			fullUpgradePanel.show()
			$FullUpgradeContainer/UpgradeHeader.show()
			$FullUpgradeContainer/on.hide()
			upgrade_tween.tween_property(fullUpgradeContainer, "anchor_left", 0.0, UPGRADE_TAB_MOVE_TIME)
			upgrade_tween.parallel().tween_property(fullUpgradeContainer, "anchor_right", 1.0, UPGRADE_TAB_MOVE_TIME)
	
func _on_transition_complete() -> void:
	
	upgrade_state = pending_up_state
	$FullUpgradeContainer/progress.hide()
	if pending_up_state:
		$FullUpgradeContainer/off.show()
		upgrade_tab_toggled.emit(true)
	else:
		$FullUpgradeContainer/on.show()
		fullUpgradePanel.hide()
		$FullUpgradeContainer/UpgradeHeader.hide()
	
	upgrade_tween = create_tween()
	
	var upg_dir : float = 20.0 if pending_up_state else -20.0
	
	upgrade_tween.tween_property(fullUpgradeContainer, "offset_left", upg_dir, 0.1)
	upgrade_tween.tween_property(fullUpgradeContainer, "offset_left", 0.0, 0.1)
	
	upgrade_tab_toggled.emit(upgrade_state)
"""
func load_from_file(jsoncase : String, stringstr : String, fN = fileNum, dec = decimal):
	
	var fileName : String = jsoncase + stringstr + parseStr.substr(0, strLength - dec) + str(fN) + "_keypoints.json"
	#if realTimeTesting:
	#	fileName = jsoncase + parseStr.substr(0, strLength - decimal) + str(fileNum) + "_keypoints.json"
	var file = FileAccess.open(fileName, FileAccess.READ)
	if file == null:
		print("Error opening file: ", FileAccess.get_open_error())
		print(fileName)
		outOfFiles =  not realTimeTesting
		return null
	
	var content = file.get_as_text()
	return content
	
func parseJson(json_string : String) -> Dictionary:
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		return data_received
		
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return {}

func findPositions(jsonDict : Dictionary) -> Array:
	if jsonDict.is_empty():
		return []
	var people = jsonDict["people"]
	if people.is_empty():
		return []
	var peopleDict = people[0]
	return peopleDict["pose_keypoints_2d"]
"""	
