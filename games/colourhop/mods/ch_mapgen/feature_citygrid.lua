-- LUALOCALS < ---------------------------------------------------------
local math, minetest
	= math, minetest
local math_ceil
	= math.ceil
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local hgapi = _G[modname]

local cityheight = hgapi.cityheight

local spires = {}
do
	local schemkey = {k = {name = "world:black"}}
	local layer = {"k"}
	for i = 1, 10 do
		local layers = {}
		for j = 1, i do layers[j] = layer end
		spires[i] = ch_schematics.ezschematic(schemkey, layers)
	end
end

hgapi.register_mapgen_shared({
		label = "generate cityscape",
		ymin = 8,
		ymax = 18,
		func = function(minp, maxp, vm, rng)
			local minz = math_ceil(minp.z / 2) * 2
			local minx = math_ceil(minp.x / 2) * 2
			for z = minz, maxp.z, 2 do
				local pos = {y = z}
				for x = minx, maxp.x, 2 do
					pos.x = x
					local d = cityheight(pos)
					d = rng(0, d)
					if d > 0 then
						minetest.place_schematic_on_vmanip(vm,
							{x = x, y = 9, z = z}, spires[d],
							nil, nil, true)
					end
				end
			end
		end
	})
