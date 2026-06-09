extends Control

#signal upgradeClick(eyeDee, upgradeCost) 
#signal upgradeSuccess(offset, text, color, count)
signal upgradeClick(eyeDee : int, upgradeCost : float, count : int, offset : Vector2, color : Color, maxedOut : bool) 


@export var ID : int = 0
@export var upgradeMax : int = 100
@export var upgrade : int = 0
@export var upgradeBase : int = 0
@export var upgradeCoefficient : float = 0
#Upgrade RichText that displays the currency
var upgradeCurrency : String
@export var upgradeExponent : float = 0
#REMEMBER TO CHANGE THIS BASED ON WHAT NODES ARE IN HERE
#I mean you could just run a get_index function
#@onready var PANEL_INDEX : int = $Panel.get_index()

@export var currencyType : int = 0
@export var secondaryType : int = 0

var rng = RandomNumberGenerator.new()	

var upgradeCost : float = 0
var canUpgrade : bool = true
#0 : 1, 1 : 5, 2 : 10, 3 : Max
var upgradeMult : int = 0
const MULT_MAX = 3
var upgradeCount = 100

var upgradePending = false

#Elements
#@onready var Background = $Control/Background
@onready var UpgradeButtons = $Control/UpgradeButtons
@onready var UpgradeButton = $Control/UpgradeButtons/Button
#@onready var UpgradeName = $Control/PanelContainer/VBoxContainer/Name
#@onready var UpgradeDescriptionLabel = $Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/UpgradeDescription
@onready var UpgradeLevelLabel = $Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/UpgradeLevel
@onready var UpgradeCostLabel = $Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/UpgradeCost

#Need to format the cost later
func setUpgradeCost() -> void:
	#$UpgradeCost.text = str(upgradeCost) + upgradeCurrency
	UpgradeCostLabel.text = "Upgrade Cost: " + str(upgradeCost) + upgradeCurrency

func _setFirstMultChange(newMult : float, money : float) -> int:
	#Mult change shouldn't occur on a max upgrade
	if (upgrade == upgradeMax):
		print("ERROR maxed upgrade needs to be set to null currencies.")
		return -1
	upgradeMult = newMult
	upgradeCost = _calcMultCost(money)
	
	#THIS NEEDS TO BE FORMATTED
	#$Button.text = upgradeCount
	
	$Control/UpgradeButtons/Button.text = "x" + str(upgradeCount)
	
	#NEED TO CHANGE THIS LATER
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/UpgradeCost.text = "Upgrade Cost: " + str(upgradeCost) + upgradeCurrency
	if (upgradeCost > money):
		canUpgrade = false
		#$Button.disabled = true
		UpgradeButton.disabled = true
		#get_child(PANEL_INDEX+2).self_modulate = Color8(94, 94, 94)
		UpgradeButtons.get_child(2).self_modulate = Color8(94, 94, 94)
		return 0
	else:
		canUpgrade = true
		return 2 if newMult != MULT_MAX else 1

func multChange(newMult : float, money : float) -> int:
	#Mult change shouldn't occur on a max upgrade
	if (upgrade == upgradeMax):
		print("ERROR maxed upgrade needs to be set to null currencies.")
		return -1
	upgradeMult = newMult
	upgradeCost = _calcMultCost(money)
	
	#THIS NEEDS TO BE FORMATTED
	#$Button.text = upgradeCount
	
	UpgradeButton.text = "x" + str(upgradeCount)
	
	setUpgradeCost()
	if (upgradeCost > money):
		canUpgrade = false
		#$Button.disabled = true
		UpgradeButton.disabled = true
		#get_child(PANEL_INDEX+2).self_modulate = Color8(94, 94, 94)
		UpgradeButtons.get_child(2).self_modulate = Color8(94, 94, 94)
		return 0
	else:
		canUpgrade = true
		return 2 if newMult != MULT_MAX else 1

func _calcMultCost(money = 0.0) -> float: 
	var tempCost = upgradeBase + upgradeCoefficient * upgrade + pow(upgradeExponent, upgrade)
	upgradeCount = 1
	match upgradeMult:
		0:
			return tempCost
		1:
			var max = 5 if (upgradeMax - upgrade) > 5 else upgradeMax - upgrade  
			for i in range(1, max, 1):
				tempCost += upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
			upgradeCount = max
			return tempCost
		2:
			var max = 10 if (upgradeMax - upgrade) > 10 else upgradeMax - upgrade  
			for i in range(1, max, 1):
				tempCost += upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
			upgradeCount = max
			return tempCost
		#Usually 3, default is to keep the error handler happy.
		_:
			for i in range(1, upgradeMax - upgrade, 1):
				tempCost += upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
				if (tempCost >= money):
					tempCost -= upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
					upgradeCount = i
					return tempCost
			upgradeCount = upgradeMax - upgrade
			return tempCost

func posChange(money : float) -> int:
	#If can afford
	if upgradeCost <= money:
		#If currently set to not upgradable
		if not canUpgrade:
			canUpgrade = true
			#$Button.disabled = false
			UpgradeButton.disabled = false
			#get_child(PANEL_INDEX+2).self_modulate = Color8(255, 255, 255)
			UpgradeButtons.get_child(2).self_modulate = Color8(255, 255, 255)
			#Find the new max buy Limit
			if upgradeMult == MULT_MAX:
				upgradeCost = upgradeBase + upgradeCoefficient * (upgrade) + pow(upgradeExponent, upgrade)
				for i in range(1, upgradeMax - upgrade, 1):
					upgradeCost += upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
					if (upgradeCost >= money):
						upgradeCost -= upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
						upgradeCount = i
						return 1
				upgradeCount = upgradeMax - upgrade
				#$Button.text = upgradeCount
				UpgradeButton.text = "x" + upgradeCount
				return 1
		#Check if max buy can be pushed to a new limit
		elif upgradeMult == MULT_MAX and upgradeCount != upgradeMax - upgrade:
			for i in range(upgradeCount, upgradeMax - upgrade, 1):
				upgradeCost += upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
				if (upgradeCost >= money):
					upgradeCost -= upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
					upgradeCount = i
					return 1
			upgradeCount = upgradeMax - upgrade
			#$Button.text = upgradeCount
			UpgradeButton.text = "x" + upgradeCount
			return 1
		return 2
	#Update status to can't afford
	else:
		return 0
		

func negChange(money : float) -> int:
	#If cannot afford
	if upgradeCost > money:
		#If can currently upgrade, this should be known by default
		#if canUpgrade:
		#Need to find new max buy limit
		if upgradeMult == MULT_MAX:
			upgradeCost = upgradeBase + upgradeCoefficient * upgrade + pow(upgradeExponent, upgrade)
			upgradeCount = 1
			#If less than minimum, set to unable
			if upgradeCost > money:
				canUpgrade = false
				#$Button.disabled = true
				UpgradeButton.disabled = true
				#get_child(PANEL_INDEX+2).self_modulate = Color8(94, 94, 94) 
				UpgradeButtons.get_child(2).self_modulate = Color8(94, 94, 94) 
			#else calculate new limit 
			else:
				for i in range(1, upgradeMax - upgrade, 1):
					upgradeCost += upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
					if (upgradeCost >= money):
						upgradeCost -= upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
						upgradeCount = i
						return 1
				upgradeCount = upgradeMax - upgrade
				#$Button.text = upgradeCount
				UpgradeButton.text = "x" + upgradeCount
				return 1
		else:
			canUpgrade = false
			#$Button.disabled = true
			UpgradeButton.disabled = true
			#get_child(PANEL_INDEX+2).self_modulate = Color8(94, 94, 94)
			UpgradeButtons.get_child(2).self_modulate = Color8(94, 94, 94) 
		return 0
	else:
		return 2
		
#upgrade currency needs a space in front
#Consider passing in an array incase it needs to be changed later
#func setParams(eyeDee : int, imagePath : String, upgradeName : String, upgradeText : String, 
#richTextUpgMoney : String, uB = 1, uC = 1.0, uE = 1.0, bigIcon = false, upgradeLevel = 0) -> void:
#0 : Upgrade's Currency, 1 : Path, 2 : Name, 3 : Description, 4: CurrencyIcon, 5: upgradeBase, 6 : upgradeCoefficient, 
#7 : upgradeExponent, 8 : upgradeMax, 9 : currentMoney 
func setParams(eyeDee : int, upgradeInfo : Array, mult : int, bigIcon = false, upgradeLevel = 0) -> int:
	ID = eyeDee
	#var tempStrs = upgradeText.split("|")
	
	#$Name.text = tempStrs[0]
	#$UpgradeDescription.text = tempStrs[1]
	$Control/PanelContainer/VBoxContainer/Name.text = upgradeInfo[2]#tempStrs[0]
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/UpgradeDescription.text = upgradeInfo[3]#tempStrs[1]
	
	upgradeBase = upgradeInfo[5]#uB
	upgradeCoefficient = upgradeInfo[6]#uC
	upgradeCurrency = upgradeInfo[4]#richTextUpgMoney
	upgradeExponent = upgradeInfo[7]#uE
	upgrade = upgradeLevel
	
	upgradeMax = upgradeInfo[8]#uMax
	#$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/UpgradeCost.text = "Upgrade Cost: " + getFormattedCost() 
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/UpgradeLevel.text = "Upgrade Level: " + str(upgrade) + "/" + str(upgradeMax)
	
	if bigIcon:
		#$BiggerIcon.texture = Image.load_from_file(imagePath)
		#$BiggerIcon.visible = true
		#$Icon2.visible = false
		$Control/BiggerIcon.texture = load(upgradeInfo[1])#Image.load_from_file(upgradeInfo[1])
		$Control/BiggerIcon.visible = true
		$Control/Icon.visible = false
	else:
		#$Icon2/TextureRect.texture = Image.load_from_file(imagePath)
		#$Control/Icon.texture = Image.load_from_file(upgradeInfo[1])
		$Control/Icon.texture = load(upgradeInfo[1])
	return _setFirstMultChange(mult, upgradeInfo[9])

#Return Upgrade cost as a formatted string
func getFormattedCost() -> String:
	return upgradeCurrency + str(upgradeCost)

#Pass in the formatted cost. When you emit the signal, make sure to send up the expected cost.
func onUpgrade() -> bool:
	match (upgrade % 3):
		0:
			#YOU MIGHT NEED TO MOVE THE UPGRADE AMOUNT TEXT ON THE BUTTON'S POSITION
			#IDK HOW THAT WILL WORK
			UpgradeButtons.move_child($Control/UpgradeButtons/Panel, 0)
			#$UpgradeCost.position = Vector2(335,3)
		1:
			UpgradeButtons.move_child($Control/UpgradeButtons/Panel3, 0)
			#$UpgradeCost.position = Vector2(339,9)
		2:
			UpgradeButtons.move_child($Control/UpgradeButtons/Panel2, 0)
			#$UpgradeCost.position = Vector2(336,6)
	UpgradeCostLabel.text = "Upgrade Cost: " + getFormattedCost()
	UpgradeLevelLabel.text = "Upgrade Level: " + str(upgrade) + "/" + str(upgradeMax)
	if upgrade < upgradeMax:
		#You could make this better if you saved the nodes in a ref but it'll increase the mem of a 
		#lot of upgrades
		
		#$UpgradeCost.text = upgradeCost + upgradeCurrency
		#upgrade+=1
		
		return true
		
	else:
		#$Background.modulate = Color8(60, 100, 68, 120)
		$Control/Background.modulate = Color8(60, 100, 68, 120)
		modulate = Color8(255, 255, 218)
		return false

#Changing Buy Amount needs to send a Signal to the Current Panel

#Click down needs to change the modulate value of the current panel darker.
func _on_button_button_down() -> void:
	#Change the modulate darker
	#get_child(PANEL_INDEX+2).self_modulate = Color8(180, 180, 180)
	UpgradeButtons.get_child(2).self_modulate = Color8(180, 180, 180)
	upgradePending = true
	#Not sure why we need to do this?!?!?
	#Above needs to check player money as well as currency based on ID.
	#upgradeClick.emit(ID, upgradeBase + upgradeCoefficient * upgrade + pow(upgradeExponent, upgrade))
	
#Brother there is NO animation being played wtf is this for?
#func _on_animation_complete(child : Node2D, offset : Vector2, text : int) -> void:
	#upgradeSuccess.emit(child.position + offset, text, child.modulate)

#Make it so people can cancel an upgrade by clicking up somewhere else.
func _on_button_mouse_exited() -> void:
	#Change the button modulate back to normal
	#get_child(PANEL_INDEX+2).self_modulate = Color8(255, 255, 255)
	UpgradeButtons.get_child(2).self_modulate = Color8(255, 255, 255)
	#Cancel the upgrade
	upgradePending = false

#MAKE SURE TO TEST THIS TO SEE IF THIS WORKS PROPERLY
func _on_button_button_up() -> void:
	#Can't do that here, because money is stored in grandparent. Thus this signal needs to send itself up to be updated
	#NOOOO you're an IDIOT, this DOESN'T NEED to happen because the parent will ultimately do a neg-change call immedietely.
	#setUpgradeLevel(upgradeCount)
	if upgradePending:
		upgradePending = false
		
		#The parent NEEDS to call neg change at some point to fix this
		
		upgrade += upgradeCount
		var maxedOut = (upgrade >= upgradeMax)
		
		#Change the button modulate back to normal
		#var tempPanel = get_child(PANEL_INDEX+2)
		var tempPanel = UpgradeButtons.get_child(2)
		tempPanel.self_modulate = Color8(255, 255, 255)
		var offset = tempPanel.global_position #Vector2(0,0)
		var panelMod = tempPanel.modulate 
		#Not sure if these will need panel by panel code so I'll just leave it formatted like this for now.
		upgradeClick.emit(ID, upgradeCost, upgradeCount, offset, panelMod, maxedOut)
		onUpgrade()
