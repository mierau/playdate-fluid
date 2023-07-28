# Fluid for Playdate

This library is written in Lua using the Playdate SDK. It provides a way to create, draw, animate, and interact with fluid. The library is a minimal simulation to keep it speedy on device, so it is constrained mostly to wave simulation. However, as this is open source, please feel freet to add more functionality if you can keep it snappy.

![fluid](https://github.com/mierau/playdate-fluid/assets/55453/0b7ed325-1990-4415-99f5-55e04fe1e363)

# Use

Create a fluid box.
```lua
local fluid = Fluid.new(0, 180, 400, 240-180)
```

Update fluid each frame to run simulation.
```lua
function playdate.update()
   fluid:update()
end
```

Draw the fluid using fill() or draw()
```lua
graphics.setColor(graphics.kColorBlack)
graphics.setDitherPattern(0.5)
fluid:fill()
```

Cause waves by providing an x coord along the surface of the fluid and a velocity to interact with. Negative velocity makes the fluid go up, positive makes the fluid go down.
```lua
fluid:touch(20, -4)
```

And some utility functions you can use.
```lua
fluid:getPointOnSurface(x) # returns an x,y pair of the x coord on the surface of the fluid polygon.
fluid:getWaveBounds() # returns the rect of the fluid currently taking into account the height of the tallest wave.
fluid:moveTo(x, y) # use to move the fluid rect to another location on screen and update the internal polygon.
fluid:moveBy(dx, dy) # use to move the fluid rect relatively to another location on screen and update the internal polygon.
```
