-- New Fireworks by googol
-- https://forum.minetest.net/viewtopic.php?f=9&t=16721
-- License: LGPLv2.1+
-- Modified by Talas for colourhop

ch_fireworks = {}

local rocket = {
	physical = false,
	collisionbox = {0, -0.5, 0, 0, 0.5, 0},
	visual = "sprite",
	textures = {"rocket_low.png"},
	timer = 0,
	rocket_firetime = 0,
	glow = 30,
	static_save = false,
}

local function calc_ball_figure(r)
	local tab = {}
	local num = 1
	for x=-r,r,0.01 do
		for y=-r,r,0.01 do
			for z=-r,r,0.01 do
				if x*x+y*y+z*z <= r*r and x*x+y*y+z*z >= (r-0.005)*(r-0.005) then
					if math.random(1,4) > 1 then
						local xrand = math.random(-3, 3) * 0.001
						local yrand = math.random(-3, 3) * 0.001
						local zrand = math.random(-3, 3) * 0.001
						tab[num] = {x=x+xrand, y=y+yrand, z=z+zrand, v=43}
					end
					num = num + 1
				end
			end
		end
	end
	return tab
end

local ball_figure = calc_ball_figure(0.1)

-- Keep track of how many particles are probably active right now.
local particle_times = {}
local now = 0
minetest.register_globalstep(function(dtime) now = now + dtime end)

-- Activate fireworks
local function partcl_gen(pos, tab, size_min, size_max, colour)
	-- Prune expired particles.
	local pt = {}
	for i = 1, #particle_times do
		local v = particle_times[i]
		if v >= now then pt[#pt + 1] = v end
	end

	for _,i in pairs(tab) do
		if math.random(1, 4) == 1 and math.random(1, 1000) >= #pt then
			minetest.add_particle({
				pos = {x=pos.x, y=pos.y, z=pos.z},
				velocity = {x=i.x*i.v, y=i.y*i.v, z=i.z*i.v},
				acceleration = {x=0, y=-1.5, z=0},
				expirationtime = 3,
				size = math.random(size_min, size_max),
				collisiondetection = true,
				vertical = false,
				animation = {type = "vertical_frames", aspect_w = 9, aspect_h = 9, length = 3.5},
				glow = 30,
				texture = "anim_"..colour.."_star.png",
			})
			pt[#pt + 1] = now + 3
		end
	end

	particle_times = pt
end

function rocket:on_activate(staticdata)
	local tmp = minetest.deserialize(staticdata)
	self.colour = tmp["colour"]
	self.high = tmp["high"]
	self.shield = tmp["shield"]
	self.sound = minetest.sound_play("simple_fireworks_rocket", {object=self.object,
							 max_hear_distance = 13, gain = 1})
	self.rocket_flytime = math.random(13, 14)/10
	self.object:set_velocity({x=0, y=9, z=0})
	if self.high then
		self.rocket_flytime = self.rocket_flytime * 1.1
		self.object:set_properties({ textures = {"rocket_high.png"} })
		self.object:set_acceleration({x=math.random(-4, 4), y=37, z=math.random(-4, 4)})
	elseif self.shield then
		self.object:set_properties({ textures = {"rocket_shield.png"} })
		self.object:set_acceleration({x=math.random(-5, 5), y=22, z=math.random(-5, 5)})
	else
		self.object:set_acceleration({x=math.random(-5, 5), y=19, z=math.random(-5, 5)})
	end
end

-- Called periodically
function rocket:on_step(dtime)
	local explode_early = false
	self.timer = self.timer + dtime
	self.rocket_firetime = self.rocket_firetime + dtime
	if self.rocket_firetime > 0.1 then
		local pos = self.object:get_pos()
		self.rocket_firetime = 0
		local xrand = math.random(-15, 15) / 10
		local zrand = math.random(-15, 15) / 10
		minetest.add_particle({
			pos = {x=pos.x, y=pos.y-0.4, z=pos.z},
			velocity = {x=xrand, y=-3, z=xrand},
			acceleration = {x=0, y=0, z=0},
			expirationtime = 1.5,
			size = 3,
			collisiondetection = true,
			vertical = false,
			animation = {type="vertical_frames", aspect_w = 9, aspect_h = 9, length = 1.6},
			glow = 10,
			texture = "anim_white_star.png",
		})
		if ch_draconis.dragon ~= nil then
			local dragon = ch_draconis.dragon
			local dist = vector.distance(self.object:get_pos(), dragon.object:get_pos())
			if dist < 8 then
				explode_early = true
				if self.sound then
					minetest.sound_stop(self.sound)
					self.sound = nil
				end
			end
		end
	end
	if explode_early or self.timer > self.rocket_flytime then
		minetest.sound_play("simple_fireworks_bang", {pos=self.object:get_pos(),
								 max_hear_distance = 90, gain = 3})
		partcl_gen(self.object:get_pos(), ball_figure, 6, 8, self.colour)
		ch_draconis.check_fireworks_hit(self.object:get_pos(), self.shield)
		self.object:remove()
	end
end

minetest.register_entity("ch_fireworks:rocket", rocket)

ch_fireworks.launch = function(pos, colour, high_altitude, shield_breaker)
	local tmp = minetest.serialize({colour = colour, high = high_altitude, shield = shield_breaker})
	local obj = minetest.add_entity(pos, "ch_fireworks:rocket", tmp)
	return obj
end
