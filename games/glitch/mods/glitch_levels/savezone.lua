local S = minetest.get_translator("glitch_levels")

-- Stay in savezone to save

local hud_ids = {}
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	hud_ids[name] = player:hud_add({
		hud_elem_type = "text",
		position = { x=0.5, y=0.60 },
		scale = { x=100, y=100 },
		size = { x=2, y=2 },
		style = 4,
		offset = { x = 0, y = -24 },
		number = 0x80FF80,
		z_index = 100,
		text = "",
		alignment = { x=0, y=0 },
	})
end)
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	hud_ids[name] = nil
end)

local timer = 0
local texttimer = 0

local SAVETIMER = 0.1 -- check savezone every X seconds
local TEXTTIMER_START = 1 -- time to display "Electrons saved!" message (in seconds),
                          -- after the save zone was left

minetest.register_globalstep(function(dtime)
	if glitch_editor.is_active() then
		return
	end
	timer = timer + dtime
	if texttimer > 0 then
		texttimer = texttimer - dtime
	end
	if timer < SAVETIMER then
		return
	end
	timer = 0

	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local pname = player:get_player_name()
		local pos = player:get_pos()
		if glitch_levels.is_in_savezone(player) then
			local current_level = glitch_levels.get_current_level(player)
			local saved = glitch_entities.save_electrons(player)
			if saved then
				minetest.sound_play({name="glitch_levels_save", gain=1}, {object=player}, true)
				minetest.log("action", "[glitch_levels] "..pname.." uses savezone")
				player:hud_change(hud_ids[pname], "text", S("Electrons saved!"))
				texttimer = TEXTTIMER_START
			end
			glitch_entities.show_electron_gui(player)
		else
			if texttimer <= 0 then
				player:hud_change(hud_ids[pname], "text", "")
			end
		end
	end
end)
