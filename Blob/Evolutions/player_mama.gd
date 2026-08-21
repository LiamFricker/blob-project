extends "res://Blob/base_evo_dmg.gd"

var targetRef : Node2D
@export var detection_range : float = 250 

var movement_tween
@export var cooldown : float = 15.0

#@onready var Sprite = $Sprite

const bullets_max = 3
var bullets_inactive = [true, true, true]
var shoot_queued : bool = false
@export var bullet_size : float = 0.0
@export var attack_speed : float = 1.0

var queued_rotation : float = 0.0

const bullet_id = 1022

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var newShape = CircleShape2D.new()
	newShape.radius = detection_range
	$InnerNode/DetectionRange/CollisionShape2D.set_deferred("shape", newShape)
	
	spawnFriend.emit(bullet_id, bullets_max, self)

func changeRot(newangle : float) -> void:
	if not $AnimationPlayer.is_playing():
	#	queued_rotation = newangle
	#else:
		rotation = newangle
	queued_rotation = newangle

func freeBullet(bullet_id : int) -> void:
	bullets_inactive[bullet_id] = true
	if shoot_queued:
		shoot_queued = false
		_shootLogic(children_list[bullet_id])
		

func _shootProj(bullet_used : Area2D) -> void:
	var mimiPos = Vector2(91.0, 101.0).rotated(rotation) + getPosition()
	
	bullet_used.updateParams(damage, knockback, bullet_size)
	bullet_used.initBullet(mimiPos, rotation + -PI/2, 10.0)	
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Spawn":
		$CooldownTimer.start()
		if queued_rotation != rotation:
			rotation = queued_rotation

func _on_cooldown_timer_timeout() -> void:
	_shootLogic(null)
	
func _shootLogic(bullet_used : Area2D) -> void:
	if not bullet_used:
		for i in range(bullets_max):
			if bullets_inactive[i]:
				bullet_used = children_list[i]
				break
		if not bullet_used:
			shoot_queued = true
			return
	
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_interval(0.5)
	movement_tween.tween_callback(_shootProj.bind(bullet_used))

	$AnimationPlayer.play("Spawn")
