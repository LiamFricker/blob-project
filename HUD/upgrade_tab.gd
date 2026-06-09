extends Control

#NEED TO PUT IN A WAY TO INITIALIZE ALL UPGRADES
#Get them from somewhere, likely store their text and data in a file
#Then instantiate them from the base upgrade 
#REMEMBER TO CONNECT THEIR SIGNALS

signal upgradeSuccess(upgradeTab : int, upgradeID : int, upgradeCost : float, upgradeCount : int, off : Vector2, color : Color)

@export var upgradeBase : PackedScene

@export var panelParticles : PackedScene
@export var upgradeText1 : Texture
@export var upgradeText2 : Texture
@export var upgradeText3 : Texture

@export var upgradePanel : PackedScene
@export var upgradeFrames1 : SpriteFrames
@export var upgradeFrames2 : SpriteFrames
@export var upgradeFrames3 : SpriteFrames

#@onready var panelCont = $PanelContainer

@onready var upgradeContainer = $MarginContainer/ScrollContainer2/upgrade_container

var rng = RandomNumberGenerator.new()

var type = 0
var tab = 0

const TEST = true

var upgrades = []

#THIS NEEDS TO KEEP TRACK OF ALL THE UPGRADE CURRENCIES
#Why am I doing it this way? Well maybe I want to add multiple currency upgrades one day
#That will be a pain in the ass... but I'LL DO IT
#Nvm, I won't we're reworking this
const UPGRADE_CURRENCY_MAX = 3
var upgradeCurrencies = []
#The currencies being used in this tab
var tabUpgradeCurrencies = []

#0 = unable to afford, 1 = buy-max setting, 2 = can afford
var upgradeStatus = []

#positions of completed upgrades to hide them (make invisible).
var completedUpgrades = []
var maxedUpgradesHidden = false

var id_to_positionsDict = {}
var upgMax = 0

#Upgrades will likely be added after PanelContainer. 
var UPGRADE_INDEX_OFFSET = 1

#@onready var globalPosOffset = Vector2(691.2,129.6) + Vector2(16, 16)#global_position#

func initializeTab(imagePath = "res://Art/Cell/HUD/DNA_Big_Paneling.png") -> Control:
	$TextureRect.texture = load(imagePath)
	return $MarginContainer/ScrollContainer2

#BIG PROBLEM HERE
#UPGRADES DONT SHOW UP UNTIL YOU UNLOCK THEM
#UPGRADES CAN BE UNLOCKED OUT OF ORDER
#THUS UPGRADES HAVE TO BE UNLOCKED IN REAL TIME AND THEIR ID NEEDS TO BE UNIQUE TO THEIR FUNCTION
#THEY NEED A SEPERATE POSITION TO WHERE THEY ARE IN THE CONTAINER
#FOR THE SAKE OF MY SANITY LETS HAVE NEWLY UNLOCKED UPGRADES GO TO THE BOTTOM 
func initializeUpgrades(upgradeTab : int, upgradesDict : Dictionary, mult : int, bigIcon = false, upgradeLevels = [], setLevels = false) -> void:
	#globalPosOffset = offset
	tab = upgradeTab
	
	tabUpgradeCurrencies.resize(UPGRADE_CURRENCY_MAX)
	tabUpgradeCurrencies.fill(false)
	
	#Probably not the best way to do this, but I'd rather do this than add two functions just to set levels on load.
	if setLevels: 
		var iterator = 0
		for upgID in upgradesDict:
			var upgradeInfo = upgradesDict[upgID]
			
			_addUpgrade(upgID, upgradeInfo, mult, bigIcon, upgradeLevels[iterator])
			iterator += 1
	else:
		for upgID in upgradesDict:
			var upgradeInfo = upgradesDict[upgID]
			
			_addUpgrade(upgID, upgradeInfo, mult, bigIcon)

#Adding a single upgrade 
#Encapsulates _addUpgrade incase I want to add stuff later
func addNewUpgrade(upgID : int, upgradeInfo : Array, mult : int, bigIcon = false, upgradeLevel = 0) -> void:
	_addUpgrade(upgID, upgradeInfo, mult, bigIcon, upgradeLevel)
	
#This is the main block to make a new upgrade, just since it's basically used twice to save me time	
func _addUpgrade(upgID : int, upgradeInfo : Array, mult : int, bigIcon = false, upgradeLevel = 0) -> void:
	id_to_positionsDict[upgID] = upgMax
	upgMax += 1
	
	#Commenting this out since it's multi currency code
	
	#Populate the upgrade currencies
	#var emptyUpgradeCurrencies = []
	#emptyUpgradeCurrencies.resize(UPGRADE_CURRENCY_MAX)
	#emptyUpgradeCurrencies.fill(false)
	#for index in upgradeInfo[0]:
		#emptyUpgradeCurrencies[index] = true 
	#	tabUpgradeCurrencies[index] = true
	
	tabUpgradeCurrencies[upgradeInfo[0]] = true
	upgradeCurrencies.append(upgradeInfo[0])
	
	var tempUpgrade = upgradeBase.instantiate()
	#tempUpgrade.setParams(eyeDee : int, imagePath : String, upgradeText : String, richTextUpgMoney : String, uB = 1, uC = 1.0, uE = 1.0)
	#tempUpgrade.setParams(upgID, upgradeInfo[1], upgradeInfo[2], upgradeInfo[3], upgradeInfo[4], upgradeInfo[5], upgradeInfo[6], bigIcon, upgradeLevel)
	var tempStatus = tempUpgrade.setParams(upgID, upgradeInfo, mult, bigIcon, upgradeLevel)
	#var tempStatus = tempUpgrade.multChange(mult, upgradeInfo[8])
	tempUpgrade.upgradeClick.connect(_on_upgrade_upgrade_click)
	upgrades.append(tempUpgrade)
	upgradeContainer.add_child(tempUpgrade)
	
	upgradeStatus.append(tempStatus)

#When upgrade multiplier is changed, update ALL the costs. Maybe add a delay to the button if this gets laggy 
#or background load the other tab changes
func upgradeTabMultChange(mult : int, currencyIndex : int, money : float) -> void:
	for i in range(upgMax):
		if upgradeCurrencies[i] == currencyIndex:
			upgradeStatus[i] = upgrades[i].multChange(mult, money)#get_child(UPGRADE_INDEX_OFFSET + i).multChange(mult, money)

#Whenever a change in currency is detected, update all the associating upgrades that use that currency.
#I think upgrade status is kinda fucking pointless and you should consider removing it
#It just adds complexity to everything for a minute extra optimization...
#But... oh well. Who cares. 
func upgradeTabMoneyChange(currency : int, money : float, gain : bool) -> void:
	if tabUpgradeCurrencies[currency]:
		for i in range(upgMax):
			#if upgradeCurrencies[i][currency]: multi-currency code
			if upgradeCurrencies[i] == currency:
				#Only trigger if 
				if gain and upgradeStatus[i] >= 1:
					upgradeStatus[i] = upgrades[i].posChange(money)#get_child(UPGRADE_INDEX_OFFSET + i).posChange(money)
				elif not gain and upgradeStatus <= 1:
					upgradeStatus[i] = upgrades[i].negChange(money)#get_child(UPGRADE_INDEX_OFFSET + i).negChange(money)


func _on_upgrade_upgrade_click(eyeDee: int, upgradeCost: float, count: int, offset: Vector2, color: Color, maxedOut : bool) -> void:
	if maxedOut:
		#commenting this out since it's multi-currency code
		#var tempArr = []
		#tempArr.resize(UPGRADE_CURRENCY_MAX)
		#tempArr.fill(false)
		
		#upgradeCurrencies[upgPos] = tempArr
		
		if not TEST:
			var upgPos = id_to_positionsDict[eyeDee]
			upgradeCurrencies[upgPos] = -1
			completedUpgrades.append(upgPos)
	
	upgradeSuccess.emit(tab, eyeDee, upgradeCost, count, offset, color)
	

#Tbh I should put the spawn code in here but just in caseI want to add something later
#func _on_panel_container_crumpled(offset: Vector2, col: Color) -> void:
	#_spawn(offset - globalPosOffset, col)

func toggleMaxedUpgrades() -> void:
	for pos in completedUpgrades:
		upgrades[pos].visible = maxedUpgradesHidden#get_child(UPGRADE_INDEX_OFFSET + pos).visible = maxedUpgradesHidden
	maxedUpgradesHidden = not maxedUpgradesHidden
