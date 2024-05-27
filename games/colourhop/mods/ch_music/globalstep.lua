local minetest = minetest

local lastphase
local cooldown = math.random(0, 1200)

local function handle_mus(dtime)
	cooldown = cooldown - dtime

	-- Figure out what phase of the day it is.
	local tod = minetest.get_timeofday()
	local phase
	if tod >= 0.7746 then phase = "night"
	elseif tod >= 0.75 then phase = "sundown"
	elseif tod >= 0.5 then phase = "midday"
	elseif tod >= 0.3 then phase = "day"
	elseif tod >= 0.1917 then phase = "sunrise"
	else phase = "midnight"
	end

	-- Only continue to play song if the phase
	-- of day is changing.
	do
		local old = lastphase
		lastphase = phase

		-- Special case: do not play a song when the
		-- game first starts; wait for first transition.
		if not old then return end

		if phase == old then return end
	end

	-- Does this phase have any music set?
	local playlist = ch_music.songs[phase]
	if not playlist then
		return
	end

	-- Force a minimum cooldown between songs so players
	-- are not overwhelmed with music.
	if cooldown > 0 then return end
	cooldown = math.random(600, 1800)

	-- Play a random song based on phase of day for all
	-- music-enabled players.
	for _, player in ipairs(minetest.get_connected_players()) do
		if player:get_meta():get_int("nomusic") ~= 1 and player:get_pos().y > -3000 then
			local pname = player:get_player_name()
			ch_music.playing[pname] = minetest.sound_play({
				name = playlist[math.random(1, #playlist)],
				to_player = pname,
				gain = 0.9
			})
		end
	end
end

minetest.register_globalstep(handle_mus)
