extends Node2D

class_name base_child

var parentReference
@export var health_max: float = 0
var health : float 
#var ID: int = 0
var isOrphan : bool = false

@export var hitboxReference : Area2D
@export var hurtboxReference : Area2D

#State: 
#1:
#2: dead
#var state: int = 0

func disable() -> void:
	#state = 2
	call_deferred("queue_free")

#Override this if needs be (such as multiple hitboxes)
func toggleHitbox(toggle : bool) -> void:
	hitboxReference.monitoring = toggle
	
#Override this if needs be (such as multiple hurtboxes)
func toggleHurtbox(toggle : bool) -> void:
	hurtboxReference.monitoring = toggle

func addPosition(addpos : Vector2) -> void:#, dims : Vector2) -> void:
	#You can make this slightly more efficient if you make this calculation 
	#On the top level where it's called instead of down here where it has to be ran
	#multiple times.
	#Wow I guess me from fucking 2 weeks ago already fixed that problem but I'm too 
	#fucking stupid to realize it.
	#Anyways, you can make it slightly more efficient if you calculate it in the top function
	#Since multiple zones change at once, but that's really minimal gains.
	
	position += addpos  

func orphan() -> void:
	isOrphan = true

func _OnDeath() -> void:
	#state = 2
	if not isOrphan:
		#If this doesn't work, we'll need IDs back
		parentReference.removeChild(self)
	visible = false
	toggleHitbox(false)
	toggleHurtbox(false)
	set_process(false)
		
