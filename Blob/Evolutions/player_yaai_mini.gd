extends "res://Blob/base_spawned_bullet.gd"

var movement_tween
var oscillate_tween

@export var update_rate = 0.5
var lifetime = 8.0

var changed = false

@onready var SecondHitbox = $SecondaryHitbox

signal creation_complete(orb_id : int, alive : bool)

func _setSize() -> void:
	var tempShape = RectangleShape2D.new()
	tempShape.size = size * Vector2(64, 64)
	$CollisionShape2D.set_deferred("shape", tempShape)
	$SecondaryHitbox/CollisionShape2D.set_deferred("shape", tempShape)
	$Sprite.scale = size * Vector2(1,1)

func updateParams(dmg : float, kb : float, sz : float) -> void:
	super(dmg, kb, sz)
	SecondHitbox.damage = dmg
	SecondHitbox.knockback = kb

func setBulletParams(pR : Node2D, bulID : int) -> void:
	super(pR, bulID)
	$SecondaryHitbox.parentRef = pR
		
func initBullet(currPos : Vector2, finalPos : Vector2, currRot : float, progress : float, lt : float = 8.0) -> void:
	set_deferred("process_mode", PROCESS_MODE_INHERIT)
	show()
	
	_startOscillate(progress)
	
	$Sprite/Tiny.scale = Vector2(1,1)
	$Sprite/Tiny.modulate = Color(1,1,1,1)
	$Sprite/Full.scale = Vector2(1,1)
	$Sprite/Full.modulate = Color(1,1,1,0)
	
	z_index = -1
	changed = false
	lifetime = lt
	
	var duration = currPos.distance_to(finalPos) / 150.0
	currRot = angle_difference(currRot+2*PI, 0)
	
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	print(currPos, " ", finalPos)
	movement_tween.tween_property(self, "position", finalPos, duration).from(currPos)
	movement_tween.parallel().tween_property($Sprite/Tiny, "position:y", -40, duration)#.set_delay(duration*0.25)
	movement_tween.parallel().tween_property($Sprite, "rotation", 0, duration * 0.6).from(currRot)
	movement_tween.finished.connect(endInit)	

func _startOscillate(progress : float) -> void:
	if oscillate_tween:
		oscillate_tween.kill()
	oscillate_tween = create_tween()
	var osc_time : float = 0.6
	if progress < 0.5:
		
		if progress < 0.25:
			var prog_reduc = progress/0.25
			var rev_reduc = (1.0 - prog_reduc)
			var osc_reduc_time = osc_time * rev_reduc
			#var transp_reduc = (Color.WHITE).lerp(Color(1,1,1,0), prog_reduc)
			
			oscillate_tween.tween_property($Sprite/Tiny/Black, "modulate:a", 0, osc_reduc_time).from(rev_reduc)
			oscillate_tween.parallel().tween_property($Sprite/Full/Black, "modulate:a", 0, osc_reduc_time).from(rev_reduc)
			oscillate_tween.parallel().tween_property($Sprite/Tiny/White, "modulate:a", 1, osc_reduc_time).from(prog_reduc)
			oscillate_tween.parallel().tween_property($Sprite/Full/White, "modulate:a", 1, osc_reduc_time).from(prog_reduc)
			oscillate_tween.tween_interval(osc_time)
			
		else:
			$Sprite/Tiny/White.modulate = Color.WHITE
			$Sprite/Tiny/Black.modulate = Color(1,1,1,0)
			var osc_reduc_time = osc_time * (1.0 - (progress-0.25)/0.25)
			oscillate_tween.tween_interval(osc_reduc_time)
	if progress < 0.75:	
		var prog_reduc = (progress-0.5)/0.25
		var rev_reduc = (1.0 - prog_reduc)
		var osc_reduc_time = osc_time * rev_reduc
		#var transp_reduc = (Color.WHITE).lerp(Color(1,1,1,0), prog_reduc)
		#var white_reduc = (Color.WHITE).lerp(Color(1,1,1,0), 1.0-prog_reduc)
		oscillate_tween.tween_property($Sprite/Tiny/Black, "modulate:a", 1, osc_reduc_time).from(prog_reduc)
		oscillate_tween.parallel().tween_property($Sprite/Full/Black, "modulate:a", 1, osc_reduc_time).from(prog_reduc)
		oscillate_tween.parallel().tween_property($Sprite/Tiny/White, "modulate:a", 0, osc_reduc_time).from(rev_reduc)
		oscillate_tween.parallel().tween_property($Sprite/Full/White, "modulate:a", 0, osc_reduc_time).from(rev_reduc)
		oscillate_tween.tween_interval(osc_time)
	else:
		$Sprite/Tiny/Black.modulate = Color.WHITE
		$Sprite/Tiny/White.modulate = Color(1,1,1,0)
		var osc_reduc_time = osc_time * (1.0 - (progress-0.75)/0.5)
		oscillate_tween.tween_interval(osc_reduc_time)
	
	oscillate_tween.finished.connect(_oscillate)

# Called when the node enters the scene tree for the first time.
func _oscillate() -> void:
	var osc_time = 1.0 if changed else 0.6
	
	if oscillate_tween:
		oscillate_tween.kill()
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

func endInit() -> void:
	z_index = 0
	$AnimationPlayer.play("transform")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		#"create":
			#creation_complete.emit(bullet_id)
		"transform":
			$Lifetime.start(lifetime)
			changed = true
			if movement_tween:
				movement_tween.kill()
			movement_tween = create_tween().set_loops()
			movement_tween.tween_callback(switchHitboxes.bind(true))
			movement_tween.tween_interval(update_rate)
			movement_tween.tween_callback(switchHitboxes.bind(false))
			movement_tween.tween_interval(update_rate)
		"death":
			_OnDeath()

func switchHitboxes(ttoggle : bool) -> void:
	#set_deferred("monitorable", ttoggle)
	#SecondHitbox.set_deferred("monitorable", not ttoggle)
	$CollisionShape2D.set_deferred("disabled", not ttoggle)
	$SecondaryHitbox/CollisionShape2D.set_deferred("disabled", ttoggle)

func _on_lifetime_timeout() -> void:
	if movement_tween:
		movement_tween.kill()
		
	#set_deferred("monitorable", false)
	#SecondHitbox.set_deferred("monitorable", false)
	#SecondHitbox.set_deferred("monitorable", false)
	$CollisionShape2D.set_deferred("disabled", true)
	$SecondaryHitbox/CollisionShape2D.set_deferred("disabled", true)
	$AnimationPlayer.play("death")
	
func _explode() -> void:
	if movement_tween:
		movement_tween.kill()
	movement_tween = create_tween()
	movement_tween.tween_property($Sprite, "modulate:v", 0.0, 0.4)
	movement_tween.parallel().tween_property($Sprite, "modulate:a", 0.0, 0.4)
	movement_tween.finished.connect(_OnDeath)

func _OnDeath() -> void:
	creation_complete.emit(bullet_id, false)
	super()
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	hide()
	if oscillate_tween:
		oscillate_tween.kill()
		
func connectDMG(calla : Callable) -> void:
	damagedEnemy.connect(calla)
	$SecondaryHitbox.connectDMG(calla)
	
