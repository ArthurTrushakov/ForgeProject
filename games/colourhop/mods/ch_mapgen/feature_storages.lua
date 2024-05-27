-- LUALOCALS < ---------------------------------------------------------
local minetest, ch_schematics = minetest, ch_schematics
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local hgapi = _G[modname]

local clear15 = { }
for i = 1, 15 do clear15[i] = "***************" end

local function myschem(botlayer, override)
	local schemkeys = {
		["."] = {name = "air", prob = 0},
		["#"] = {name = "world:black"},
		["o"] = {name = "world:yellow"},
		["+"] = {name = "world:blue"},
		["*"] = {name = "world:ambient"},
		r = {name = "buildings:red"},
		g = {name = "buildings:green"},
		b = {name = "buildings:blue"},
		y = {name = "buildings:yellow"},
		p = {name = "buildings:purple"},
		k = {name = "buildings:black"},
		["1"] = {name = "world:yellow"},
		["2"] = {name = "world:yellow"},
		["3"] = {name = "world:yellow"},
		["4"] = {name = "world:yellow"},
	}
	for k, v in pairs(override or {}) do schemkeys[k] = v end
	local layers = {botlayer}
	for _ = 1, 14 do layers[#layers + 1] = clear15 end
	return ch_schematics.ezschematic(schemkeys, layers)
end

local dark = myschem()

local access = myschem({
		"###############",
		"###############",
		"##ooooooooooo##",
		"##o#########o##",
		"##o#########o##",
		"##o##ooooo##o##",
		"##o##o***o##o##",
		"##o##o***o##o##",
		"##o##o***o##o##",
		"##o##ooooo##o##",
		"##o#########o##",
		"##o#########o##",
		"##ooooooooooo##",
		"###############",
		"###############",
	})

local roomfloor = {
	"###############",
	"###############",
	"##ooooooooooo##",
	"##o#########o##",
	"##o#########o##",
	"##o##oo4oo##o##",
	"##o##o#b#o##o##",
	"##o##2bgb1##o##",
	"##o##o#b#o##o##",
	"##o##oo3oo##o##",
	"##o#########o##",
	"##o#########o##",
	"##ooooooooooo##",
	"###############",
	"###############",
}
local room = myschem(roomfloor)
local roome = myschem(roomfloor, {["1"] = {name = "world:black"}})
local roomw = myschem(roomfloor, {["2"] = {name = "world:black"}})
local rooms = myschem(roomfloor, {["3"] = {name = "world:black"}})
local roomn = myschem(roomfloor, {["4"] = {name = "world:black"}})

local chutelayers = {
	{
		"***",
		"***",
		"***"
	}
}
for i = 2, 100 do chutelayers[i] = chutelayers[1] end
local chute = ch_schematics.ezschematic({
		["*"] = {name = "world:ambient"},
	}, chutelayers)

local storage_ymin = -3015
local storage_ymax = -3000

hgapi.register_mapgen_shared({
		label = "generate storages",
		ymin = storage_ymin,
		ymax = storage_ymax,
		func = function(minp, maxp, vm)
			local maxa = {x=maxp.x+1, y=maxp.y+1, z=maxp.z+1}
			for x = minp.x, maxa.x, 16 do
				for z = minp.z, maxa.z, 16 do
					local xd = (x / 16) % 9
					local zd = (z / 16) % 9
					if xd == 4 and zd == 4 then
						minetest.place_schematic_on_vmanip(vm,
							{x = x, y = storage_ymin, z = z}, access, nil, nil, true)
					elseif xd == 3 and (zd >= 3 and zd <= 5) then
						minetest.place_schematic_on_vmanip(vm,
							{x = x, y = storage_ymin+1, z = z}, dark, nil, nil, true)
					elseif xd == 4 and (zd == 3 or zd == 5) then
						minetest.place_schematic_on_vmanip(vm,
							{x = x, y = storage_ymin+1, z = z}, dark, nil, nil, true)
					elseif xd == 5 and (zd >= 3 and zd <= 5) then
						minetest.place_schematic_on_vmanip(vm,
							{x = x, y = storage_ymin+1, z = z}, dark, nil, nil, true)
					else
						if xd == 0 or (xd == 1 and zd > 0 and zd < 8) then
							minetest.place_schematic_on_vmanip(vm,
							{x = x, y = storage_ymin, z = z},
							roome, nil, nil, true)
						elseif xd == 8 or (xd == 7 and zd > 0 and zd < 8) then
							minetest.place_schematic_on_vmanip(vm,
							{x = x, y = storage_ymin, z = z},
							roomw, nil, nil, true)
						elseif (zd == 0 and xd ~= 0 and xd ~= 8) or (zd == 1 and xd > 1 and xd < 7) then
							minetest.place_schematic_on_vmanip(vm,
							{x = x, y = storage_ymin, z = z},
							rooms, nil, nil, true)
						elseif (zd == 8 and xd ~= 0 and xd ~= 8) or (zd == 7 and xd > 1 and xd < 7) then
							minetest.place_schematic_on_vmanip(vm,
							{x = x, y = storage_ymin, z = z},
							roomn, nil, nil, true)
						else
							minetest.place_schematic_on_vmanip(vm,
							{x = x, y = storage_ymin, z = z},
							room, nil, nil, true)
						end
					end
				end
			end
		end
	})

hgapi.register_mapgen_shared({
		label = "generate storage access chutes",
		ymin = storage_ymin - 100,
		ymax = storage_ymin,
		func = function(minp, maxp, vm, _, _, _)
			local maxa = {x=maxp.x+1, y=maxp.y+1, z=maxp.z+1}
			for x = minp.x, maxa.x, 16 do
				for z = minp.z, maxa.z, 16 do
					local xd = (x / 16) % 9
					local zd = (z / 16) % 9
					if xd == 4 and zd == 4 then
						minetest.place_schematic_on_vmanip(vm,
						{x = x + 6, y = storage_ymin - 100, z = z + 6},
						chute, nil, nil, true)
					end
				end
			end
		end
	})
