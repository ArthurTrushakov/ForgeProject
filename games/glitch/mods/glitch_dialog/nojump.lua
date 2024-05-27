local nojump_players = {}

-- Show a message to player when trying to jump

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local name = player:get_player_name()
		local ctrl = player:get_player_control()
		if not nojump_players[name] and ctrl.jump and not glitch_abilities.has_ability(player, "glitch:jumppad") then
			local meta = player:get_meta()
			if meta:get_int("glitch_levels:intro_complete") == 1 then
				meta:set_int("glitch_dialog:nojump", 1)
				glitch_dialog.show_dialogtree(player, "glitch:nojump")
				nojump_players[name] = true
			end
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	nojump_players[name] = nil
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local meta = player:get_meta()
	if meta:get_int("glitch_dialog:nojump") == 1 then
		nojump_players[name] = true
	end
end)
