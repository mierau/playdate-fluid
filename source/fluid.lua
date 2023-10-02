-- Library by Dustin Mierau
-- GitHub: @mierau

import "CoreLibs/graphics"

local graphics <const> = playdate.graphics
local geometry <const> = playdate.geometry
local math_max <const> = math.max
local math_min <const> = math.min
local math_ceil <const> = math.ceil
local math_floor <const> = math.floor

local function round(num)
	return num + 0.5 - (num + 0.5) % 1
end

local function clamp(val, min, max)
	return val < min and min or val > max and max or val
end

Fluid = {}
Fluid.__index = Fluid

function Fluid.new(x, y, width, height, options)
	options = options or {}

	local fluid = {}
	setmetatable(fluid, Fluid)

	-- Set default options.
	fluid.tension = options.tension or 0.03 -- Wave stiffness.
	fluid.dampening = options.dampening or 0.0025 -- Wave oscillation.
	fluid.speed = options.speed or 0.06 -- Wave speed.
	fluid.vertex_count = options.vertices or 20

	-- Allocate vertices.
	fluid.vertices = table.create(fluid.vertex_count, 0)

	-- Allocate polygon.
	fluid.polygon = geometry.polygon.new(fluid.vertex_count + 2)
	fluid.polygon:close()

	-- Set bounds.
	fluid:setBounds(x, y, width, height)

	-- Initialize.
	fluid:reset()

	return fluid
end

function Fluid:moveTo(x, y)
	self:setBounds(x, y, self.bounds.width, self.bounds.height)
end

function Fluid:moveBy(dx, dy)
	self:setBounds(self.bounds.x + dx, self.bounds.y + dy, self.bounds.width, self.bounds.height)
end

function Fluid:setBounds(x, y, width, height)
	self.bounds = geometry.rect.new(x, y, width, height)

	-- Update fluid column width.
	self.column_width = width / (self.vertex_count - 1)

	-- Update height of vertices.
	self.wave_range = {tallest = nil, shortest = nil}
	for _, v in pairs(self.vertices) do
		local height_delta <const> = v.height - v.natural_height
		v.natural_height = height
		v.height = height + height_delta
		self.wave_range.tallest = math.ceil(math.max(self.wave_range.tallest or v.height, v.height))
		self.wave_range.shortest = math.floor(math.min(self.wave_range.shortest or v.height, v.height))
	end

	-- Move vertices.
	self:updatePolygon()
end

function Fluid:reset()
	-- Reset vertices to 0.
	for i = 1, self.vertex_count do
		self.vertices[i] = {
			height = self.bounds.height,
			natural_height = self.bounds.height,
			velocity = 0
		}
	end

	self.wave_range = {tallest = self.bounds.height, shortest = self.bounds.height}

	-- Move vertices.
	self:updatePolygon()
end

function Fluid:getPointOnSurface(x)
	return self.polygon:pointOnPolygon(clamp(x - self.bounds.x, 0, self.bounds.width))
end

function Fluid:touch(x, velocity)
	-- Don't allow touches outside the bounds of the water surface.
	if x < self.bounds.x or x > self.bounds.x + self.bounds.width then
		return
	end

	-- Apply velocity to vertex at touch point.
	local vertex_index <const> = clamp(round((((x - self.bounds.x) / self.bounds.width) * (self.vertex_count - 1)) + 1), 1, self.vertex_count)
	self.vertices[vertex_index].velocity = -velocity
end

function Fluid:updatePolygon()
	for i, vertex in pairs(self.vertices) do
		self.polygon:setPointAt(i, self.bounds.x + ((i-1) * self.column_width), (self.bounds.y + self.bounds.height) - vertex.height)
	end

	-- Set bottom right and left vertices.
	local fluid_bottom <const> = self.bounds.y + self.bounds.height
	self.polygon:setPointAt(self.vertex_count + 1, self.bounds.x + self.bounds.width, fluid_bottom)
	self.polygon:setPointAt(self.vertex_count + 2, self.bounds.x, fluid_bottom)
end

-- Assuming that math.huge, math.max, and math.min are localized at the top of your file
local math_huge = math.huge
local math_max = math.max
local math_min = math.min

function Fluid:update()
	local wave_range = self.wave_range
	local vertices = self.vertices
	local tension = self.tension
	local dampening = self.dampening
	local speed = self.speed
	local bounds = self.bounds
	local bounds_x = bounds.x
	local bounds_height = bounds.height
	local bounds_y = bounds.y
	local column_width = self.column_width
	local polygon = self.polygon
	local vertex_count = self.vertex_count

	-- Pre-compute and cache
	local tension_dampening = tension - dampening
	local speed_double = speed * 2

	-- Initialize wave_range variables to extreme values
	local tallest = -math.huge
	local shortest = math.huge

	-- Use a batch to update vertices
	local batch_size = 4  -- or any other number that makes sense for your case
	for i = 1, vertex_count, batch_size do
		for j = 0, batch_size - 1 do
			if i + j <= vertex_count then
				local v = vertices[i + j]
				local velocity = v.velocity
				velocity += tension_dampening * (v.natural_height - v.height)
				local new_height = v.height + velocity
				v.height = new_height
				v.velocity = velocity

				tallest = (new_height > tallest) and new_height or tallest
				shortest = (new_height < shortest) and new_height or shortest
			end
		end
	end

	-- Coarse-grained tasks
	-- Combine left and right propagation to reduce loop overhead
	for i = 1, vertex_count do
		local vertex = vertices[i]
		local height = vertex.height
		local velocity = vertex.velocity

		if i > 1 then
			local left_vertex = vertices[i - 1]
			local left_change = speed * (height - left_vertex.height)
			left_vertex.velocity += left_change
			left_vertex.height += left_change
		end

		if i < vertex_count then
			local right_vertex = vertices[i + 1]
			local right_change = speed * (height - right_vertex.height)
			right_vertex.velocity += right_change
			right_vertex.height += right_change
		end

		-- Inline simple polygon update
		local new_point_y = (bounds_y + bounds_height) - height
		polygon:setPointAt(i, bounds_x + ((i - 1) * column_width), new_point_y)
	end

	wave_range.tallest = tallest
	wave_range.shortest = shortest
end

function Fluid:getWaveBounds()
	return geometry.rect.new(self.bounds.x, (self.bounds.y + self.bounds.height) - self.wave_range.tallest, self.bounds.width, self.wave_range.tallest - self.wave_range.shortest)
end

function Fluid:fill()
	graphics.fillPolygon(self.polygon)
end

function Fluid:draw()
	graphics.drawPolygon(self.polygon)
end
