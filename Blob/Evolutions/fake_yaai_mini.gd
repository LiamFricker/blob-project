extends Node2D

var oscillate_tween
var progress : float = 0
@export var orb_id : int = 0

signal creation_complete(orb_id : int, alive : bool)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var osc_time = 1.0
	
	oscillate_tween = create_tween().set_loops()
	oscillate_tween.tween_property($Sprite/Tiny/Black, "modulate:a", 0, osc_time)
	oscillate_tween.parallel().tween_property($Sprite/Tiny/White, "modulate:a", 1, osc_time)
	oscillate_tween.parallel().tween_property(self, "progress", 0.5, osc_time*2).from(0)
	#oscillate_tween.tween_interval(osc_time)
	oscillate_tween.tween_property($Sprite/Tiny/Black, "modulate:a", 1, osc_time)
	oscillate_tween.parallel().tween_property($Sprite/Tiny/White, "modulate:a", 0, osc_time)
	oscillate_tween.parallel().tween_property(self, "progress", 1.0, osc_time*2)
	#oscillate_tween.tween_interval(osc_time)

func setSize(size : float) -> void:
	$Sprite.scale = size * Vector2(1,1)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	creation_complete.emit(orb_id, true)

func create() -> void:
	show()
	_ready()
	$AnimationPlayer.play("create")

func vanish() -> float: 
	hide()
	if oscillate_tween:
		oscillate_tween.kill()
	return progress
