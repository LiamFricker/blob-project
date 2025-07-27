extends Node2D

@export var tentacle_number: int = 0 
#Like a clock starting from 1, 0. Since we don't add that many tentacles and it doesn't happen a lot,
#We should reset them each time to their proper spots. 
#Set Amplitude to 1 when you're ready to use it. Just make it not visible else.
#Handle all the interactions with signals and stuff. Tentacles will need to be able to attack and
#maybe pick up stuff.
#Add the whip and attack. Maybe also the grab though that can be later idk

var tween

#Whip Vars
var whipping:bool = false 
var whipAmp:float = 0.0
var whipSpeed:float = 1.0

#Search Vars
var searching:bool = false


"""
Tentacle Amounts:
0:
1: down
2: at bottom corners
3: at l/r/b
4: at l/r bottom mids
5: at l/r/b bottom corners
6: 5 with 1 top corner right
7: 5 with top corners
8: 7 without b but bottom mids
9: 7 with bottom mids
"""

var busyState = false #If charging or performing an action 

func _process(_delta:float) -> void:
	if whipping:
		$Node2D/Line2D.material.set_shader_parameter("whip_direction", whipAmp)  

func _on_detection_area_entered(area: Area2D) -> void:
	var c:float = Vector2(-self.global_position.y, self.global_position.x).dot(area.global_position) 
	if tween:
		tween.kill()
	tween = create_tween()
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D2.set_deferred("disabled", false)
	if c >= PI/2.0 or c < -0.0:
		tween.tween_property($Node2D, "rotation", PI/3, 1)
		tween.paralle().tween_property($Hitbox, "rotation", PI/3, 1)
		tween.tween_property($Node2D, "rotation", PI/3, 0.2)
		tween.paralle().tween_property($Hitbox, "rotation", PI/3, 1)
	else:
		tween.tween_property($Node2D, "rotation", -PI/3, 1)
		tween.paralle().tween_property($Hitbox, "rotation", -PI/3, 1)
		tween.tween_property($Node2D, "rotation", -PI/3, 0.2)
		tween.paralle().tween_property($Hitbox, "rotation", -PI/3, 0.2)
	tween.tween_property($Node2D, "rotation", 0, 1)
	tween.paralle().tween_property($Hitbox, "rotation", 0, 1)
	tween.tween_callback(self.endSearch)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if searching:
		if tween:
			tween.tween_property($Node2D, "rotation", 0, 1)
			tween.paralle().tween_property($Hitbox, "rotation", 0, 1)
		tween.tween_callback(self.endSearch)

func endSearch() -> void:
	searching = false
	$Hitbox/CollisionShape2D.set_deferred("disabled", false)
	$Hitbox/CollisionShape2D2.set_deferred("disabled", true)
	
func whip(reverse = 1) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	print("WHIP")
	whipping = true
	tween.tween_property(self, "whipAmp", reverse*1.0, 0.8/whipSpeed)
	tween.parallel().tween_property($Node2D, "rotation", PI/16 *reverse, 0.8/whipSpeed)
	tween.tween_property(self, "whipAmp", reverse*1.05, 0.1/whipSpeed)
	tween.tween_property(self, "whipAmp", reverse*0.95, 0.1/whipSpeed)
	tween.tween_property(self, "whipAmp", reverse*1.05, 0.1/whipSpeed)
	tween.tween_property(self, "whipAmp", reverse*0.95, 0.1/whipSpeed)
	tween.tween_property(self, "whipAmp", 0, 0.2 *1/whipSpeed)
	tween.tween_callback(self.reverseWhip.bind(reverse))

func reverseWhip(reverse:int) -> void:
	$Node2D/Line2D.material.set_shader_parameter("reverse_direction", true)  
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "whipAmp", reverse*1.0, 0.2/whipSpeed)
	tween.parallel().tween_property($Node2D, "scale", Vector2(2, 1), 0.2/whipSpeed)
	tween.parallel().tween_property($Node2D, "rotation", -PI/1.5 *reverse, 0.2/whipSpeed)
	tween.tween_property(self, "whipAmp", 0.0, 1.5 *1/whipSpeed)
	tween.parallel().tween_property($Node2D, "scale", Vector2(1, 1), 1.5 *1/whipSpeed)
	tween.parallel().tween_property($Node2D, "rotation", 0, 1.5 *1/whipSpeed)
	tween.tween_callback(self.endWhip)

func endWhip() -> void:
	$Node2D/Line2D.material.set_shader_parameter("reverse_direction", false)  
	whipping = false

func tentConfig() -> void:
	$Node2D/Line2D.material.set_shader_parameter("amplitude", 1.0)
	match tentacle_number:
		0:
			position = Vector2(4, -4)
			rotation = -PI/4
		1:
			position = Vector2(8, 0)
			rotation = 0
		2:
			position = Vector2(4, 4)
			rotation = PI/4
		3:
			position = Vector2(2, 6)
			rotation = 3*PI/8
		4:
			position = Vector2(0, 8)
			rotation = PI/2
		5:
			position = Vector2(-2, 6)
			rotation = 5*PI/8
		6:
			position = Vector2(-4, 4)
			rotation = 3*PI/4
		7:
			position = Vector2(8, 0)
			rotation = PI
		8:
			position = Vector2(-4, -4)
			rotation = -3*PI/4
		
