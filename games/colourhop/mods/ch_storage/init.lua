
local minetest = minetest

ch_storage = {}

local mod_meta = minetest.get_mod_storage()

-- Load data
minetest.after(0, function()
	local used_storage = mod_meta:get_string("used_storage")
	if used_storage and used_storage ~= "" then
		ch_storage.used_storage = minetest.deserialize(used_storage)
	else
		ch_storage.used_storage = {}
	end
end)


local function next_room(rel_pos)
	local next_pos = {x=0, y=0, z=0}
	if rel_pos.x < 8 then
		next_pos.z = rel_pos.z
		if rel_pos.z > 1 and rel_pos.z < 7 then
			if rel_pos.x == 1 then
				next_pos.x = 7
			else
				next_pos.x = rel_pos.x + 1
			end
		else
			next_pos.x = rel_pos.x + 1
		end
	elseif rel_pos.z >= 8 then
		return nil
	else
		next_pos.z = rel_pos.z+1
	end
	return next_pos
end

local quad_size = 9*16
local quad_y = -3015

local function nearest_quad(pos)
	return {x=math.floor(pos.x/quad_size)*quad_size, y=quad_y, z=math.floor(pos.z/quad_size)*quad_size}
end

local function next_quad(quad_pos)
	return {x=quad_pos.x+quad_size, y=quad_pos.y, z=quad_pos.z+quad_size}
end

local function room_id(room_pos)
	return room_pos.x/16 + (room_pos.z/16)*1000*1000
end

function ch_storage.assign_storage_room(storage_point)
	local point_meta = minetest.get_meta(storage_point)

	local found_pos = nil
	local next_pos = {x=0, y=0, z=0}
	local quad = nearest_quad(storage_point)
	local tries = 0
	while not found_pos and tries < 1000*1000 do
		tries = tries + 1
		local room_pos = {x=quad.x+next_pos.x*16, y=quad.y+next_pos.y*16, z=quad.z+next_pos.z*16}
		local id = room_id(room_pos)
		if not ch_storage.used_storage[id] then
			found_pos = room_pos
		else
			next_pos = next_room(next_pos)
			if not next_pos then
				quad = next_quad(quad)
				next_pos = {x=0, y=0, z=0}
			end
		end
	end
	local id = room_id(found_pos)
	ch_storage.used_storage[id] = true
	mod_meta:set_string("used_storage", minetest.serialize(ch_storage.used_storage))

	local room_core_pos = {x=found_pos.x+7, y=found_pos.y+1, z=found_pos.z+7}

	point_meta:set_int("storage_x", room_core_pos.x)
	point_meta:set_int("storage_y", room_core_pos.y)
	point_meta:set_int("storage_z", room_core_pos.z)
	return room_core_pos
end

minetest.register_globalstep(function()
	for _, player in ipairs(minetest.get_connected_players()) do
		local pos = player:get_pos()
		if pos.y < -3000 then
			local room_pos = {x=math.floor(pos.x/16)*16, y=quad_y, z=math.floor(pos.z/16)*16}
			local id = room_id(room_pos)
			if not ch_storage.used_storage[id] then
				if minetest.check_player_privs(player, "interact") then
					ch_storage.used_storage[id] = true
					mod_meta:set_string("used_storage", minetest.serialize(ch_storage.used_storage))
				end
			end
		end
	end
end)
