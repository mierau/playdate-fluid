import "fluid"

local graphics = playdate.graphics
local geometry = playdate.geometry

local setup = false
local last_frame_time = 0
local fluid = Fluid.new(0, 180, 400, 240-180)
local cursor = { x = 220, y = 30 }
local toy1 = { x = 0, y = 0 }
local toy2 = { x = 250, y = 0 }
local surf_delay = 0

local CURSOR_SPEED = 200
local FILL_SPEED = 20
local BOAT_VELOCITY = 20

function playdate.update()
	if not setup then
		setup = true
		
		-- Setup game refresh rate.
		playdate.display.setRefreshRate(50)
		
		-- Seed random number generator.
		local s, ms = playdate.getSecondsSinceEpoch()
		math.randomseed(ms+s)
	end
	
	-- Calculate time since last frame.
	local current_time <const> = playdate.getCurrentTimeMilliseconds()
	local dt = (current_time - last_frame_time) / 1000
	if last_frame_time == 0 then dt = 0 end
	last_frame_time = current_time
	
	update(dt)
	draw()
	
	playdate.drawFPS(5, 223)
end

function draw()
		-- Clear
	graphics.clear(graphics.kColorWhite)
	
	-- Draw cursor
	graphics.setColor(graphics.kColorBlack)
	graphics.setLineWidth(2)
	graphics.drawCircleAtPoint(cursor.x, cursor.y, 10)
	
	-- Draw toys
	graphics.setColor(graphics.kColorXOR)
	graphics.fillRect(toy1.x - 15, toy1.y - 8, 30, 10)
	graphics.setColor(graphics.kColorXOR)
	graphics.fillCircleAtPoint(toy2.x, toy2.y, 30)
	
	-- Draw fluid
	graphics.setColor(graphics.kColorWhite)
	fluid:fill()
	graphics.setColor(graphics.kColorBlack)
	graphics.setDitherPattern(0.5)
	fluid:fill()

end

function update(dt)
	fluid:update()
	updateCursor(dt)
	updateToys(dt)
	updateFill(dt)
end

function updateCursor(dt)
	local old_x <const> = cursor.x
	local old_y <const> = cursor.y
	local dx = 0
	local dy = 0
	
	-- Move cursor.
	if playdate.buttonIsPressed(playdate.kButtonLeft) then
		dx = -CURSOR_SPEED * dt
	elseif playdate.buttonIsPressed(playdate.kButtonRight) then
		dx = CURSOR_SPEED * dt
	end
	if playdate.buttonIsPressed(playdate.kButtonUp) then
		dy = -CURSOR_SPEED * dt
	elseif playdate.buttonIsPressed(playdate.kButtonDown) then
		dy = CURSOR_SPEED * dt
	end
	
	cursor.x += dx
	cursor.y += dy
	
	-- Splash or surf water if cursor is touching surface.
	surf_delay = math.max(surf_delay - dt, 0)
	if cursor.y ~= old_y or cursor.x ~= old_x then
		if old_y < fluid.bounds.y and cursor.y >= fluid.bounds.y then
			fluid:touch(cursor.x, 8)
			surf_delay = 0.3
		elseif old_y > fluid.bounds.y and cursor.y <= fluid.bounds.y then
			fluid:touch(cursor.x, -8)
			surf_delay = 0.3
		elseif surf_delay == 0 and cursor.y < (fluid.bounds.y + 10) and cursor.y > (fluid.bounds.y - 10) then
			fluid:touch(cursor.x, 2)
		end
	end
end

function updateToys(dt)
	-- Move toy boat around.
	toy1.x += BOAT_VELOCITY * dt
	if toy1.x > fluid.bounds.width or toy1.x < 0 then
		BOAT_VELOCITY *= -1
	end
	
	-- Update toy positions.
	local toy1_position <const> = fluid:getPointOnSurface(toy1.x)
	toy1.y = toy1_position.y
	local toy2_position <const> = fluid:getPointOnSurface(toy2.x)
	toy2.y = toy2_position.y
end

function updateFill(dt)
	-- Skip filling adjustments if no buttons pressed.
	if not playdate.buttonIsPressed(playdate.kButtonA) and not playdate.buttonIsPressed(playdate.kButtonB) then
		return
	end
		
	-- Slowly fill up and drain
	local fluid_bounds = fluid.bounds
	
	-- Fill or drain.
	if playdate.buttonIsPressed(playdate.kButtonA) then
		fluid_bounds.height += FILL_SPEED * dt
	elseif playdate.buttonIsPressed(playdate.kButtonB) then
		fluid_bounds.height -= FILL_SPEED * dt
	end
	fluid_bounds.y = 240 - fluid_bounds.height
	fluid:setBounds(fluid_bounds.x, fluid_bounds.y, fluid_bounds.width, fluid_bounds.height)
end