# Value Spring

A very simple addon for Godot 4 that allows the user to
animate whatever values they want from code, based on
[this video](https://www.youtube.com/watch?v=KPoeNZZ6H4s) by t3ssel8r.

It adds the following objects:

- `ValueSpring`
  - A type of `Resource` that can be used from any node to animate arbitrary values.
- `SpringFollower3D` and `SpringFollower2D`
  - A node that uses two `ValueSpring`s to follow another node in 3D or 2D space.
  These cover the most basic usage of the `ValueSpring`, as well as serving as
  an example of how to use them in code.

The plugin also includes a simple visualization of the spring behavior when
viewing any `ValueSpring` resource.

The springs can be used with most `Variant` types that support basic math
symbols, namely these:

- `float`
- `Vector2`
- `Vector3`
- `Vector4`
- `Quaternion`
- `Color`

Additionally, the following integer-based types will *technically* work,
but due to their whole number nature the result will probably not be very good.

- `int`
- `Vector2i`
- `Vector3i`
- `Vector4i`

The `Color` type will be animated in OKHSL space.

## Usage

Once installed into your addons folder, you can add a new resource
as an exported variable to your node scripts, and edit the settings of it
from the inspector:

```gdscript
@export var spring: ValueSpring
```

Since the spring can support many types of Variants, make sure you call
the `spring_reset()` method early in your node's lifetime to set the starting value.

For example, if you are making a node that follows another node, you might
set the starting value to that node's global position:

```gdscript
func _ready() -> void:
  var start_value = global_position
  spring.reset_spring(start_value)
```

You should then keep calling the update function of the spring to animate it,
and retrieve the updated value:

```gdscript
func _process(delta: float) -> void:
  global_position = update(delta, target_pos)
```

One `SpringValue` should generally be used to animate one thing. If you want
to animate more than one value, use two separate `SpringValue`s.

Please also check out the example scene to see the spring in action!

## License

The code for this project is [unlicensed](/LICENSE.md) - which is to say,
it is public domain and you can do whatever you want with it.

If you want to credit me in your game, feel free - but it is not a requirement.
