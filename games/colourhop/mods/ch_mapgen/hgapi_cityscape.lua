-- LUALOCALS < ---------------------------------------------------------
local minetest
	= minetest
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local hgapi = _G[modname]

local octaves = 5
local persist = 0.9
local citydensity
minetest.after(0, function()
		citydensity = minetest.get_perlin({
				seeddiff = 64364,
				octaves = 5,
				persistence = 0.8,
				spread = {x = 64, y = 64, z = 64}
			})
	end)
local citymax = (1 + persist / 2) ^ (octaves - 1)
local function cityheight(pos)
	local d = citydensity:get_2d(pos) / citymax * 40 - 10
	if d < 0 then return 0 end
	local dsqr = pos.x * pos.x + pos.y * pos.y
	if dsqr < 400 then return 0 end
	if dsqr < 800 then d = d * (dsqr - 400) / 400 end
	if d > 10 then return 10 end
	return d
end
hgapi.cityheight = cityheight
