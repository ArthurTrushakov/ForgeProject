ch_draconis = {}

ch_draconis.walkable_nodes = {}

ch_draconis.dragon = nil
ch_draconis.dragon_spawning = 0

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_nodes) do
		if name ~= "air" and name ~= "ignore" then
			if minetest.registered_nodes[name].walkable then
				table.insert(ch_draconis.walkable_nodes, name)
			end
		end
	end
end)

function ch_draconis.find_value_in_table(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

local function all_first_to_upper(str)
	str = string.gsub(" "..str, "%W%l", string.upper):sub(2)
	return str
end

local function underscore_to_space(str)
	return (str:gsub("_", " "))
end

function ch_draconis.string_format(str)
	if str then
		if str:match(":") then
			str = str:split(":")[2]
		end
		str = all_first_to_upper(str)
		str = underscore_to_space(str)
		return str
	end
end

local path = minetest.get_modpath("ch_draconis")

dofile(path.."/api/api.lua")
dofile(path.."/api/hq_lq.lua")
dofile(path.."/mobs/purple_dragon.lua")
dofile(path.."/mobs/blue_dragon.lua")
dofile(path.."/mobs/black_dragon.lua")

-- Delete old Dragons

minetest.register_entity(":c_dragons:blue_dragon", {
	hp_max = 1,
	physical = false,
	is_visible = false,
	static_save = false,
	on_activate = function(self, staticdata, dtime_s)
		ch_draconis.dragon = nil
	end,
	on_step = function(self, dtime, moveresult)
		ch_draconis.dragon = nil
		self.object:remove()
	end,
	on_deactivate = function(self)
		ch_draconis.dragon = nil
	end
})

minetest.register_entity(":c_dragons:purple_dragon", {
	hp_max = 1,
	physical = false,
	is_visible = false,
	static_save = false,
	on_activate = function(self, staticdata, dtime_s)
		ch_draconis.dragon = nil
	end,
	on_step = function(self, dtime, moveresult)
		ch_draconis.dragon = nil
		self.object:remove()
	end,
	on_deactivate = function(self)
		ch_draconis.dragon = nil
	end
})

minetest.register_entity(":c_dragons:black_dragon", {
	hp_max = 1,
	physical = false,
	is_visible = false,
	static_save = false,
	on_activate = function(self, staticdata, dtime_s)
		ch_draconis.dragon = nil
	end,
	on_step = function(self, dtime, moveresult)
		ch_draconis.dragon = nil
		self.object:remove()
	end,
	on_deactivate = function(self)
		ch_draconis.dragon = nil
	end
})


minetest.log("action", "[MOD] Colourhop Draconis v1.0 loaded")


