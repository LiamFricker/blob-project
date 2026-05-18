extends CanvasLayer

@export var upgradeTab : PackedScene

const UPGRADE_CURRENCY_MAX = 3
var currency_array = PackedFloat32Array([0, 0, 0])
var maxedUpgradesHidden = false

#I'm pretty sure the upgrade tabs will likely have a container of itself, but let's just pretend they don't for simplicity.
#We could also just store their direct references in this array since they'll be used often
var tab_to_positionsDict = {}
var upgradeTabs

const UPGRADE_DATA_FILEPATH = "res://etc.json"

var bigIcon = false

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

func addTab(tab : int, upgradeIDs : Array, mult : int, upgradeLevels = [], setLevels = false) -> void:
	#helper function to access data file and such
	# > here
	var upgradeFullDict = {}
	var upgradeDict = {}
	for ID in upgradeIDs:
		var tempInfo = upgradeFullDict[ID]
		tempInfo.append(currency_array[tempInfo[0]])
		upgradeDict[ID] = tempInfo
	
	var tempTab = upgradeTab.instantiate()
	tempTab.initializeUpgrades(tab, upgradeDict, mult, bigIcon, upgradeLevels, setLevels)
	if maxedUpgradesHidden:
		tempTab.toggleMaxedUpgrades()
	
	#MAKE SURE TO ADD THIS TO THE CORRECT CONTAINER
	add_child(tempTab)
	
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

#Make sure to toggle this on a setting or something.
func toggleCompletedUpgrades() -> void:
	for uT in upgradeTabs:
		uT.toggleMaxedUpgrades()
	maxedUpgradesHidden = not maxedUpgradesHidden
	
#Placeholder code for finding the correct upgrade tab if I need this
func getUpgradeTab(pos : int) -> VBoxContainer:
	return $TabContainer/VBoxContainer2



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
