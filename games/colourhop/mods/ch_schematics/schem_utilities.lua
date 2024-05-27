
local schemkeys = {
	["."] = {name = "air", prob = 0},
	["#"] = {name = "world:black"},
	["*"] = {name = "air"},
	r = {name = "buildings:red"},
	g = {name = "buildings:green"},
	b = {name = "buildings:blue"},
	y = {name = "buildings:yellow"},
	p = {name = "buildings:purple"},
	k = {name = "buildings:black"},

}

ch_schematics.utilities = {}
ch_schematics.utility_defs = {}
ch_schematics.utility_cores = {}

local return_point, return_point_size, return_point_def = ch_schematics.ezschematic(schemkeys,
	{
		{
			"..y..",
			".yyy.",
			"yyyyy",
			".yyy.",
			"..y..",
		},
		{
			"*****",
			"*****",
			"**p**",
			"*****",
			"*****",
		},
		{
			"*****",
			"*****",
			"**p**",
			"*****",
			"*****",
		},
		{
			"*****",
			"*****",
			"**g**",
			"*****",
			"*****",
		},
	})
ch_schematics.utilities[#ch_schematics.utilities + 1] = {schem = return_point, size = return_point_size}
ch_schematics.utility_defs[#ch_schematics.utility_defs + 1] = return_point_def
ch_schematics.utility_cores[#ch_schematics.utility_cores + 1] = {x=2, y=3, z=2}


local snapshot_point, snapshot_point_size, snapshot_point_def = ch_schematics.ezschematic(schemkeys,
	{
		{
			".*.",
			"*p*",
			".*.",
		},
		{
			".b.",
			"bgb",
			".b.",
		},
		{
			".p.",
			"pgp",
			".p.",
		},
		{
			"***",
			"*g*",
			"***",
		},
	})
ch_schematics.utilities[#ch_schematics.utilities + 1] = {schem = snapshot_point, size = snapshot_point_size}
ch_schematics.utility_defs[#ch_schematics.utility_defs + 1] = snapshot_point_def
ch_schematics.utility_cores[#ch_schematics.utility_cores + 1] = {x=1, y=3, z=1}

local storage_point, storage_point_size, storage_point_def = ch_schematics.ezschematic(schemkeys,
	{
		{
			"yyryyyryy",
			"ybbbbbbby",
			"rbyybyybr",
			"ybybbbyby",
			"ybbbgbbby",
			"ybybbbyby",
			"rbyybyybr",
			"ybbbbbbby",
			"yyryyyryy",
		},
		{
			"*********",
			"***b*b***",
			"*********",
			"*b*****b*",
			"****g****",
			"*b*****b*",
			"*********",
			"***b*b***",
			"*********",
		},
	})
ch_schematics.utilities[#ch_schematics.utilities + 1] = {schem = storage_point, size = storage_point_size}
ch_schematics.utility_defs[#ch_schematics.utility_defs + 1] = storage_point_def
ch_schematics.utility_cores[#ch_schematics.utility_cores + 1] = {x=4, y=1, z=4}

local exit_point, exit_point_size, exit_point_def = ch_schematics.ezschematic(schemkeys,
	{
		{
			".b.",
			"bgb",
			".b.",
		},
		{
			".*.",
			"*g*",
			".*.",
		},
	})
ch_schematics.utilities[#ch_schematics.utilities + 1] = {schem = exit_point, size = exit_point_size}
ch_schematics.utility_defs[#ch_schematics.utility_defs + 1] = exit_point_def
ch_schematics.utility_cores[#ch_schematics.utility_cores + 1] = {x=1, y=1, z=1}

local lab_area = {
	"*********",
	"*.......*",
	"*.......*",
	"*.......*",
	"*.......*",
	"*.......*",
	"*.......*",
	"*.......*",
	"*********"
}

local automaton_lab, automaton_lab_size, automaton_lab_def = ch_schematics.ezschematic(schemkeys,
	{
		{
			"pyyyyyyyp",
			"y#######y",
			"y#######y",
			"y###g###y",
			"y##ggg##y",
			"y###g###y",
			"y#######y",
			"y#######y",
			"pyyyyyyyp",
		},
		lab_area, lab_area, lab_area,
		lab_area, lab_area, lab_area,
		lab_area, lab_area
	})
ch_schematics.utilities[#ch_schematics.utilities + 1] = {schem = automaton_lab, size = automaton_lab_size}
ch_schematics.utility_defs[#ch_schematics.utility_defs + 1] = automaton_lab_def
ch_schematics.utility_cores[#ch_schematics.utility_cores + 1] = {x=4, y=0, z=0}

