extends "res://Blob/base_enemy_attachment.gd"

signal creation_complete(orb_id)

var orbit_id
var changed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var osc_time = 1.0 if changed else 0.6
	
	oscillate_tween = create_tween().set_loops()
	oscillate_tween.tween_property($Sprite/Tiny/Black, "modulate:a", 0, osc_time)
	oscillate_tween.parallel().tween_property($Sprite/Full/Black, "modulate:a", 0, osc_time)
	oscillate_tween.parallel().tween_property($Sprite/Tiny/White, "modulate:a", 1, osc_time)
	oscillate_tween.parallel().tween_property($Sprite/Full/White, "modulate:a", 1, osc_time)
	oscillate_tween.tween_interval(osc_time)
	oscillate_tween.tween_property($Sprite/Tiny/Black, "modulate:a", 1, osc_time)
	oscillate_tween.parallel().tween_property($Sprite/Full/Black, "modulate:a", 1, osc_time)
	oscillate_tween.parallel().tween_property($Sprite/Tiny/White, "modulate:a", 0, osc_time)
	oscillate_tween.parallel().tween_property($Sprite/Full/White, "modulate:a", 0, osc_time)
	oscillate_tween.tween_interval(osc_time)

func setParams(dmg : float, pR : Node2D, kb = 0.0, sz = 0.0, orb_id = 1) -> void:
	orbit_id = orb_id
	super(dmg, pR, kb, sz)

func initSelf(currPos : Vector2, finalPos : Vector2, currRot : float, currIndex : int) -> void:

	var duration = currPos.distance_to(finalPos) / 100.0
	
	z_index = currIndex
	
	movement_tween = create_tween()
	movement_tween.tween_property(self, "position", finalPos, duration).from(currPos)
	movement_tween.parallel().tween_property($Sprite/Tiny, "position:y", -40, duration)
	movement_tween.parallel().tween_property(self, "rotation", 0, duration * 0.25).from(currRot)
	movement_tween.finished.connect(endInit)
	
func endInit() -> void:
	z_index = 0
	$AnimationPlayer.play("transform")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"create":
			creation_complete.emit(orbit_id)
		"transform":
			$Hitbox.set_deferred("monitoring", true)
			$Lifetime.start()
			changed = true
		"death":
			_delete()


func _on_hitbox_area_entered(_area: Area2D) -> void:
	print("AREA ENTERED?")

func _on_hitbox_body_entered(body: Node2D) -> void:
	var tempRef = body.getAttachNode()
	if tempRef.idCount(ID) >= 1:
		tempRef.triggerDamage(damage)
		$Lifetime.stop()
		_on_lifetime_timeout()
	else:
		$Hitbox.set_deferred("monitoring", false)
		#attachRef.remove_child(self)
		attachRef.call_deferred("remove_child", self)
		attachRef = tempRef
		tempRef.attachSelf(self, ID)
		attached = true
		position = Vector2.ZERO
		$Lifetime.start(10)

func orphan(_pos : Vector2) -> void:
	
	_on_lifetime_timeout()

func _on_lifetime_timeout() -> void:
	#if attachRef:
	"""
	if attached:
		attachRef.attachDeath(ID)
	else:
		attachRef.removeChild(self)
	"""
	
	if movement_tween:
		movement_tween.kill()
	
	$Hitbox.set_deferred("monitoring", false)
	$AnimationPlayer.play("death")
