extends MultiMeshInstance3D
class_name Tracers
## An extension of MultiMeshInstance3D used to draw bullet tracers.[br][br]
##
## Use the boilerplate to request tracer instances from a pool and let this node handle the rest![br][br]
##
## References [Tracers.TracerInstance]

## The maximum amount of tracer instances which can be drawn.
const MAX_TRACERS : int = 256

@onready var current_tracer : int = -1:
	set(to_what):
		current_tracer = to_what % MAX_TRACERS

## An individual Tracer instance.
class TracerInstance:
	## The Index in the MultiMesh buffer for this Tracer.
	var idx : int = -1
	## The length of this Tracer.
	var length : float = 1.0
	## The width of this Tracer.
	var width : float = 1.0
	## The speed of this Tracer in meters per-second.
	var speed : float = 60.0
	## The remaining lifetime of this Tracer.
	var lifetime : float = 1.0:
		set(to_what):
			lifetime = maxf(to_what, 0.0)
	
	func _init(_idx:int = -1, _len:float = 1.0, _width:float = 1.0, _speed:float = 60.0, _lifetime:float = 1.0) -> void:
		idx = _idx
		length = _len
		width = _width
		speed = _speed
		lifetime = _lifetime
	
	## A method to reset this Tracer's properties.[br][br]
	## Best used when this tracer instance's lifetime is zero.
	func refresh(_len:float = 1.0, _width:float = 1.0, _speed:float = 60.0, _lifetime:float = 1.0) -> void:
		length = _len
		width = _width
		speed = _speed
		lifetime = _lifetime
	
	## A method to invoke each frame.
	func process(delta:float) -> void:
		lifetime -= delta

## An array retaining references to indexed [Tracers.TracerInstance], each holding
## data relevant to the corresponding tracer in this [MultiMeshInstance3D]'s
## [MultiMesh].
@onready var live_tracers : Array[TracerInstance] = []

func _ready() -> void:
	add_to_group("Tracer")
	for i in range(0, MAX_TRACERS):
		var tracer := TracerInstance.new(i)
		live_tracers.append(tracer)
		var trans := Transform3D.IDENTITY
		trans.basis *= 0.001
		multimesh.instance_count += 1
		multimesh.set_instance_transform(multimesh.instance_count-1, trans)

func request_tracer(origin:Transform3D, length:float = 1.0, width:float = 1.0, speed:float = 60.0, lifetime:float = 1.0) -> void:
	current_tracer += 1
	print(current_tracer)
	var tracer := live_tracers[current_tracer]
	multimesh.set_instance_transform(current_tracer, origin)
	tracer.refresh(length, width, speed, lifetime)


func _process(delta:float):
	
	for tracer in live_tracers:
		if tracer.lifetime:
			# Lots of necessary stuff, since we'll be reusing tracers instead of reconstruction.
			var trans := multimesh.get_instance_transform(tracer.idx)
			trans.origin += trans.basis.z * tracer.speed * delta
			trans.basis = trans.basis.orthonormalized()
			trans.basis.x *= tracer.width
			trans.basis.y *= tracer.width
			trans.basis.z *= tracer.length
			multimesh.set_instance_transform(tracer.idx, trans)
			tracer.process(delta)
		else:
			var trans := Transform3D.IDENTITY
			trans.basis *= 0.001
			multimesh.set_instance_transform(tracer.idx, trans)
	pass
