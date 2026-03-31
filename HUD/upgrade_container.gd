extends VBoxContainer

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

#THIS NEEDS TO KEEP TRACK OF ALL THE UPGRADE CURRENCIES
var totalUpgradeCurrency = [0, 0]
var upgradeCurrencies = [[0, 0], [0, 0], [0, 0]]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _createPanel(global_pos : Vector2, text : int) -> void:
	var tempPanel = upgradePanel.instantiate()
	tempPanel.global_position = global_pos
	match text:
		1:
			tempPanel.sprite_frames = upgradeFrames1
		2:
			tempPanel.sprite_frames = upgradeFrames2
		3:
			tempPanel.sprite_frames = upgradeFrames3
	
	panelCont.connect(tempPanel.crumpled, panelCont._crumpledCatch)
	panelCont.add_child(tempPanel)

#Run this based on the count 

#offset should be global pos of child
#should add a degree to it based on the ending pos
func _spawn(offset : Vector2, text : int, col : Color) -> void:
	var tempPanel = panelParticles.instantiate()
	tempPanel.modulate = col
	var angle = rng.randf_range(PI/4, 3*PI/4)
	var veloc = rng.randf_range(0.75, 1.75) * Vector2.from_angle(angle)
	angle = rng.randf_range(PI/4, 3*PI/4)
	var secVeloc = rng.randf_range(0.75, 1.75) * Vector2.from_angle(angle)
	match text:
		1:
			tempPanel.initialize(offset, veloc, secVeloc, upgradeText1)
		2:
			tempPanel.initialize(offset, veloc, secVeloc, upgradeText2)
		3:
			tempPanel.initialize(offset, veloc, secVeloc, upgradeText3)
	add_child(tempPanel)


func _on_panel_container_emit_signal() -> void:
	pass # Replace with function body.


func _on_panel_container_crumpled(offset: Variant, texture: Variant) -> void:
	pass # Replace with function body.
