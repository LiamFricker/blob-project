extends Control

signal upgradeClick(eyeDee, upgradeCost) 
signal upgradeSuccess(offset, text, color, count)

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
@onready var PANEL_INDEX : int = $Panel.get_index()

@export var currencyType : int = 0
@export var secondaryType : int = 0

var rng = RandomNumberGenerator.new()	

var upgradeCost : float = 0
var canUpgrade : bool = true
#0 : 1, 1 : 5, 2 : 10, 3 : Max
var upgradeMult : int = 0 
const MULT_MAX = 3
var upgradeCount = 1

#Need to format the cost later
func setUpgradeCost() -> void:
	$UpgradeCost.text = str(upgradeCost) + upgradeCurrency

func multChange(newMult : float, money : float) -> void :
	if (upgrade == upgradeMax):
		return
	upgradeMult = newMult
	upgradeCost = _calcMultCost(money)
	$Button.text = upgradeCount
	setUpgradeCost()
	if (upgradeCost > money):
		canUpgrade = false
		$Button.disabled = true
		get_child(PANEL_INDEX+2).self_modulate = Color8(94, 94, 94)

func _calcMultCost(money = 0.0) -> float : 
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
		_:
			for i in range(1, upgradeMax - upgrade, 1):
				tempCost += upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
				if (tempCost >= money):
					tempCost -= upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
					upgradeCount = i
					return tempCost
			upgradeCount = upgradeMax - upgrade
			return tempCost

func posChange(money : float) -> void:
	if not canUpgrade and upgrade != upgradeMax and upgradeCost <= money:
		canUpgrade = true
		$Button.disabled = false
		get_child(PANEL_INDEX+2).self_modulate = Color8(0, 0, 0)
		if upgradeMult == MULT_MAX:
			upgradeCost = 0
			for i in range(0, upgradeMax - upgrade, 1):
				upgradeCost += upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
				if (upgradeCost >= money):
					upgradeCost -= upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
					upgradeCount = i
					return
			upgradeCount = upgradeMax - upgrade
			$Button.text = upgradeCount
		

func negChange(money : float) -> void:
	if canUpgrade and upgrade != upgradeMax and upgradeCost > money:
		if upgradeMult == MULT_MAX:
			upgradeCost = upgradeBase + upgradeCoefficient * upgrade + pow(upgradeExponent, upgrade)
			upgradeCount = 1
			if upgradeCost > money:
				canUpgrade = false
				$Button.disabled = true
				get_child(PANEL_INDEX+2).self_modulate = Color8(94, 94, 94) 
			else:
				for i in range(1, upgradeMax - upgrade, 1):
					upgradeCost += upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
					if (upgradeCost >= money):
						upgradeCost -= upgradeBase + upgradeCoefficient * (upgrade+i) + pow(upgradeExponent, upgrade+i)
						upgradeCount = i
						return
				upgradeCount = upgradeMax - upgrade
				$Button.text = upgradeCount
		else:
			canUpgrade = false
			$Button.disabled = true
			get_child(PANEL_INDEX+2).self_modulate = Color8(94, 94, 94)  
		
#upgrade currency needs a space in front
func _setParams(eyeDee : int, imagePath : String, upgradeText : String, upgMoney : String, RichUB = "1", uB = 1, uC = 1.0, uE = 1.0) -> void:
	ID = eyeDee
	$UpgradeDescription.text = upgradeText
	upgradeBase = uB
	upgradeCoefficient = uC
	upgradeCurrency = upgMoney
	$UpgradeCost.text = RichUB + upgradeCurrency
	upgradeExponent = uE
	if ID == 69:
		$BiggerIcon.texture = Image.load_from_file(imagePath)
		$BiggerIcon.visible = true
		$Icon2.visible = false
	else:
		$Icon/TextureRect.texture = Image.load_from_file(imagePath)

#Pass in the formatted cost. When you emit the signal, make sure to send up the expected cost.
func onUpgrade(upgradeCost : String) -> bool:
	if upgrade < upgradeMax:
		#You could make this better if you saved the nodes in a ref but it'll increase the mem of a 
		#lot of upgrades
		match (upgrade % 3):
			0:
				move_child($Panel3, PANEL_INDEX)
				$UpgradeCost.position = Vector2(335,3)
			1:
				move_child($Panel2, PANEL_INDEX)
				$UpgradeCost.position = Vector2(339,9)
			2:
				move_child($Panel, PANEL_INDEX)
				$UpgradeCost.position = Vector2(336,6)
		$UpgradeCost.text = upgradeCost + upgradeCurrency
		upgrade+=1
		return true
	else:
		$Background.modulate = Color8(60, 100, 68, 120)
		modulate = Color8(255, 255, 218)
		return false

#Changing Buy Amount needs to send a Signal to the Current Panel

#Click down needs to change the modulate value of the current panel darker.
func _on_button_button_down() -> void:
	#Above needs to check player money as well as currency based on ID.
	upgradeClick.emit(ID, upgradeBase + upgradeCoefficient * upgrade + pow(upgradeExponent, upgrade))
	
func _on_animation_complete(child : Node2D, offset : Vector2, text : int) -> void:
	upgradeClick.emit(child.position + offset, text, child.modulate)

#Make it so people can cancel an upgrade by clicking up somewhere else.
func _on_button_mouse_exited() -> void:
	pass # Replace with function body.

func _on_button_button_up() -> void:
	pass # Replace with function body.
