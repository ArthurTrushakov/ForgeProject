local S = minetest.get_translator("glitch_nodes")

minetest.register_alias("mapgen_stone", "glitch_nodes:solid_flat")

minetest.register_node("glitch_nodes:solid_grid", {
	description = S("Solid (Grid Style)"),
	tiles = { "glitch_nodes_solid_grid.png" },
	groups = { dig_creative = 3, colored = 1 },
	sounds = glitch_sounds.node_sound_defaults(),
	paramtype2 = "color",
	palette = "glitch_nodes_palette.png",
})
minetest.register_node("glitch_nodes:solid_flat", {
	description = S("Solid (Flat Style)"),
	tiles = { "glitch_nodes_solid_flat.png" },
	groups = { dig_creative = 3, colored = 1 },
	sounds = glitch_sounds.node_sound_defaults(),
	paramtype2 = "color",
	palette = "glitch_nodes_palette.png",
})
minetest.register_node("glitch_nodes:solid_concentric", {
	description = S("Solid (Concentric Style)"),
	tiles = { "glitch_nodes_solid_concentric.png" },
	groups = { dig_creative = 3, colored = 1 },
	sounds = glitch_sounds.node_sound_defaults(),
	paramtype2 = "color",
	palette = "glitch_nodes_palette.png",
})
minetest.register_node("glitch_nodes:solid_tile", {
	description = S("Solid (Tile Style)"),
	tiles = { "glitch_nodes_solid_tile.png" },
	groups = { dig_creative = 3, colored = 1 },
	sounds = glitch_sounds.node_sound_defaults(),
	paramtype2 = "color",
	palette = "glitch_nodes_palette.png",
})

-- Workarond for the node looking like solid flat in the
-- inventory/wield image
-- TODO: Remove this when MT fixes transparency on inventory/wield images
local seethrough_tile
if glitch_editor.is_active() then
	seethrough_tile = "glitch_nodes_seethrough_editor.png"
else
	seethrough_tile = "glitch_nodes_seethrough.png"
end
minetest.register_node("glitch_nodes:seethrough", {
	description = S("Seethrough"),
	tiles = { seethrough_tile },
	use_texture_alpha = "blend",
	drawtype = "glasslike",
	paramtype = "light",
	sunlight_propagates = true,
	groups = { dig_creative = 3, colored = 1 },
	sounds = glitch_sounds.node_sound_defaults(),
	paramtype2 = "color",
	palette = "glitch_nodes_palette.png",
})

-- Gateway teleports to other levels.
-- Note: Gateway handling is in glitch_levels mod
minetest.register_node("glitch_nodes:gateway", {
	description = S("Gateway"),
	tiles = {
		{ name = "glitch_nodes_gateway_anim.png", animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 1 } },
		"glitch_nodes_gateway_bottom.png",
		"glitch_nodes_gateway_side.png",
	},
	groups = { dig_creative = 3 },
	sounds = glitch_sounds.node_sound_defaults(),
})

local resetter_tile, resetter_tile_noblack, resetter_drawtype, resetter_pointable, resetter_alpha, resetter_resist
if glitch_editor.is_active() then
	resetter_drawtype = "allfaces"
	resetter_tile = "glitch_nodes_resetter_editor.png"
	resetter_tile_noblack = "glitch_nodes_resetter_noblack_editor.png"
	resetter_alpha = 32
else
	resetter_drawtype = "airlike"
	resetter_pointable = false
	resetter_alpha = 255
	resetter_resist = 7
end
-- Special node that causes the player to reset the level while inside it.
-- Resetting is handled in glitch_levels
minetest.register_node("glitch_nodes:resetter", {
	description = S("Resetter"),
	tiles = {resetter_tile},
	drawtype = resetter_drawtype,
	pointable = resetter_pointable,
	paramtype = "light",
	visual_scale = 0.8,
	sunlight_propagates = true,
	move_resistance = resetter_resist,
	post_effect_color = {r=0,b=0,g=0,a=resetter_alpha},
	groups = { dig_creative = 3, resetter = 1 },
	walkable = false,
})
-- Same as resetter, except the screen doesn't turn black
-- and doesn't slow down player
minetest.register_node("glitch_nodes:resetter_noblack", {
	description = S("Resetter (no blackout)"),
	tiles = {resetter_tile_noblack},
	drawtype = resetter_drawtype,
	pointable = resetter_pointable,
	paramtype = "light",
	visual_scale = 0.8,
	sunlight_propagates = true,
	groups = { dig_creative = 3, resetter = 1 },
	walkable = false,
})

local barrier_tiles, barrier_drawtype, barrier_pointable
if glitch_editor.is_active() then
	barrier_tiles = {"glitch_nodes_barrier_editor.png"}
	barrier_drawtype = "allfaces"
else
	barrier_drawtype = "airlike"
	barrier_pointable = false
end
-- An invisible node that blocks movement
minetest.register_node("glitch_nodes:barrier", {
	description = S("Invisible Barrier"),
	drawtype = barrier_drawtype,
	tiles = barrier_tiles,
	pointable = barrier_pointable,
	paramtype = "light",
	sunlight_propagates = true,
	groups = { dig_creative = 3 },
	walkable = true,
})

minetest.register_node("glitch_nodes:system", {
	description = S("System Node"),
	tiles = {
		{name="glitch_nodes_system_node.png", animation={type="vertical_frames", aspec_w=16, aspect_h=16, length=3}},
	},
	groups = { dig_creative = 3 },
	sounds = glitch_sounds.node_sound_defaults(),
	light_source = 7,
	paramtype = "light",
})

local CR_R = 1/16 -- climbrail radius
local CR_S = 3/16 -- climbrail selectionbox radius (for editor)

local climbrail_selection_box
if glitch_editor.is_active() then
	climbrail_selection_box = {
		type = "connected",
		fixed = { -CR_S, -CR_S, -CR_S, CR_S, CR_S, CR_S },
		connect_left = { -0.5, -CR_S, -CR_S, -CR_S, CR_S, CR_S },
		connect_right = { CR_S, -CR_S, -CR_S, 0.5, CR_S, CR_S },
		connect_top = { -CR_S, CR_S, -CR_S, CR_S, 0.5, CR_S },
		connect_bottom = { -CR_S, -0.5, -CR_S, CR_S, -CR_S, CR_S },
		connect_front = { -CR_S, -CR_S, -0.5, CR_S, CR_S, -CR_S },
		connect_back = { -CR_S, -CR_S, CR_S, CR_S, CR_S, 0.5 },
	}
end

local climbdef = {
	description = S("Cable"),
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	tiles = { "glitch_nodes_climbrail.png" },
	inventory_image = "glitch_nodes_climbrail_inv.png",
	use_texture_alpha = "clip",
	node_box = {
		type = "connected",
		fixed = { -CR_R, -CR_R, -CR_R, CR_R, CR_R, CR_R },
		connect_left = { -0.5, -CR_R, -CR_R, -CR_R, CR_R, CR_R },
		connect_right = { CR_R, -CR_R, -CR_R, 0.5, CR_R, CR_R },
		connect_top = { -CR_R, CR_R, -CR_R, CR_R, 0.5, CR_R },
		connect_bottom = { -CR_R, -0.5, -CR_R, CR_R, -CR_R, CR_R },
		connect_front = { -CR_R, -CR_R, -0.5, CR_R, CR_R, -CR_R },
		connect_back = { -CR_R, -CR_R, CR_R, CR_R, CR_R, 0.5 },
	},
	selection_box = climbrail_selection_box,
	connects_to = { "group:climbrail", "group:climbrail_connector" },
	climbable = true,
	walkable = false,
	groups = { climbrail = 1, dig_creative = 3 },
	sounds = glitch_sounds.node_sound_defaults(),
}
-- The non-climbable version is used to replace the normal climbrail if the
-- player doesn't have the climb ability yet
local climbdef_noclimb = table.copy(climbdef)
climbdef_noclimb.climbable = false
climbdef_noclimb.description = S("Cable (not climbable)")
climbdef_noclimb.inventory_image = "glitch_nodes_climbrail_noclimb_inv.png"

local climbdef_nojump = table.copy(climbdef)
climbdef_nojump.groups.disable_jump = 1
climbdef_nojump.description = S("Cable (no jump)")
climbdef_nojump.tiles = {"glitch_nodes_climbrail_nojump_top.png","glitch_nodes_climbrail_nojump_bottom.png","glitch_nodes_climbrail_nojump.png"}
climbdef_nojump.inventory_image = "glitch_nodes_climbrail_nojump_inv.png"

local climbdef_nojumpnoclimb = table.copy(climbdef_nojump)
climbdef_nojumpnoclimb.climbable = false
climbdef_nojumpnoclimb.description = S("Cable (no jump, not climbable)")
climbdef_nojumpnoclimb.inventory_image = "glitch_nodes_climbrail_nojumpnoclimb_inv.png"

minetest.register_node("glitch_nodes:climbrail", climbdef)
minetest.register_node("glitch_nodes:climbrail_nojump", climbdef_nojump)
minetest.register_node("glitch_nodes:climbrail_noclimb", climbdef_noclimb)
minetest.register_node("glitch_nodes:climbrail_nojumpnoclimb", climbdef_nojumpnoclimb)

-- Decorative solid node for a nice climbrail connection
minetest.register_node("glitch_nodes:climbrail_connector", {
	description = S("Cable Connector"),
	tiles = { "glitch_nodes_climbrail_connector.png" },
	groups = { climbrail_connector = 1, dig_creative = 3 },
	sounds = glitch_sounds.node_sound_defaults(),
})
minetest.register_node("glitch_nodes:climbrail_connector_nojump", {
	description = S("Cable Connector (no jump)"),
	tiles = { "glitch_nodes_climbrail_connector_nojump.png" },
	groups = { climbrail_connector = 1, dig_creative = 3, disable_jump = 1 },
	sounds = glitch_sounds.node_sound_defaults(),
})

local bounce_levels = {
	{ 80, S("Weak Bouncer"), "glitch_nodes_bouncer_weak.png" },
	{ 100, S("Full Bouncer"), "glitch_nodes_bouncer_normal.png" },
	{ 120, S("Super Bouncer"), "glitch_nodes_bouncer_super.png" },
}
for b=1, #bounce_levels do
	local bounce = bounce_levels[b][1]
	local bstr = string.format("%03d", bounce )
	minetest.register_node("glitch_nodes:bouncer_"..bstr, {
		description = bounce_levels[b][2],
		tiles = { bounce_levels[b][3] },
		groups = { bouncy = -bounce, dig_creative = 3 },
		sounds = glitch_sounds.node_sound_defaults(),
	})
end

-- Handling is in glitch_abilities
minetest.register_node("glitch_nodes:jumppad", {
	description = S("Launchpad"),
	tiles = {
		{name="glitch_nodes_jumppad_top_anim.png", animation={type="vertical_frames", aspec_w=16, aspect_h=16, length=3}},
		"glitch_nodes_jumppad_bottom.png",
		"glitch_nodes_jumppad_side.png"
	},
	place_param2 = 32,
	-- Disable *builtin* jumping on jump pad; the jump key is checked in glitch_abilities
	groups = { dig_creative = 3, disable_jump = 1 },
	sounds = glitch_sounds.node_sound_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.4375, -0.5, -0.4375, 0.5, 0.5},
			{-0.4375, 0.4375, 0.125, -0.375, 0.5, 0.5},
			{-0.375, 0.4375, 0.25, -0.3125, 0.5, 0.5},
			{-0.3125, 0.4375, 0.3125, -0.25, 0.5, 0.5},
			{-0.25, 0.4375, 0.375, -0.125, 0.5, 0.5},
			{-0.125, 0.4375, 0.4375, 0.125, 0.5, 0.5},
			{0.125, 0.4375, 0.375, 0.25, 0.5, 0.5},
			{0.25, 0.4375, 0.3125, 0.3125, 0.5, 0.5},
			{0.3125, 0.4375, 0.25, 0.375, 0.5, 0.5},
			{0.375, 0.4375, 0.125, 0.5, 0.5, 0.5},
			{0.4375, 0.4375, -0.5, 0.5, 0.5, 0.125},
			{0.375, 0.4375, -0.5, 0.4375, 0.5, -0.125},
			{0.3125, 0.4375, -0.5, 0.375, 0.5, -0.25},
			{0.25, 0.4375, -0.5, 0.3125, 0.5, -0.3125},
			{0.125, 0.4375, -0.5, 0.25, 0.5, -0.375},
			{-0.125, 0.4375, -0.5, 0.125, 0.5, -0.4375},
			{-0.25, 0.4375, -0.5, -0.125, 0.5, -0.375},
			{-0.3125, 0.4375, -0.5, -0.25, 0.5, -0.3125},
			{-0.375, 0.4375, -0.5, -0.3125, 0.5, -0.25},
			{-0.4375, 0.4375, -0.5, -0.375, 0.5, -0.125},
			{-0.125, 0.4375, 0.3125, 0.125, 0.5, 0.375},
			{-0.25, 0.4375, 0.25, 0.25, 0.5, 0.3125},
			{-0.375, 0.4375, -0.125, -0.3125, 0.5, 0.125},
			{-0.3125, 0.4375, -0.25, -0.25, 0.5, 0.25},
			{0.3125, 0.4375, -0.125, 0.375, 0.5, 0.125},
			{0.25, 0.4375, -0.25, 0.3125, 0.5, 0.25},
			{-0.25, 0.4375, -0.3125, 0.25, 0.5, -0.25},
			{-0.125, 0.4375, -0.375, 0.125, 0.5, -0.3125},
			{-0.0625, 0.4375, -0.0625, 0.0625, 0.5, 0.0625},
			{-0.125, 0.4375, 0.125, 0.125, 0.5, 0.1875},
			{-0.1875, 0.4375, -0.1875, -0.125, 0.5, 0.1875},
			{0.125, 0.4375, -0.1875, 0.1875, 0.5, 0.1875},
			{-0.125, 0.4375, -0.1875, 0.125, 0.5, -0.125},
			{-0.25, 0.4375, 0.1875, -0.1875, 0.5, 0.25},
			{0.1875, 0.4375, 0.1875, 0.25, 0.5, 0.25},
			{0.1875, 0.4375, -0.25, 0.25, 0.5, -0.1875},
			{-0.25, 0.4375, -0.25, -0.1875, 0.5, -0.1875},
			{-0.5, -0.5, -0.5, 0.5, 0.4375, 0.5},
		}
	},
	selection_box = {
		type = "regular",
	},
	collision_box = {
		type = "regular",
	},
})

local set_gravity = function(player, gravity)
	if gravity == "plus" then
		playerphysics.add_physics_factor(player, "gravity", "nodemod_gravity", 1)
	elseif gravity == "minus" then
		playerphysics.add_physics_factor(player, "gravity", "nodemod_gravity", -1)
	elseif gravity == "zero" then
		playerphysics.add_physics_factor(player, "gravity", "nodemod_gravity", 0)
	end
end

minetest.register_node("glitch_nodes:lamp_on", {
	description = S("Lamp"),
	tiles = {
		"glitch_nodes_lamp_on.png",
	},
	light_source = minetest.LIGHT_MAX,
	paramtype = "light",
	groups = { dig_creative = 3 },
	sounds = glitch_sounds.node_sound_defaults(),
})

local GRAVITY = tonumber(minetest.settings:get("movement_gravity")) or 9.81

-- Darkness: A special transparent node that blocks sunlight,
-- causing all nodes below it to darken. Nice for an "abyss" effect.
local dark_tiles, dark_drawtype, dark_pointable
if glitch_editor.is_active() then
	dark_drawtype = "glasslike"
	dark_tiles = { "glitch_nodes_darkness_editor.png" }
	dark_pointable = true
else
	dark_drawtype = "airlike"
	dark_pointable = false
end
minetest.register_node("glitch_nodes:darkness", {
	description = S("Darkness"),
	drawtype = dark_drawtype,
	tiles = dark_tiles,
	pointable = dark_pointable,
	walkable = false,
	paramtype = "light",
	sunlight_propagates = false,
	wield_image = "glitch_nodes_darkness_inv.png",
	inventory_image = "glitch_nodes_darkness_inv.png",
	groups = { dig_creative = 3 },
})


-- Triggers save feature
local savetile1 = "blank.png"
local savetile2 = { name = "glitch_nodes_savezone.png", animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.4 }, backface_culling = true }
local save_pointable
if glitch_editor.is_active() then
	save_pointable = true
else
	save_pointable = false
end
minetest.register_node("glitch_nodes:savezone", {
	description = S("Save Zone"),
	drawtype = "nodebox",
	tiles = {
		savetile1, savetile1, savetile2,
	},
	node_box = {
		type = "regular",
	},
	walkable = false,
	pointable = save_pointable,
	use_texture_alpha = "blend",
	paramtype = "light",
	sunlight_propagates = true,
	post_effect_color = { r = 0, b = 0, g = 255, a = 32 },
	groups = { dig_creative = 3 },
	sounds = glitch_sounds.node_sound_defaults(),
})

-- Decorative block only, but should be always placed below glitch_nodes:savezone
minetest.register_node("glitch_nodes:savezone_block", {
	description = S("Save Zone Block"),
	drawtype = "nodebox",
	tiles = {
		"glitch_nodes_savezone_block.png",
	},
	groups = { dig_creative = 3 },
	sounds = glitch_sounds.node_sound_defaults(),
})


dofile(minetest.get_modpath("glitch_nodes").."/noise.lua")
