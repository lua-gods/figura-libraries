### Class Name: `SpringAPI`

example code
```lua
local mySpring = Spring.newVec3(
	0.5, -- Response Speed
	0.1, -- Damping Coeficient
	0 -- Initial Response Strength
)
:setGravity(vec(0, -9.8, 0)) -- constant force being applied
:setGuardrailRadius(2) -- maximum distance of the spring
```

# Methods
|Returns|Methods|
|-|-|
|`GN.Spring<T>` |SpringAPI.[new](#springapinewresponsespeed-dampingcoeficient-initialresponsestrength-zero)(responseSpeed : T?, dampingCoeficient : T?, initialResponseStrength : T?, zero : T?)|
|`GN.Spring<Vector2>` |SpringAPI.[newVec2](#springapinewvec2responsespeed-dampingcoeficient-initialresponsestrength)(responseSpeed : Vector2｜number, dampingCoeficient : Vector2｜number, initialResponseStrength : Vector2｜number)|
|`GN.Spring<Vector3>` |SpringAPI.[newVec3](#springapinewvec3responsespeed-dampingcoeficient-initialresponsestrength)(responseSpeed : Vector3｜number, dampingCoeficient : Vector3｜number, initialResponseStrength : Vector3｜number)|
## `SpringAPI.new(responseSpeed, dampingCoeficient, initialResponseStrength, zero)`
### Arguments
- `T?` `responseSpeed`

- `T?` `dampingCoeficient`

- `T?` `initialResponseStrength`

- `T?` `zero`

### Returns `GN.Spring<T>`

## `SpringAPI.newVec2(responseSpeed, dampingCoeficient, initialResponseStrength)`
### Arguments
- `Vector2|number` `responseSpeed`

- `Vector2|number` `dampingCoeficient`

- `Vector2|number` `initialResponseStrength`

### Returns `GN.Spring<Vector2>`

## `SpringAPI.newVec3(responseSpeed, dampingCoeficient, initialResponseStrength)`
### Arguments
- `Vector3|number` `responseSpeed`

- `Vector3|number` `dampingCoeficient`

- `Vector3|number` `initialResponseStrength`

### Returns `GN.Spring<Vector3>`

---
---
---

### Class Name: `GN.Spring`
# Properties
|Type|Field|Description| |
|-|-|-|-|
|`T`|accel|...| |
|`T`|dampingCoeficient|...| |
|`T`|gravity|...| |
|`T`|guardrailRadius|...| |
|`integer`|id|...| |
|`T`|initialResponseStrength|...| |
|`T`|lpos|...| |
|`T`|ltarget|...| |
|`T`|pos|...| |
|`T`|responseSpeed|...| |
|`T`|target|...| |
|`T`|vel|...| |
# Methods
|Returns|Methods|
|-|-|
|`T` |Spring:[samplePos](#springsampleposself-delta)(self : GN.Spring<T>, delta : number?)|
|`T` |Spring:[sampleTarget](#springsampletargetself-delta)(self : GN.Spring<T>, delta : number?)|
|`GN.Spring<T>` |Spring:[setPos](#springsetposself-pos)(self : GN.Spring<T>, pos : T)|
|`GN.Spring<T>` |Spring:[setTarget](#springsettargetself-pos)(self : GN.Spring<T>, pos : T)|
|`GN.Spring<T>` |Spring:[setGuardrailRadius](#springsetguardrailradiusself-radius)(self : GN.Spring<T>, radius : number)|
|`GN.Spring<T>` |Spring:[setGravity](#springsetgravityself-gravity)(self : GN.Spring<T>, gravity : T)|
||Spring:[free](#springfree)()|
|`GN.Spring<T>` |Spring:[impulse](#springimpulseself-x)(self : GN.Spring<T>, x : T)|
## `Spring:samplePos(self, delta)`
### Arguments
- `GN.Spring<T>` `self`

- `number?` `delta`

### Returns `T`

## `Spring:sampleTarget(self, delta)`
### Arguments
- `GN.Spring<T>` `self`

- `number?` `delta`

### Returns `T`

## `Spring:setPos(self, pos)`
### Arguments
- `GN.Spring<T>` `self`

- `T` `pos`

### Returns `GN.Spring<T>`

## `Spring:setTarget(self, pos)`
### Arguments
- `GN.Spring<T>` `self`

- `T` `pos`

### Returns `GN.Spring<T>`

## `Spring:setGuardrailRadius(self, radius)`
### Arguments
- `GN.Spring<T>` `self`

- `number` `radius`

### Returns `GN.Spring<T>`

## `Spring:setGravity(self, gravity)`
### Arguments
- `GN.Spring<T>` `self`

- `T` `gravity`

### Returns `GN.Spring<T>`

## `Spring:free()`

## `Spring:impulse(self, x)`
### Arguments
- `GN.Spring<T>` `self`

- `T` `x`

### Returns `GN.Spring<T>`

