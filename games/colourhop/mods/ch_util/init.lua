-- LUALOCALS < ---------------------------------------------------------
local dofile, ipairs, minetest, rawset
	= dofile, ipairs, minetest, rawset
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()

local myapi = {}
rawset(_G, modname, myapi)

local includes = {
	"playerstep"
}

local modpath = minetest.get_modpath(modname)
for _, n in ipairs(includes) do
	dofile(modpath .. "/" .. n .. ".lua")
end
