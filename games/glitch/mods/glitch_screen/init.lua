local S = minetest.get_translator("glitch_screen")

glitch_screen = {}

local huds = {}
local huds_text = {}
local sounds = {}
local multiscreen = {}

-- Possible screentypes:
-- * "glitch": glitched screen effect
-- * "glitch_with_sound": glitched screen effect with sound
-- * "end": end screen


-- * player: player to show screen to
-- * screentype: see above
-- * screens: number of screens
-- * screentime: time per screen in seconds
-- * after_callback: (optional) function is called when the last screen was shown
-- * after_callback_param: this parameter is passed to after_callback
glitch_screen.show_screen_multi = function(player, screentype, screens, screentime, after_callback, after_callback_param)
	local name = player:get_player_name()
	if screens <= 0 then
		return
	end
	glitch_screen.show_screen(player, screentype, true)

	screens = screens - 1
	multiscreen[name] = { screentype = screentype, screentime = screentime, screens = screens, current_timer = screentime, after_callback = after_callback, after_callback_param = after_callback_param }
end

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local name = player:get_player_name()
		if multiscreen[name] then
			multiscreen[name].current_timer = multiscreen[name].current_timer - dtime
			if multiscreen[name].current_timer <= 0 then
				if multiscreen[name].screens <= 0 then
					if multiscreen[name].after_callback then
						multiscreen[name].after_callback(multiscreen[name].after_callback_param)
					end
					multiscreen[name] = nil
					glitch_screen.remove_screen(player)
				else
					glitch_screen.show_screen(player, multiscreen[name].screentype, true)
					multiscreen[name].current_timer = multiscreen[name].screentime
					multiscreen[name].screens = multiscreen[name].screens - 1
				end
			end
		end
	end
end)

glitch_screen.show_screen = function(player, screentype, is_multiscreen)
	if not screentype == "glitch" and not screentype == "glitch_with_sound" and not screentype == "end" then
		error("[glitch_screen] Invalid screentype: "..tostring(screentype))
		return
	end

	local name = player:get_player_name()
	local suffix = ""
	local random_invert = ""
	if screentype ~= "end" then
		local channels = { "r", "g", "b" }
		for c=1, #channels do
			local r = math.random(0,1)
			if r == 1 then
				random_invert = random_invert .. channels[c]
			end
		end
	end
	if random_invert ~= "" then
		suffix = "^[invert:"..random_invert 
	end
	local img
	if screentype == "end" then
		img = "glitch_screen_black.png"
		glitch_utils.set_is_in_end_screen(player, true)
	else
		img = "glitch_screen_screen.png"
		glitch_utils.set_is_in_end_screen(player, false)
	end
	local oldhud = huds[name]
	huds[name] = player:hud_add({
		hud_elem_type = "image",
		alignment = { x = 1, y = 1 },
		scale = { x = -100, y = -100 }, -- fullscreen
		text = img .. suffix,
		z_index = 1000,
	})
	local oldhud_text = huds_text[name]
	if screentype == "end" then
		huds_text[name] = player:hud_add({
			hud_elem_type = "text",
			position = { x = 0.5, y = 0.5 },
			alignment = { x = 0, y = 0 },
			scale = { x = 100, y = 100 },
			size = { x = 10, y = 10 },
			text = S("The End"),
			style = 4, -- mono
			number = 0x00FF00,
			z_index = 1001,
		})
		minetest.sound_play({name="glitch_logo_sound", gain=0.7}, {to_player=name}, true)
	end

	if oldhud then
		player:hud_remove(oldhud)
	end
	if oldhud_text then
		player:hud_remove(oldhud_text)
	end
	if screentype == "glitch_with_sound" then
		if not is_multiscreen or not sounds[name] then
			sounds[name] = minetest.sound_play({name="glitch_sounds_glitched", gain=0.7}, {to_player=name})
		end
	end
	return
end

glitch_screen.remove_screen = function(player)
	local name = player:get_player_name()
	if huds[name] then
		player:hud_remove(huds[name])
		huds[name] = nil
	end
	if huds_text[name] then
		player:hud_remove(huds_text[name])
		huds_text[name] = nil
	end
	if sounds[name] then
		minetest.sound_stop(sounds[name])
		sounds[name] = nil
	end
	multiscreen[name] = nil
	glitch_utils.set_is_in_end_screen(player, false)
end

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	huds[name] = nil
	huds_text[name] = nil
	sounds[name] = nil
end)
