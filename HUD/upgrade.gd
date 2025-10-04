extends Control

signal upgradeClick(eyeDee, upgradeCost)

@export var ID : int = 0
@export var upgradeMax : int = 0
@export var upgrade : int = 0
@export var upgradeBase : int = 0
@export var upgradeCoefficient : float = 0
#Upgrade RichText that displays the currency
var upgradeCurrency : String
@export var upgradeExponent : float = 0
#REMEMBER TO CHANGE THIS BASED ON WHAT NODES ARE IN HERE
#I mean you could just run a get_index function
const PANEL_INDEX : int = 4
	
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

func _on_button_button_down() -> void:
	#Above needs to check player money as well as currency based on ID.
	upgradeClick.emit(ID, upgradeBase + upgradeCoefficient * upgrade + pow(upgradeExponent, upgrade))
