
ch_music = {}

-- List of songs for the start of each phase of the day,
-- each entry has equal probability.
ch_music.songs = {
	sunrise = {
		"www.mathewpablo.com_caketown1"
	},
	sundown = {
		"www.mathewpablo.com_snowland"
	},
	night = {
	"cynicmusic_crystal_cave_song18",
		"cynicmusic_crystal_cave_song18",
		"cynicmusic_crystal_cave_song18",
		"pauliuw_the_field_of_dreams",
		"pauliuw_the_field_of_dreams",
	}
}

ch_music.playing = {}

local m = minetest.get_modpath("ch_music")

dofile(m .. "/globalstep.lua")
