extends Node2D

#Ngl I don't give a shit about optimizing this
#Let's just disable the ones we don't need and call it a day

@export var tentacle_total = 9
#@export var tentacle_scene : PackedScene

@onready var tentacle_list = [$Tentacle0, $Tentacle1, $Tentacle2, $Tentacle3, $Tentacle4, $Tentacle5, $Tentacle6, $Tentacle7, $Tentacle8]
var tentacle_tween
var oscillate_tween

var chargeTentacleSpin = 0
var reverseTentacleSpin = 0
var charge_max = 0
var charge_cooldown = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
"""
func createTentacle(count : int) -> void:
	var tempTentacle = tentacle_scene.instantiate()
	tentacle_list.append(tempTentacle)
	add_child(tempTentacle)
"""

func updateTentacles(upgraded = false) -> void:
	match tentacle_total:
		1:
			$Tentacle4.enable()
		2:
			if upgraded:
				$Tentacle4.disable()
			$Tentacle2.enable()
			$Tentacle6.enable()
		3:
			if upgraded:
				$Tentacle2.disable()
				$Tentacle6.disable()
			$Tentacle1.enable()
			$Tentacle4.enable()
			$Tentacle7.enable()
		4:
			if upgraded:
				$Tentacle4.disable()
			else:
				$Tentacle1.enable()
				$Tentacle7.enable()
			$Tentacle3.enable()
			$Tentacle5.enable()
		5:
			if upgraded:
				$Tentacle3.disable()
				$Tentacle5.disable()
			else:
				$Tentacle1.enable()
				$Tentacle7.enable()
			$Tentacle2.enable()
			$Tentacle4.enable()
			$Tentacle6.enable()
		6:
			if upgraded:
				$Tentacle2.disable()
				$Tentacle4.disable()
				$Tentacle6.disable()
			else:
				$Tentacle1.enable()
				$Tentacle7.enable()
			$Tentacle3.enable()
			$Tentacle5.enable()
			$Tentacle0.enable()
			$Tentacle8.enable()
		7:
			if upgraded:
				$Tentacle3.disable()
				$Tentacle5.disable()
			else:
				$Tentacle1.enable()
				$Tentacle7.enable()
				$Tentacle0.enable()
				$Tentacle8.enable()
			$Tentacle2.enable()
			$Tentacle4.enable()
			$Tentacle6.enable()
		8:
			if upgraded:
				$Tentacle4.disable()
			else:
				$Tentacle1.enable()
				$Tentacle7.enable()
				$Tentacle0.enable()
				$Tentacle8.enable()
				$Tentacle2.enable()
				$Tentacle6.enable()
			$Tentacle3.enable()
			$Tentacle5.enable()
		9:
			if not upgraded:
				$Tentacle1.enable()
				$Tentacle7.enable()
				$Tentacle0.enable()
				$Tentacle8.enable()
				$Tentacle2.enable()
				$Tentacle6.enable()
				$Tentacle3.enable()
				$Tentacle5.enable()
			$Tentacle4.enable()

func resetCharge(cutoff : bool) -> void:#distance:float, angle:float) -> void:
	if cutoff:
		$InnerNode/Sprite/Node2D.position = Vector2(0,0)
		for t in tentacle_list:
			t.reset()
	

#I HATE THIS I WANT THIS TO LOOK BETTER THIS IS DISGUSTING DISGUSTING 
#Oh well another time when I'm better at coding 
#hopefully I can smooth it out in testing
#Let's keep this one this way since this might be called every frame. 
#If we find a better way of doing that (I have one in my brain)
#We can change it to the more visually pleasing way
func handleTentacleShader():
	match tentacle_total:
		1:
			tentacle_list[4].setDirection(chargeTentacleSpin)
		2:
			tentacle_list[2].setDirection(chargeTentacleSpin)
			tentacle_list[6].setDirection(chargeTentacleSpin)
		3:
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[4].setDirection(chargeTentacleSpin)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		4:
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[3].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			tentacle_list[5].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		5:
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[2].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			
			tentacle_list[4].setDirection(chargeTentacleSpin)
			
			tentacle_list[6].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		6:
			tentacle_list[0].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			tentacle_list[3].setDirection(chargeTentacleSpin+reverseTentacleSpin*3)
						
			tentacle_list[5].setDirection(chargeTentacleSpin-reverseTentacleSpin*3)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[8].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		7:
			tentacle_list[0].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			tentacle_list[2].setDirection(chargeTentacleSpin+reverseTentacleSpin*3)
			
			tentacle_list[4].setDirection(chargeTentacleSpin)
			
			tentacle_list[6].setDirection(chargeTentacleSpin-reverseTentacleSpin*3)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[8].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		8:
			tentacle_list[0].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			tentacle_list[2].setDirection(chargeTentacleSpin+reverseTentacleSpin*3)
			tentacle_list[3].setDirection(chargeTentacleSpin+reverseTentacleSpin*4)
						
			tentacle_list[5].setDirection(chargeTentacleSpin-reverseTentacleSpin*4)
			tentacle_list[6].setDirection(chargeTentacleSpin-reverseTentacleSpin*3)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[8].setDirection(chargeTentacleSpin-reverseTentacleSpin)
		9:
			tentacle_list[0].setDirection(chargeTentacleSpin+reverseTentacleSpin)
			tentacle_list[1].setDirection(chargeTentacleSpin+reverseTentacleSpin*2)
			tentacle_list[2].setDirection(chargeTentacleSpin+reverseTentacleSpin*3)
			tentacle_list[3].setDirection(chargeTentacleSpin+reverseTentacleSpin*4)
			
			tentacle_list[4].setDirection(chargeTentacleSpin)
			
			tentacle_list[5].setDirection(chargeTentacleSpin-reverseTentacleSpin*4)
			tentacle_list[6].setDirection(chargeTentacleSpin-reverseTentacleSpin*3)
			tentacle_list[7].setDirection(chargeTentacleSpin-reverseTentacleSpin*2)
			tentacle_list[8].setDirection(chargeTentacleSpin-reverseTentacleSpin)

"""
	Tentacle Amounts:
	0:
	1: 4
	2: 26
	3: 147
	4: 1357
	5: 12467
	6: 013578
	7: 0124678
	8: 01235678
	9: 012345678
	4: 1,3,7,9
	26: 2,5,7,8,9
	35: 4,6,8,9
	17: 3+
	08: 6+
"""
	
func handleTentacleSqueeze():
	if tentacle_tween:
		tentacle_tween.kill()
	tentacle_tween = create_tween().set_parallel()
	#Don't bother making this efficient, just make it readable please.
	if tentacle_total >= 6: 
		tentacle_tween.tween_property(tentacle_list[0], "position", Vector2(4, -2), charge_max)
		tentacle_tween.tween_property(tentacle_list[8], "position", Vector2(-4, -2), charge_max)
		
	if tentacle_total >= 7 or tentacle_total == 2 or tentacle_total == 5:
		tentacle_tween.tween_property(tentacle_list[2], "position", Vector2(4, 2), charge_max)
		tentacle_tween.tween_property(tentacle_list[6], "position", Vector2(-4, 2), charge_max)
	
	if tentacle_total >= 8 or tentacle_total == 4 or tentacle_total == 9:
		tentacle_tween.tween_property(tentacle_list[3], "position", Vector2(2, 2), charge_max)
		tentacle_tween.tween_property(tentacle_list[5], "position", Vector2(-2, 2), charge_max)
	
	if tentacle_total % 2 == 1 and tentacle_total != 5:
		tentacle_tween.tween_property(tentacle_list[4], "position", Vector2(0, 2), charge_max)

func handleTentacleChargeSwipe(temp : float, charge_cd : float) -> void:
	if tentacle_tween:
		tentacle_tween.kill()
	tentacle_tween = create_tween().set_parallel()
	
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween().set_parallel()
	
	if tentacle_total >= 6: 
		tentacle_tween.parallel().tween_property(tentacle_list[0], "position", Vector2(4, -4-3.6*temp), 0.08 * charge_cd)
		tentacle_tween.parallel().tween_property(tentacle_list[8], "position", Vector2(-4, -4-3.6*temp), 0.08 * charge_cd)
		
		oscillate_tween.parallel().tween_property(tentacle_list[0], "rotation", PI/2, 0.3 * charge_cd)
		oscillate_tween.parallel().tween_property(tentacle_list[8], "rotation", -3*PI/2, 0.3 * charge_cd)
		
		tentacle_tween.parallel().tween_property(tentacle_list[0], "position", Vector2(4, -4), 0.3 * charge_cooldown)
		tentacle_tween.parallel().tween_property(tentacle_list[8], "position", Vector2(-4, -4), 0.3 * charge_cooldown)
		
		oscillate_tween.parallel().tween_property(tentacle_list[0], "rotation", -PI/4, 0.6 * charge_cooldown)
		oscillate_tween.parallel().tween_property(tentacle_list[8], "rotation", -3*PI/4, 0.6 * charge_cooldown)
	
	if tentacle_total >= 3:
		tentacle_tween.parallel().tween_property(tentacle_list[1], "position", Vector2(6, -3.6*temp), 0.08 * charge_cd)
		tentacle_tween.parallel().tween_property(tentacle_list[7], "position", Vector2(-6, -3.6*temp), 0.08 * charge_cd)
		
		oscillate_tween.parallel().tween_property(tentacle_list[1], "rotation", PI/2, 0.3 * charge_cd)
		oscillate_tween.tween_property(tentacle_list[7], "rotation", PI/2, 0.3 * charge_cooldown)
		
		tentacle_tween.parallel().tween_property(tentacle_list[1], "position", Vector2(8, 0), 0.3 * charge_cooldown)
		tentacle_tween.parallel().tween_property(tentacle_list[7], "position", Vector2(-8, 0), 0.3 * charge_cooldown)
		
		oscillate_tween.tween_property(tentacle_list[1], "rotation", 0, 0.6 * charge_cooldown)
		oscillate_tween.parallel().tween_property(tentacle_list[7], "rotation", PI, 0.6 * charge_cooldown)
		
	if tentacle_total >= 7 or tentacle_total == 2 or tentacle_total == 5:
		tentacle_tween.parallel().tween_property(tentacle_list[2], "position", Vector2(4, 4-3.6*temp), 0.08 * charge_cd)
		tentacle_tween.parallel().tween_property(tentacle_list[6], "position", Vector2(-4, 4-3.6*temp), 0.08 * charge_cd)
		
		oscillate_tween.parallel().tween_property(tentacle_list[2], "rotation", PI/2, 0.3 * charge_cd)
		oscillate_tween.parallel().tween_property(tentacle_list[6], "rotation", PI/2, 0.3 * charge_cd)
		
		tentacle_tween.parallel().tween_property(tentacle_list[2], "position", Vector2(4, 4), 0.3 * charge_cooldown)
		tentacle_tween.parallel().tween_property(tentacle_list[6], "position", Vector2(-4, 4), 0.3 * charge_cooldown)
		
		oscillate_tween.parallel().tween_property(tentacle_list[2], "rotation", PI/4, 0.6 * charge_cooldown)
		oscillate_tween.parallel().tween_property(tentacle_list[6], "rotation", 3*PI/4, 0.6 * charge_cooldown)
		
	if tentacle_total >= 8 or tentacle_total == 4 or tentacle_total == 9:
		tentacle_tween.parallel().tween_property(tentacle_list[3], "position", Vector2(2, 6-3.6*temp), 0.08 * charge_cd)
		tentacle_tween.parallel().tween_property(tentacle_list[5], "position", Vector2(-2, 6-3.6*temp), 0.08 * charge_cd)
		
		oscillate_tween.parallel().tween_property(tentacle_list[3], "rotation", PI/2, 0.3 * charge_cd)
		oscillate_tween.parallel().tween_property(tentacle_list[5], "rotation", PI/2, 0.3 * charge_cd)
		
		tentacle_tween.parallel().tween_property(tentacle_list[3], "position", Vector2(2, 6), 0.3 * charge_cooldown)
		tentacle_tween.parallel().tween_property(tentacle_list[5], "position", Vector2(-2, 6), 0.3 * charge_cooldown)
		
		oscillate_tween.parallel().tween_property(tentacle_list[3], "rotation", 3*PI/8, 0.6 * charge_cooldown)
		oscillate_tween.parallel().tween_property(tentacle_list[5], "rotation", 5*PI/8, 0.6 * charge_cooldown)
	
	if tentacle_total % 2 == 1 and tentacle_total != 5:
		tentacle_tween.parallel().tween_property(tentacle_list[4], "position", Vector2(0, 8-3.6*temp), 0.08 * charge_cd)
		
		tentacle_tween.parallel().tween_property(tentacle_list[4], "position", Vector2(0, 8), 0.3 * charge_cooldown)
