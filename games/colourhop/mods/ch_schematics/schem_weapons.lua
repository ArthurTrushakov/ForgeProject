-- LUALOCALS < ---------------------------------------------------------
local math, minetest, pairs
	= math, minetest, pairs
local math_ceil
	= math.ceil
-- LUALOCALS > ---------------------------------------------------------

local schemkeys = {
	["."] = {name = "air", prob = 0},
	["#"] = {name = "world:black"},
	["*"] = {name = "air"},
	r = {name = "world:red"},
	g = {name = "world:green"},
	b = {name = "world:blue"},
	y = {name = "world:yellow"},
	p = {name = "world:purple"},
}

local base = {".g.", "grg", ".g."}
local red = {".*.", "*r*", ".*."}
local blue = {".*.", "*b*", ".*."}
local top = {".*.", "*y*", ".*."}
local clear = {"...", ".*.", "..."}

local fireworks = {{}, {red}, {blue}}
local fw_defs = {}
for k, v in pairs(fireworks) do
	local slices = {base}
	for i = 1, #v do slices[#slices + 1] = v[i] end
	slices[#slices + 1] = top
	for _ = 1, 10 do slices[#slices + 1] = clear end
	local schem, size, def = ch_schematics.ezschematic(schemkeys, slices)
	fireworks[k] = {schem = schem, size = size}
	fw_defs[k] = def
end

local ionbase = {
	"....###....",
	".####g####.",
	".#yyybyyy#.",
	".#ybbbbby#.",
	"##yb#b#by##",
	"#gbbbrbbbg#",
	"##yb#b#by##",
	".#ybbbbby#.",
	".#yyybyyy#.",
	".####g####.",
	"....###....",
}
local iontower = {
	"....***....",
	".*********.",
	".*********.",
	".*********.",
	"***********",
	"*****p*****",
	"***********",
	".*********.",
	".*********.",
	".*********.",
	"....***....",
}
local ionclear = {
	"....***....",
	".*********.",
	".*********.",
	".*********.",
	"***********",
	"***********",
	"***********",
	".*********.",
	".*********.",
	".*********.",
	"....***....",
}
local ionschem, ionsize, iondef = ch_schematics.ezschematic(schemkeys, {
		ionbase,
		iontower,
		iontower,
		iontower,
		ionclear, ionclear, ionclear, ionclear,
		ionclear, ionclear, ionclear, ionclear,
		ionclear, ionclear, ionclear, ionclear,
	})
fireworks[4] = {schem = ionschem, size = ionsize}

ch_schematics.weapons = {
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	2, 2, 2, 2, 2, 2, 2,
	3, 3, 3,
	4,
}

for i = 1, #ch_schematics.weapons do
	ch_schematics.weapons[i] = fireworks[ch_schematics.weapons[i]]
end

ch_schematics.weapon_defs = {fw_defs[1], fw_defs[2], fw_defs[3], iondef}
