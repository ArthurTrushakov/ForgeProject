-- LUALOCALS < ---------------------------------------------------------
local minetest, type
    = minetest, type
-- LUALOCALS > ---------------------------------------------------------

local function player_name(player)
	if not player then return end
	if type(player) == "string" then return player end
	player = player.get_player_name and player:get_player_name()
	if type(player) == "string" then return player end
end

local priv_cache = {}

local function invalidateafter(method)
	local oldfunc = minetest[method]
	minetest[method] = function(player, ...)
		local function helper(...)
			local name = player_name(player)
			if name then priv_cache[name] = nil end
			return ...
		end
		return helper(oldfunc(player, ...))
	end
end
invalidateafter("set_privileges")
invalidateafter("remove_player_auth")

local function invalidateon(event)
	minetest["register_on_" .. event](function(player)
			local name = player_name(player)
			if name then priv_cache[name] = nil end
		end)
end
invalidateon("joinplayer")
invalidateon("leaveplayer")

local oldreload = minetest.auth_reload
function minetest.auth_reload(...)
	priv_cache = {}
	return oldreload(...)
end

local oldget = minetest.get_player_privs
function minetest.get_player_privs(player)
	local pname = player_name(player)
	if not pname then return oldget(player) end
	local cached = priv_cache[pname]
	if cached then return cached end
	cached = oldget(pname)
	priv_cache[pname] = cached
	return cached
end
