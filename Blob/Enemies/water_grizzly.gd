extends Node2D

enum {
	IDLE,
	AGGRESSION, 
	CHARGE_SWIPE,
	SWIPE,
	DEAD
}
var state = IDLE

var PlayerRef : Node2D
var TargetRef : Node2D
var playerTarget : bool = false

@onready var Inner = $InnerNode

var ID : int = -1

@export var max_health: float = 100
@onready var health = max_health
var difficulty = 0
@export var base_damage : float = 1

@export var charge_time : float = 100

@export var swipe_length : float = 100
var swing_speed : float = 1.0
var direction_angle: float = 1.0

var MapULBound: Vector2
var MapDRBound: Vector2
var homepos : Vector2

var move_tween

var current_attack = 0
var phase = 1

var swipe_count = 0
const swipe_max = 3

const follow_range_squared = 4000000 

#dot (poison)
var dot_remaining
var dot_pow
enum{
	NONE, VIRUS, POISON
} 
var dot_type = NONE
var dot_tween

func _init(TopLeftBound : Vector2, BotRightBound : Vector2, origin = Vector2.ZERO, diff = 0, boss_count = 0) -> void:
	MapULBound = TopLeftBound
	MapDRBound = BotRightBound
	homepos = origin
	difficulty = diff
	ID = -(1+boss_count)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _stateMachine() -> void:
	pass

func _chooseNextAttack() -> void:
	if playerTarget:
		#0: Run, 1: Swipe, 2: Dash
		match current_attack:
			0:
				_runStart()
			1:
				_swipeStart()
			2:
				_dashStart()
	else:
		_swipeStart()
		
#Set run speed scale to 1.25x
#Set run charge to 1.5x for first attack in phase 2. Either that or make a shorter duration version
func _runStart() -> void:
	pass

func _runEnd() -> void:
	
	if phase == 1 or swipe_count == 0:
		current_attack = 1
		swipe_count = 0
	else:
		current_attack = 2
		swipe_count = 0

func _swipeStart() -> void:
	#I don't think the ear wags really do matter that much, so let's just get rid of them for now.
	#If you think it's fun after trying it, you can add it in later.
	#Maybe in Phase 3 have a mechanic where the ear wags do actually matter with larger dirctional hitbox.
	#Maybe in Phase 3 also add in feints too. You can reverse the animation to do so.
	$AnimationPlayer.speed_scale = swing_speed
	match swipe_count:
		0:
			$AnimationPlayer.play("LeftSwingStart")
		1:
			$AnimationPlayer.play("RightSwingStart")
		2:
			$AnimationPlayer.play("LeftSwingStart")
		swipe_max:
			swipe_count = -1
			current_attack = 0
			_chooseNextAttack()
			return
	
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	var temp_angle = _getTargetDirection()
	var end_angle = log(temp_angle+1) if temp_angle < 0 else log(-temp_angle+1)
	move_tween.tween_property(self, rotation, end_angle, 0.3 / swing_speed)
	move_tween.tween_parallel(self, direction_angle, temp_angle, 0.3 / swing_speed)
	

func _swipeRelease(isLeft : bool) -> void:
	var angleOffset : float 
	if isLeft:
		angleOffset = -PI/6
		$AnimationPlayer.play("LeftSwingEnd")
	else:
		angleOffset = PI/6
		$AnimationPlayer.play("RightSwingEnd")
	
	var swipeEndLoc : Vector2 = getPosition() + swipe_length * Vector2.from_angle(direction_angle+angleOffset)
	
	move_tween.tween_property(Inner, position, swipeEndLoc, 0.45 / swing_speed)
	
func _dashStart() -> void:
	pass
	
func _phaseChange() -> void:
	match phase:
		1:
			phase = 2
			swipe_count = 0
		2:
			phase = 3

func _sceneTransition(next_scene : int) -> void:
	match next_scene:
		0:
			pass
		1:
			pass

func _getTargetDirection() -> float:
	var targetPos : Vector2 = TargetRef.getPosVector2
	var tempAng = getPosition().angle_to_point(targetPos) - (PI / 2) #this should be base direction
	return tempAng if tempAng > -PI else 2*PI + tempAng

func _aggressionTrigger(playerFound : bool) -> void:
	if playerFound:
		state = AGGRESSION
	else:
		_findClosestTarget()
		
#Use the 
func _findClosestTarget() -> void:
	var DetectionNode = $InnerNode/BroadDetectionRadius
	DetectionNode.monitoring = true
	if not (DetectionNode.has_overlapping_areas() or DetectionNode.has_overlapping_bodies()):
		TargetRef = null
		state = IDLE
	var localAreas = DetectionNode.get_overlapping_areas()
	#Could probably do a mapped lambda function here but I'm lazy
	
	var minDistance = follow_range_squared
	var tempPos = getPosition()
	var currDist = 0
	var closestNodeRef
	for a in localAreas:
		var mainbody = a.getParent()
		if mainbody.ID == ID:
			continue
		currDist = tempPos.distance_squared_to(mainbody.getPosition()) 
		if currDist < minDistance:
			minDistance = currDist
			closestNodeRef = mainbody
	
	var localBodies = DetectionNode.get_overlapping_bodies()
	
	for b in localBodies:
		if b.ID == ID:
			continue
		currDist = tempPos.distance_squared_to(b.getPosition()) 
		if currDist < minDistance:
			minDistance = currDist
			closestNodeRef = b
	
	TargetRef = closestNodeRef
	state = AGGRESSION
	
func _onPlayerDetection(PlayRef : Node2D) -> void:
	#Disable the detection radius
	$InnerNode/DetectionRadius.monitoring = false
	PlayerRef = PlayRef
	TargetRef = PlayerRef
	playerTarget = true
	$PlayerDistanceCheck.start()
	_aggressionTrigger(true)

func addPosition(addpos : Vector2) -> void:#, dims : Vector2) -> void:
	position += addpos  
	#for c in children_list:
	#	c.addPosition(addpos)

func increaseVirusLevel(type : int, intensity : float, duration = 2.0) -> void: #ID : int, 
	#Virus immunity
	pass

func applyPoison(intensity : float, duration = 2.0) -> void: #ID : int, 
	var dotLeft = 0
	dot_type = POISON
	if dot_tween:
		dot_tween.kill()
		if dot_remaining == -1:
			dotLeft = dot_remaining * dot_pow
	dot_tween = create_tween()
	dot_tween.tween_method(_dot_tick, 0, int(dotLeft + intensity*duration), duration) #ID, 
	dot_tween.tween_callback(_dot_end.bind(false))
	dot_pow = intensity
	dot_remaining = 0

func _dot_tick(dot_speed : int, type : int = 0) -> void:
	health -= (dot_speed - dot_remaining)
	dot_remaining = dot_speed
	if health <= 0:
		if dot_tween:
			dot_tween.kill()
		_dot_end(true, type)	#ID, 

func _dot_end(death : bool, type : int = 0) -> void: #ID : int, 
	dot_remaining = -1
	if death:
		_OnDeath()		
		
func takeDamage(amt : float, _kwargs = []) -> void:
	if state == IDLE:
		_aggressionTrigger(false)
	health -= amt
	if health <= 0:
		_OnDeath()	

func _OnDeath() -> void:
	state = DEAD
	visible = false
	toggleHitbox(false)
	toggleHurtbox(false)
	set_process(false)

#Override this if needs be (such as multiple hitboxes)
func toggleHitbox(toggle : bool) -> void:
	pass
	#if hitboxReference:
	#	hitboxReference.set_deferred("monitoring", toggle)
	#	hitboxReference.set_deferred("monitorable", toggle)
	
#Override this if needs be (such as multiple hurtboxes)
func toggleHurtbox(toggle : bool) -> void:
	pass
	#if hurtboxReference:
	#	hurtboxReference.set_deferred("monitoring", toggle)
	#	hitboxReference.set_deferred("monitorable", toggle)

#Use this to get the position for the creature
func getPosition() -> Vector2:
	return position + Inner.position


func _on_player_distance_check_timeout() -> void:
	#Might need a null check here
	var playerPos = PlayerRef.getPosition() 
	if getPosition().distance_squared_to(PlayerRef.getPosition()) > follow_range_squared:
		_findClosestTarget()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"LeftSwingStart":
			_swipeRelease(true)
		"RightSwingStart":
			_swipeRelease(false)
