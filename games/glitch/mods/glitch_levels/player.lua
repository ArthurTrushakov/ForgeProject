local S = minetest.get_translator("glitch_levels")

minetest.register_on_newplayer(function(player)
	glitch_levels.move_to_level(player, glitch_levels.START_LEVEL, glitch_levels.START_SPAWN_NO)
end)

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	local current_level = meta:get_string("glitch_levels:current_level")
	if current_level == "" then
		current_level = glitch_levels.START_LEVEL
		meta:set_string("glitch_levels:current_level", current_level)
	end
	if not glitch_editor.is_active() then
		local rejoin_handled = glitch_levels.handle_on_rejoin(player)
		if not rejoin_handled then
			glitch_levels.restart_level(player)
		end
	end
	if meta:get_int("glitch_levels:intro_complete") == 1 then
		glitch_abilities.add_ability(player, "glitch:slide", false)
	end
end)

-- Restart level if player falls out of bounds or is inside a resetter node
local timer = 0
local CHECK_TIMER = 1.0
local restarting_players = {}
minetest.register_globalstep(function(dtime)
	if glitch_editor.is_active() then
		return
	end
	timer = timer + dtime
	if timer < CHECK_TIMER then
		return
	end
	timer = 0
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local name = player:get_player_name()
		local restart = false
		local node = minetest.get_node(player:get_pos())
		local is_resetter = minetest.get_item_group(node.name, "resetter") == 1
		local is_in_bounds = glitch_levels.is_in_bounds(player)
		if (not restarting_players[name]) and ((not is_in_bounds) or is_resetter) then
			if is_resetter or glitch_levels.does_reset_on_fallout(player) then
				restart = true
			end
			if (not is_in_bounds) then
				glitch_levels.handle_on_fallout(player)
			end
		end
		if restart then
			restarting_players[name] = true
			local after_restart = function(player_name)
				restarting_players[player_name] = false
			end
			local after_screen = function(player)
				if player and player:is_player() then
					glitch_ambience.set_ambience_volume(player, 0.1, 1.0)
					local name = player:get_player_name()
					local spawn_no
					if is_resetter and node.param2 ~= 0 then
						spawn_no = node.param2
					end
					glitch_levels.restart_level(player, after_restart, name, spawn_no)
				end
			end
			glitch_entities.lose_temp_electrons(player)
			glitch_ambience.set_ambience_volume(player, 10, 0.001)
			glitch_screen.show_screen_multi(player, "glitch_with_sound", 2, 0.5, after_screen, player)
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	restarting_players[name] = nil
end)

minetest.register_chatcommand("level", {
	description = S("Teleport yourself to a given level"),
	params = S("<level> [<spawn number>]"),
	privs = { server = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player or not player:is_player() then
			return false, S("No player.")
		end
		if restarting_players[name] then
			return false, S("Can't change level now!")
		end
		local splits = string.split(param, " ")
		local levelname, spawn_no
		if #splits == 1 then
			levelname = param
		elseif #splits == 2 then
			levelname = splits[1]
			spawn_no = tonumber(splits[2])
			if not spawn_no then
				return false, S("Invalid spawn number!")
			end
		else
			return false
		end
		if not glitch_levels.level_exists(levelname) then
			return false, S("Level ID does not exist! (use “/list_levels” for a list)")
		elseif spawn_no and not glitch_levels.level_spawn_exists(levelname, spawn_no) then
			return false, S("Level spawn number does not exist!")
		else
			glitch_levels.move_to_level(player, levelname, spawn_no)
			return true
		end
	end,
})

minetest.register_chatcommand("restart", {
	description = S("Restart the current level"),
	param = "",
	privs = { server = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player or not player:is_player() then
			return false, S("No player.")
		end
		if restarting_players[name] then
			return false, S("Restart in progress.")
		end
		glitch_levels.restart_level(player)
		return true
	end,
})

minetest.register_chatcommand("list_levels", {
	description = S("Shows a list of all levels"),
	param = "",
	privs = { server = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player or not player:is_player() then
			return false, S("No player.")
		end
		local levels = glitch_levels.get_levels()
		local level_table = {}
		for id, def in pairs(levels) do
			table.insert(level_table, S("* @1 (@2)", id, def.description))
		end
		local levelstr = table.concat(level_table, "\n")
		levelstr = S("List of levels:").."\n"..levelstr
		return true, levelstr
	end,
})

