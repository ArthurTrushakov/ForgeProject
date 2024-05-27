glitch_ambience = {}

local MUSIC_GAIN = tonumber(minetest.settings:get("glitch_music_gain")) or 0.1

local ambiences = {
	-- No sound (default)
	silence = {},
	white_noise = {
		soundspec = { name = "glitch_ambience_pink_noise", gain = 0.1 },  -- Pink noise is more tolerable than white noise due to reduced high-frequency content
	},
	music_we_can_do_it = {
		soundspec = { name = "glitch_ambience_visager_we_can_do_it_loop", gain = MUSIC_GAIN },
	},
	music_eerie_mausoleum = {
		soundspec = { name = "glitch_ambience_visager_eerie_mausoleum_loop", gain = MUSIC_GAIN },
	},
	music_welcome_player = {
		soundspec = { name = "glitch_ambience_visager_welcome_player_loop", gain = MUSIC_GAIN },
	},
	music_plateau_at_night= {
		soundspec = { name = "glitch_ambience_visager_plateau_at_night_loop", gain = MUSIC_GAIN },
	},

}

local state = {}

glitch_ambience.set_ambience = function(player, ambience)
	local name = player:get_player_name()
	if not state[name] then
		state[name] = { volume = 1 }
	end
	-- We're already playing this ambience!
	if state[name].ambience_id == ambience then
		return
	end
	state[name].ambience_id = ambience
	if state[name].sound_id then
		minetest.sound_stop(state[name].sound_id)
	end
	if ambiences[ambience].soundspec then
		local soundspec = table.copy(ambiences[ambience].soundspec)
		soundspec.gain = soundspec.gain or 1
		soundspec.gain = soundspec.gain * state[name].volume
		local id = minetest.sound_play(ambiences[ambience].soundspec, {to_player=name, loop=true})
		state[name].sound_id = id
	end
	state[name].ambience = ambience
	minetest.log("action", "[glitch_ambience] Ambience of "..name.." set to '"..ambience.."'")
end

glitch_ambience.set_ambience_volume = function(player, fade, volume)
	local name = player:get_player_name()
	state[name].volume = volume
	local amb = ambiences[state[name].ambience_id]
	if amb.soundspec and state[name].sound_id then
		minetest.sound_fade(state[name].sound_id, fade, volume * (amb.soundspec.gain or 1))
	end

end

minetest.register_on_joinplayer(function(player)
	glitch_ambience.set_ambience(player, "silence")
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	state[name] = nil
end)
