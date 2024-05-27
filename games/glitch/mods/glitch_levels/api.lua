local levels = {}

glitch_levels = {}

local active_forceloads = {}

-- Trigger player teleport if they are this many nodes away from the level bounds
local BOUNDS_TOLERANCE = 20

-- Time (in µs) after a teleport after which to ignore the "far collect" of entities
local IGNORE_FAR_COLLECT_TIME_AFTER_TELEPORT = 500000

local total_electrons = 0
function glitch_levels.get_total_electrons()
	return total_electrons
end
function glitch_levels.get_level_electrons(name)
	return levels[name].electrons_count
end

local generate_electron_identifier = function(levelname, rpos)
	return levelname .. ","..tostring(rpos.x)..","..tostring(rpos.y)..","..tostring(rpos.z)
end

-- List of all electron identifiers
local all_electron_ids = {}

-- Returns true if the electron with the given identifier exists in the game
function glitch_levels.electron_exists(identifier)
	return all_electron_ids[identifier] == true
end

local analyze_level = function(name)
	local def = levels[name]
	local schemdata = minetest.read_schematic(minetest.get_modpath("glitch_levels").."/schems/"..def.schematic, {write_yslice_prob="none"})
	levels[name].size = schemdata.size
	local electrons_count = 0
	local savezone_data = {}
	local gateway_data = {}
	local i = 1
	for z=0, schemdata.size.z-1 do
	for y=0, schemdata.size.y-1 do
	for x=0, schemdata.size.x-1 do
		local mapnode = schemdata.data[i]
		local lpos = {x=x,y=y,z=z}
		if mapnode.name == "glitch_entities:spawner_electron" then
			electrons_count = electrons_count + 1
			total_electrons = total_electrons + 1
			local electron_id = generate_electron_identifier(name, lpos)
			all_electron_ids[electron_id] = true
		elseif mapnode.name == "glitch_nodes:savezone" then
			table.insert(savezone_data, lpos)
		elseif mapnode.name == "glitch_nodes:gateway" then
			table.insert(gateway_data, { pos = lpos, gateway_no = mapnode.param2 })
		end
		i = i + 1
	end
	end
	end
	levels[name].electrons_count = electrons_count
	levels[name].savezone_data = savezone_data
	levels[name].gateway_data = gateway_data
	minetest.log("action", "[glitch_levels] Level '"..name.."' has "..electrons_count.." electron(s), "..(#savezone_data).." savezone node(s) and "..(#gateway_data).." gateway node(s)")
end

--[[
level definition = {
	pos = <vector>, -- origin pos in world
	description = "string", -- human-readable level name/title
	schematic = <schematic file name>,
	-- spawn positions (where the player may spawn)
	-- spawn 1 is the default spawn position
	spawns = { -- spawn positions are relative to pos
		[1] = { pos = <vector>, yaw = <number>, pitch = <number> },
		[2] = { pos = <vector>, yaw = <number>, pitch = <number> },
		-- pos is the spawn position
		-- yaw and pitch are optional, they set the player look direction
		...
	},
	sky = <sky name>, -- from glitch_sky mod
	ambience = <ambience name>, -- from glitch_ambience mod
	gateways = { -- list of gateways and their target levels
		[0] = <gateway definition>,
		[1] = <gateway definition>,
		-- ...
	},
	ability = <ability name> or <table>,
	-- Required for levels with ability spawners. If a single string value,
	-- this is the ability identifier of the abilit to give.
	-- If a table, will spawn the ability type based on the param2
	-- value of the node, with the table keys being the
	-- param2 value and the values being the ability names.
	reset_on_fallout = <bool>, -- if true (default), will reset player if falling out
	on_fallout = function(player), -- called when player is out of level bounds
	on_rejoin = function(player), -- called if player start the game into this level
}

gateway definition:
	* Either a string (name of the target level). This will spawn
	the player to spawn number 1.
	* Or a table:
		{
			level = <levelname>,
			spawn_no = <spawn number>,
			electrons = <number of required electrons>, --optional
			gravity = <number>, -- optional
			on_spawn = <function(player)>, --optional
		}
	Use the table to specify to which spawn number to spawn.
]]

-- Adds a level into the level "database". name is the identifier
-- def is the level definition (see above)
glitch_levels.add_level = function(name, def)
	levels[name] = def
	analyze_level(name)
end

glitch_levels.get_levels = function()
	return levels
end

-- Takes an absolute world position and a level name
-- and returns the relative level position
glitch_levels.get_relative_position_in_level = function(pos, levelname)
	local level = levels[levelname]
	if not level then
		return nil
	end
	local levelpos = level.pos
	local rpos = vector.subtract(pos, levelpos)
	return rpos
end

-- Returns true if player is currently inside a savezone
glitch_levels.is_in_savezone = function(player)
	local current_level = glitch_levels.get_current_level(player)
	if not current_level then
		return false
	end
	local ppos = vector.round(player:get_pos())
	local rpos = glitch_levels.get_relative_position_in_level(ppos, current_level)
	local savezones = levels[current_level].savezone_data
	for s=1, #savezones do
		if savezones[s].x == rpos.x and savezones[s].y == rpos.y and savezones[s].z == rpos.z then
			return true
		end
	end
	return false
end

-- Returns true if player is currently on a gateway in a level.
-- If true, second return value is gateway number.
glitch_levels.is_on_gateway = function(player)
	local current_level = glitch_levels.get_current_level(player)
	if not current_level then
		return false
	end
	local ppos = vector.round(player:get_pos())
	local rpos = glitch_levels.get_relative_position_in_level(ppos, current_level)
	local gateways = levels[current_level].gateway_data
	for g=1, #gateways do
		local gateway = gateways[g]
		if gateway.pos.x == rpos.x and gateway.pos.y+1 == rpos.y and gateway.pos.z == rpos.z then
			return true, gateway.gateway_no
		end
	end
	return false
end

-- Remove level-relevant entities between the two positions
local clear_entities = function(minpos, maxpos)
	local objects = minetest.get_objects_in_area(minpos, maxpos)
	for o=1, #objects do
		local obj = objects[o]
		local lua = obj:get_luaentity()
		if lua then
			-- Check if this is a known level entity
			if glitch_entities.level_entities[lua.name] then
				obj:remove()
			end
		end
	end
end

local colorize_level = function(minpos, maxpos, levelname)
	if glitch_editor.is_active() then
		return
	end
	local level = levels[levelname]
	local color = level.color_index or 0
	if color ~= 0 then
		local colornodes = minetest.find_nodes_in_area(minpos, maxpos, {"group:colored"})
		for n=1, #colornodes do
			local pos = colornodes[n]
			local node = minetest.get_node(pos)
			local param2 = node.param2
			param2 = node.param2 + color*32
			minetest.set_node(pos, {name=node.name, param2=param2})
		end
	end
end
	
-- Replace spawner nodes with entities between minpos and maxpos.
-- (the area MUST be fully emerged and loaded before calling this!)
local spawn_entities = function(minpos, maxpos, levelname, player)
	if glitch_editor.is_active() then
		return
	end
	local spawners = minetest.find_nodes_in_area(minpos, maxpos, {"group:spawner"})
	local gotten_electrons = glitch_entities.get_collected_electrons(player)
	for s=1, #spawners do
		local pos = spawners[s]
		local node = minetest.get_node(pos)
		local entity_name
		local ndef = minetest.registered_nodes[node.name]
		if ndef and ndef._spawns then
			entity_name = ndef._spawns
		end

		if entity_name == "glitch_entities:electron" then
			-- Check if electron already exists
			local rpos = glitch_levels.get_relative_position_in_level(pos, levelname)
			rpos = vector.round(rpos)
			local identifier = generate_electron_identifier(levelname, rpos)
			if not gotten_electrons[identifier] then

				local obj = minetest.add_entity(pos, entity_name)
				if obj then
					local ent = obj:get_luaentity()
					if ent then
						ent._identifier = identifier
						minetest.log("info", "[glitch_levels] Electron spawned: "..identifier)
					end
				end
			end
		elseif entity_name == "glitch_entities:ability" then
			local abilitydef = levels[levelname].ability
			if abilitydef then
				local ability
				if type(abilitydef) == "table" then
					ability = abilitydef[node.param2]
				else
					ability = abilitydef
				end

				-- Check if player already has ability
				local has_ability = glitch_abilities.has_ability(player, ability)
				if not has_ability then
					-- Shift a bit upwards
					local newpos = {x=pos.x, y=pos.y, z=pos.z}
					newpos.y = newpos.y + 0.5
					-- Spawn ability object
					local obj = minetest.add_entity(newpos, entity_name)
					if obj then

						-- Set ability name
						local ent = obj:get_luaentity()
						if ent then
							ent._ability = ability
							minetest.log("info", "[glitch_levels] Ability spawned: "..ability)
						end
					end
				end
			else
				minetest.log("error", "[glitch_levels] Ability entity in level, but ability is not specified in level definition: "..ability)
			end
		else
			minetest.add_entity(pos, entity_name)
		end
	end
end

local build_level_callback = function(blockpos, action, calls_remaining, param)
	if calls_remaining > 0 then
		return
	end
	if action ~= minetest.EMERGE_FROM_DISK and action ~= minetest.EMERGE_FROM_MEMORY and action ~= minetest.EMERGE_GENERATED then
		return
	end
	clear_entities(param.minpos, param.maxpos)
	local schemspec = minetest.get_modpath("glitch_levels").."/schems/"..param.schematic
	minetest.place_schematic(param.minpos, schemspec, "0", {}, true, "")
	colorize_level(param.minpos, param.maxpos, param.name)
	-- Additional optional callback function to trigger an additional event
	-- after building the level is complete.
	if param.extra_callback then
		param.extra_callback(param.extra_callback_param)
	end
	minetest.log("action", "[glitch_levels] Level built: "..param.name.." @"..minetest.pos_to_string(param.minpos))
end

glitch_levels.build_level = function(levelname, extra_callback, extra_callback_param)
	minetest.log("action", "[glitch_levels] Building level "..levelname.." ...")
	local def = levels[levelname]
	local minpos = def.pos
	local maxpos = vector.add(def.pos, def.size)
	maxpos = vector.subtract(maxpos, vector.new(1,1,1))
	local param = { minpos = minpos, maxpos = maxpos, name = levelname, schematic = def.schematic, extra_callback = extra_callback, extra_callback_param = extra_callback_param }
	local ok, failpos = minetest.emerge_area(def.pos, maxpos, build_level_callback, param)
	if ok == false then
		minetest.log("error", "[glitch_levels] emerge failed: "..dump(tostring(failpos)))
	end
end

glitch_levels.level_exists = function(level)
	return levels[level] ~= nil
end

glitch_levels.get_current_level = function(player)
	local meta = player:get_meta()
	local current_level = meta:get_string("glitch_levels:current_level")
	if current_level == "" then
		return nil
	end
	return current_level
end

glitch_levels.get_level_bounds = function(level)
	local leveldef = levels[level]
	if not leveldef then
		return
	end
	local minpos = leveldef.pos
	local maxpos = vector.add(leveldef.pos, leveldef.size)
	return minpos, maxpos
end

glitch_levels.get_level_description = function(level)
	local leveldef = levels[level]
	if not leveldef then
		-- Fallback: Return level ID
		return level
	end
	return leveldef.description
end

local reset_forceloads = function()
	for f=1, #active_forceloads do
		minetest.forceload_free_block(active_forceloads[f], true)
	end
	active_forceloads = {}
	minetest.log("action", "[glitch_levels] Forceloads reset!")
end
local add_forceloads_for_level = function(level)
	local minpos, maxpos = glitch_levels.get_level_bounds(level)
	local nodes = minetest.find_nodes_in_area(minpos, maxpos, {"group:special_spawner"})
	local cnt = 0
	for n=1, #nodes do
		-- Forceload without limit
		local ok = minetest.forceload_block(nodes[n], true, -1)
		if ok then
			cnt = cnt + 1
		else
			minetest.log("action", "[glitch_levels] Could not forceload block at "..minetest.pos_to_string(nodes[n]))
		end
	end
	if cnt > 1 then
		minetest.log("action", "[glitch_levels] "..cnt.." forceload(s) added for level "..level)
	end
end

-- Returns true if the specified spawn number exists
glitch_levels.level_spawn_exists = function(levelname, spawn_no)
	local def = levels[levelname]
	if not def then
		return false
	end
	if def.spawns then
		return def.spawns[spawn_no] ~= nil
	else
		return false
	end
end

glitch_levels.move_to_level = function(player, level, spawn_no)
	local name = player:get_player_name()
	local def = levels[level]
	if not def then
		minetest.log("error", "[glitch_levels] Trying to move player to non-existent level '"..tostring(level).."'!")
		return
	end
	local meta = player:get_meta()
	meta:set_string("glitch_levels:current_level", level)
	local sky
	if not def.sky then
		sky = "glitchworld_green"
	end
	reset_forceloads()
	add_forceloads_for_level(level)
	glitch_sky.set_sky(player, def.sky)
	local ambience = def.ambience
	if not ambience then
		ambience = "silence"
	end
	glitch_ambience.set_ambience(player, ambience)
	local minpos, maxpos = glitch_levels.get_level_bounds(level)
	glitch_utils.update_ability_nodes(player, minpos, maxpos)
	glitch_inventory_formspec.set_value(player, "electrons_level_game", levels[level].electrons_count)
	glitch_inventory_formspec.set_value(player, "electrons_total_game", total_electrons)
	glitch_entities.update_electron_count(player)

	clear_entities(minpos, maxpos)

	if def.spawns then
		local spawn = def.spawns[spawn_no or 1]
		if not spawn then
			minetest.log("error", "[glitch_levels] spawn_no "..tostring(spawn_no).." does not exist in level '"..level.."'!")
			return
		end
		-- Get level spawn info
		local spawnpos = spawn.pos
		local yaw = spawn.yaw
		local pitch = spawn.pitch
		local gravity = spawn.gravity or 1
		if not spawnpos then
			return
		end
		local real_spawnpos = vector.add(def.pos, spawnpos)

		-- This disables the extended entity collect check for a brief moment after the teleport
		local meta = player:get_meta()
		local wait_until = minetest.get_us_time() + IGNORE_FAR_COLLECT_TIME_AFTER_TELEPORT
		glitch_utils.disable_far_collect_until(player, wait_until)

		-- Spawn player
		player:set_pos(real_spawnpos)

		-- Apply optional look direction
		if yaw then
			player:set_look_horizontal(yaw)
		end
		if pitch then
			player:set_look_vertical(pitch)
		end
		playerphysics.add_physics_factor(player, "gravity", "level_gravity", gravity)
		if spawn.on_spawn then
			spawn.on_spawn(player)
		end
	else
		minetest.log("error", "[glitch_levels] Missing spawns for level '"..level.."'!")
		return
	end

	if not glitch_editor.is_active() then
		spawn_entities(minpos, maxpos, level, player)
		-- WORKAROUND:
		-- Spawn entities again after 1 second, just in case.
		-- (sometimes, entities fail to spawn)
		-- TODO: Figure out a way to not need this.
		minetest.after(1, function()
			if not player or not player:is_player() then
				return
			end
			spawn_entities(minpos, maxpos, level, player)
		end)
	end

	local msg = "Player moved to level '"..level.."'"
	if spawn_no then
		msg = msg .. ", spawn no. "..spawn_no
	else
		msg = msg .. ", default spawn"
	end
	minetest.log("action", "[glitch_levels] "..msg)
end

glitch_levels.rebuild_level = function(levelname, extra_callback, extra_callback_param)
	glitch_levels.build_level(levelname, extra_callback, extra_callback_param)
end

local is_intro_complete = function(player)
	local meta = player:get_meta()
	return meta:get_int("glitch_levels:intro_complete") == 1
end

glitch_levels.restart_level = function(player, restart_extra_callback, restart_extra_callback_param, spawn_no)
	glitch_entities.lose_temp_electrons(player)
	local current_level = glitch_levels.get_current_level(player)
	if current_level == "" then
		current_level = glitch_levels.START_LEVEL
	end
	if not spawn_no and current_level == glitch_levels.START_LEVEL and not is_intro_complete(player) then
		spawn_no = glitch_levels.START_SPAWN_NO
	end
	local extra_callback = function(param)
		glitch_levels.move_to_level(param.player, param.level, spawn_no)
		if restart_extra_callback then
			restart_extra_callback(restart_extra_callback_param)
		end
	end
	local extra_callback_param = { player = player, level = current_level }
	glitch_levels.rebuild_level(current_level, extra_callback, extra_callback_param)
end

glitch_levels.does_reset_on_fallout = function(player)
	local current_level = glitch_levels.get_current_level(player)
	if current_level == "" then
		return false
	end
	local leveldef = levels[current_level]
	return leveldef.reset_on_fallout ~= false
end

glitch_levels.handle_on_rejoin = function(player)
	local current_level = glitch_levels.get_current_level(player)
	if current_level == "" then
		return false
	end
	local leveldef = levels[current_level]
	if leveldef.on_rejoin then
		leveldef.on_rejoin(player)
		return true
	end
end

glitch_levels.handle_on_fallout = function(player)
	local current_level = glitch_levels.get_current_level(player)
	if current_level == "" then
		return
	end
	local leveldef = levels[current_level]
	if leveldef.on_fallout then
		leveldef.on_fallout(player)
	end
end

glitch_levels.is_in_bounds = function(player)
	local current_level = glitch_levels.get_current_level(player)
	if current_level == "" then
		-- If not in any level, we consider this as "in bound"
		return true
	end
	local ppos = player:get_pos()
	local leveldef = levels[current_level]
	local tol = vector.new(BOUNDS_TOLERANCE, BOUNDS_TOLERANCE, BOUNDS_TOLERANCE)
	local llminpos, llmaxpos = glitch_levels.get_level_bounds(current_level)
	local llmaxpos = vector.add(leveldef.pos, leveldef.size)
	llmaxpos = vector.subtract(llmaxpos, vector.new(1,1,1))
	local lminpos = vector.subtract(llminpos, tol)
	local lmaxpos = vector.add(llmaxpos, tol)
	return ppos.y >= lminpos.y and ppos.y <= lmaxpos.y and ppos.x >= lminpos.x and ppos.x <= lmaxpos.x and ppos.z >= lminpos.z and ppos.z <= lmaxpos.z
end

-- Returns the destination of gateway number `gateway_no` of the given level.
-- Returns <dest_level>, <dest_spawn_no>
-- 	(destination level and spawn number)
glitch_levels.get_gateway_destination = function(level, gateway_no)
	local leveldef = levels[level]
	local gatewaydef = leveldef.gateways[gateway_no]
	local dest_level
	local dest_spawn_no = 1
	if type(gatewaydef) == "string" then
		dest_level = gatewaydef
	else
		dest_level = gatewaydef.level
		dest_spawn_no = gatewaydef.spawn_no
	end
	return dest_level, dest_spawn_no
end

-- Returns the number of required electrons to use a gateway
glitch_levels.get_gateway_required_electrons = function(level, gateway_no)
	local leveldef = levels[level]
	local gatewaydef = leveldef.gateways[gateway_no]
	local elecs
	if type(gatewaydef) == "table" then
		elecs = gatewaydef.electrons
	end
	if not elecs then
		elecs = 0
	end
	return elecs
end

if not glitch_editor.is_active() then
	-- Special spawner ABM (regularily triggers their spawn function)
	minetest.register_abm({
		label = "Trigger special spawners",
		nodenames = {"group:special_spawner"},
		interval = 1,
		chance = 40,
		action = function(pos, node)
			local def = minetest.registered_nodes[node.name]
			def._spawn_func(pos)
		end,
	})
end
