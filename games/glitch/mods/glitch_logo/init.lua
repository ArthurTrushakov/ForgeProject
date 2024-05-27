glitch_logo = {}

local L1 = "glitch_logo_logo.png"
local L2 = "glitch_logo_scuffed_1.png"
local L3 = "glitch_logo_scuffed_2.png"
local S1 = "glitch_logo_sound"
local S2 = "glitch_sounds_glitched"

local iv = 0.343/2
local GLITCH_REPEAT = 11

local LOGO_TIMES =	{  3,  0.5 }
local LOGO_PHASES =	{ L1, L2 }
local LOGO_SOUNDS =	{ S1, S2 }
for i=1, GLITCH_REPEAT do
	if i % 2 == 0 and i ~= GLITCH_REPEAT then
		table.insert(LOGO_TIMES, iv)
		table.insert(LOGO_PHASES, L3)
	else
		table.insert(LOGO_TIMES, iv+0.05)
		table.insert(LOGO_PHASES, L2)
	end
	if i == GLITCH_REPEAT then
		table.insert(LOGO_SOUNDS, -1)
	else
		table.insert(LOGO_SOUNDS, false)
	end
end

table.insert(LOGO_TIMES, 2)

local sequence_number = 0
local ids = {}
local snd_ids = {}

-- Show game logo to player
-- * player: Player object
-- * after_callback(): Called when logo display is complete
glitch_logo.show_logo = function(player, after_callback)
	local name = player:get_player_name()
	if ids[name] then
		player:hud_remove(ids[name])
		ids[name] = nil
	end
	if snd_ids[name] then
		minetest.sound_stop(snd_ids[name])
		snd_ids[name] = nil
	end

	-- regular logo
	ids[name] = player:hud_add({
		hud_elem_type = "image",
		position = { x=0.5, y= 0.3 },
		scale = { x=8, y=8 },
		z_index = 150,
		text = "glitch_logo_logo.png",
		alignment = { x=0, y=0 },
	})
	-- regular jingle
	minetest.sound_play({name=LOGO_SOUNDS[1], gain=0.7}, {to_player=name}, true)


	-- Show scuffed logo, play scuffed jingle
	local next_phase
	next_phase = function(param)
		if param.seq ~= sequence_number then
			return
		end
		if not param.player:is_player() then
			return
		end
		local pname = param.player:get_player_name()
		if param.phase > #LOGO_PHASES then
			-- Logo display complete
			param.player:hud_remove(param.id)
			ids[pname] = nil
			if snd_ids[pname] then
				minetest.sound_stop(snd_ids[pname])
				snd_ids[pname] = nil
			end
			if after_callback then
				after_callback()
			end
			return
		else
			param.player:hud_change(param.id, "text", LOGO_PHASES[param.phase])
		end
		if LOGO_SOUNDS[param.phase] and LOGO_SOUNDS[param.phase] ~= -1 then
			local snd_id = minetest.sound_play({name=LOGO_SOUNDS[param.phase], gain=0.7}, {to_player=pname})
			snd_ids[pname] = snd_id
			param.snd = snd_id
		elseif LOGO_SOUNDS[param.phase] == -1 and snd_ids[pname] then
			minetest.sound_stop(snd_ids[pname])
			snd_ids[pname] = nil
		end

		param.phase = param.phase + 1
		minetest.after(LOGO_TIMES[param.phase], next_phase, param)
	end
	sequence_number = sequence_number + 1
	minetest.after(LOGO_TIMES[1], next_phase, {player=player, seq=sequence_number, id=ids[name], phase=2})
end

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	ids[name] = nil
	snd_ids[name] = nil
end)
