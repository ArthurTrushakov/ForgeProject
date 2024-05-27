-- LUALOCALS < ---------------------------------------------------------
local dofile, ipairs, minetest
	= dofile, ipairs, minetest
-- LUALOCALS > ---------------------------------------------------------

local includes = {
	"hgapi",
	"hgapi_mapgen",
	"hgapi_cityscape",
	"feature_citygrid",
	"feature_weapons",
	"feature_altars",
	"feature_storages",
	"feature_layers",
	"feature_royal",
	"convert_ambient",
}

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
for _, n in ipairs(includes) do
	dofile(modpath .. "/" .. n .. ".lua")
end
