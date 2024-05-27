-- LUALOCALS < ---------------------------------------------------------
local minetest, ch_schematics = minetest, ch_schematics
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local hgapi = _G[modname]

local str = string.rep("*", 80)
local slice = {}
for i = 1, 80 do slice[i] = str end
local slices = {}
for i = 1, 11 do slices[i] = slice end
local schem = ch_schematics.ezschematic({
	["*"] = {name = "world:ambient"}
}, slices)

local function addlayer(label, ymin, ymax)
	hgapi.register_mapgen_shared({
		label = "generate " .. label,
		ymin = ymin,
		ymax = ymax,
		func = function(minp, maxp, vm)
			for z = minp.z, maxp.z + 79, 80 do
				for x = minp.x, maxp.x + 79, 80 do
					minetest.place_schematic_on_vmanip(vm,
						{x = x, y = ymin, z = z},
						schem, nil, nil, true)
				end
			end
		end
	})
end
addlayer("layer1", -3115, -3105)
addlayer("layer2", -3135, -3125)
