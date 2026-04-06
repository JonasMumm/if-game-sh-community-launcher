class_name wobbler
extends RefCounted

var target : float;
var current : float;
var dampingLambda : float;
var acceleration : float;
var speed : float;
var idleWobbleProtection : bool;

func _init(cur : float, tar : float, acc : float, damping: float, speedo : float, idleWobbleProtect : bool):
	current = cur
	target = tar
	acceleration = acc
	dampingLambda = damping
	speed = speedo
	idleWobbleProtection=idleWobbleProtect
	
func update(deltaTime : float) -> float:
	var delta = target - current;
	if (delta == 0 && abs(speed) < deltaTime * acceleration * 0.25): 
		return current;
	var maxAccel = 0
	
	if idleWobbleProtection:
		maxAccel = min(abs(delta), deltaTime * acceleration)
	else:
		maxAccel = deltaTime * acceleration
	speed += sign(delta) * maxAccel;
	speed = Damp(speed, 0, dampingLambda, deltaTime);
	current += speed * deltaTime;
	return current;

static func Damp(a : float, b : float, lambda : float, dt : float) -> float:
	return lerp(a, b, 1- exp(-lambda * dt))
