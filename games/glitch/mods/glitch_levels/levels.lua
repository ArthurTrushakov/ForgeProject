local S = minetest.get_translator("glitch_levels")

glitch_levels.START_LEVEL = "void"
glitch_levels.START_SPAWN_NO = 3

local last_pos
local POS_CHANGE = 2000
local POS_MAX = 28000
local generate_pos = function()
	if not last_pos then
		last_pos = vector.new(0, 0, 0)
	end
	local pos = vector.new(last_pos.x, last_pos.y, last_pos.z)
	pos.x = pos.x + POS_CHANGE
	if pos.x > POS_MAX then
		pos.x = -POS_MAX
		pos.z = pos.z + POS_CHANGE
		if pos.z > POS_MAX then
			error("[glitch_levels] Level generator ran out of space!")
		end
	end
	last_pos = vector.new(pos.x, pos.y, pos.z)
	return pos
end

local on_spawn_dialog = function(dialogtree_id)
	return function(player)
		local meta = player:get_meta()
		local gotten = meta:get_int("glitch_levels:story|"..dialogtree_id) == 1
		if not gotten then
			glitch_dialog.show_dialogtree(player, dialogtree_id)
			meta:set_int("glitch_levels:story|"..dialogtree_id, 1)
		end
	end
end

-- The first level (must be added first)
glitch_levels.add_level("void", {
	description = S("Void Pipe"),
	pos = generate_pos(),
	spawns = {
		-- gateway
		{ pos = vector.new(27, 52, 13), yaw = math.pi/2, function(player)
			glitch_abilities.add_ability(player, "glitch:slide", false)
		end,},
		-- near Helper
		{ pos = vector.new(4, 53, 4), yaw = math.pi/2, pitch = 0, on_spawn = function(player)
			-- Play the Intro stuff
			glitch_ambience.set_ambience(player, "white_noise")
			minetest.after(4.9, function(player)
				if player and player:is_player() then
					glitch_dialog.show_dialogtree(player, "glitch:after_dump")
					glitch_ambience.set_ambience(player, "silence")
					glitch_abilities.add_ability(player, "glitch:slide", false)
					local meta = player:get_meta()
					meta:set_int("glitch_levels:intro_complete", 1)
				end
			end, player)
			local pos = player:get_pos()
			local offsets = {
				vector.new(0,0,1),
				vector.new(0,0,-1),
				vector.new(-1,0,0),
				vector.new(1,0,0),
				vector.new(0,1,0),
				vector.new(0,-1,0),
			}
			for i=1, #offsets do
				minetest.set_node(vector.add(pos, offsets[i]), {name = "glitch_nodes:white_noise_temp"})
			end
		end},
		-- in the pipe
		{ pos = vector.new(13, 155, 13), pitch = math.pi / 2, gravity = 0.1 },
	},
	schematic = "glitch_levels_void.mts",
	gateways = {
		[0] = { level = "hub", electrons = 8 },
	},
	sky = "glitchworld_gray",
	color_index = 0,
	ambience = "music_eerie_mausoleum",
})

glitch_levels.add_level("playground", {
	description = S("Data Cube Center"),
	pos = generate_pos(),
	spawns = {
		-- gateway
		{ pos = vector.new(19, 31, 16), yaw = (3*math.pi)/2 },
	},
	schematic = "glitch_levels_playground.mts",
	gateways = {
		[0] = "hub",
	},
	sky = "glitchworld_darkgreen",
	color_index = 5,
	ambience = "music_welcome_player",
})

glitch_levels.add_level("powerslide_playground", {
	description = S("Powerslide Playground"),
	pos = generate_pos(),
	spawns = {
		-- bottom of the large ramp
		{ pos = vector.new(49, 1, 20), yaw = math.pi/2 },
	},
	schematic = "glitch_levels_powerslide_playground.mts",
	gateways = {
		[0] = "powerslide_temple",
	},
	sky = "glitchworld_green",
	color_index = 5,
	ambience = "music_welcome_player",
})

glitch_levels.add_level("powerslide_temple", {
	description = S("Powerslide Sector"),
	pos = generate_pos(),
	spawns = {
		-- entrance
		{ pos = vector.new(59, 26, 16), yaw = math.pi/2, on_spawn = on_spawn_dialog("glitch:white_noise_intermission_2") },
	},
	schematic = "glitch_levels_powerslide_temple.mts",
	ability = "glitch:powerslide",
	gateways = {
		-- exit right
		[0] = "hub",
		-- exit left
		[1] = "powerslide_temple",
		-- bottomless pit
		[2] = "powerslide_playground",
	},
	sky = "glitchworld_temple",
	color_index = 6,
	ambience = "music_plateau_at_night",
})

glitch_levels.add_level("pipes", {
	description = S("Transport Pipes"),
	pos = generate_pos(),
	spawns = {
		-- East
		{ pos = vector.new(89, 18, 10), yaw = math.pi/2 },
		-- West
		{ pos = vector.new(11, 18, 11), yaw = (3*math.pi)/2, on_spawn = on_spawn_dialog("glitch:white_noise_intermission_4") },
	},
	schematic = "glitch_levels_pipes.mts",
	gateways = {
		[0] = { level = "climb_temple", electrons = 384 },
		[1] = "hub",
	},
	sky = "glitchworld_gray",
	color_index = 0,
	ambience = "music_eerie_mausoleum",
})

glitch_levels.add_level("tallslope_temple", {
	description = S("Super Slope Sliding Sector"),
	pos = generate_pos(),
	spawns = {
		-- entrance
		{ pos = vector.new(19, 9, 2), yaw = 0, on_spawn = on_spawn_dialog("glitch:white_noise_intermission_3") },
	},
	schematic = "glitch_levels_tallslope_temple.mts",
	ability = "glitch:stepheight",
	gateways = {
		-- exit right
		[0] = "hub",
	},
	sky = "glitchworld_temple",
	color_index = 6,
	ambience = "music_plateau_at_night",
})

glitch_levels.add_level("farlands", {
	description = S("Far Lands"),
	pos = generate_pos(),
	spawns = {
		-- Depths
		{ pos = vector.new(69, 83, 23), yaw = math.pi/2 },
		-- Opening
		{ pos = vector.new(41,138, 23), yaw = math.pi/2 },
	},
	schematic = "glitch_levels_farlands.mts",
	gateways = {
		[0] = "tower", -- at Depths
		[1] = { level = "tallslope_temple", electrons = 32 }, -- at Opening
		[2] = { level = "farlands", spawn_no = 1, electrons = 448 }, -- at the Bottom (returns to start)
	},
	sky = "glitchworld_green",
	color_index = 0,
	ambience = "music_we_can_do_it",
})

-- The chaotic noise level, everything is supposed to appear broken
glitch_levels.add_level("noise", {
	description = "Ì,c VÒð_÷ðý", -- represents a data corruption, thus non-translatable
	pos = generate_pos(),
	spawns = {
		{ pos = vector.new(20, 33, 1), on_spawn = on_spawn_dialog("glitch:white_noise_reveal") }, -- concentric chaos
		{ pos = vector.new(30, 29, 45), on_spawn = function(player)
			-- Lose all abilities on first enter
			local meta = player:get_meta()
			if meta:get_int("glitch_levels:noise_abilities_lost") == 0 then
				glitch_abilities.remove_ability(player, "glitch:powerslide")
				glitch_abilities.remove_ability(player, "glitch:stepheight")
				glitch_abilities.remove_ability(player, "glitch:climb")
				glitch_abilities.remove_ability(player, "glitch:jumppad")
				meta:set_int("glitch_levels:noise_abilities_lost", 1)
				minetest.log("action", "[glitch_levels] Story: Player lost all abilities in noise level")
			end
			local dialog_func = on_spawn_dialog("glitch:white_noise_gateway")
			dialog_func(player)
		end, }, -- jump pads
		{ pos = vector.new(20, 26, 20), on_spawn = on_spawn_dialog("glitch:white_noise_gateway_2") }, -- gateway confusion
		{ pos = vector.new(15, 27, 30) }, -- bridge
		{ pos = vector.new(22, 50, 1) }, -- pipe
	},
	schematic = "glitch_levels_noise.mts",
	gateways = {
		-- concentric chaos exit
		[0] = { level = "noise", spawn_no = 2, electrons = 7 },
		-- jump pads exit
		[1] = { level = "noise", spawn_no = 3, electrons = 127},
		-- gateway confusion exit
		[2] = { level = "noise", spawn_no = 4, electrons = -2147483648}, -- the negative number is intentional
		-- bridge secret
		[3] = { level = "noise", spawn_no = 5, electrons = 1 },
		-- return to start
		[4] = { level = "noise", spawn_no = 1, electrons = 24 },
		-- useless fake gateway (too many electrons)
		[5] = { level = "noise", spawn_no = 1, electrons = 65535},
		-- final exit (secret lamp circle)
		[6] = "hub",
	},
	sky = "gray_noise",
	ambience = "white_noise",
	ability = {
		[1] = "glitch:jumppad",
		[2] = "glitch:stepheight",
		[3] = "glitch:climb",
		[4] = "glitch:powerslide",
	},
	reset_on_fallout = false,
	on_fallout = function(player)
		-- This will complete the game!
		minetest.log("action", "[glitch_levels] Fallout in noise level triggered! Starting outro ...")
		glitch_levels.move_to_level(player, "outro1")
		minetest.sound_play({name="glitch_levels_gateway", gain=1}, {object=player}, true)
	end,
})

-- Hub (level that connects many other levels)
glitch_levels.add_level("hub", {
	description = S("Hub"),
	pos = generate_pos(),
	spawns = {
		{ pos = vector.new(34, 17, 34), pitch = 0, on_spawn = on_spawn_dialog("glitch:white_noise_intermission_1") }, -- center
	},
	schematic = "glitch_levels_hub.mts",
	gateways = {
		[0] = { level = "core", electrons = 512 }, -- N (unused)
		[1] = { level = "tower", electrons = 64 }, -- NE
		[2] = { level = "playground", electrons = 48 }, -- E
		[3] = { level = "powerslide_temple", electrons = 16 }, -- SE
		[4] = { level = "core", electrons = 512 },-- S
		[5] = "void", -- SW
		[6] = { level = "pipes", electrons = 256 }, -- W
		[7] = { level = "tallslope_temple", electrons = 32 },-- NW
	},
	sky = "glitchworld_gray",
	ambience = "music_welcome_player",
})

-- Jump pad tower
glitch_levels.add_level("tower", {
	description = S("Tower"),
	pos = generate_pos(),
	spawns = {
		{ pos = vector.new(3, 27, 16), yaw = (3*math.pi)/2, on_spawn = on_spawn_dialog("glitch:white_noise_intermission_5") },
	},
	schematic = "glitch_levels_tower.mts",
	gateways = {
		[0] = { level = "jumppad_temple", electrons = 128 },
		[1] = { level="farlands", spawn_no = 2, electrons = 384 },
		[2] = "hub",
	},
	sky = "dark",
	color_index = 4,
	ambience = "music_we_can_do_it",
})

-- Jump pad temple
glitch_levels.add_level("jumppad_temple", {
	description = S("Launching Sector"),
	ability = "glitch:jumppad",
	pos = generate_pos(),
	spawns = {
		{ pos = vector.new(16, 20, 4), yaw = 0, },
	},
	schematic = "glitch_levels_jumppad_temple.mts",
	gateways = {
		[0] = "tower",
		[1] = { level = "farlands", electrons = 256 },
	},
	sky = "glitchworld_temple",
	color_index = 6,
	ambience = "music_plateau_at_night",
})

-- Climb Temple
glitch_levels.add_level("climb_temple", {
	description = S("Climbing Sector"),
	ability = "glitch:climb",
	pos = generate_pos(),
	spawns = {
		{ pos = vector.new(60, 19, 15), yaw = math.pi/2},
	},
	schematic = "glitch_levels_climb_temple.mts",
	gateways = {
		[0] = { level = "pipes", spawn_no = 2 },
	},
	sky = "glitchworld_temple",
	color_index = 6,
	ambience = "music_plateau_at_night",
})

-- System Core
glitch_levels.add_level("core", {
	description = S("System Core"),
	pos = generate_pos(),
	spawns = {
		{ pos = vector.new(10, 6, 124), yaw = math.pi, on_spawn = on_spawn_dialog("glitch:white_noise_intermission_6") },
	},
	schematic = "glitch_levels_core.mts",
	gateways = {
		[0] = { level = "hub" },
		[1] = { level = "noise", electrons = 512 },
	},
	sky = "dark",
	color_index = 1,
	ambience = "music_eerie_mausoleum",
})

-- Special outro levels for the game ending
-- Encountering the System
glitch_levels.add_level("outro1", {
	description = S("The System"),
	pos = generate_pos(),
	spawns = {
		{
			pos = vector.new(7, 10, 7),
			pitch = 0,
			on_spawn = function(player)
				minetest.after(2, function()
					if player and player:is_player() then
						glitch_dialog.show_dialogtree(player, "glitch:outro")
					end
				end)
			end,
		},
	},
	schematic = "glitch_levels_outro_system.mts",
	gateways = {},
	sky = "dark",
	ambience = "music_eerie_mausoleum",
})
-- After player is teleported by the System (white noise again)
glitch_levels.add_level("outro2", {
	description = "3é‚<~;YàµQ3“'}", -- represents a data corruption, thus non-translatable
	pos = generate_pos(),
	spawns = {
		{
			pos = vector.new(5, 3, 3),
			pitch = 0,
			on_spawn = function(player)
				player:set_inventory_formspec("")
				minetest.after(5.0, function()
					if player and player:is_player() then
						-- "Here we go again ..." speech. Triggers 'The End' screen
						glitch_dialog.show_dialogtree(player, "glitch:outro_2")
					end
				end)
			end,
		},
	},
	schematic = "glitch_levels_outro_noise.mts",
	gateways = {},
	sky = "gray_noise",
	ambience = "white_noise",
	on_rejoin = function(player)
		-- Return player to hub when restarting the game after it was complete.
		-- (so the player can collect new electrons)
		glitch_levels.move_to_level(player, "hub")
	end,
})

minetest.after(0, function()
	local levels = glitch_levels.get_levels()
	for name, def in pairs(levels) do
		glitch_levels.build_level(name)
	end
end)

