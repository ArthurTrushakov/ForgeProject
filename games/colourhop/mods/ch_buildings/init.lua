
local minetest, ch_storage = minetest, ch_storage

ch_buildings = {}

ch_buildings.full_sunlight_above = function(pos)
	-- Get light at node above during midday (which should be equal to sun light)
	return minetest.get_node_light({x=pos.x, y=pos.y+0.5, z=pos.z}, 0.5) == 15
end

local function has_position(tab, pos)
	for _,te in ipairs(tab) do
		if te.x == pos.x and te.y == pos.y and te.z == pos.z then
			return true
		end
	end
	return false
end

ch_buildings.only_air_above = function(pos)
	local sky_pos = {x = pos.x, y = pos.y+50, z = pos.z}
	local pos2 = {x = pos.x, y = pos.y+1, z = pos.z}
	local ray = minetest.raycast(sky_pos, pos2, false, false)
	for pointed_thing in ray do
		if pointed_thing.type == "node" then
			return false
		end
	end
	return true
end

local function get_colour(nodespec)
	-- NOTE: function assumes tables contain a single string with a node group.
	if type(nodespec) == "table" then
		if nodespec[1] == "group:yellow" then
			return "yellow"
		elseif nodespec[1] == "group:red" then
			return "red"
		elseif nodespec[1] == "group:green" then
			return "green"
		elseif nodespec[1] == "group:black" then
			return "black"
		elseif nodespec[1] == "group:blue" then
			return "blue"
		elseif nodespec[1] == "group:purple" then
			return "purple"
		end
		print("[ERROR] Couldn't find colour from node group")
		return "unknown_group"
	else
		if nodespec == "world:yellow" or nodespec == "buildings:yellow" then
			return "yellow"
		elseif nodespec == "world:red" or nodespec == "buildings:red" then
			return "red"
		elseif nodespec == "world:green" or nodespec == "buildings:green" then
			return "green"
		elseif nodespec == "world:black" or nodespec == "buildings:black" then
			return "black"
		elseif nodespec == "world:blue" or nodespec == "buildings:blue" then
			return "blue"
		elseif nodespec == "world:purple" or nodespec == "buildings:purple" then
			return "purple"
		end
		print("[ERROR] Couldn't find colour from node name")
		return "unknown_name"
	end
end

local function to_group(nodespec)
	return {"group:" .. get_colour(nodespec)}
end

local function check_schem_colour(schem, target, c, o, rx, ry, rz)
	local nodes = minetest.find_nodes_in_area({x=c.x-rx, y=c.y-ry, z=c.z-rz}, {x=c.x+rx, y=c.y+ry, z=c.z+rz}, target)
	for _,scp in ipairs(schem) do
		local a = {x=o.x+scp.x, y=o.y+scp.y, z=o.z+scp.z}
		if not has_position(nodes, a) then
			return false
		end
	end
	return true
end

local function check_for_altar1(top_green_pos)
	local radx = 4
	local rady = 2
	local radz = 4
	local center_pos = {x=top_green_pos.x, y=top_green_pos.y-2, z=top_green_pos.z}
	local origin = {x=center_pos.x-radx-1, y=center_pos.y-rady-1, z=center_pos.z-radz-1}
	-- check if all required nodes are present
	for nodename,schem in pairs(ch_schematics.altar_defs[1]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			if not check_schem_colour(schem, to_group(nodename), center_pos, origin, radx, rady, radz) then
				return false
			end
		end
	end
	-- Check that we have sky above the whole thing.
	for _,yellowp in ipairs(ch_schematics.altar_defs[1]["buildings:yellow"]) do
		local a = {x=origin.x+yellowp.x, y=origin.y+yellowp.y, z=origin.z+yellowp.z}
		if not ch_buildings.only_air_above(a) then
			return false
		end
	end
	for _,greenp in ipairs(ch_schematics.altar_defs[1]["buildings:green"]) do
		local a = {x=origin.x+greenp.x, y=origin.y+greenp.y, z=origin.z+greenp.z}
		if not ch_buildings.only_air_above(a) then
			return false
		end
	end
	for _,blackp in ipairs(ch_schematics.altar_defs[1]["buildings:black"]) do
		local a = {x=origin.x+blackp.x, y=origin.y+blackp.y, z=origin.z+blackp.z}
		if not ch_buildings.full_sunlight_above(a) then
			return false
		end
	end
	-- If we got here, then the altar is valid. Activate it!
	for nodename,schem in pairs(ch_schematics.altar_defs[1]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			-- Convert to dark blocks.
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = nodename})
				local meta = minetest.get_meta(a)
				meta:set_int("corex", top_green_pos.x)
				meta:set_int("corey", top_green_pos.y)
				meta:set_int("corez", top_green_pos.z)
			end
		end
	end
	-- Set top green block to altar main block (timer for particle effects)
	minetest.set_node(top_green_pos, {name = "buildings:altar1"})
	local tm = minetest.get_node_timer(top_green_pos)
	tm:start(3)
	return true
end

local function build_altar1(top_green_pos)
	-- debug function..
	local radx = 4
	local rady = 2
	local radz = 4
	local origin = {x=top_green_pos.x-radx-1, y=top_green_pos.y-2*rady-1, z=top_green_pos.z-radz-1}
	for nodename,schem in pairs(ch_schematics.altar_defs[1]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			local colour = get_colour(nodename)
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = "world:" .. colour})
			end
		end
	end
	return true
end

local function check_for_altar2(top_green_pos)
	local radx = 4
	local rady = 2
	local radz = 4
	local center_pos = {x=top_green_pos.x, y=top_green_pos.y-2, z=top_green_pos.z}
	local origin = {x=center_pos.x-radx-1, y=center_pos.y-rady-1, z=center_pos.z-radz-1}
	-- check if all required nodes are present
	for nodename,schem in pairs(ch_schematics.altar_defs[2]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			if not check_schem_colour(schem, to_group(nodename), center_pos, origin, radx, rady, radz) then
				return false
			end
		end
	end
	-- Check that we have sky above the whole thing.
	for _,redp in ipairs(ch_schematics.altar_defs[2]["buildings:red"]) do
		local a = {x=origin.x+redp.x, y=origin.y+redp.y, z=origin.z+redp.z}
		if not ch_buildings.full_sunlight_above(a) then
			return false
		end
	end
	for _,yellowp in ipairs(ch_schematics.altar_defs[2]["buildings:yellow"]) do
		local a = {x=origin.x+yellowp.x, y=origin.y+yellowp.y, z=origin.z+yellowp.z}
		if not ch_buildings.only_air_above(a) then
			return false
		end
	end
	for _,greenp in ipairs(ch_schematics.altar_defs[2]["buildings:green"]) do
		local a = {x=origin.x+greenp.x, y=origin.y+greenp.y, z=origin.z+greenp.z}
		if not ch_buildings.only_air_above(a) then
			return false
		end
	end
	for _,blackp in ipairs(ch_schematics.altar_defs[2]["buildings:black"]) do
		local a = {x=origin.x+blackp.x, y=origin.y+blackp.y, z=origin.z+blackp.z}
		if not ch_buildings.full_sunlight_above(a) then
			return false
		end
	end
	-- If we got here, then the altar is valid. Activate it!
	for nodename,schem in pairs(ch_schematics.altar_defs[2]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			-- Convert to dark blocks.
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = nodename})
				local meta = minetest.get_meta(a)
				meta:set_int("corex", top_green_pos.x)
				meta:set_int("corey", top_green_pos.y)
				meta:set_int("corez", top_green_pos.z)
			end
		end
	end
	-- Set top green block to altar main block (timer for particle effects)
	minetest.set_node(top_green_pos, {name = "buildings:altar2"})
	local tm = minetest.get_node_timer(top_green_pos)
	tm:start(3)
	return true
end

local function build_altar2(top_green_pos)
	-- debug function..
	local radx = 4
	local rady = 2
	local radz = 4
	local origin = {x=top_green_pos.x-radx-1, y=top_green_pos.y-2*rady-1, z=top_green_pos.z-radz-1}
	for nodename,schem in pairs(ch_schematics.altar_defs[2]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			local colour = get_colour(nodename)
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = "world:" .. colour})
			end
		end
	end
	return true
end

local function check_for_altar3(top_green_pos)
	local radx = 7
	local rady = 3
	local radz = 7
	local center_pos = {x=top_green_pos.x, y=top_green_pos.y-3, z=top_green_pos.z}
	local origin = {x=top_green_pos.x-radx-1, y=top_green_pos.y-5-1, z=top_green_pos.z-radz-1}
	-- check if all required nodes are present
	for nodename,schem in pairs(ch_schematics.altar_defs[3]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			if not check_schem_colour(schem, to_group(nodename), center_pos, origin, radx, rady, radz) then
				return false
			end
		end
	end
	-- Check that we have sky above the whole thing.
	for _,yellowp in ipairs(ch_schematics.altar_defs[3]["buildings:yellow"]) do
		local a = {x=origin.x+yellowp.x, y=origin.y+yellowp.y, z=origin.z+yellowp.z}
		if not ch_buildings.full_sunlight_above(a) then
			return false
		end
	end
	for _,greenp in ipairs(ch_schematics.altar_defs[3]["buildings:green"]) do
		local a = {x=origin.x+greenp.x, y=origin.y+greenp.y, z=origin.z+greenp.z}
		if not ch_buildings.only_air_above(a) then
			return false
		end
	end
	-- for other colours, only check if ypos == 1
	for _,bluep in ipairs(ch_schematics.altar_defs[3]["buildings:blue"]) do
		if bluep.y == 1 then
			local a = {x=origin.x+bluep.x, y=origin.y+bluep.y, z=origin.z+bluep.z}
			if not ch_buildings.full_sunlight_above(a) then
				return false
			end
		end
	end
	for _,blackp in ipairs(ch_schematics.altar_defs[3]["buildings:black"]) do
		if blackp.y == 1 then
			local a = {x=origin.x+blackp.x, y=origin.y+blackp.y, z=origin.z+blackp.z}
			if not ch_buildings.full_sunlight_above(a) then
				return false
			end
		end
	end

	-- next, check the walls.. a bit more complicated..
	for _,blackp in ipairs(ch_schematics.altar_defs[3]["buildings:black"]) do
		if blackp.y == 3 then
			if blackp.x > 10 or blackp.x < 6 or blackp.z > 10 or blackp.z < 6 then
				local a = {x=origin.x+blackp.x, y=origin.y+blackp.y, z=origin.z+blackp.z}
				if not ch_buildings.only_air_above(a) then
					return false
				end
			end
		end
	end

	-- finally, check that the purple on each pillar has sky above it
	for _,purplep in ipairs(ch_schematics.altar_defs[3]["buildings:purple"]) do
		if purplep.y == 4 and purplep.x ~= 8 then
			local a = {x=origin.x+purplep.x, y=origin.y+purplep.y, z=origin.z+purplep.z}
			if not ch_buildings.only_air_above(a) then
				return false
			end
		end
	end

	-- If we got here, then the altar is valid. Activate it!
	for nodename,schem in pairs(ch_schematics.altar_defs[3]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			-- Convert to dark blocks.
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = nodename})
				local meta = minetest.get_meta(a)
				meta:set_int("corex", top_green_pos.x)
				meta:set_int("corey", top_green_pos.y)
				meta:set_int("corez", top_green_pos.z)
			end
		end
	end
	-- Set top green block to altar main block (timer for particle effects)
	minetest.set_node(top_green_pos, {name = "buildings:altar3"})
	local tm = minetest.get_node_timer(top_green_pos)
	tm:start(3)
	return true
end

local function build_altar3(top_green_pos)
	-- debug function..
	local radx = 7
	local rady = 3
	local radz = 7
	local origin = {x=top_green_pos.x-radx-1, y=top_green_pos.y-5-1, z=top_green_pos.z-radz-1}
	for nodename,schem in pairs(ch_schematics.altar_defs[3]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			local colour = get_colour(nodename)
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = "world:" .. colour})
			end
		end
	end
	return true
end

local function build_ion_cannon(top_green_pos)
	-- debug function..
	local radx = 3
	local rady = 2
	local radz = 3
	local origin = {x=top_green_pos.x-radx-3, y=top_green_pos.y-3-1, z=top_green_pos.z-radz-3}
	for nodename,schem in pairs(ch_schematics.weapon_defs[4]) do
		if nodename ~= "air" then
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = nodename})
			end
		end
	end
	return true
end

ch_buildings.check_for_ion_cannon = function(bottom_center_pos)
	local radx = 3
	local rady = 2
	local radz = 3
	local center_pos = {x=bottom_center_pos.x, y=bottom_center_pos.y+2, z=bottom_center_pos.z}
	local origin = {x=bottom_center_pos.x-radx-3, y=bottom_center_pos.y-1, z=bottom_center_pos.z-radz-3}

	-- check if all required nodes are present
	for nodename,schem in pairs(ch_schematics.weapon_defs[4]) do
		if nodename ~= "air" and nodename ~= "world:black" and nodename ~= "world:green" then
			if not check_schem_colour(schem, to_group(nodename), center_pos, origin, radx, rady, radz) then
				return false
			end
		end
	end
	-- Check for the 4 required black nodes
	local b = {{x=5, y=1, z=5}, {x=5, y=1, z=7}, {x=7, y=1, z=5}, {x=7, y=1, z=7}}
	if not check_schem_colour(b, {"group:black"}, center_pos, origin, radx, rady, radz) then
		return false
	end

	-- Check that we have sky above the whole thing.
	for _,yellowp in ipairs(ch_schematics.weapon_defs[4]["world:yellow"]) do
		local a = {x=origin.x+yellowp.x, y=origin.y+yellowp.y, z=origin.z+yellowp.z}
		if not ch_buildings.full_sunlight_above(a) then
			return false
		end
	end
	for _,blackp in ipairs(b) do
		local a = {x=origin.x+blackp.x, y=origin.y+blackp.y, z=origin.z+blackp.z}
		if not ch_buildings.full_sunlight_above(a) then
			return false
		end
	end
	for _,bluep in ipairs(ch_schematics.weapon_defs[4]["world:blue"]) do
		local a = {x=origin.x+bluep.x, y=origin.y+bluep.y, z=origin.z+bluep.z}
		if not ch_buildings.full_sunlight_above(a) then
			return false
		end
	end
	-- Finally, check that we have air above the central pillar
	if not ch_buildings.only_air_above({x=center_pos.x, y=center_pos.y+1, z=center_pos.z}) then
		return false
	end

	-- Yep, thats an ion cannon alright
	return true
end

local function check_for_return_point(top_green_pos)
	local center_pos = {x=top_green_pos.x, y=top_green_pos.y-2, z=top_green_pos.z}
	local core_offset = ch_schematics.utility_cores[1]
	local origin = {x=top_green_pos.x-core_offset.x-1, y=top_green_pos.y-core_offset.y-1, z=top_green_pos.z-core_offset.z-1}
	-- check if all required nodes are present
	for nodename,schem in pairs(ch_schematics.utility_defs[1]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			if not check_schem_colour(schem, to_group(nodename), center_pos, origin, 2, 2, 2) then
				return false
			end
		elseif nodename == "air" then
			if not check_schem_colour(schem, "air", center_pos, origin, 2, 2, 2) then
				return false
			end
		end
	end
	-- If we got here, then the return_point is valid. Activate it!
	for nodename,schem in pairs(ch_schematics.utility_defs[1]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			-- Convert to dark blocks.
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = nodename})
				local meta = minetest.get_meta(a)
				meta:set_int("corex", top_green_pos.x)
				meta:set_int("corey", top_green_pos.y)
				meta:set_int("corez", top_green_pos.z)
			end
		end
	end
	-- Set top green block to return_point main block
	minetest.set_node(top_green_pos, {name = "buildings:return_point"})
	-- Nearby players gets their return point set to this one.
	for _, player in pairs(minetest.get_connected_players()) do
		if vector.distance(player:get_pos(), top_green_pos) < 3 then
			local meta = player:get_meta()
			meta:set_int("return_point_x", top_green_pos.x)
			meta:set_int("return_point_y", top_green_pos.y)
			meta:set_int("return_point_z", top_green_pos.z)
		end
	end
	return true
end

local function check_for_snapshot_point(top_green_pos)
	local center_pos = {x=top_green_pos.x, y=top_green_pos.y-2, z=top_green_pos.z}
	local core_offset = ch_schematics.utility_cores[2]
	local origin = {x=top_green_pos.x-core_offset.x-1, y=top_green_pos.y-core_offset.y-1, z=top_green_pos.z-core_offset.z-1}
	-- check if all required nodes are present
	for nodename,schem in pairs(ch_schematics.utility_defs[2]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			if not check_schem_colour(schem, to_group(nodename), center_pos, origin, 1, 2, 1) then
				return false
			end
		elseif nodename == "air" then
			if not check_schem_colour(schem, "air", center_pos, origin, 1, 2, 1) then
				return false
			end
		end
	end
	-- If we got here, then the snapshot_point is valid. Activate it!
	for nodename,schem in pairs(ch_schematics.utility_defs[2]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			-- Convert to dark blocks.
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = nodename})
				local meta = minetest.get_meta(a)
				meta:set_int("corex", top_green_pos.x)
				meta:set_int("corey", top_green_pos.y)
				meta:set_int("corez", top_green_pos.z)
			end
		end
	end
	-- Set top green block to snapshot_point main block
	minetest.set_node(top_green_pos, {name = "buildings:snapshot_point"})
	-- Make a snapshot of the surroundings.
	local rx = 10
	local ry = 10
	local rz = 10
	local meta = minetest.get_meta(top_green_pos)
	local minpos = {x=top_green_pos.x-rx, y=top_green_pos.y-2-ry, z=top_green_pos.z-rz}
	local maxpos = {x=top_green_pos.x+rx, y=top_green_pos.y-2+ry, z=top_green_pos.z+rz}
	local snapshot_nodes = minetest.find_nodes_in_area(minpos, maxpos, {"group:world", "air"}, true)
	meta:set_string("snapshot", minetest.serialize(snapshot_nodes))
	return true
end

ch_buildings.create_exit_point = function(top_green_pos, storage_pos)
	minetest.forceload_block(top_green_pos, true)
	minetest.after(0.01, function()
		local check = minetest.get_node(top_green_pos)
		if not check or check.name == "ignore" then
			return ch_buildings.create_exit_point(top_green_pos, storage_pos)
		end
		local center_pos = {x=top_green_pos.x, y=top_green_pos.y, z=top_green_pos.z}
		local core_offset = ch_schematics.utility_cores[4]
		local origin = {x=top_green_pos.x-core_offset.x-1, y=top_green_pos.y-core_offset.y-1, z=top_green_pos.z-core_offset.z-1}
		for nodename,schem in pairs(ch_schematics.utility_defs[4]) do
			if nodename ~= "air" then
				for _,scp in ipairs(schem) do
					local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
					minetest.set_node(a, {name = nodename})
					local meta = minetest.get_meta(a)
					meta:set_int("corex", top_green_pos.x)
					meta:set_int("corey", top_green_pos.y)
					meta:set_int("corez", top_green_pos.z)
				end
			end
		end
		-- Set top green block to exit_point main block
		minetest.set_node(top_green_pos, {name = "buildings:exit_point"})
		if storage_pos then
			local point_meta = minetest.get_meta(top_green_pos)
			point_meta:set_int("exit_x", storage_pos.x)
			point_meta:set_int("exit_y", storage_pos.y)
			point_meta:set_int("exit_z", storage_pos.z)
		end
		minetest.forceload_free_block(top_green_pos, true)
	end)
end

local function check_for_storage_point(top_green_pos)
	local center_pos = {x=top_green_pos.x, y=top_green_pos.y, z=top_green_pos.z}
	local core_offset = ch_schematics.utility_cores[3]
	local origin = {x=top_green_pos.x-core_offset.x-1, y=top_green_pos.y-core_offset.y-1, z=top_green_pos.z-core_offset.z-1}
	-- check if all required nodes are present
	for nodename,schem in pairs(ch_schematics.utility_defs[3]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			if not check_schem_colour(schem, to_group(nodename), center_pos, origin, 4, 2, 4) then
				return false
			end
		elseif nodename == "air" then
			if not check_schem_colour(schem, "air", center_pos, origin, 4, 2, 4) then
				return false
			end
		end
	end
	-- If we got here, then the storage_point is valid. Activate it!
	for nodename,schem in pairs(ch_schematics.utility_defs[3]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			-- Convert to dark blocks.
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = nodename})
				local meta = minetest.get_meta(a)
				meta:set_int("corex", top_green_pos.x)
				meta:set_int("corey", top_green_pos.y)
				meta:set_int("corez", top_green_pos.z)
			end
		end
	end
	-- Set top green block to storage_point main block
	minetest.set_node(top_green_pos, {name = "buildings:storage_point"})
	-- Allocate and assign storage room for this storage_point..
	local exit_pos = ch_storage.assign_storage_room(top_green_pos)
	-- create the exit point
	ch_buildings.create_exit_point(exit_pos, top_green_pos)
	return true
end

local function check_for_exit_point(top_green_pos)
	local center_pos = {x=top_green_pos.x, y=top_green_pos.y, z=top_green_pos.z}
	local core_offset = ch_schematics.utility_cores[4]
	local origin = {x=top_green_pos.x-core_offset.x-1, y=top_green_pos.y-core_offset.y-1, z=top_green_pos.z-core_offset.z-1}
	-- check if all required nodes are present
	for nodename,schem in pairs(ch_schematics.utility_defs[4]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			if not check_schem_colour(schem, to_group(nodename), center_pos, origin, 1, 2, 1) then
				return false
			end
		elseif nodename == "air" then
			if not check_schem_colour(schem, "air", center_pos, origin, 1, 2, 1) then
				return false
			end
		end
	end
	-- If we got here, then the exit_point is valid. Activate it!
	for nodename,schem in pairs(ch_schematics.utility_defs[4]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			-- Convert to dark blocks.
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				minetest.set_node(a, {name = nodename})
				local meta = minetest.get_meta(a)
				meta:set_int("corex", top_green_pos.x)
				meta:set_int("corey", top_green_pos.y)
				meta:set_int("corez", top_green_pos.z)
			end
		end
	end
	-- Set top green block to exit_point main block
	minetest.set_node(top_green_pos, {name = "buildings:exit_point"})
	-- Set exit dest to closest player's entrace.
	local point_meta = minetest.get_meta(top_green_pos)
	local closest = 5
	for _, player in pairs(minetest.get_connected_players()) do
		local dist = vector.distance(player:get_pos(), top_green_pos)
		if dist < closest then
			local meta = player:get_meta()
			point_meta:set_int("exit_x", meta:get_int("entrance_x"))
			point_meta:set_int("exit_y", meta:get_int("entrance_y"))
			point_meta:set_int("exit_z", meta:get_int("entrance_z"))
			closest = dist
		end
	end
	return true
end

local function check_for_automaton_lab(green_center_pos)
	local center_pos = {x=green_center_pos.x, y=green_center_pos.y+4, z=green_center_pos.z}
	local core_pos = {x=green_center_pos.x, y=green_center_pos.y, z=center_pos.z-4}
	local core_offset = ch_schematics.utility_cores[5]
	local origin = {x=core_pos.x-core_offset.x-1, y=core_pos.y-core_offset.y-1, z=core_pos.z-core_offset.z-1}
	-- check if all required nodes are present
	for nodename,schem in pairs(ch_schematics.utility_defs[5]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			if not check_schem_colour(schem, to_group(nodename), center_pos, origin, 4, 5, 4) then
				return false
			end
		elseif nodename == "air" then
			if not check_schem_colour(schem, "air", center_pos, origin, 4, 5, 4) then
				return false
			end
		end
	end
	-- If we got here, then the automaton_lab is valid. Activate it!
	for nodename,schem in pairs(ch_schematics.utility_defs[5]) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			-- Convert to dark blocks.
			for _,scp in ipairs(schem) do
				if nodename ~= "buildings:green" then
					local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
					minetest.set_node(a, {name = nodename})
					local meta = minetest.get_meta(a)
					meta:set_int("corex", core_pos.x)
					meta:set_int("corey", core_pos.y)
					meta:set_int("corez", core_pos.z)
				end
			end
		end
	end
	-- Set control blocks to automaton_lab main blocks
	minetest.set_node({x=core_pos.x-1,y=core_pos.y,z=core_pos.z}, {name = "buildings:automaton_lab_paste"})
	minetest.set_node(core_pos, {name = "buildings:automaton_lab_execute"})
	minetest.set_node({x=core_pos.x+1,y=core_pos.y,z=core_pos.z}, {name = "buildings:automaton_lab_cut"})
	return true
end

ch_buildings.check_on_green = function(pos)
	-- check if this is some kind of building that should be activated
	if pos.y > -3000 then
		if check_for_altar1(pos) then
			return true
		end
		if check_for_altar2(pos) then
			return true
		end
		if check_for_altar3(pos) then
			return true
		end
	end
	if check_for_return_point(pos) then
		return true
	end
	if check_for_snapshot_point(pos) then
		return true
	end
	if check_for_storage_point(pos) then
		return true
	end
	if pos.y < -3000 and check_for_exit_point(pos) then
		return true
	end
	if check_for_automaton_lab(pos) then
		return true
	end

	--build_altar1(pos)

	return false
end

local function break_building(origin, schematic)
	for nodename,schem in pairs(schematic) do
		local def = minetest.registered_nodes[nodename]
		if def.groups.building then
			local colour = get_colour(nodename)
			for _,scp in ipairs(schem) do
				local a = {x=origin.x+scp.x, y=origin.y+scp.y, z=origin.z+scp.z}
				local current = minetest.get_node_or_nil(a)
				if current and current.name ~= "air" then
					local rnd = math.random(1, 100)
					if rnd < 5 then
						minetest.set_node(a, {name = "air"})
					elseif rnd < 10 or colour == "black" then
						minetest.set_node(a, {name = "world:black"})
					else
						minetest.set_node(a, {name = "world:" .. colour})
					end
				end
			end
		end
	end
	return true
end

ch_buildings.destroy_altar = function(pos)
	local node = minetest.get_node_or_nil(pos)
	if not node or not minetest.registered_nodes[node.name] then
		return false
	end
	local def = minetest.registered_nodes[node.name]
	if not def.groups.altar then
		return false
	end
	local core_offset = ch_schematics.altar_cores[def.groups.altar]
	local origin = {x=pos.x-core_offset.x-1, y=pos.y-core_offset.y-1, z=pos.z-core_offset.z-1}
	break_building(origin, ch_schematics.altar_defs[def.groups.altar])
	if ch_draconis.dragon then
		ch_draconis.check_altar_destroyed(pos)
	end
	return true
end

ch_buildings.destroy_building = function(pos)
	local node = minetest.get_node_or_nil(pos)
	if not node or not minetest.registered_nodes[node.name] then
		return false
	end
	local def = minetest.registered_nodes[node.name]
	if def.groups.altar then
		return ch_buildings.destroy_altar(pos)
	elseif def.groups.utility then
		local core_offset = ch_schematics.utility_cores[def.groups.utility]
		local origin = {x=pos.x-core_offset.x-1, y=pos.y-core_offset.y-1, z=pos.z-core_offset.z-1}
		return break_building(origin, ch_schematics.utility_defs[def.groups.utility])
	end
	return false
end

ch_buildings.incremental_break = function(node, pos, dir)
	local vandalism = false
	local meta = minetest.get_meta(pos)
	local corex = meta:get_int("corex")
	local corey = meta:get_int("corey")
	local corez = meta:get_int("corez")
	if not corex and not corey and not corez then
		-- convert old altar blocks to new generic naming
		corex = meta:get_int("altarx")
		corey = meta:get_int("altary")
		corez = meta:get_int("altarz")
	end
	local basename
	if node.name == "buildings:black" then
		minetest.set_node(pos, {name = "buildings:blacka"})
	elseif node.name == "buildings:blacka" then
		minetest.set_node(pos, {name = "buildings:blackb"})
	elseif node.name == "buildings:blackb" then
		basename = "buildings:black"
		vandalism = true
	elseif node.name == "buildings:red" then
		minetest.set_node(pos, {name = "buildings:reda"})
	elseif node.name == "buildings:reda" then
		minetest.set_node(pos, {name = "buildings:redb"})
	elseif node.name == "buildings:redb" then
		basename = "buildings:red"
		vandalism = true
	elseif node.name == "buildings:green" then
		minetest.set_node(pos, {name = "buildings:greena"})
	elseif node.name == "buildings:greena" then
		minetest.set_node(pos, {name = "buildings:greenb"})
	elseif node.name == "buildings:greenb" then
		basename = "buildings:green"
		vandalism = true
	elseif node.name == "buildings:yellow" then
		minetest.set_node(pos, {name = "buildings:yellowa"})
	elseif node.name == "buildings:yellowa" then
		minetest.set_node(pos, {name = "buildings:yellowb"})
	elseif node.name == "buildings:yellowb" then
		basename = "buildings:yellow"
		vandalism = true
	elseif node.name == "buildings:blue" then
		minetest.set_node(pos, {name = "buildings:bluea"})
	elseif node.name == "buildings:bluea" then
		minetest.set_node(pos, {name = "buildings:blueb"})
	elseif node.name == "buildings:blueb" then
		basename = "buildings:blue"
		vandalism = true
	elseif node.name == "buildings:purple" then
		minetest.set_node(pos, {name = "buildings:purplea"})
	elseif node.name == "buildings:purplea" then
		minetest.set_node(pos, {name = "buildings:purpleb"})
	elseif node.name == "buildings:purpleb" then
		basename = "buildings:purple"
		vandalism = true
	end
	if vandalism then
		local break_particles = {
			node = {name = basename},
			size = 0,
			time = 0.05,
			amount = 30,
			minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
			maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
			minvel = {x = -2, y = -2, z = -2},
			maxvel = {x = 2, y = 2, z = 2},
			minacc = {x = 0, y = -5, z = 0},
			maxacc = {x = 0, y = -5, z = 0},
		}
		minetest.set_node(pos, {name = "air"})
		minetest.add_particlespawner(break_particles)
		minetest.check_for_falling({x=pos.x, y=pos.y+1, z=pos.z})
		ch_buildings.destroy_building({x=corex, y=corey, z=corez})
	elseif corex or corey or corez then
		local new_meta = minetest.get_meta(pos)
		new_meta:set_int("corex", corex)
		new_meta:set_int("corey", corey)
		new_meta:set_int("corez", corez)
	end
end


local w = minetest.get_modpath("ch_buildings")

dofile(w .. "/blocks.lua")
