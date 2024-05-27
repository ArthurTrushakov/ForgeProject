-- Level entities.
-- These are persistent entities that are considered to be part of a level.

local S = minetest.get_translator("glitch_entities")

-- Debug feature: If true, will spawn particles at positions that
-- are checked for collectibles
local SHOW_CHECKED_POSITIONS = false

-- Returns true if an object of the same type already exists
-- at its place
local object_already_exists = function(self)
	local pos = self.object:get_pos()
	local objs = minetest.get_objects_inside_radius(pos, 0.4)
	for o=1, #objs do
		local obj = objs[o]
		local ent = obj:get_luaentity()
		if obj ~= self.object and ent and ent.name == self.name then
			return true
		end
	end
	return false
end

-- Returns true if the object is allowed to exist
glitch_entities.is_entity_allowed = function(self)
	return (not glitch_editor.is_active()) and (not object_already_exists(self))
end

-- List of level entities
glitch_entities.level_entities = {
	["glitch_entities:cube"] = true,
	["glitch_entities:electron"] = true,
	["glitch_entities:ability"] = true,
}

--[[ DECORATIVE CUBE ENTITY ]]

local SCALE_CUBE = 1.7
minetest.register_entity("glitch_entities:cube", {
	visual = "mesh",
	shaded = true,
	mesh = "glitch_entities_cube.obj",
	visual_size = { x=SCALE_CUBE, y=SCALE_CUBE, z=SCALE_CUBE },
	automatic_rotate = 1,
	backface_culling = false,
	textures = {
		"glitch_entities_cube.png",
		"glitch_entities_cube.png",
		"glitch_entities_cube.png",
		"glitch_entities_cube.png",
		"glitch_entities_cube.png",
		"glitch_entities_cube.png",
	},
	shaded = true,
	pointable = false,
	_anim_timer = 0,
	on_activate = function(self, staticdata, dtime_s)
		if not glitch_entities.is_entity_allowed(self) then
			self.object:remove()
			return
		end
		if dtime_s == 0 then
			local x = math.random(-100, 100)*0.01
			local y = math.random(-100, 100)*0.01
			local z = math.random(-100, 100)*0.01
			self.object:set_rotation({x=x,y=y,z=z})
		end
	end,
})


--[[ ELECTRON ENTITY ]]
-- A special entity that can be collected by the player by moving close to it
local COLLECT_RANGE_ELECTRON = 0.825
local SCALE_ELECTRON = 0.5
local ELECTRON_GUI_COUNTER_TIME = 5
local ELECTRON_GUI_COUNTER_COLOR_TEMP = 0xCCCCCC
local ELECTRON_GUI_COUNTER_COLOR_SAFE = 0x82CAE1

-- Number of positions to check between two position (including
-- the two). Part of "far-collect" to make electron detection much
-- more precise. A higher number increases precision but might
-- reduce performance.
local COLLECT_CHECK_INTERMEDIATE_STEPS = 11

local electron_guis = {}
-- Stores last player position
local last_player_pos = {}

local update_electron_gui = function(player, electrons_temp, electrons_safe)
	-- Don't show electron counter in editor
	if glitch_editor.is_active() then
		return
	end
	-- Don't show electron counter during intro
	local meta = player:get_meta()
	if meta:get_int("glitch_levels:intro_complete") == 0 then
		return
	end
	local name = player:get_player_name()
	local gui = electron_guis[name]
	if not gui then
		return
	end
	local electrons_extra = electrons_temp - electrons_safe
	local counter_text = tostring(electrons_safe)
	local counter_text_extra
	if electrons_extra > 0 then
		counter_text_extra = S("+@1", electrons_extra)
	else
		counter_text_extra = ""
	end
	player:hud_change(gui.bg, "text", "glitch_entities_electron_gui_bg.png")
	player:hud_change(gui.icon, "text", "glitch_entities_electron_icon.png")
	player:hud_change(gui.counter, "text", counter_text)
	player:hud_change(gui.counter_extra, "text", counter_text_extra)
	gui.sequence_number = gui.sequence_number + 1
	minetest.after(ELECTRON_GUI_COUNTER_TIME, function(param)
		if not player or not player:is_player() then
			return
		end
		local aname = player:get_player_name()
		local agui = electron_guis[aname]
		-- Don't hide if the electron GUI was updated again before
		if agui.sequence_number ~= param then
			return
		end
		player:hud_change(agui.bg, "text", "blank.png")
		player:hud_change(agui.icon, "text", "blank.png")
		player:hud_change(agui.counter, "text", "")
		player:hud_change(agui.counter_extra, "text", "")
	end, gui.sequence_number)
end

-- TODO: If this is called repeatedly, this will cause some minetest.after spam.
-- Probably not a huge deal, but would be cleaner code, probably.
glitch_entities.show_electron_gui = function(player)
	local current_level = glitch_levels.get_current_level(player)
	local electrons_temp = glitch_entities.count_collected_electrons(player, false)
	local electrons_safe = glitch_entities.count_collected_electrons(player, true)
	update_electron_gui(player, electrons_temp, electrons_safe)
end

local collect_electron = function(player, entity)
	if (not entity._identifier) or entity._identifier == "unknown,0,0,0" then
		return
	end

	-- Update player meta
	local meta = player:get_meta()
	local ccs = meta:get_string("glitch_entities:collected_electrons_temp")
	local cc
	if cc == "" then
		cc = {}
	else
		cc = minetest.deserialize(ccs)
		if not (cc and type(cc) == "table") then
			cc = {}
		end
	end
	cc[entity._identifier] = true
	ccs = minetest.serialize(cc)
	meta:set_string("glitch_entities:collected_electrons_temp", ccs)

	local current_level = glitch_levels.get_current_level(player)
	local e_level, e_total = glitch_entities.count_collected_electrons_in_level(player, current_level)

	-- Update electron counters
	glitch_entities.update_electron_count(player)

	-- Log
	minetest.log("action", player:get_player_name() .. " collects electron '" ..tostring(player._identifier).."'")

	local selfpos = entity.object:get_pos()

	-- Sound and particle effects
	minetest.sound_play({name="glitch_entities_collect", gain=1}, {pos=selfpos}, true)
	local minvel = vector.new(-6,-8,-6)
	local maxvel = vector.new(6,8,6)
	minetest.add_particlespawner({
		amount = 30,
		exptime = { min = 0.9, max = 1.0 },
		size = 1,
		time = 0.005,
		texture = {
			name = "glitch_entities_electron_particle.png",
			alpha_tween = { start = 0.85, 1, 0 },
		},
		pos = { min=vector.subtract(selfpos, 0.2), max = vector.add(selfpos, 0.2) },
		vel = { min=minvel, max=maxvel },
		drag = vector.new(1, 1, 1),
	})

	-- Because it was collected, we destroy this entity
	entity.object:remove()
end


minetest.register_entity("glitch_entities:electron", {
	visual = "mesh",
	shaded = true,
	mesh = "glitch_entities_electron.obj",
	visual_size = { x=SCALE_ELECTRON, y=SCALE_ELECTRON, z=SCALE_ELECTRON },
	collisionbox = { -0.25, -0.25, -0.25, 0.25, 0.25, 0.25 },
	selectionbox = { -0.25, -0.25, -0.25, 0.25, 0.25, 0.25 },
	automatic_rotate = 1,
	backface_culling = false,
	physical = false,
	pointable = false,
	textures = {
		"glitch_entities_electron.png",
	},

	-- A string that identifies a electron in a level.
	-- Required so the game knows *which* electron was collected
	-- Syntax: <levelname>,<x>,<y>,<z>
	-- Note: x, y, z are the electron's position relative to the
	-- level origin.
	_identifier = "unknown,0,0,0", -- start with a dummy identifier

	on_activate = function(self, staticdata, dtime_s)
		if not glitch_entities.is_entity_allowed(self) then
			self.object:remove()
			return
		end
		local data = minetest.deserialize(staticdata)
		if data and data._identifier then
			self._identifier = data._identifier
		end
	end,
	get_staticdata = function(self)
		local data = { _identifier = self._identifier }
		local sdata = minetest.serialize(data)
		return sdata
	end,
})

minetest.register_chatcommand("list_collected", {
	description = S("Show the list of your collected electrons"),
	params = "",
	privs = { server = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player or not player:is_player() then
			return false, S("No player.")
		end
		local meta = player:get_meta()
		local ccs = meta:get_string("glitch_entities:collected_electrons")
		local cc = minetest.deserialize(ccs)
		local ccst = meta:get_string("glitch_entities:collected_electrons_temp")
		local cct = minetest.deserialize(ccst)
		if not cct then
			return true, S("Nothing collected.")
		end
		local collected_safe = {}
		for k, v in pairs(cc) do
			table.insert(collected_safe, k)
		end
		local out1 = table.concat(collected_safe, ", ")

		local collected_temp = {}
		for k, v in pairs(cct) do
			table.insert(collected_temp, k)
		end
		local out2 = table.concat(collected_temp, ", ")

		local out = S("Safe electrons: @1", out1).."\n"..S("All electrons: @1", out2)

		return true, out
	end,
})

minetest.register_chatcommand("reset_collected", {
	description = S("Remove all your collected and saved electrons (cannot be undone)"),
	params = "",
	privs = { server = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player or not player:is_player() then
			return false, S("No player.")
		end
		local meta = player:get_meta()
		meta:set_string("glitch_entities:collected_electrons", "")
		meta:set_string("glitch_entities:collected_electrons_temp", "")
		glitch_entities.update_electron_count(player)
		return true, S("All your electrons are now gone.")
	end,
})

-- Return table of all collected electrons of player (key = identifier, value = true)
function glitch_entities.get_collected_electrons(player, safe)
	local meta = player:get_meta()
	local ccs
	if safe then
		ccs = meta:get_string("glitch_entities:collected_electrons")
	else
		ccs = meta:get_string("glitch_entities:collected_electrons_temp")
	end
	local cc = minetest.deserialize(ccs)
	if not cc then
		return {}
	else
		return cc
	end
end

function glitch_entities.lose_temp_electrons(player)
	local meta = player:get_meta()
	local cc = meta:get_string("glitch_entities:collected_electrons")
	meta:set_string("glitch_entities:collected_electrons_temp", cc)
	glitch_entities.update_electron_count(player)
end

function glitch_entities.save_electrons(player)
	if glitch_entities.are_electrons_safe(player) then
		-- No saving neccessary
		return false
	else
		local meta = player:get_meta()
		local cct = meta:get_string("glitch_entities:collected_electrons_temp")
		meta:set_string("glitch_entities:collected_electrons", cct)
		glitch_entities.update_electron_count(player)
		return  true
	end
end

function glitch_entities.are_electrons_safe(player)
	local meta = player:get_meta()
	local cct = meta:get_string("glitch_entities:collected_electrons_temp")
	local cc = meta:get_string("glitch_entities:collected_electrons")
	return cc == cct
end

local function count_collected_electrons_helper(player, level, safe)
	local elecs = glitch_entities.get_collected_electrons(player, safe)
	local num_total = 0
	local num_level = 0
	for id, _ in pairs(elecs) do
		num_total = num_total + 1
		if level then
			local splits = string.split(id, ",")
			if splits and splits[1] and splits[1] == level then
				num_level = num_level + 1
			end
		end
	end
	return num_total, num_level
end

-- Returns total number of player's collected electrons
function glitch_entities.count_collected_electrons(player, safe)
	local num_total = count_collected_electrons_helper(player, nil, safe)
	return num_total
end

-- Returns number of player's collected electrons for a given level
-- Second return value is total electron count.
function glitch_entities.count_collected_electrons_in_level(player, level, safe)
	local num_total, num_level = count_collected_electrons_helper(player, level, safe)
	return num_level, num_total
end

-- For updating inventory and GUI
function glitch_entities.update_electron_count(player)
	local e_level_temp, e_level_safe, e_total_temp, e_total_safe = 0, 0, 0, 0
	local level = glitch_levels.get_current_level(player)
	if level then
		e_level_temp = glitch_entities.count_collected_electrons_in_level(player, level, false)
		e_level_safe = glitch_entities.count_collected_electrons_in_level(player, level, true)
	end

	-- Update GUI
	local e_total_temp = glitch_entities.count_collected_electrons(player, false)
	local e_total_safe = glitch_entities.count_collected_electrons(player, true)
	update_electron_gui(player, e_total_temp, e_total_safe)

	-- Update inventory
	glitch_inventory_formspec.set_value(player, "electrons_total_temp", e_total_temp)
	glitch_inventory_formspec.set_value(player, "electrons_level_temp", e_level_temp)
	glitch_inventory_formspec.set_value(player, "electrons_total_safe", e_total_safe)
	glitch_inventory_formspec.set_value(player, "electrons_level_safe", e_level_safe)
	glitch_inventory_formspec.update(player)
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()

	-- Remove all collected electrons from player meta
	-- that no longer exist in levels. This can happen
	-- when a level was changed after a version update.
	local meta = player:get_meta()
	local ccs = meta:get_string("glitch_entities:collected_electrons")
	local cc = minetest.deserialize(ccs)
	local cc2
	if not cc then
		cc = {}
		cc2 = {}
	else
		cc2 = table.copy(cc)
	end
	local removed = 0
	for id,_ in pairs(cc) do
		if not glitch_levels.electron_exists(id) then
			cc2[id] = nil
			removed = removed + 1
		end
	end
	if removed > 0 then
		ccs = minetest.serialize(cc2)
		meta:set_string("glitch_entities:collected_electrons", ccs)
		minetest.log("action", "[glitch_entities] Removed "..removed.." legacy electron(s) from "..name)
	end

	-- Add HUD elements for the electron counter
	electron_guis[name] = {}
	electron_guis[name].bg = player:hud_add({
		hud_elem_type = "image",
		z_index = 10,
		position = { x = 0, y = 1 },
		-- wide enough for 7 characters
		scale = { x = 30, y = 6.5 },
		text = "",
		alignment = { x = 1, y = -1 },
		offset = { x = 0, y = 0 },
	})
	electron_guis[name].icon = player:hud_add({
		hud_elem_type = "image",
		z_index = 11,
		position = { x = 0, y = 1 },
		scale = { x = 5, y = 5 },
		text = "blank.png",
		alignment = { x = 1, y = 0 },
		offset = { x = 12, y = -48 },
	})
	electron_guis[name].counter = player:hud_add({
		hud_elem_type = "text",
		number = ELECTRON_GUI_COUNTER_COLOR_SAFE,
		style = 4,
		z_index = 12,
		position = { x = 0, y = 1 },
		size = { x = 5, y = 5 },
		scale = { x = 100, y = 100 },
		text = "",
		alignment = { x = 1, y = 0 },
		offset = { x = 48+70, y = -48 },
	})
	electron_guis[name].counter_extra = player:hud_add({
		hud_elem_type = "text",
		number = ELECTRON_GUI_COUNTER_COLOR_TEMP,
		style = 4,
		z_index = 12,
		position = { x = 0, y = 1 },
		size = { x = 2, y = 2 },
		scale = { x = 100, y = 100 },
		text = "",
		alignment = { x = -1, y = 1 },
		offset = { x = 48+70+345, y = -48 },
	})

	electron_guis[name].sequence_number = 0
	glitch_entities.update_electron_count(player)
end)
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	electron_guis[name] = nil
	last_player_pos[name] = nil
end)

-- Ability
local SCALE_ABILITY = 3.0
local COLLECT_RANGE_ABILITY = 1.0

local collect_ability = function(player, entity)
	if (not entity._ability) then
		return
	end

	local selfpos = entity.object:get_pos()
	-- Get ability
	glitch_abilities.add_ability(player, entity._ability, true)

	-- Log
	minetest.log("action", player:get_player_name() .. " collects ability '" ..tostring(entity._ability).."'")

	-- Sound and particle effects
	minetest.sound_play({name="glitch_entities_collect", gain=1, pitch=0.2}, {pos=selfpos}, true)
	local minvel = vector.new(-14,-14,-14)
	local maxvel = vector.new(14,14,14)
	minetest.add_particlespawner({
		amount = 120,
		exptime = { min = 1.8, max = 2.0 },
		size = 2,
		time = 1.6,
		texture = {
			name = "glitch_entities_ability_particle.png",
			alpha_tween = { start = 0.85, 1, 0 },
		},
		pos = { min=vector.subtract(selfpos, 0.2), max = vector.add(selfpos, 0.2) },
		vel = { min=minvel, max=maxvel },
		drag = vector.new(1, 1, 1),
	})

	-- Because it was collected, we destroy this entity
	entity.object:remove()
end

minetest.register_entity("glitch_entities:ability", {
	visual = "mesh",
	shaded = true,
	mesh = "glitch_entities_ability.obj",
	visual_size = { x=SCALE_ABILITY, y=SCALE_ABILITY, z=SCALE_ABILITY },
	collisionbox = { -0.25, -0.25, -0.25, 0.25, 0.25, 0.25 },
	selectionbox = { -0.25, -0.25, -0.25, 0.25, 0.25, 0.25 },
	automatic_rotate = 0.5,
	backface_culling = false,
	physical = false,
	pointable = false,
	textures = {
		"glitch_entities_ability_outer.png",
		"glitch_entities_ability_inner.png",
	},

	-- Store which ability this gives
	_ability = nil,

	on_activate = function(self, staticdata, dtime_s)
		if not glitch_entities.is_entity_allowed(self) then
			self.object:remove()
			return
		end
		local data = minetest.deserialize(staticdata)
		if data and data._ability then
			self._ability = data._ability
		end
	end,
	get_staticdata = function(self)
		local data = { _ability = self._ability }
		local sdata = minetest.serialize(data)
		return sdata
	end,
})

-- Returns a list of `steps` positions on a straight
-- line between pos1 and pos2 (including the two).
-- `steps` must be at least 2.
local get_intermediate_positions = function(pos1, pos2, steps)
	if steps < 2 then
		return nil
	end
	local posses = { pos1 }
	local sx, sy, sz, ex, ey, ez
	sx = math.min(pos1.x, pos2.x)
	sy = math.min(pos1.y, pos2.y)
	sz = math.min(pos1.z, pos2.z)
	ex = math.max(pos1.x, pos2.x)
	ey = math.max(pos1.y, pos2.y)
	ez = math.max(pos1.z, pos2.z)
	local xup, yup, zup
	xup = pos1.x < pos2.x
	yup = pos1.y < pos2.y
	zup = pos1.z < pos2.z
	local x,y,z
	steps = steps - 1
	for s=1, steps-1 do
		if xup then
			x = sx + (ex - sx) * (s/steps)
		else
			x = sx + (ex - sx) * ((steps-s)/steps)
		end
		if yup then
			y = sy + (ey - sy) * (s/steps)
		else
			y = sy + (ey - sy) * ((steps-s)/steps)
		end
		if zup then
			z = sz + (ez - sz) * (s/steps)
		else
			z = sz + (ez - sz) * ((steps-s)/steps)
		end
		table.insert(posses, vector.new(x,y,z))
	end
	table.insert(posses, pos2)
	return posses
end

-- Returns true if player will use the extended collect check,
-- (with multiple position checks).
-- Return false if player can only perform a simple collect check
-- (only checks current position).
local can_collect_far = function(player)
	local meta = player:get_meta()
	local now = minetest.get_us_time()
	local wait_until = glitch_utils.get_disable_far_collect_until(player)
	if wait_until == nil then
		return true
	end
	return now > wait_until
end

-- Helper function to collect a collectible object if in range
local scan_and_collect = function(player_pos, object_pos, collect_range, collect_function, player, luaentity)
	local dist = vector.distance(player_pos, object_pos)
	if dist <= collect_range then
		collect_function(player, luaentity)
	end
end

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	local max_collect_range = math.max(COLLECT_RANGE_ELECTRON, COLLECT_RANGE_ABILITY)
	for p=1, #players do
		local player = players[p]
		local name = player:get_player_name()
		local last_pos = last_player_pos[name] -- pos of the previous globalstep
		local ppos = player:get_pos()
		if not last_pos then
			last_pos = ppos
		end

		local check_posses
		--[[ If player did not move or the far-collect is disabled
		(which happens if the player has freshly teleported),
		the player will check multiple positions on a line between
		current pos and last_pos to greatly increase the chance that
		a fast-moving player will still collect all objects.
		This is neccessary because a fast-moving player might sometimes not return
		a position close to an object, thus failing to collect it although
		the player clearly has passed the position.
		We only check a straight line and not accurately simulate the actual path
		between the two positions which might not be the exact player movement,
		but this inaccuracy might not matter since the time between globalsteps
		is very short.

		"far-collect" refers to the multiple position checks.
		]]
		if vector.distance(ppos, last_pos) < 0.2 or (not can_collect_far(player)) then
			-- simple collect:
			-- We only check the check the current player pos.
			check_posses = { ppos }
		else
			-- far-collect:
			-- We check multiple positions (explained above).
			check_posses = get_intermediate_positions(last_pos, ppos, COLLECT_CHECK_INTERMEDIATE_STEPS)
		end

		for c=1, #check_posses do
			if SHOW_CHECKED_POSITIONS then
				-- DEBUG: Show all positions which are checked for collectibles
				minetest.add_particlespawner({
					amount = 1,
					exptime = 10,
					size = 1,
					texture = {
						name = "glitch_entities_electron_particle.png^[colorize:#FF0000:127",
					},
					pos = check_posses[c],
					glow = minetest.LIGHT_MAX,
				})
			end
			local cpos = check_posses[c]
			local objs = minetest.get_objects_in_area(vector.subtract(cpos, max_collect_range), vector.add(cpos, max_collect_range))
			for o=1, #objs do
				local obj = objs[o]
				local lua = obj:get_luaentity()
				if lua then
					local dist
					local opos = obj:get_pos()
					if lua.name == "glitch_entities:electron" then
						scan_and_collect(cpos, opos, COLLECT_RANGE_ELECTRON, collect_electron, player, lua)
					elseif lua.name == "glitch_entities:ability" then
						scan_and_collect(cpos, opos, COLLECT_RANGE_ABILITY, collect_ability, player, lua)
					end
				end
			end
		end
		-- Remember pos for the next globalstep
		last_player_pos[name] = ppos
	end
end)

--[[ SPAWNER NODES ]]
-- Mark spawn positions of entities in levels
local function register_spawner_node(entity_partname, description, mesh, tiles, fallback_inventory_image, scale)
	local drawtype, inventory_image, wield_image, wield_scale, pointable
	if not glitch_editor.is_active() then
		drawtype = "airlike"
		mesh = nil
		inventory_image = fallback_inventory_image
		wield_image = fallback_inventory_image
		tiles = nil
		pointable = false
	else
		drawtype = "mesh"
		wield_scale = { x=0.2 * scale, y=0.2 * scale, z=0.2 * scale}
		pointable = true
	end
	minetest.register_node("glitch_entities:spawner_"..entity_partname, {
		description = description,
		drawtype = drawtype,
		mesh = mesh,
		visual_scale = 0.1 * scale,
		wield_scale = wield_scale,
		tiles = tiles,
		inventory_image = inventory_image,
		wield_image = wield_image,
		pointable = pointable,
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		groups = { spawner = 1, dig_creative = 3 },

		-- Name of the entity that this node spawns
		_spawns = "glitch_entities:"..entity_partname,
	})
end
register_spawner_node("electron", S("Electron Spawner"), "glitch_entities_electron.obj", { "glitch_entities_electron.png" }, "glitch_entities_electron_inv.png", SCALE_ELECTRON)
register_spawner_node("cube", S("Cube Spawner"), "glitch_entities_cube.obj", { "glitch_entities_cube.png" }, "glitch_entities_cube_inv.png", 0.5)
register_spawner_node("ability", S("Ability Spawner"), "glitch_entities_ability.obj", { "glitch_entities_ability_inner.png", "glitch_entities_ability_outer.png" }, "glitch_entities_ability_inv.png", 1.6)
