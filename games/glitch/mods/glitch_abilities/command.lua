local S = minetest.get_translator("glitch_abilities")
minetest.register_chatcommand("ability", {
	description = S("Give/remove yourself an ability or list abilities"),
	params = S("(add <ability>) | (remove <ability>) | list"),
	privs = { server = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player or not player:is_player() then
			return false, S("No player.")
		end
		local split = string.split(param, " ")
		if (split[1] == "add" or split[1] == "remove") and split[2] then
			local ability_function, ret_msg
			if split[1] == "add" then
				ability_function = glitch_abilities.add_ability
				ret_msg = S("All abilities added.")
			else
				ability_function = glitch_abilities.remove_ability
				ret_msg = S("All abilities removed.")
			end
			local abl = split[2]
			if abl == "all" then
				for abl2,_ in pairs(glitch_abilities.registered_abilities) do
					ability_function(player, abl2, false)
				end
				return true, ret_msg
			end
			if not glitch_abilities.registered_abilities[abl] then
				return false, S("Unknown ability.")
			end
			ability_function(player, abl, true)
			return true
		elseif param == "list" then
			local list = {}
			for abl,_ in pairs(glitch_abilities.registered_abilities) do
				table.insert(list, abl)
			end
			local ret = table.concat(list, " ")
			if ret ~= "" then
				return true, ret
			else
				return false, S("No abilities.")
			end
		else
			return false
		end
	end,
})

