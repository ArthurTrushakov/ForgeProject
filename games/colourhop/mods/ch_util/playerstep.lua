-- LUALOCALS < ---------------------------------------------------------
local ipairs, minetest, string, type
	= ipairs, minetest, string, type
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local myapi = _G[modname]

function myapi.register_playerstep(stepfunc)
	local player_data = {}
	local function getdata(player_or_name)
		if type(player_or_name) ~= string then
			player_or_name = player_or_name:get_player_name()
		end
		local data = player_data[player_or_name]
		if not data then
			data = {}
			player_data[player_or_name] = data
		end
		return data
	end
	minetest.register_globalstep(function(dtime)
			for _, player in ipairs(minetest.get_connected_players()) do
				stepfunc(player, getdata(player), dtime)
			end
		end)
	minetest.register_on_leaveplayer(function(player)
			player_data[player:get_player_name()] = nil
		end)
	return getdata
end
