local S = minetest.get_translator("glitch_npcs")

local LOOK_RADIUS = 5

glitch_npcs = {}
glitch_npcs.registered_npcs = {}

local function register_spawner_node(entity_partname, description, mesh, tiles, fallback_inventory_image, scale)
	local drawtype, inventory_image, wield_image, wield_scale, pointable
	if not glitch_editor.is_active() then
		drawtype = "airlike"
		mesh = nil
		inventory_image = fallback_inventory_image
		wield_image = fallback_inventory_image
		tiles = nil
		pointable = false
	else
		drawtype = "mesh"
		wield_scale = { x=0.2 * scale, y=0.2 * scale, z=0.2 * scale}
		pointable = true
	end
	minetest.register_node("glitch_npcs:spawner_"..entity_partname, {
		description = description,
		drawtype = drawtype,
		mesh = mesh,
		visual_scale = 0.1 * scale,
		wield_scale = wield_scale,
		tiles = tiles,
		inventory_image = inventory_image,
		wield_image = wield_image,
		pointable = pointable,
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		groups = { spawner = 1, spawner_npc = 1, dig_creative = 3 },

		-- Name of the entity that this node spawns
		_spawns = "glitch_npcs:"..entity_partname,
	})
end

glitch_npcs.register_npc = function(name, def)
	glitch_npcs.registered_npcs[name] = def
	local scale = def.scale or 0.8

	minetest.register_entity("glitch_npcs:"..name, {
		visual = "mesh",
		shaded = true,
		mesh = "glitch_entities_cube.obj",
		visual_size = { x=scale, y=scale, z=scale },
		collisionbox = { -scale/2, -scale/2, -scale/2, scale/2, scale/2, scale/2 },
		selectionbox = { -scale/2, -scale/2, -scale/2, scale/2, scale/2, scale/2, rotate = true },
		textures = def.textures,
		_anim_timer = 0,
		physical = true,

		on_rightclick = function(self, clicker)
			if def.dialogtree and clicker and clicker:is_player() then
				glitch_dialog.show_dialogtree(clicker, def.dialogtree)
			end
		end,
		on_activate = function(self, staticdata, dtime_s)
			if not glitch_entities.is_entity_allowed(self) then
				self.object:remove()
				return
			end
			self._anim_timer = 0
			self.object:set_acceleration({x=0, y=-8, z=0})
			local pos = self.object:get_pos()
			pos.y = pos.y - 0.1
			self.object:set_pos(pos)
		end,
		on_step = function(self, dtime_s)
			self._anim_timer = self._anim_timer + dtime_s
			if self._anim_timer < 1 then
				return
			else
				self._anim_timer = 0
			end

			-- Look at player, if a player is nearby
			local objects = minetest.get_objects_inside_radius(self.object:get_pos(), LOOK_RADIUS)
			for o=1, #objects do
				local obj = objects[o]
				if obj and obj:is_player() then
					local dir = vector.direction(obj:get_pos(), self.object:get_pos())
					local yaw = minetest.dir_to_yaw(dir)
					if yaw then
						self.object:set_yaw(yaw)
						break
					end
				end
			end
		end,
	})

	register_spawner_node(name, S("NPC: @1", def.description), "glitch_entities_cube.obj", def.textures, def.fallback_image, 0.8)
end

local textures_helper = {
	"glitch_npcs_helper_side.png",
	"glitch_npcs_helper_side.png",
	"glitch_npcs_helper_side.png",
	"glitch_npcs_helper_side.png",
	"glitch_npcs_helper_side.png",
	"glitch_npcs_helper_front.png",
}
local fallback_helper = "glitch_npcs_helper_front.png"
local textures_master = {
	"glitch_npcs_master_side.png",
	"glitch_npcs_master_side.png",
	"glitch_npcs_master_side.png",
	"glitch_npcs_master_side.png",
	"glitch_npcs_master_side.png",
	"glitch_npcs_master_front.png",
}
local fallback_master = "glitch_npcs_master_front.png"

local helpers = {
	{ "helper_void", S("Void Helper"), "glitch:helper_void_start" },
	{ "helper_gateway", S("Gateway Helper"), "glitch:helper_gateway" },
	{ "helper_savezone", S("Savezone Helper"), "glitch:helper_savezone" },
	{ "helper_distortion_denier", S("Distortion Denier"), "glitch:helper_distortion_denier" },
	{ "helper_distortion_worrier", S("Distortion Worrier"), "glitch:helper_distortion_worrier" },
}
local masters = {
	{ "master_powerslide", S("Powerslide Master"), "glitch:master_powerslide" },
	{ "master_tallslope", S("Slope Master"), "glitch:master_tallslope" },
	{ "master_jumppad", S("Launch Master"), "glitch:master_jumppad" },
	{ "master_climb", S("Climb Master"), "glitch:master_climb" },
}

for h=1, #helpers do
	glitch_npcs.register_npc(helpers[h][1], {
		description = helpers[h][2],
		dialogtree = helpers[h][3],
		textures = textures_helper,
		fallback_texture = fallback_helper,
	})
end
for m=1, #masters do
	glitch_npcs.register_npc(masters[m][1], {
		description = masters[m][2],
		dialogtree = masters[m][3],
		textures = textures_master,
		fallback_texture = fallback_master,
	})
end
