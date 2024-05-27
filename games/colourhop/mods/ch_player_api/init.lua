
dofile(minetest.get_modpath("ch_player_api") .. "/api.lua")

ch_player_api.register_model("red.b3d", {
	animation_speed = 30,
	textures = {"player_red.png", "player_eyes.png"},
	animations = {
		stand     = {x = 0,   y = 48},
		walk      = {x = 55, y = 85},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.05,
})

ch_player_api.register_model("green.b3d", {
	animation_speed = 30,
	textures = {"player_green.png", "player_eyes.png"},
	animations = {
		stand     = {x = 0,   y = 48},
		walk      = {x = 55, y = 85},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.05,
})

ch_player_api.register_model("yellow.b3d", {
	animation_speed = 30,
	textures = {"player_yellow.png", "player_eyes.png", "player_bowtie.png"},
	animations = {
		stand     = {x = 0,   y = 48},
		walk      = {x = 55, y = 85},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.15,
})

ch_player_api.register_model("blue.b3d", {
	animation_speed = 30,
	textures = {"player_blue.png", "player_eyes.png"},
	animations = {
		stand     = {x = 0,   y = 48},
		walk      = {x = 55, y = 85},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.15,
})

ch_player_api.register_model("purple.b3d", {
	animation_speed = 30,
	textures = {"player_purple.png", "player_eyes.png"},
	animations = {
		stand     = {x = 0,   y = 48},
		walk      = {x = 55, y = 85},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 0.98,
})

ch_player_api.register_model("black.b3d", {
	animation_speed = 30,
	textures = {"player_black.png", "player_eyes.png"},
	animations = {
		stand     = {x = 0,   y = 48},
		walk      = {x = 55, y = 85},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.03,
})

local invformset = {}
minetest.register_on_leaveplayer(function(player) invformset[player:get_player_name()] = nil end)

local function setinvspec(player, shownow)
	-- there is no inventory, but we might use it later for instructions / tasks
	local colours = ch_player_api.get_colours(player)
	local nowal_defeated = colours.black
	local royal_blob_defeated = (player:get_meta():get_int("defeated_rb") == 1)
	local content = {
		"Message from the Royal Blob:",
		"\nThe three terrible dragons have ravaged this land and stolen its colours!",
		"\nYou are an invincible blob, that can change colour and paint by jumping.",
		"\n\nBuild dragon altars, activate them, and wait for midnight.",
		"Gain new colours by defeating the dragons.",
		"\nLook for clues in the ruins. Learn from them, experiment.",
		"\n\nPlease bring colour back to the world.",
	}
	if nowal_defeated and royal_blob_defeated then
		content = {
			"You have taken fate into your hands and defeated your rivals.",
			"\nThe world is yours, what will you do next?",
			"\n\nPerhaps make a mod to add more content?",
		}
	elseif royal_blob_defeated then
		content = {
			"The black dragon still spreads it's wings in the midnight sky.",
			"\nWill you be the one to defeat it?",
		}
	elseif nowal_defeated then
		content = {
			"Message from the late Nowal:",
			"\nWho came first, the blobs or the dragons?",
			"\nWhy do you serve the Royal Blob?",
			"\nSeek them out in their lair under the storage rooms.",
		}
	end
	content[#content+1] = "\n\n\nhttps://content.minetest.net/packages/talas/colourhop/"
	content[#content+1] = "\nhttps://gitlab.com/talas777/colourhop/"
	local nomusic = player:get_meta():get_int("nomusic")
	nomusic = nomusic and nomusic ~= 0 and 1 or 0
	local invform = {
		"size[15,8]",
		"bgcolor[#000000C0;true]",
		"listcolors[#00000000;#00000000;#00000000;#000000FF;#FFFFFFFF]",
		"textarea[0.25,0.25;15,7.25;;;",
		table.concat(content, " "),
		"]",
		"image_button[14.25,7.25;0.75,0.75;ch_player_api_nomusic_",
		nomusic,
		".png^[opacity:128;togglemusic;;;false]"
	}
	invform = table.concat(invform)
	if invformset[player:get_player_name()] == invform then return end
	invformset[player:get_player_name()] = invform
	player:set_inventory_formspec(invform)
	if shownow then minetest.show_formspec(player:get_player_name(), "", invform) end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" or not fields.togglemusic then return end
	local meta = player:get_meta()
	local val = meta:get_int("nomusic")
	val = val and val ~= 0 and 0 or 1
	meta:set_int("nomusic", val)
	if ch_music and val ~= 0 then
		local playing = ch_music.playing[player:get_player_name()]
		if playing then minetest.sound_fade(playing, 1, 0) end
	end
	return setinvspec(player, true)
end)

minetest.register_globalstep(function()
	for _, player in ipairs(minetest.get_connected_players()) do
		setinvspec(player)
	end
end)

-- Update appearance when the player joins
minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	local col = meta:get_int("colour")
	if col < ch_colours.red then
		col = ch_colours.red
		meta:set_int("colour", col)
	end
	local colourname = ch_colours.colour_name(col)

	-- Migrate old players to new system
	local old_col = meta:get_int("max_col")
	if old_col ~= 0 then
		local colours = ch_player_api.get_colours(player)
		if old_col >= 4 then
			colours.blue = true
		end
		if old_col >= 5 then
			colours.purple = true
		end
		if old_col >= 6 then
			colours.black = true
		end
		meta:set_string("max_col", nil)
		meta:set_string("colours", minetest.serialize(colours))
	end

	-- just in case it got stuck..
	meta:set_int("teleclimbing", 0)

	-- we use the hotbar to display your current color
	player:hud_set_flags({hotbar = true, wielditem = false, crosshair = false, healthbar = false, breathbar = false})
	player:hud_set_hotbar_itemcount(1)
	player:hud_set_hotbar_selected_image("ch_player_api_blank.png")

	-- try to make player invulnerable
	player:set_armor_groups({immortal=1, fall_damage_add_percent=-100})

	ch_player_api.set_colour(player, colourname)

	setinvspec(player)
end)
