extends VBoxContainer

#NEED TO PUT IN A WAY TO INITIALIZE ALL UPGRADES
#Get them from somewhere, likely store their text and data in a file
#Then instantiate them from the base upgrade 
#REMEMBER TO CONNECT THEIR SIGNALS

signal upgradeSuccess(upgradeTab : int, upgradeID : int, upgradeCost : float, upgradeCount : int)

@export var upgradeBase : PackedScene

@export var panelParticles : PackedScene
@export var upgradeText1 : Texture
@export var upgradeText2 : Texture
@export var upgradeText3 : Texture

@export var upgradePanel : PackedScene
@export var upgradeFrames1 : SpriteFrames
@export var upgradeFrames2 : SpriteFrames
@export var upgradeFrames3 : SpriteFrames

@onready var panelCont = $PanelContainer

var rng = RandomNumberGenerator.new()

var type = 0
var tab = 0

#THIS NEEDS TO KEEP TRACK OF ALL THE UPGRADE CURRENCIES
var totalUpgradeCurrency = [0, 0]
var upgradeCurrencies = [[0, 0], [0, 0], [0, 0]]

#BIG PROBLEM HERE
#UPGRADES DONT SHOW UP UNTIL YOU UNLOCK THEM
#UPGRADES CAN BE UNLOCKED OUT OF ORDER
#THUS UPGRADES HAVE TO BE UNLOCKED IN REAL TIME AND THEIR ID NEEDS TO BE UNIQUE TO THEIR FUNCTION
#THEY NEED A SEPERATE POSITION TO WHERE THEY ARE IN THE CONTAINER
#FOR THE SAKE OF MY SANITY LETS HAVE NEWLY UNLOCKED UPGRADES GO TO THE BOTTOM 
func initializeUpgrades(upgradeTab : int) -> void:
	#OPEN FILE READ DATA
	var upgrades = 1
	for i in range(upgrades):
		tab = upgradeTab
		var tempUpgrade = upgradeBase.instantiate()
		#tempUpgrade.setParams(eyeDee : int, imagePath : String, upgradeText : String, upgMoney : String, RichUB = "1", uB = 1, uC = 1.0, uE = 1.0)
		connect(tempUpgrade.upgradeClick, _on_upgrade_upgrade_click)
		add_child(tempUpgrade)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
	
	panelCont.connect(tempPanel.crumpled, panelCont._crumpledCatch)
	panelCont.add_child(tempPanel)

#Run this based on the count 

#offset should be global pos of child
#should add a degree to it based on the ending pos
func _spawn(offset : Vector2, col : Color) -> void:
	var tempPanel = panelParticles.instantiate()
	tempPanel.modulate = col
	var angle = rng.randf_range(PI/4, 3*PI/4)
	var veloc = rng.randf_range(0.75, 1.75) * Vector2.from_angle(angle)
	angle = rng.randf_range(PI/4, 3*PI/4)
	var secVeloc = rng.randf_range(0.75, 1.75) * Vector2.from_angle(angle)
	match type:
		1:
			tempPanel.initialize(offset, veloc, secVeloc, upgradeText1)
		2:
			tempPanel.initialize(offset, veloc, secVeloc, upgradeText2)
		3:
			tempPanel.initialize(offset, veloc, secVeloc, upgradeText3)
	add_child(tempPanel)

func _on_upgrade_upgrade_click(eyeDee: int, upgradeCost: float, count: int, offset: Vector2, color: Color) -> void:
	upgradeSuccess.emit(tab, eyeDee, upgradeCost, count)
	_createPanel(offset, color)

#Tbh I should put the spawn code in here but just in caseI want to add something later
func _on_panel_container_crumpled(offset: Vector2, col: Color) -> void:
	_spawn(offset, col)
