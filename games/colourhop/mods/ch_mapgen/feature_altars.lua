-- LUALOCALS < ---------------------------------------------------------
local math, minetest, ch_schematics
	= math, minetest, ch_schematics
local math_ceil
	= math.ceil
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local hgapi = _G[modname]

local cityheight = hgapi.cityheight
hgapi.register_mapgen_shared({
		label = "generate altars",
		priority = -200,
		ymin = 8,
		ymax = 18,
		func = function(minp, maxp, vm, rng)
			for _ = 1, (maxp.x - minp.x) * (maxp.z - minp.z) / 200 do
				local x = rng(minp.x, maxp.x - 2)
				local z = rng(minp.z, maxp.z - 2)
				x = math_ceil(x / 2) * 2 + 1
				z = math_ceil(z / 2) * 2 + 1
				if cityheight({x = x, y = z}) > rng(4, 10) then
					local picked = ch_schematics.altars[rng(1, #ch_schematics.altars)]
					if picked.size.x % 4 == 1 then x = x + 1 end
					if picked.size.z % 4 == 1 then z = z + 1 end
					if maxp.x - x >= picked.size.x
					and maxp.z - z >= picked.size.z then
						minetest.place_schematic_on_vmanip(vm,
							{x = x, y = 8, z = z}, picked.schem,
							nil, nil, true)
						return
					end
				end
			end
		end
	})
