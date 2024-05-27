local S = minetest.get_translator("glitch_nodeboxes")

glitch_nodeboxes = {}

local register_slab = function(name, def)
	local sunlight_propagates, use_texture_alpha
	if def.glasslike then
		sunlight_propagates = true
		use_texture_alpha = "blend"
	end
	minetest.register_node("glitch_nodeboxes:slab"..name, {
		description = def.description,
		tiles = def.tiles,
		use_texture_alpha = use_texture_alpha,
		sunlight_propagates = sunlight_propagates,
		paramtype = "light",
		paramtype2 = "colorfacedir",
		palette = "glitch_nodes_palette.png",
		place_param2 = 0,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 },
		},
		groups = { dig_creative = 3, colored = 1 },
		sounds = glitch_sounds.node_sound_defaults(),
	})
end

-- Workarond for the node looking like solid flat in editor
-- TODO: Remove this when MT fixes transparency on inventory/wield images
local seethrough_tile
if glitch_editor.is_active() then
	seethrough_tile = "glitch_nodes_seethrough_editor.png"
else
	seethrough_tile = "glitch_nodes_seethrough.png"
end

register_slab("solid_grid", {description=S("Solid Slab (grid style)"), tiles=
	{
		"glitch_nodes_solid_grid.png",
		"glitch_nodes_solid_grid.png",
		"glitch_nodeboxes_slab_solid_grid.png",
	}
})
register_slab("solid_flat", {description=S("Solid Slab (flat style)"), tiles={"glitch_nodes_solid_flat.png"}})
register_slab("solid_tile", {description=S("Solid Slab (tile style)"), tiles={"glitch_nodes_solid_tile.png"}})
register_slab("seethrough", {description=S("Seethrough Slab"), tiles={{name=seethrough_tile,backface_culling=true}}, glasslike=true})

local stairbox = function(steps, height, offset)
	local boxes = {}
	if not offset then
		offset = 0
	end
	for s=1, steps do
		local h = (s/steps) * height
		local w = (steps-s+1)/steps
		h = h - 0.5 + offset
		w = w - 0.5
		local box = { -0.5, -0.5, -w, 0.5, h, 0.5 }
		table.insert(boxes, box)
	end
	return boxes
end

local STEPS_STEEP = 7
local STEPS_SMOOTH = 4

glitch_nodeboxes.STEPHEIGHT_STEEP = 1/STEPS_STEEP
glitch_nodeboxes.STEPHEIGHT_SMOOTH = 0.5/STEPS_SMOOTH

-- Steep stepheight must be higher for the Super Slope Sliding ability to work
assert(glitch_nodeboxes.STEPHEIGHT_STEEP > glitch_nodeboxes.STEPHEIGHT_SMOOTH)

local register_slopes = function(name, def)
	local sunlight_propagates, use_texture_alpha
	if def.glasslike then
		sunlight_propagates = true
		use_texture_alpha = "blend"
	end
	minetest.register_node("glitch_nodeboxes:steepslope_"..name, {
		description = def.description_steep,
		tiles = def.tiles,
		use_texture_alpha = use_texture_alpha,
		sunlight_propagates = sunlight_propagates,
		paramtype = "light",
		paramtype2 = "colorfacedir",
		palette = "glitch_nodes_palette.png",
		drawtype = "mesh",
		collision_box = {
			type = "fixed",
			fixed = stairbox(STEPS_STEEP, 1.0),
		},
		mesh = "glitch_nodeboxes_slope_steep.obj",
		groups = { dig_creative = 3, colored = 1},
		sounds = glitch_sounds.node_sound_defaults(),
	})
	minetest.register_node("glitch_nodeboxes:smoothslope_"..name, {
		description = def.description_smooth,
		tiles = def.tiles,
		use_texture_alpha = use_texture_alpha,
		sunlight_propagates = sunlight_propagates,
		paramtype = "light",
		paramtype2 = "colorfacedir",
		palette = "glitch_nodes_palette.png",
		drawtype = "mesh",
		selection_box = {
			type = "fixed",
			fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 },
		},
		collision_box = {
			type = "fixed",
			fixed = stairbox(STEPS_SMOOTH, 0.5),
		},
		mesh = "glitch_nodeboxes_slope_smooth.obj",
		groups = { dig_creative = 3, colored = 1 },
		sounds = glitch_sounds.node_sound_defaults(),
	})
	minetest.register_node("glitch_nodeboxes:smoothslopeelevated_"..name, {
		description = def.description_smooth_elevated,
		tiles = def.tiles,
		use_texture_alpha = use_texture_alpha,
		sunlight_propagates = sunlight_propagates,
		paramtype = "light",
		paramtype2 = "colorfacedir",
		palette = "glitch_nodes_palette.png",
		drawtype = "mesh",
		collision_box = {
			type = "fixed",
			fixed = stairbox(STEPS_SMOOTH, 0.5, 0.5),
		},
		mesh = "glitch_nodeboxes_slope_smooth_elevated.obj",
		groups = { dig_creative = 3, colored = 1 },
		sounds = glitch_sounds.node_sound_defaults(),
	})
end

register_slopes("solid_grid", {
	description_smooth=S("Solid Small Slope (grid style)"),
	description_smooth_elevated=S("Solid Elevated Small Slope (grid style)"),
	description_steep=S("Solid Tall Slope (grid style)"),
	tiles={
		"glitch_nodes_solid_grid.png",
		"glitch_nodes_solid_grid.png",
		"glitch_nodeboxes_slab_solid_grid.png",
	}
})
register_slopes("solid_flat", {
	description_smooth=S("Solid Small Slope (flat style)"),
	description_smooth_elevated=S("Solid Elevated Small Slope (flat style)"),
	description_steep=S("Solid Tall Slope (flat style)"),
	tiles={"glitch_nodes_solid_flat.png"}})
register_slopes("solid_tile", {
	description_smooth=S("Solid Small Slope (tile style)"),
	description_smooth_elevated=S("Solid Elevated Small Slope (tile style)"),
	description_steep=S("Solid Tall Slope (tile style)"),
	tiles={"glitch_nodes_solid_tile.png"}})
register_slopes("seethrough", {
	description_smooth=S("Seethrough Slope"),
	description_smooth_elevated=S("Seethrough Elevated Small Slope"),
	description_steep=S("Seethrough Tall Slope"),
	tiles={{name=seethrough_tile,backface_culling=true}},
	glasslike=true})


