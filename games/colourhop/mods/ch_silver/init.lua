local ch_buildings, ch_colours, ch_flashscreen, ch_util, minetest, vector, cmsg = ch_buildings, ch_colours, ch_flashscreen, ch_util, minetest, vector, cmsg

local S = minetest.get_translator("silver")

ch_silver = {}

local layer1_floor = -3116
local layer2_floor = -3136
local royal_floor = -4016

local abberation_cd1 = 20
local abberation_cd2 = 35

local quad_size = 20*8
local room_y = -4015

local function nearest_room(pos)
	return {x=math.floor(pos.x/quad_size)*quad_size, y=room_y, z=math.floor(pos.z/quad_size)*quad_size}
end

local mod_meta = minetest.get_mod_storage()

local function room_id(room_pos)
	return math.floor(room_pos.x/quad_size + (room_pos.z/quad_size)*1000*1000)
end

-- Load data
minetest.after(0, function()
	local used_rooms = mod_meta:get_string("used_rooms")
	if used_rooms and used_rooms ~= nil and used_rooms ~= "" then
		ch_silver.used_rooms = minetest.deserialize(used_rooms)
	else
		ch_silver.used_rooms = {}
	end
	ch_silver.active_rooms = {}
end)

local function assign_royal_room(near_pos)
	local found_pos = nil
	local id = nil
	local tries = 0
	local search_pos = {x=near_pos.x, y=near_pos.y, z=near_pos.z}
	while not found_pos and tries < 1000*1000 do
		tries = tries + 1
		local next_pos = nearest_room(search_pos)
		local room_pos = {x=next_pos.x, y=next_pos.y, z=next_pos.z}
		id = room_id(room_pos)
		if not ch_silver.used_rooms[id] then
			found_pos = room_pos
		else
			search_pos.x = search_pos.x + quad_size
			search_pos.z = search_pos.z + quad_size
		end
	end
	local room_core_pos = {x=found_pos.x+9+8, y=found_pos.y+1, z=found_pos.z+17+8}
	return room_core_pos, id
end

local function spawn_boss(bpos, rid)
	minetest.forceload_block(bpos, true)
	ch_silver.active_rooms[rid] = true
	-- N.B. actual boss spawning moved to a globalstep, to ensure that
	-- the boss is spawned EXACTLY ONCE for each room that has any
	-- surviving generators.
end

minetest.register_node("ch_silver:abberation", {
	description = S("Silver"),
	tiles = {"silver.png"},
	groups = {stone = 1, silver = 1},
	trigger_on_jump = 1,
	light_source = 8,
	paramtype = "light",
	on_timer = function(pos, elapsed)
		minetest.set_node(pos, {name = "world:black"})
		minetest.add_particlespawner({
			node = {name = "ch_silver:abberation"},
			size = 0,
			time = 0.05,
			amount = 30,
			minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
			maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
			minvel = {x = -2, y = -2, z = -2},
			maxvel = {x = 2, y = 2, z = 2},
			minacc = {x = 0, y = -5, z = 0},
			maxacc = {x = 0, y = -5, z = 0},
			glow = 3,
		})
		if pos.y ~= layer2_floor then return end
		if not minetest.get_meta(pos):get_int("out") == 1 then return end

		local rdest,rid = assign_royal_room(pos)
		if not rdest or not rid then
			return
		end
		local cx = false
		for _, player in ipairs(minetest.get_connected_players()) do
			if minetest.check_player_privs(player, "interact") and vector.distance(player:get_pos(), pos) < 2 then
				if not cx then
					if not ch_silver.active_rooms[rid] then
						-- Spawn boss!
						local bpos = {x=rdest.x, y=rdest.y-2, z=rdest.z-10}
						spawn_boss(bpos, rid)
					end
				end
				cx = true
				player:get_meta():set_float("rb_teleported", minetest.get_gametime())
				player:set_pos(rdest)
				player:set_look_horizontal(math.pi)
				ch_flashscreen.showflash(player, "#000099", 3)
				minetest.sound_play("silver_vanish", {
					pos = pos,
					gain = 1.0,
					loop = false
				})
				minetest.add_particlespawner({
					node = {name = "ch_silver:abberation"},
					size = 0,
					time = 0.05,
					amount = 30,
					minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
					maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
					minvel = {x = -2, y = -2, z = -2},
					maxvel = {x = 2, y = 2, z = 2},
					minacc = {x = 0, y = -5, z = 0},
					maxacc = {x = 0, y = -5, z = 0},
					glow = 6,
				})
			end
		end
	end,
	sounds = {
		footstep = {name = "black", gain = 0.2},
		dug = {name = "black", gain = 1.0}
	},
})

minetest.register_entity("ch_silver:silver_blob", {
	hp_max = 1,
	armor_groups = {immortal = 1},
	physical = false,
	visual = "mesh",
	mesh = "silver.b3d",
	textures = {"player_silver.png", "player_eyes.png"},
	is_visible = true,
	glow = 8,
	dest = nil,
	wait_time = 0,
	static_save = false,
	search_dist = 10,
	on_step = function(self, dtime)
		local speed = 5
		if self.wait_time < 5 then
			self.wait_time = self.wait_time + dtime
			return
		end
		local pos = self.object:get_pos()
		if not self.dest then
			local minp = {x=pos.x-self.search_dist, y=layer2_floor, z=pos.z-self.search_dist}
			local maxp = {x=pos.x+self.search_dist, y=layer2_floor, z=pos.z+self.search_dist}
			local nodes = minetest.find_nodes_in_area(minp, maxp, {"group:black"})
			if #nodes < 1 then return end
			local dest = nodes[math.random(1, #nodes)]
			for _, player in ipairs(minetest.get_connected_players()) do
				if minetest.check_player_privs(player, "interact") and vector.distance(player:get_pos(), dest) < 3 then
					self.search_dist = self.search_dist * 1.5
					return
				end
			end
			self.dest = dest
			minetest.set_node(self.dest, {name = "ch_silver:abberation"})
			local tm = minetest.get_node_timer(self.dest)
			tm:start(20)
			minetest.sound_play("silver_short", {
				pos = self.dest,
				gain = 1.0,
				loop = false
			})
			local anim_walk = {x=55, y=85}
			local anim_speed = 30
			self.object:set_animation(anim_walk, anim_speed, 0, true)
			return
		end
		local dir = vector.direction(pos, self.dest)
		local yaw = minetest.dir_to_yaw(dir)
		self.object:set_yaw(yaw)
		local vel = vector.multiply(dir, speed)
		vel.y = 0
		self.object:set_velocity(vel)
		local dist = vector.distance(pos, self.dest)
		if dist < 1 then
			local tm = minetest.get_node_timer(self.dest)
			tm:start(2.75)
			local meta = minetest.get_meta(self.dest)
			meta:get_int("out", 1)
			minetest.sound_play("silver_vanish", {
				pos = self.dest,
				gain = 1.0,
				loop = false
			})
			self.object:remove()
			minetest.add_particlespawner({
				node = {name = "ch_silver:abberation"},
				size = 0,
				time = 0.05,
				amount = 30,
				minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
				maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
				minvel = {x = -2, y = -2, z = -2},
				maxvel = {x = 2, y = 2, z = 2},
				minacc = {x = 0, y = -5, z = 0},
				maxacc = {x = 0, y = -5, z = 0},
				glow = 6,
			})
			return
		end
	end
})

local function generator_threatened(gen_pos, alert_dist)
	local gen_node = minetest.get_node_or_nil(gen_pos)
	if gen_node and gen_node.name == "buildings:green" then
		for _, player in ipairs(minetest.get_connected_players()) do
			if minetest.check_player_privs(player, "interact") and vector.distance(player:get_pos(), gen_pos) < alert_dist then
				return true
			end
		end
	end
	return false
end

local function generator_alive(gen_pos)
	local gen_node = minetest.get_node_or_nil(gen_pos)
	return gen_node and minetest.get_item_group(gen_node.name, "darkgreen") > 0
end

-- N.B. boss spawning moved to here.
local function placeboss(bpos)
	local obj = minetest.add_entity({x=bpos.x, y=bpos.y+0.5, z=bpos.z}, "ch_silver:royal_blob")
	if not obj then return end
	minetest.after(0.5, function()
			if not obj:get_pos() then return end
			for _, player in pairs(minetest.get_connected_players()) do
				if vector.distance(bpos, player:get_pos()) < 64 then
					cmsg.push_message_player(player,
						S("The Royal Blob has been disturbed!"))
				end
			end
		end)
end
minetest.register_globalstep(function()
	local blobs_by_room = {}
	for _, ent in pairs(minetest.luaentities) do
		if ent.name == "ch_silver:royal_blob" then
			local pos = ent.object and ent.object:get_pos()
			if pos then
				local id = room_id(nearest_room(pos))
				blobs_by_room[id] = ent
			end
		end
	end
	local players_in_room = {}
	for _, player in pairs(minetest.get_connected_players()) do
		local pos = player:get_pos()
		if pos then
			local rpos = nearest_room(pos)
			local id = room_id(rpos)
			players_in_room[id] = true
			if not blobs_by_room[id] then
				local centerpos = {x=rpos.x+9+8, y=rpos.y, z=rpos.z+7+8}
				if generator_alive({x=centerpos.x+3, y=centerpos.y-2, z=centerpos.z})
				or generator_alive({x=centerpos.x-3, y=centerpos.y-2, z=centerpos.z})
				or generator_alive({x=centerpos.x, y=centerpos.y-2, z=centerpos.z+3})
				or generator_alive({x=centerpos.x, y=centerpos.y-2, z=centerpos.z-3}) then
					local bpos = {x=centerpos.x, y=centerpos.y-1, z=centerpos.z}
					placeboss(bpos)
					break
				end
			end
		end
	end
	for id, ent in pairs(blobs_by_room) do
		if not players_in_room[id] then
			ent.object:remove()
		end
	end
end)

local function trigger_generator(gen_pos)
	ch_colours.remote_trigger_at({x=gen_pos.x+1, y=gen_pos.y+1, z=gen_pos.z+1}, 0, nil)
	ch_colours.remote_trigger_at({x=gen_pos.x+1, y=gen_pos.y+1, z=gen_pos.z},   0, nil)
	ch_colours.remote_trigger_at({x=gen_pos.x+1, y=gen_pos.y+1, z=gen_pos.z-1}, 0, nil)
	ch_colours.remote_trigger_at({x=gen_pos.x,   y=gen_pos.y+1, z=gen_pos.z+1}, 0, nil)
	ch_colours.remote_trigger_at({x=gen_pos.x,   y=gen_pos.y+1, z=gen_pos.z},   0, nil)
	ch_colours.remote_trigger_at({x=gen_pos.x,   y=gen_pos.y+1, z=gen_pos.z-1}, 0, nil)
	ch_colours.remote_trigger_at({x=gen_pos.x-1, y=gen_pos.y+1, z=gen_pos.z+1}, 0, nil)
	ch_colours.remote_trigger_at({x=gen_pos.x-1, y=gen_pos.y+1, z=gen_pos.z},   0, nil)
	ch_colours.remote_trigger_at({x=gen_pos.x-1, y=gen_pos.y+1, z=gen_pos.z-1}, 0, nil)
	minetest.add_particlespawner({
		node = {name = "buildings:green"},
		size = 0,
		time = 0.05,
		amount = 30,
		minpos = {x = gen_pos.x - 0.5, y = gen_pos.y + 0.5, z = gen_pos.z - 0.5},
		maxpos = {x = gen_pos.x + 0.5, y = gen_pos.y + 1, z = gen_pos.z + 0.5},
		minvel = {x = -2, y = 3, z = -2},
		maxvel = {x = 2, y = 5, z = 2},
		minacc = {x = 0, y = -5, z = 0},
		maxacc = {x = 0, y = -5, z = 0},
		glow = 5,
	})
end

local function reward_players(room_center)
	for _,player in ipairs(minetest.get_connected_players()) do
		local player_pos = player:get_pos()
		local player_dist = vector.distance(room_center, player_pos)
		if player_dist < 64 then
			cmsg.push_message_player(player,
				S("The Royal Blob is defeated!"))
			local meta = player:get_meta()
			meta:set_int("defeated_rb", 1)
			ch_flashscreen.showflash(player, "#ffff00", 1)
		end
	end
end

local royal_weapon = dofile(
	minetest.get_modpath(minetest.get_current_modname())
	.. "/weapon.lua"
)

minetest.register_entity("ch_silver:royal_blob", {
	hp_max = 1,
	armor_groups = {immortal = 1},
	physical = false,
	visual = "mesh",
	mesh = "royal.b3d",
	textures = {"player_silver.png", "player_eyes.png", "player_crown.png"},
	is_visible = true,
	glow = 8,
	dest = nil,
	wait_time = 0,
	static_save = false,
	room_pos = nil,
	room_center_pos = nil,
	search_dist = 10,
	alert_dist = 4,
	path_timeout = 2,
	walking = false,

	on_step = function(self, dtime)
		royal_weapon(self, dtime)
		local pos = self.object:get_pos()
		if not self.room_pos then
			self.room_pos = nearest_room(pos)
			self.room_center_pos = {x=self.room_pos.x+9+8, y=self.room_pos.y, z=self.room_pos.z+7+8}
		end
		if self.wait_time > 0 then
			self.wait_time = self.wait_time - dtime
			return
		end
		local gen1 = {x=self.room_center_pos.x+3, y=self.room_center_pos.y-2, z=self.room_center_pos.z}
		local gen2 = {x=self.room_center_pos.x-3, y=self.room_center_pos.y-2, z=self.room_center_pos.z}
		local gen3 = {x=self.room_center_pos.x, y=self.room_center_pos.y-2, z=self.room_center_pos.z+3}
		local gen4 = {x=self.room_center_pos.x, y=self.room_center_pos.y-2, z=self.room_center_pos.z-3}
		local a1 = generator_alive(gen1)
		local a2 = generator_alive(gen2)
		local a3 = generator_alive(gen3)
		local a4 = generator_alive(gen4)
		if a1 == nil or a2 == nil or a3 == nil or a4 == nil then return self.object:remove() end
		if not (a1 or a2 or a3 or a4) then
			-- All generators down, gg
			self.object:remove()
			-- TODO: particles, sounds, screen flashes
			minetest.forceload_free_block(self.room_center_pos, true)
			local id = room_id(self.room_pos)
			ch_silver.used_rooms[id] = true
			mod_meta:set_string("used_rooms", minetest.serialize(ch_silver.used_rooms))
			reward_players(self.room_center_pos)
			return
		end
		if not self.dest then
			-- Check if we should move to one of the generators
			local dest
			if a1 and generator_threatened(gen1, self.alert_dist) then
				dest = {x=gen1.x, y=pos.y, z=gen1.z}
			elseif a2 and generator_threatened(gen2, self.alert_dist) then
				dest = {x=gen2.x, y=pos.y, z=gen2.z}
			elseif a3 and generator_threatened(gen3, self.alert_dist) then
				dest = {x=gen3.x, y=pos.y, z=gen3.z}
			elseif a4 and generator_threatened(gen4, self.alert_dist) then
				dest = {x=gen4.x, y=pos.y, z=gen4.z}
			else
				-- Go back to center.
				dest = {x=self.room_center_pos.x, y=pos.y, z=self.room_center_pos.z}
			end

			if dest and vector.distance(pos, dest) > 1 then
				self.dest = dest
				self.path_timeout = 2
			else
				-- We're already where we should be
				self.wait_time = 5
				-- Turn all nearby world nodes into blue.
				local minp = {x=pos.x-2, y=pos.y-2, z=pos.z-2}
				local maxp = {x=pos.x+2, y=pos.y+2, z=pos.z+2}
				local nodes = minetest.find_nodes_in_area(minp, maxp, {"group:world"}, true)
				for name,tab in pairs(nodes) do
					if name ~= "world:blue" and name ~= "world:blue_active" then
						for _,pos in pairs(tab) do
							minetest.set_node(pos, {name = "world:blue"})
						end
					end
				end
				-- Trigger all the generators
				if a1 then trigger_generator(gen1) end
				if a2 then trigger_generator(gen2) end
				if a3 then trigger_generator(gen3) end
				if a4 then trigger_generator(gen4) end
			end
			return
		end
		local anim_stand = {x=0, y=48}
		local anim_walk = {x=55, y=85}
		local anim_speed = 20
		local fp = {x=pos.x, y=math.ceil(pos.y), z=pos.z}
		local tp = {x=self.dest.x, y=math.ceil(self.dest.y), z=self.dest.z}
		local path = minetest.find_path(fp, tp, 50, 0, 0)
		if path then
			if not self.walking then
				self.object:set_animation(anim_walk, anim_speed, 0, true)
				self.walking = true
			end
			local speed = 2
			local first_node
			if #path < 2 then
				first_node = tp
			else
				first_node = path[2]
			end
			local dir = vector.direction(pos, first_node)
			local yaw = minetest.dir_to_yaw(dir)
			self.object:set_yaw(yaw)
			local vel = vector.multiply(dir, speed)
			vel.y = 0
			self.object:set_velocity(vel)
			local dist = vector.distance(pos, self.dest)
			if dist < 0.2 then
				self.object:set_velocity({x=0, y=0, z=0})
				self.dest = nil
				if self.walking then
					self.object:set_animation(anim_stand, anim_speed, 0, true)
					self.walking = false
				end
			end
		else
			self.object:set_velocity({x=0, y=0, z=0})
			if self.walking then
				self.object:set_animation(anim_stand, anim_speed, 0, true)
				self.walking = false
			end
			self.path_timeout = self.path_timeout - dtime
			if self.path_timeout <= 0 then
				self.dest = nil
			end
		end
	end
})

ch_util.register_playerstep(function(player, data, dtime)
	local meta = player:get_meta()
	local pos = player:get_pos()
	local yfloor = math.floor(pos.y)
	local stored_abberation_delay = meta:get_int("abberation_cd")
	if not data.abberation_delay then
		if stored_abberation_delay > 0 then
			data.abberation_delay = stored_abberation_delay
		end
	end
	if yfloor < layer1_floor+5 and yfloor > layer1_floor-5 then
		if not data.abberation_delay and math.random(0, 100) < 5 then
			local minp = {x=pos.x-10, y=layer1_floor, z=pos.z-10}
			local maxp = {x=pos.x+10, y=layer1_floor, z=pos.z+10}
			local nodes = minetest.find_nodes_in_area(minp, maxp, {"group:black"})
			if #nodes < 1 then return end
			local sel_pos = nodes[math.random(1, #nodes)]
			minetest.set_node(sel_pos, {name = "ch_silver:abberation"})
			local tm = minetest.get_node_timer(sel_pos)
			tm:start(2.75)
			meta:set_int("abberation_cd", abberation_cd1)
			minetest.sound_play("silver_abberation", {
				pos = sel_pos,
				gain = 1.0,
				loop = false
			})
			return
		end
	elseif yfloor < layer2_floor+5 and yfloor > layer2_floor-5 then
		if not data.abberation_delay and math.random(0, 100) < 10 then
			local minp = {x=pos.x-20, y=layer2_floor, z=pos.z-20}
			local maxp = {x=pos.x+20, y=layer2_floor, z=pos.z+20}
			local nodes = minetest.find_nodes_in_area(minp, maxp, {"group:black"})
			if #nodes < 1 then return end
			local sel_pos = nodes[math.random(1, #nodes)]
			if vector.distance(pos, sel_pos) < 5 then
				return
			end
			minetest.set_node(sel_pos, {name = "ch_silver:abberation"})
			local tm = minetest.get_node_timer(sel_pos)
			tm:start(2)
			meta:set_int("abberation_cd", abberation_cd2)
			minetest.sound_play("silver_short", {
				pos = sel_pos,
				gain = 1.0,
				loop = false
			})
			local ent = minetest.add_entity({x=sel_pos.x, y=sel_pos.y+0.5, z=sel_pos.z}, "ch_silver:silver_blob")
			local dir = vector.direction(sel_pos, pos)
			local yaw = minetest.dir_to_yaw(dir)
			ent:set_yaw(yaw)
			return
		end
	end
	if data.abberation_delay then
		data.abberation_delay = data.abberation_delay - dtime
		if data.abberation_delay <= 0 then
			data.abberation_delay = nil
			meta:set_int("abberation_cd", 0)
		end
	end
end)
