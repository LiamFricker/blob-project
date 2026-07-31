extends "res://Blob/base_player_attack.gd"

var bomb_tween

func initExplosion(col : int, tickLoops : int) -> void:
	match col:
		0:
			#Waddle
			$EmptyPlayerTest.modulate = Color8(214, 172, 19, 150)
			
		1:
			#Board
			$EmptyPlayerTest.modulate = Color8(0, 225, 255, 200)
		2:
			#Frog
			$EmptyPlayerTest.modulate = Color8(74, 255, 125, 180) #(0, 255, 132, 150)
	bomb_tween = create_tween().set_loops(tickLoops)
	bomb_tween.tween_property($EmptyPlayerTest, "modulate:r", 0.5, 0.15).as_relative()
	bomb_tween.parallel().tween_property($EmptyPlayerTest, "modulate:v", 0.25, 0.15).as_relative()
	bomb_tween.tween_property($EmptyPlayerTest, "modulate:r", -0.5, 0.15).as_relative()
	bomb_tween.parallel().tween_property($EmptyPlayerTest, "modulate:v", -0.25, 0.15).as_relative()
	bomb_tween.finished.connect(_explosion)

func _explosion()-> void:
	$EmptyPlayerTest.hide()
	$AnimatedSprite2D.show()
	$AnimatedSprite2D.play("default")
	toggle(true)
	if bomb_tween:
		bomb_tween.kill()
	bomb_tween = create_tween()
	bomb_tween.tween_interval(0.4)
	bomb_tween.tween_property($AnimatedSprite2D, "modulate:v", 0.0, 0.75)#.as_relative()
	#bomb_tween.parallel().tween_property($AnimatedSprite2D, "modulate:v", 0.0, 0.75)#.as_relative()
	bomb_tween.parallel().tween_property($AnimatedSprite2D, "modulate:a", 0.0, 0.35).set_delay(0.45)
	bomb_tween.finished.connect(_delete)

func _delete() -> void:
	parentRef.removeChild(self)
	call_deferred("queue_free")
