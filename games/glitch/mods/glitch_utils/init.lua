glitch_utils = {}

local update_ability_nodes = function(player, minpos, maxpos)
	local climb = glitch_abilities.has_ability(player, "glitch:climb")
	local nodes = minetest.find_nodes_in_area(minpos, maxpos, {"group:climbrail"})
	for n=1, #nodes do
		local pos = nodes[n]
		local node = minetest.get_node(pos)
		if climb then
			if node.name == "glitch_nodes:climbrail_noclimb" then
				minetest.set_node(pos, {name="glitch_nodes:climbrail"})
			elseif node.name == "glitch_nodes:climbrail_nojumpnoclimb" then
				minetest.set_node(pos, {name="glitch_nodes:climbrail_nojump"})
			end
		else
			if node.name == "glitch_nodes:climbrail" then
				minetest.set_node(pos, {name="glitch_nodes:climbrail_noclimb"})
			elseif node.name == "glitch_nodes:climbrail_nojump" then
				minetest.set_node(pos, {name="glitch_nodes:climbrail_nojumpnoclimb"})
			end
		end
	end
	minetest.log("action", "[glitch_utils] Ability nodes updated in area "..minetest.pos_to_string(minpos)..", "..minetest.pos_to_string(maxpos))
end

local emerge_callback = function(blockpos, action, calls_remaining, param)
	if calls_remaining > 0 then
		return
	end
	if action == minetest.EMERGE_FROM_DISK or action == minetest.EMERGE_FROM_MEMORY or action == minetest.EMERGE_GENERATED then
		update_ability_nodes(param.player, param.minpos, param.maxpos)
	end
end


-- Updates the nodes according to the player ability within the area minpos-maxpos
glitch_utils.update_ability_nodes = function(player, minpos, maxpos)
	if minetest.get_node(minpos).name == "ignore" then
		minetest.emerge_area(minpos, maxpos, emerge_callback, {player=player, minpos=minpos, maxpos=maxpos})
	else
		update_ability_nodes(player, minpos, maxpos)
	end
end

local disable_far_collect_until = {}

glitch_utils.disable_far_collect_until = function(player, ustime)
	local name = player:get_player_name()
	disable_far_collect_until[name] = ustime
end

glitch_utils.get_disable_far_collect_until = function(player)
	local name = player:get_player_name()
	return disable_far_collect_until[name]
end

local is_in_end_screen = {}

glitch_utils.set_is_in_end_screen = function(player, state)
	local name = player:get_player_name()
	is_in_end_screen[name] = state
end
glitch_utils.is_in_end_screen = function(player)
	local name = player:get_player_name()
	return is_in_end_screen[name]
end

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	disable_far_collect_until[name] = nil
	is_in_end_screen[name] = nil
end)
