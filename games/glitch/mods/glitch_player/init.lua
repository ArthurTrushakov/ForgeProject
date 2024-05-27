local S = minetest.get_translator("glitch_player")
local F = minetest.formspec_escape

local PLAYER_SIZE = 0.8
local PLAYER_SIZE_HALF = PLAYER_SIZE/2

minetest.register_on_joinplayer(function(player)
	local inv = player:get_inventory()
	inv:set_size("craft", 0)
	inv:set_size("craftresult", 0)

	-- Disable sneaking
	player:set_physics_override({sneak=false})

	-- Disable jumping
	playerphysics.add_physics_factor(player, "jump", "disable_jump", 0)

	player:set_properties({
		visual = "mesh",
		shaded = true,
		mesh = "glitch_player_player.obj",
		backface_culling = true,
		textures = {
			"glitch_player_player_side.png",
			"glitch_player_player_side.png",
			"glitch_player_player_side.png",
			"glitch_player_player_side.png",
			"glitch_player_player_front.png",
			"glitch_player_player_side.png",
		},
		shaded = true,
		visual_size = { x = PLAYER_SIZE, y = PLAYER_SIZE },
		eye_height = 0.27,
		collisionbox = { -PLAYER_SIZE_HALF, -PLAYER_SIZE_HALF, -PLAYER_SIZE_HALF, PLAYER_SIZE_HALF, PLAYER_SIZE_HALF, PLAYER_SIZE_HALF },
		selectionbox = { -PLAYER_SIZE_HALF, -PLAYER_SIZE_HALF, -PLAYER_SIZE_HALF, PLAYER_SIZE_HALF, PLAYER_SIZE_HALF, PLAYER_SIZE_HALF, rotate = true },
	})
	player:hud_set_hotbar_selected_image("glitch_gui_hotbar_selected.png")

	-- Hide debug info
	player:hud_set_flags({basic_debug=false})

	local hud_flags = {
		healthbar = false,
		breathbar = false,
		minimap = false,
		minimap_radar = false,
	}

	if glitch_editor.is_active() then
		inv:set_size("main", 40)
		player:hud_set_hotbar_itemcount(10)
		player:hud_set_hotbar_image("glitch_gui_hotbar_10.png")
	else
		player:hud_set_hotbar_itemcount(1)
		player:hud_set_hotbar_image("glitch_gui_hotbar_1.png")
		hud_flags.hotbar = false
		hud_flags.wielditem = false
	end
	player:hud_set_flags(hud_flags)
end)
