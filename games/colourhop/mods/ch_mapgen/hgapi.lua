-- LUALOCALS < ---------------------------------------------------------
local minetest, rawset
	= minetest, rawset
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local hgapi = {}
rawset(_G, modname, hgapi)
