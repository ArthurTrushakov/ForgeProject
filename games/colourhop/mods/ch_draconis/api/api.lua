------------------
-- Draconis API --
------------------
----- Ver 1.1 ----

local S = minetest.get_translator("ch_draconis")

local l_time = 0
local l_N = 2048
local l_samples = {}
local l_ctr = 0
local l_sumsq = 0
local l_sum = 0
local l_max = 0.1

----------
-- Math --
----------

local pi = math.pi
local random = math.random
local abs = math.abs
local min = math.min
local max = math.max
local floor = math.floor
local ceil = math.ceil
local deg = math.deg
local atan2 = math.atan2
local sin = math.sin
local cos = math.cos
local function R(x) -- Round to nearest multiple of 0.5
	return x + 0.5 - (x + 0.5) % 1
end
local function diff(a, b) -- Get difference between 2 angles
	return atan2(sin(b - a), cos(b - a))
end

local vec_dir = vector.direction
local vec_dist = vector.distance
local vec_new = vector.new
local vec_sub = vector.subtract
local vec_add = vector.add

local dir2yaw = minetest.dir_to_yaw
local yaw2dir = minetest.yaw_to_dir

local function clamp(n)
	if n < -180 then
		n = n + 360
	elseif n > 180 then
		n = n - 360
	end
	if n < -60 then
		n = -60
	elseif n > 60 then
		n = 60
	end
	return n
end

local function interp(a, b, w)
	if abs(a - b) > deg(pi) then
		if a < b then
			return ((a + (b - a) * w) + (deg(pi) * 2))
		elseif a > b then
			return ((a + (b - a) * w) - (deg(pi) * 2))
		end
	end
	return a + (b - a) * w
end

----------------------
-- Helper Functions --
----------------------

local str_find = string.find

local hitbox = mob_core.get_hitbox

local function find_closest_pos(tbl, pos)
	local iter = 2
	if #tbl < 2 then return end
	local closest = tbl[1]
	while iter < #tbl do
		if vec_dist(pos, closest) < vec_dist(pos, tbl[iter + 1]) then
			iter = iter + 1
		else
			closest = tbl[iter]
			iter = iter + 1
		end
	end
	if iter >= #tbl and closest then return closest end
end

local function get_collision_in_radius(pos, width, height)
	local pos1 = vector.new(pos.x - width, pos.y, pos.z - width)
	local pos2 = vector.new(pos.x + width, pos.y + height, pos.z + width)
	local collisions = {}
	for z = pos1.z, pos2.z do
		for y = pos1.y, pos2.y do
			for x = pos1.x, pos2.x do
				local npos = vector.new(x, y, z)
				local name = minetest.get_node(npos).name
				if minetest.registered_nodes[name].walkable then
					table.insert(collisions, npos)
				end
			end
		end
	end
	return collisions
end

local moveable = mob_core.is_moveable

function ch_draconis.get_collision_avoidance_pos(self)
	local width = hitbox(self)[4]
	local pos = self.object:get_pos()
	local yaw = self.object:get_yaw()
	local outset = width * 2
	local ahead = vector.add(pos, vector.multiply(minetest.yaw_to_dir(yaw), outset))
	local can_fit = moveable(ahead, width, self.height)
	if not can_fit then
		local collisions = get_collision_in_radius(ahead, width, self.height)
		local obstacle = find_closest_pos(collisions, pos)
		if obstacle then
			local avoidance_path = vector.normalize((vector.subtract(pos, obstacle)))
			local avoidance_pos = vector.add(pos, vector.multiply(avoidance_path, outset))
			local magnitude = (width * 2) - vec_dist(pos, obstacle)
			return avoidance_pos, magnitude
		end
	end
end

function ch_draconis.get_line_of_sight(a, b)
	local steps = floor(vec_dist(a, b))
	local line = {}

	for i = 0, steps do
		local pos

		if steps > 0 then
			pos = {
				x = a.x + (b.x - a.x) * (i / steps),
				y = a.y + (b.y - a.y) * (i / steps),
				z = a.z + (b.z - a.z) * (i / steps)
			}
		else
			pos = a
		end
		table.insert(line, pos)
	end

	if #line < 1 then
		return false
	else
		for i = 1, #line do
			local node = minetest.get_node(line[i])
			if minetest.registered_nodes[node.name].walkable
			and mobkit.get_node_height(line[i]) >= 4.5 then
				return false
			end
		end
	end
	return true
end

function ch_draconis.get_collision(self, dir, range)
	local pos = self.object:get_pos()
	local pos2 = vector.add(pos, vector.multiply(dir, range or 16))
	local ray = minetest.raycast(pos, pos2, false, false)
	for pointed_thing in ray do
		if pointed_thing.type == "node" then
			return true
		end
	end
	return false
end

function ch_draconis.ray_collision_detect(self)
	for i = 1, 179, 30 do
		local yaw_a = self.object:get_yaw() + math.rad(i)
		local dir_a = minetest.yaw_to_dir(yaw_a)
		local collision_a = ch_draconis.get_collision(self, dir_a, hitbox(self)[4] + 4)
		if collision_a then
			local yaw_b = self.object:get_yaw() + math.rad(-i)
			local dir_b = minetest.yaw_to_dir(yaw_b)
			local collision_b = ch_draconis.get_collision(self, dir_b, hitbox(self)[4] + 4)
			if not collision_b then
				return yaw_b
			end
		else
			return yaw_a
		end
	end
end

------------------
-- Registration --
------------------

function ch_draconis.register_dragon(type, def)
	local mobname = "ch_draconis:" .. type .. "_dragon"
	minetest.register_entity(mobname, {
		-- Stats
		max_hp = def.hp,
		view_range = 64,
		reach = 14,
		damage = 20,
		knockback = 4,
		lung_capacity = 60,
		floor_avoidance_range = 32,
		-- Movement & Physics
		max_speed = 16,
		stepheight = 1.76,
		jump_height = 1.26,
		max_fall = 100,
		buoyancy = 1,
		springiness = 0,
		turn_rate = 4,
		-- Visual
	glow = 3,
		collisionbox = {-2.45, 0, -2.45, 2.45, 5, 2.45},
		visual_size = {x = 35, y = 35},
		visual = "mesh",
		mesh = "draconis_dragon.b3d",
		textures = {
			"draconis_" .. type .. "_dragon_body.png^draconis_" .. type .. "_dragon_head_detail.png"
		},
		animation = {
			stand = {range = {x = 1, y = 60}, speed = 15, frame_blend = 0.3, loop = true},
			stand_fire = {range = {x = 70, y = 130}, speed = 15, frame_blend = 0.3, loop = true},
			wing_flap = {range = {x = 140, y = 200}, speed = 15, frame_blend = 0.3, loop = false},
			walk = {range = {x = 210, y = 250}, speed = 35, frame_blend = 0.3, loop = true},
			walk_fire = {range = {x = 260, y = 300}, speed = 35, frame_blend = 0.3, loop = true},
			takeoff = {range = {x = 310, y = 330}, speed = 25, frame_blend = 0.3, loop = false},
			fly_idle = {range = {x = 340, y = 380}, speed = 25, frame_blend = 0.3, loop = true},
			fly_idle_fire = {range = {x = 390, y = 430}, speed = 25, frame_blend = 0.3, loop = true},
			fly = {range = {x = 440, y = 480}, speed = 25, frame_blend = 0.3, loop = true},
			fly_fire = {range = {x = 490, y = 530}, speed = 25, frame_blend = 0.3, loop = true},
			dive_bomb = {range = {x = 540, y = 580}, speed = 25, frame_blend = 0.3, loop = true},
			death = {range = {x = 670, y = 670}, speed = 1, frame_blend = 2, prty = 3, loop = true},
			shoulder_idle = {range = {x = 680, y = 740}, speed = 10, frame_blend = 0.6, loop = true}
		},
		dynamic_anim_data = {
			yaw_factor = 0.11,
			swing_factor = 0.33,
			pivot_h = 0.5,
			pivot_v = 0.75,
			tail = {
				{ -- Segment 1
					pos = {
						x = 0,
						y = 0,
						z = 0
					},
					rot = {
						x = 180,
						y = 180,
						z = 1
					}
				},
				{ -- Segment 2
					pos = {
						x = 0,
						y = 0.7,
						z = 0
					},
					rot = {
						x = 0,
						y = 0,
						z = 1
					}
				},
				{ -- Segment 3
					pos = {
						x = 0,
						y = 1,
						z = 0
					},
					rot = {
						x = 0,
						y = 0,
						z = 1
					}
				},
				{ -- Segment 4
					pos = {
						x = 0,
						y = 1,
						z = 0
					},
					rot = {
						x = 0,
						y = 0,
						z = 1
					}
				}
			},
			head = {
				{ -- Segment 1
					pitch_offset = 20,
					bite_angle = -20,
					pitch_factor = 0.22,
					pos = {
						x = 0,
						y = 0.83,
						z = 0.036
					},
					rot = {
						x = 0,
						y = 0,
						z = 0
					}
				},
				{ -- Segment 2
					pitch_offset = -5,
					bite_angle = 10,
					pitch_factor = 0.22,
					pos = {
						x = 0,
						y = 0.45,
						z = 0
					},
					rot = {
						x = 0,
						y = 0,
						z = 0
					}
				},
				{ -- Segment 3
					pitch_offset = -5,
					bite_angle = 10,
					pitch_factor = 0.22,
					pos = {
						x = 0,
						y = 0.45,
						z = 0
					},
					rot = {
						x = 0,
						y = 0,
						z = 0
					}
				},
				{ -- Head
					pitch_offset = -20,
					bite_angle = 5,
					pitch_factor = 0.44,
					pos = {
						x = 0,
						y = 0.41,
						z = 0
					},
					rot = {
						x = 0,
						y = 0,
						z = 0
					}
				}
			}
		},
		-- Sound
		sounds = {
			roar = {
				{
					name = "draconis_dragon_teen_roar",
					gain = 1,
					distance = 512,
					length = 2.5
				}
			},
			random = {
				{
					name = "draconis_dragon_teen_random_1",
					gain = 1,
					distance = 512,
					length = 1
				},
				{
					name = "draconis_dragon_teen_random_2",
					gain = 1,
					distance = 512,
					length = 1
				},
				{
					name = "draconis_dragon_teen_roar",
					gain = 1,
					distance = 512,
					length = 2.5
				}
			},
			random2 = {
				{
					name = "draconis_dragon_adult_1",
					gain = 1,
					distance = 512,
					length = 2
				},
				{
					name = "draconis_dragon_adult_2",
					gain = 1,
					distance = 512,
					length = 3.5
				},
				{
					name = "draconis_dragon_adult_3",
					gain = 1,
					distance = 512,
					length = 4
				}
			},
			hurt = {
				{
					name = "draconis_dragon_hurt",
					gain = 1,
					distance = 512
				},
				{
					name = "draconis_dragon_hurt",
					gain = 1,
					pitch = 0.5,
					distance = 512
				},
				{
					name = "draconis_dragon_hurt",
					gain = 1,
					pitch = 0.25,
					distance = 512
				},
			},
			flap = {
				name = "draconis_flap",
				gain = 1,
				distance = 512
			}
		},
		-- Basic
		physical = true,
		collide_with_objects = false,
		static_save = true,
		defend_owner = true,
		push_on_collide = true,
		punch_cooldown = 0.25,
		follow = ch_draconis.global_meat,
		timeout = 0,
		open_jaw = ch_draconis.open_jaw,
		move_head = ch_draconis.move_head,
		move_tail = ch_draconis.move_tail,
		physics = ch_draconis.physics,
		logic = def.logic,
		get_staticdata = mobkit.statfunc,
		on_activate = ch_draconis.on_activate,
		on_step = ch_draconis.on_step,
		on_deactivate = function(self)
			-- TODO: instead of deleting immediately, we should let them time out slowly.
			self.hp = 0
			self.despawned = true
			ch_draconis.dragon = nil
			if not self.no_altar then
				ch_buildings.destroy_altar({x=self.altar_pos_x, y=self.altar_pos_y, z=self.altar_pos_z})
			end
			return
		end,
		on_rightclick = function(self, clicker)
			return
		end,
		on_punch = function(self, puncher, _, tool_capabilities, dir)
			return
		end
	})
	return mobname
end

---------------------
-- Visual Entities --
---------------------

local function set_eyes(self, ent)
	local eyes = minetest.add_entity(self.object:get_pos(), ent)
	if eyes then
		eyes:set_attach(self.object, "Head", {x = 0, y = -0.975, z = -2.5}, {x = 69, y = 0, z = 180})
		return eyes
	end
end

minetest.register_entity("ch_draconis:shield", {
	hp_max = 1,
	armor_groups = {immortal = 1},
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "mesh",
	mesh = "shield.b3d",
        --visual_size = {x = 1.01, y = 1.01},
	textures = {"shield_sphere.png"},
	use_texture_alpha = true,
	is_visible = true,
	makes_footstep_sound = false,
	glow = 11,
	blink_timer = 18,
	on_step = function(self, dtime)
		if not self.object:get_attach() then
			self.object:remove()
			return
		end
		self.object:set_armor_groups({immortal = 1})
		if self.object:get_attach()
		and self.object:get_attach():get_luaentity() then
			local parent = self.object:get_attach():get_luaentity()
			if parent.shielded then
				self.object:set_properties({textures = {"shield_sphere.png"}})
			else
				self.object:set_properties({textures = {"transparency.png"}})
			end
		end
	end
})

local function set_shield(self)
	local shield = minetest.add_entity(self.object:get_pos(), "ch_draconis:shield")
	if shield then
		shield:set_attach(self.object, "Torso.1", {x = 0, y = 0, z = 0})
		return shield
	end
end

-----------------------
-- Dynamic Animation --
-----------------------

function ch_draconis.head_tracking(self)
	local yaw = self.object:get_yaw()
	if self.hp <= 0 then
		self:move_head(yaw)
		return
	end
	local pos = mobkit.get_stand_pos(self)
	local v = vector.add(pos, vector.multiply(yaw2dir(yaw), 8 * self.growth_scale))
	local head_height = 6 * self.growth_scale
	if self._anim == "fly_idle"
	or self._anim == "fly_idle_fire" then
		head_height = 11 * self.growth_scale
	end
	pos.x = v.x
	pos.y = pos.y + head_height
	pos.z = v.z
	if not self.head_tracking then
		local objects = minetest.get_objects_inside_radius(pos, 16)
		for _, object in ipairs(objects) do
			if object:is_player() then
				local dir_2_plyr = vector.direction(pos, object:get_pos())
				local yaw_2_plyr = dir2yaw(dir_2_plyr)
				if abs(yaw - yaw_2_plyr) < 1
				or abs(yaw - yaw_2_plyr) > 5.3 then
					self.head_tracking = object
				end
				break
			end
		end
		if self._anim == "stand" then
			self:move_head(yaw)
		else
			self:move_head(self._tyaw)
		end
	else
		if not mobkit.exists(self.head_tracking) then
			self.head_tracking = nil
			return
		end
		local ppos = self.head_tracking:get_pos()
		ppos.y = ppos.y + 1.4
		local dir = vector.direction(pos, ppos)
		local tyaw = minetest.dir_to_yaw(dir)
		if abs(yaw - tyaw) > 1
		and abs(yaw - tyaw) < 5.3 then
			self.head_tracking = nil
			dir.y = 0
			return
		end
		self:move_head(tyaw, dir.y)
	end
end

-----------------
-- On Activate --
-----------------


function ch_draconis.on_activate(self, staticdata, dtime_s)
	mob_core.on_activate(self, staticdata, dtime_s)
	while not self.eyes do
		if self.name == ch_draconis.blue_dragon then
			self.eyes = set_eyes(self, "ch_draconis:ice_eyes")
		elseif self.name == ch_draconis.purple_dragon then
			self.eyes = set_eyes(self, "ch_draconis:fire_eyes")
		elseif self.name == ch_draconis.black_dragon then
			self.eyes = set_eyes(self, "ch_draconis:fire_eyes2")
		end
	end
	if not self.shield_ent and (self.name == ch_draconis.purple_dragon or self.name == ch_draconis.black_dragon) then
		self.shield_ent = set_shield(self)
	end
	self.logic_state = mobkit.recall(self, "logic_state") or "landed"
	self.flight_timer = mobkit.recall(self, "flight_timer") or 1
	self.age = mobkit.recall(self, "age") or 100
	self.growth_scale = mobkit.recall(self, "growth_scale") or 1
	self.time_from_last_sound = 0
	self.order = mobkit.recall(self, "order") or "wander"
	self.fly_allowed = mobkit.recall(self, "fly_allowed") or false
	self.idle_timer = mobkit.recall(self, "idle_timer") or 0
	self.greet_timer = mobkit.recall(self, "greet_timer") or 0
	self.current_phase = mobkit.recall(self, "current_phase") or 0
	self.hit_debouncer = mobkit.recall(self, "hit_debouncer") or 0
	self.mini_hits = mobkit.recall(self, "mini_hits") or 0
	self.no_altar = mobkit.recall(self, "no_altar") or false
	self.altar_pos_x = mobkit.recall(self, "altar_pos_x") or 0
	self.altar_pos_y = mobkit.recall(self, "altar_pos_y") or 0
	self.altar_pos_z = mobkit.recall(self, "altar_pos_z") or 0
	self.beam_charge = mobkit.recall(self, "beam_charge") or 0
	self.swoop_charge = mobkit.recall(self, "swoop_charge") or 0
	self.shielded = mobkit.recall(self, "shielded") or false
	self.target_blacklist = {}
	self.fall_distance = 0
	self.flap_sound_timer = 1.5
	self.flap_sound_played = false
	self.roar_anim_length = 0
	self.anim_frame = 0
	self.frame_offset = 0
	mob_core.set_scale(self, self.growth_scale)
	self.drops = nil
	if self.dynamic_anim_data then
		local data = self.dynamic_anim_data
		if data.tail then
			ch_draconis.move_tail(self)
		end
	end
	self.dtime = 0.1
	self:move_head(self.object:get_yaw())
	ch_draconis.dragon = self
end

-------------
-- On Step --
-------------

local function nearplayers(self, func)
	local apos = {x = self.altar_pos_x, y = 0, z = self.altar_pos_z}
	if not (apos.x and apos.z) then return end
	for _, player in pairs(minetest.get_connected_players()) do
		if minetest.get_player_privs(player).interact then
			local ppos = player:get_pos()
			ppos.y = 0
			if vector.distance(ppos, apos) < 128 then func(player) end
		end
	end
end

local function globalroar(self, sound)
	local params = self.sounds[sound]
	if #params > 0 then params = params[random(#params)] end
	local param_table = {
		max_hear_distance = 128,
		gain = 4 * params.gain,
		pitch = (params.pitch or 1) + (random(-5, 5) * 0.01)
	}
	return nearplayers(self, function(player)
		local ppos = player:get_pos()
		local basetheta = math.random() * math.pi * 2
		for i = 1, 3 do
			local theta = basetheta + math.pi * 2 / 3 * i
			local pos = vector.add(ppos, {
				x = 16 * math.sin(theta),
				y = 0,
				z = 16 * math.cos(theta)
			})
			param_table.pos = pos
			param_table.to_player = player:get_player_name()
			minetest.sound_play(params.name, param_table, true)
		end
	end)
end
ch_draconis.globalroar = globalroar

local function flashplayers(self, color, ttl)
	globalroar(self, "roar")
	return nearplayers(self, function(player)
		return ch_flashscreen.showflash(player, color, ttl)
	end)
end
ch_draconis.flashplayers = flashplayers

local function flash_red(self)
	minetest.after(0.0, function()
		self.object:set_texture_mod("^[colorize:#FF000040")
		flashplayers(self, "#ff0000", 1)
		core.after(0.2, function()
			if mobkit.is_alive(self) then
				self.object:set_texture_mod("")
			end
		end)
	end)
end

function ch_draconis.physics(self)
	local vel=self.object:get_velocity()
		-- dumb friction
	if self.isonground and not self.isinliquid then
		self.object:set_velocity({x= vel.x> 0.2 and vel.x*0.4 or 0,
								y=vel.y,
								z=vel.z > 0.2 and vel.z*0.4 or 0})
	end

	local surface = nil
	local surfnodename = nil
	local spos = mobkit.get_stand_pos(self)
	spos.y = spos.y+0.01
	local snodepos = mobkit.get_node_pos(spos)
	local surfnode = mobkit.nodeatpos(spos)
	while surfnode and surfnode.drawtype == 'liquid' do
		surfnodename = surfnode.name
		surface = snodepos.y+0.5
		if surface > spos.y+self.height then break end
		snodepos.y = snodepos.y+1
		surfnode = mobkit.nodeatpos(snodepos)
	end
	self.isinliquid = surfnodename
	if surface then
		local submergence = min(surface-spos.y,self.height)/self.height
		local buoyacc = 9.8*(self.buoyancy-submergence)
		mobkit.set_acceleration(self.object,
			{x=-vel.x*self.water_drag,y=buoyacc-vel.y*abs(vel.y)*0.4,z=-vel.z*self.water_drag})
	else
		self.object:set_acceleration({x=0,y=-9.8,z=0})
	end
end

function ch_draconis.flap_sound(self)
	if not self._anim then return end
	if self._anim:match("fly") then
		if self.frame_offset > 30
		and not self.flap_sound_played then
			minetest.sound_play("draconis_flap", {
				object = self.object,
				gain = 1.0,
				max_hear_distance = 128,
				loop = false,
			})
			self.flap_sound_played = true
		elseif self.frame_offset < 10 then
			self.flap_sound_played = false
		end
	end
end

function ch_draconis.set_adult_textures(self)
	local texture = self.object:get_properties().textures[1]
	local adult_overlay = "draconis_purple_dragon_head_detail.png"
	if self.name == ch_draconis.blue_dragon then
		adult_overlay = "draconis_blue_dragon_head_detail.png"
	elseif self.name == ch_draconis.black_dragon then
		adult_overlay = "draconis_black_dragon_head_detail.png"
	end
	self.object:set_properties({
		textures = {texture .. "^" .. adult_overlay}
	})
end

function ch_draconis.on_step(self, dtime, moveresult)
	if self._anim then
		local aparms = self.animation[self._anim]
		if self.anim_frame ~= -1 then
			self.anim_frame = self.anim_frame + dtime
			self.frame_offset = floor(self.anim_frame * aparms.speed)
			if self.frame_offset > aparms.range.y - aparms.range.x then
				self.anim_frame = 0
				self.frame_offset = 0
			end
		end
	end
	self.turn_rate = 6 - (self.growth_scale * 1.5)
	mob_core.on_step(self, dtime, moveresult)
	if not mobkit.is_alive(self) then return end
	local pos = self.object:get_pos()
	if not self.eyes:get_yaw() then
		if self.name == ch_draconis.blue_dragon then
			self.eyes = set_eyes(self, "ch_draconis:ice_eyes")
		elseif self.name == ch_draconis.purple_dragon then
			self.eyes = set_eyes(self, "ch_draconis:fire_eyes")
		elseif self.name == ch_draconis.black_dragon then
			self.eyes = set_eyes(self, "ch_draconis:fire_eyes2")
		end
	end
	if not self.shield_ent and (self.name == ch_draconis.purple_dragon or self.name == ch_draconis.black_dragon) then
		self.shield_ent = set_shield(self)
	end
	if mobkit.timer(self, 1) then
		self.time_from_last_sound = self.time_from_last_sound + 1
	end
	if mobkit.timer(self, 5) then
		if #self.target_blacklist > 0 then
			table.remove(self.target_blacklist, 1)
		end
	end
	if self.isonground or self.isinliquid then
		self.max_speed = 12
	else
		self.max_speed = 24
	end
	ch_draconis.flap_sound(self)
	if self.isonground 
	and (self.object:get_rotation().x ~= 0
	or self.object:get_rotation().z ~= 0) then
		self.object:set_yaw(self.object:get_yaw())
	end
	ch_draconis.head_tracking(self)
	self:open_jaw()
	if self.dynamic_anim_data then
		local data = self.dynamic_anim_data
		if data.tail then
			ch_draconis.move_tail(self)
		end
	end
end

-----------------------------
-- Tamed Dragon Management --
-----------------------------

local function set_order(self, player, order)
	if order == "stand" then
		if self.isinliquid then return end
		mobkit.clear_queue_high(self)
		mobkit.clear_queue_low(self)
		self.object:set_velocity({x = 0, y = 0, z = 0})
		self.object:set_acceleration({x = 0, y = 0, z = 0})
		self.status = "stand"
		self.order = "stand"
		ch_draconis.animate(self, "stand")
	end
	if order == "wander" then
		mobkit.clear_queue_high(self)
		mobkit.clear_queue_low(self)
		self.status = ""
		self.order = "wander"
	end
	if order == "follow" then
		mobkit.clear_queue_low(self)
		self.status = "following"
		self.order = "follow"
		ch_draconis.hq_follow(self, 5, player)
	end
	mobkit.remember(self, "status", self.status)
	mobkit.remember(self, "order", self.order)
end

local mob_obj = {}

--------------
-- Spawning --
--------------

local function spawn_dragon(pos, mob)
	local age = 50
	if mob == ch_draconis.purple_dragon then
		age = 75
	elseif mob == ch_draconis.black_dragon then
		age = 90
	end
	if not pos then return false end
	local dragon = minetest.add_entity({x = pos.x, y = 70, z = pos.z}, mob)
	if dragon then
		local ent = dragon:get_luaentity()
		ch_draconis.dragon = ent
		ent.altar_pos_x = mobkit.remember(ent, "altar_pos_x", pos.x)
		ent.altar_pos_y = mobkit.remember(ent, "altar_pos_y", pos.y)
		ent.altar_pos_z = mobkit.remember(ent, "altar_pos_z", pos.z)
		ent._mem = mobkit.remember(ent, "_mem", true)
		ent.age = mobkit.remember(ent, "age", age)
		ent.growth_scale = mobkit.remember(ent, "growth_scale", age * 0.01)
		if age <= 50 then
			ent.growth_stage = mobkit.remember(ent, "growth_stage", 2)
		end
		if age <= 75 then
			ent.growth_stage = mobkit.remember(ent, "growth_stage", 3)
		end
		if age > 75 then
			ent.growth_stage = mobkit.remember(ent, "growth_stage", 4)
		end
		mob_core.set_scale(ent, ent.growth_scale)
		mob_core.set_textures(ent)
		ent.drops = nil
	end
end

function ch_draconis.spawn_dragon(pos, mob)
	ch_draconis.dragon_spawning = 1
	minetest.forceload_block(pos, false)
	spawn_dragon(pos, mob)
	minetest.after(0.01, function()
		local loop = true
		local objects = minetest.get_objects_inside_radius({x=pos.x, y = 70, z = pos.z}, 0.5)
		for i = 1, #objects do
			local object = objects[i]
			if object
			  and object:get_luaentity()
			  and object:get_luaentity().name == mob then
				loop = false
			end
		end
		minetest.after(1, function()
			minetest.forceload_free_block(pos)
		end)
		if loop then
			minetest.after(4, function()
				ch_draconis.spawn_dragon(pos, mob)
			end)
		else
			ch_draconis.dragon_spawning = 0
		end
	end)
end


-----------------
-- Pathfinding --
-----------------

function ch_draconis.adjust_pos(self, pos2)
	local width = hitbox(self)[4] + 2
	local can_fit = moveable(pos2, width, self.height)
	if not can_fit then
		local minp = vector.new(pos2.x - width, pos2.y - 1, pos2.z - width)
		local maxp = vector.new(pos2.x + width, pos2.y + 1, pos2.z + width)
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				for x = minp.x, maxp.x do
					local npos = vector.new(x, y, z)
					local under = vector.new(npos.x, npos.y - 1, npos.z)
					local is_walkable =
						minetest.registered_nodes[minetest.get_node(under).name]
							.walkable
					if can_fit and is_walkable then
						return npos
					end
				end
			end
		end
	end
	return pos2
end

-------------
-- Mob API --
-------------

function ch_draconis.is_stuck(self)
	if not mobkit.is_alive(self) then return end
	if not self.moveresult then return end
	local moveresult = self.moveresult
	if self.height < 1 then return false end
	for _, collision in ipairs(moveresult.collisions) do
		if collision.type == "node" then
			local pos = mobkit.get_stand_pos(self)
			local node_pos = collision.node_pos
			local yaw = self.object:get_yaw()
			local yaw_to_node = minetest.dir_to_yaw(vec_dir(pos, node_pos))
			if node_pos.y >= pos.y + 1
			and abs(diff(yaw, yaw_to_node)) <= 1.5 then
				local node = minetest.get_node(node_pos)
				if minetest.registered_nodes[node.name].walkable then
					return true
				end
			end
		end
	end
	return false
end

function ch_draconis.play_sound(self, sound, is_event)
	if is_event then
		if self.time_from_last_sound < 1 then return end
	else
		if self.time_from_last_sound < 6 then return end
	end
	local params = self.sounds[sound]
	local param_table = {object = self.object}

	if #params > 0 then
		params = params[random(#params)]
	end

	param_table.gain = params.gain
	param_table.pitch = (params.pitch or 1) + (random(-5, 5) * 0.01)
	self.roar_anim_length = params.length
	self.time_from_last_sound = 0
	self.jaw_init = true
	return minetest.sound_play(params.name, param_table)
end

function ch_draconis.handle_sounds(self)
	if self._anim
	and self._anim:find("fire") then
		return
	end
	local time_from_last_sound = self.time_from_last_sound
	if time_from_last_sound > 6 then
		local r = random(ceil(16 * self.growth_scale))
		if r < 2 then
			ch_draconis.play_sound(self, "random", false)
		end
	end
end

function ch_draconis.animate(self, anim)
	if self.animation and self.animation[anim] then
		if self._anim == anim then return end
		local old_anim = nil
		if self._anim then
			old_anim = self._anim
		end
		self._anim = anim

		local old_prty = 1
		if old_anim
		and self.animation[old_anim].prty then
			old_prty = self.animation[old_anim].prty
		end
		local prty = 1
		if self.animation[anim].prty then
			prty = self.animation[anim].prty
		end

		local aparms
		if #self.animation[anim] > 0 then
			aparms = self.animation[anim][random(#self.animation[anim])]
		else
			aparms = self.animation[anim]
		end

		aparms.frame_blend = aparms.frame_blend or 0
		if old_prty > prty then
			aparms.frame_blend = self.animation[old_anim].frame_blend or 0
		end

		self.anim_frame = -aparms.frame_blend
		self.frame_offset = 0

		self.object:set_animation(aparms.range, aparms.speed, aparms.frame_blend, aparms.loop)
	else
		self._anim = nil
	end
end

function ch_draconis.get_head_pos(self, pos2)
	local pos = self.object:get_pos()
	pos.y = pos.y + 6 * self.growth_scale
	local yaw = self.object:get_yaw()
	local dir = vector.direction(pos, pos2)
	local yaw_diff = diff(yaw, minetest.dir_to_yaw(dir))
	if yaw_diff > 1 then
		local look_dir = minetest.yaw_to_dir(yaw + 1)
		dir.x = look_dir.x
		dir.z = look_dir.z
	elseif yaw_diff < -1 then
		local look_dir = minetest.yaw_to_dir(yaw - 1)
		dir.x = look_dir.x
		dir.z = look_dir.z
	end
	local head_yaw = yaw + (yaw_diff * 0.33)
	return vector.add(pos, vector.multiply(minetest.yaw_to_dir(head_yaw), (7 - abs(yaw_diff)) * self.growth_scale)), dir
end

local get_head_pos = ch_draconis.get_head_pos

local fireworks_radius = 64
local ioncannon_radius = 50
local red_beat_radius = 13
local blue_action_radius = 19

function ch_draconis.check_altar_destroyed(altar_pos)
	if ch_draconis.dragon ~= nil then
		local self = ch_draconis.dragon
		local own_altar_pos = {x=self.altar_pos_x, y=self.altar_pos_y, z=self.altar_pos_z}
		if own_altar_pos.x == altar_pos.x and own_altar_pos.y == altar_pos.y and own_altar_pos.z == altar_pos.z then
			-- TODO: Revenge attack before leaving?
			ch_draconis.play_sound(self, "roar", true)
			self.no_altar = mobkit.remember(self, "no_altar", true)
		end
	end
end

local function learncolour(altar_pos, name)
	for _,player in ipairs(minetest.get_connected_players()) do
		if minetest.get_player_privs(player).interact then
			local player_pos = player:get_pos()
			local player_dist = vec_dist(altar_pos, player_pos)
			if player_dist < 128 then
				local colours = ch_player_api.get_colours(player)
				if name == ch_draconis.blue_dragon then
					colours.blue = true
				elseif name == ch_draconis.purple_dragon then
					colours.purple = true
				elseif name == ch_draconis.black_dragon then
					colours.black = true
				end
				ch_player_api.set_colours(player, colours)
			end
		end
	end
end

function ch_draconis.damage_dragon(damage)
	local self = ch_draconis.dragon
	if not self then return end

	if self.shielded then
		-- TODO: make shield flash or something??
		return
	end

	if self.hit_debouncer > 0 then
		-- have to wait before you're allowed to hit it again.
		self.mini_hits = mobkit.remember(self, "mini_hits", self.mini_hits + damage)
		if self.mini_hits < 10 then
			return
		end
		self.mini_hits = mobkit.remember(self, "mini_hits", self.mini_hits - 10)
	end
	flash_red(self)
	if self.greet_timer < 10 then
		-- HOW DARE YOU?!?
		self.current_phase = mobkit.remember(self, "current_phase", 4)
		-- TODO: angrier sound?
		ch_draconis.play_sound(self, "roar", true)
	else
		self.current_phase = mobkit.remember(self, "current_phase", self.current_phase + 1)
		mobkit.make_sound(self, "hurt", true)
	end
	if self.name == ch_draconis.black_dragon then
		mobkit.hurt(self, 1)
	else
		mobkit.hurt(self, damage)
	end
	self.idle_timer = mobkit.remember(self, "idle_timer", 0)
	self.hit_debouncer = mobkit.remember(self, "hit_debouncer", 5)

	if self.hp <= 0 then
		local altar_pos = {x=self.altar_pos_x, y=self.altar_pos_y, z=self.altar_pos_z}
		learncolour(altar_pos, self.name)
		if self.name == ch_draconis.blue_dragon then
			cmsg.push_message_all(S("Marundir is defeated!"))
			minetest.set_node(altar_pos, {name = "buildings:blue"})
		elseif self.name == ch_draconis.purple_dragon then
			cmsg.push_message_all(S("Tyrirol is defeated!"))
			minetest.set_node(altar_pos, {name = "buildings:purple"})
		elseif self.name == ch_draconis.black_dragon then
			cmsg.push_message_all(S("Nowal is defeated!"))
			minetest.set_node(altar_pos, {name = "buildings:black"})
		end
	end
end

function ch_draconis.check_fireworks_hit(bang_pos, shield_breaker)
	if ch_draconis.dragon ~= nil then
		local self = ch_draconis.dragon
		local dist = vec_dist(bang_pos, self.object:get_pos())
		local ydist = abs(bang_pos.y - self.object:get_pos().y)
		if shield_breaker then
			if self.shielded and dist < fireworks_radius then
				-- TODO: make a sound of shield breaking?
				cmsg.push_message_all(S("The barrier is broken, strike now!"))
				self.shield_regen_time = mobkit.remember(self, "shield_regen_time", 0)
				self.shielded = mobkit.remember(self, "shielded", false)
				flashplayers(self, "#ffff00", 1)
			end
			return
		end
		if self.name == ch_draconis.black_dragon then
			-- Pff, not scared of fireworks!
			return
		end
		if dist < fireworks_radius and ydist < 13 then
			ch_draconis.damage_dragon(1)
		end
	end
end

function ch_draconis.check_ioncannon_hit(cannon_pos)
	if ch_draconis.dragon ~= nil then
		local self = ch_draconis.dragon
		local flat_c_pos = {x=cannon_pos.x, y=0, z=cannon_pos.z}
		local dpos = self.object:get_pos()
		local flat_d_pos = {x=dpos.x, y=0, z=dpos.z}
		local flat_dist = vec_dist(flat_c_pos, flat_d_pos)
		if flat_dist < ioncannon_radius then
			ch_draconis.damage_dragon(2)
		end
	end
end

function ch_draconis.check_red_hit(bang_pos)
	if ch_draconis.dragon ~= nil then
		local self = ch_draconis.dragon
		local dist = vec_dist(bang_pos, self.object:get_pos())
		if self.name == ch_draconis.black_dragon then
			-- Pff, not scared by red!
			return
		end
		if dist < red_beat_radius then
			ch_draconis.damage_dragon(1)
		end
	end
end

function ch_draconis.check_blue_hit(bang_pos)
	if ch_draconis.dragon ~= nil then
		local self = ch_draconis.dragon
		local dist = vec_dist(bang_pos, self.object:get_pos())
		if self.shielded and dist < blue_action_radius then
			-- TODO: make a sound of shield breaking?
			cmsg.push_message_all(S("The barrier is broken, strike now!"))
			self.shield_regen_time = mobkit.remember(self, "shield_regen_time", 0)
			self.shielded = mobkit.remember(self, "shielded", false)
			flashplayers(self, "#ffff00", 1)
		end
	end
end

-- Dynamic Animation --

local function clamp_bone_rot(n) -- Fixes issues with bones jittering when yaw clamps
	if n < -180 then
		n = n + 360
	elseif n > 180 then
		n = n - 360
	end
	if n < -60 then
		n = -60
	elseif n > 60 then
		n = 60
	end
	return n
end

local function interp_bone_rot(a, b, w) -- Smoothens bone movement
	local pi = math.pi
	if math.abs(a - b) > math.deg(pi) then
		if a < b then
			return ((a + (b - a) * w) + (math.deg(pi) * 2))
		elseif a > b then
			return ((a + (b - a) * w) - (math.deg(pi) * 2)) 
		end
	end
	return a + (b - a) * w
end

function ch_draconis.open_jaw(self)
	if not self._anim then return end
	if self.jaw_init then
		if self._anim:find("fire") then
			self.jaw_init = false
			self.roar_anim_length = 0
			return
		end
		local _, rot = self.object:get_bone_position("Jaw.CTRL")
		local b_rot = interp_bone_rot(rot.x, -45, 0.2)
		self.object:set_bone_position("Jaw.CTRL", {x=0,y=0.455,z=-0.255}, {x=b_rot,y=0,z=0})
		self.roar_anim_length = self.roar_anim_length - self.dtime
		if floor(rot.x) == -45
		and self.roar_anim_length <= 0 then
			self.jaw_init = false
			self.roar_anim_length = 0
		end
	else
		local _, rot = self.object:get_bone_position("Jaw.CTRL")
		local b_rot = interp_bone_rot(rot.x, 0, self.dtime * 3)
		self.object:set_bone_position("Jaw.CTRL", {x=0,y=0.455,z=-0.255}, {x=b_rot,y=0,z=0})
	end
end

function ch_draconis.move_tail(self)
	local tyaw = self._tyaw
	if self._anim == "stand"
	or self._anim == "stand_fire"
	or self._anim == "fly_idle"
	or self._anim == "fly_idle_fire" then
		tyaw = self.object:get_yaw()
	end
	local yaw = self.object:get_yaw()
	for seg = 1, #self.dynamic_anim_data.tail do
		local data = self.dynamic_anim_data.tail[seg]
		local _, rot = self.object:get_bone_position("Tail.".. seg .. ".CTRL")
		rot = rot.z
		local tgt_rot = clamp_bone_rot(-math.deg(yaw - tyaw)) * self.dynamic_anim_data.swing_factor
		local new_rot = 0
		if self.dtime then
			new_rot = interp_bone_rot(rot, tgt_rot, self.dtime * 1.5)
		end
		self.object:set_bone_position("Tail.".. seg .. ".CTRL", data.pos, {x = data.rot.x, y = data.rot.y, z = new_rot * data.rot.z})
	end
end

function ch_draconis.move_head(self, tyaw, pitch)
	local yaw = self.object:get_yaw()
	for seg = 1, #self.dynamic_anim_data.head do
		local seg_no = #self.dynamic_anim_data.head
		local data = self.dynamic_anim_data.head[seg]
		local bone_name = "Neck.".. seg .. ".CTRL"
		if seg == seg_no then
			bone_name = "Head.CTRL"
		end
		local _, rot = self.object:get_bone_position(bone_name)
		local look_yaw = clamp_bone_rot(math.deg(yaw - tyaw))
		local look_pitch = data.rot.x
		if pitch then
			look_pitch = clamp_bone_rot(math.deg(pitch)) * data.pitch_factor
		end
		if tyaw ~= yaw then
			look_yaw = look_yaw * self.dynamic_anim_data.yaw_factor
		end
		local bone_yaw = look_yaw
		local bone_pitch = look_pitch + (data.pitch_offset or 0)
		if self.jaw_init
		and data.bite_angle then
			look_pitch = look_pitch + data.bite_angle
		end
		if self.dtime then
			bone_yaw = interp_bone_rot(rot.z, look_yaw, self.dtime * 1.5)
			bone_pitch = interp_bone_rot(rot.x, look_pitch + (data.pitch_offset or 0), self.dtime * 1.5)
		end
		self.object:set_bone_position(bone_name, data.pos, {x = bone_pitch, y = data.rot.y, z = bone_yaw})
	end
end

-- Dragon Breath --


local function change_nodes(pos, radius, chance, groups, change_to, activation_chance)
	local minp = {x=pos.x - radius, y=pos.y - math.ceil(radius * 0.5), z=pos.z - radius}
	local maxp = {x=pos.x + radius, y=pos.y + math.ceil(radius * 0.5), z=pos.z + radius}
	local nodes = minetest.find_nodes_in_area(minp, maxp, groups)
	for i = 1, #nodes do
		if not minetest.is_protected(nodes[i], "") and vec_dist(nodes[i], pos) < radius and math.random(1, 100) <= chance then
			local node = minetest.get_node(nodes[i])
			if node and node.name ~= "air" then
				local def = minetest.registered_nodes[node.name]
				if not def.groups.building then
					minetest.set_node(nodes[i], {name = change_to} )
					if math.random(1, 100) <= activation_chance then
						local new_node = minetest.get_node_or_nil(nodes[i])
						if new_node then
							-- Yes, it's magic
							ch_colours.trigger(new_node, nodes[i], 0, nil)
						end
					end
					minetest.check_for_falling(nodes[i])
				end
			end
		end
	end
end

local function breath_sound(self, sound)
	if not self.breath_timer then self.breath_timer = 0.1 end
	self.breath_timer = self.breath_timer - self.dtime
	if self.breath_timer <= 0 then
		self.breath_timer = 2
		minetest.sound_play(sound,{
			object = self.object,
			gain = 1.0,
			max_hear_distance = 64,
			loop = false,
		})
	end
end


function ch_draconis.breath_attack(self, goal, range)
	breath_sound(self, "draconis_beam_breath")
	local pos
	local dir
	pos, dir = get_head_pos(self, goal)
	dir.y = vec_dir(pos, goal).y
	pos.y = pos.y + self.object:get_rotation().x
	local dest = vector.add(pos, vector.multiply(dir, range))

	local no_hit, hit_pos = minetest.line_of_sight(pos, dest)
	if no_hit then
		hit_pos = dest
	end

	local length = vec_dist(pos, hit_pos)
	dir = vec_dir(pos, hit_pos)
	local tex_name
	local breath_type
	local act_chance = 30
	if self.name == ch_draconis.blue_dragon then
		tex_name = "draconis_blue_particle_" .. random(1, 3) .. ".png"
		breath_type = "world:blue"
	elseif self.name == ch_draconis.purple_dragon then
		tex_name = "draconis_purple_particle_" .. random(1, 3) .. ".png"
		breath_type = "world:purple"
	else
		tex_name = "draconis_black_particle_" .. random(1, 3) .. ".png"
		breath_type = "world:black"
	end
	minetest.add_particlespawner({
		amount = 20,
		time = 0.5,
		minpos = vector.add(pos, vector.multiply(self.object:get_velocity(), 0.22)),
		maxpos = vector.add(pos, vector.multiply(self.object:get_velocity(), 0.22)),
		minvel = vector.multiply(dir, 32),
		maxvel = vector.multiply(dir, 48),
		minacc = {x = -4, y = -4, z = -4},
		maxacc = {x = 4, y = 4, z = 4},
		minexptime = 0.02 * length,
		maxexptime = 0.04 * length,
		minsize = 8 * self.growth_scale,
		maxsize = 12 * self.growth_scale,
		collisiondetection = true,
		vertical = false,
		glow = 8,
		texture = tex_name
	})

	if no_hit then
		return
	end

	minetest.after(0.03 * length, function()
		change_nodes(hit_pos, 5, 15, {"group:world"}, breath_type, act_chance)
	end)
end

