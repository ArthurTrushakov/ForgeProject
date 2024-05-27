glitch_sounds = {}

function glitch_sounds.node_sound_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name = "", gain = 1.0}
	table.dug = table.dug or
			{name = "glitch_sounds_default_dug", gain = 0.3}
	table.place = table.place or
			{name = "glitch_sounds_default_place", gain = 0.5}
	return table
end

