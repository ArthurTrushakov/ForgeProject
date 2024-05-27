-- Temporary entities.
-- These entities are non-persistent entities that are
-- for pure decoration.

local S = minetest.get_translator("glitch_entities")

-- List of temporary entities
glitch_entities.temp_entities = {
	["glitch_entities:falling_bit"] = true,
}

-- Decorative falling bit (e.g. for the chute in the Void level)
local SCALE_BIT = 0.8
minetest.register_entity("glitch_entities:falling_bit", {
	visual = "mesh",
	shaded = true,
	mesh = "glitch_entities_cube.obj",
	visual_size = { x=SCALE_BIT, y=SCALE_BIT, z=SCALE_BIT },
	backface_culling = false,
	pointable = false,
	selectionbox = { -SCALE_BIT/2, -SCALE_BIT/2, -SCALE_BIT/2, SCALE_BIT/2, SCALE_BIT/2, SCALE_BIT/2 },
	textures = {
		"glitch_entities_bit_0.png",
		"glitch_entities_bit_0.png",
		"glitch_entities_bit_0.png",
		"glitch_entities_bit_0.png",
		"glitch_entities_bit_0.png",
		"glitch_entities_bit_0.png",
	},
	shaded = true,
	static_save = false,
	_set_fall_dir = function(self, dir)
		local k = 8 + math.random(-100,100)*0.01
		local vel = vector.multiply(dir, k)
		self.object:set_velocity(vel)

	end,
	on_activate = function(self, staticdata, dtime_s)
		self:_set_fall_dir({x=0,y=-1,z=0})
		local r = (math.pi/2) * math.random(0,3)
		self.object:set_yaw(r)
		local bit = math.random(0, 1)
		if bit == 1 then
			self.object:set_properties({
				textures = {
					"glitch_entities_bit_1.png",
					"glitch_entities_bit_1.png",
					"glitch_entities_bit_1.png",
					"glitch_entities_bit_1.png",
					"glitch_entities_bit_1.png",
					"glitch_entities_bit_1.png",
				}
			})
		end
	end,
})

local s_drawtype, s_img, s_pointable, s_wscale
if glitch_editor.is_active() then
	s_drawtype = "mesh"
	s_pointable = true
	s_wscale = { x=0.1 * SCALE_BIT, y=0.1 * SCALE_BIT, z=0.1 * SCALE_BIT}
else
	s_drawtype = "airlike"
	s_img = "glitch_entities_bit_inv.png"
	s_pointable = false
end

minetest.register_node("glitch_entities:spawner_falling_bit", {
	description = S("Falling Bit Spawner"),
	drawtype = s_drawtype,
	inventory_image = s_img,
	wield_image = s_img,
	wield_scale = s_wscale,
	mesh = "glitch_entities_cube.obj",
	visual_scale = 0.1 * SCALE_BIT,
	tiles = {
		"glitch_entities_bit_editor_spawnarrow.png",
		"glitch_entities_bit_editor_spawnarrow.png^[transformR180",
		"glitch_entities_bit_editor_spawnarrow.png^[transformR270",
		"glitch_entities_bit_editor_spawnarrow.png^[transformR90",
		"glitch_entities_bit_editor_spawnside.png",
		"glitch_entities_bit_editor.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	walkable = false,
	pointable = s_pointable,
	groups = { special_spawner = 1, dig_creative = 3 },

	_spawns = "glitch_entities:falling_bit",
	_spawn_func = function(pos)
		local x = math.random(-100,100)*0.001
		local y = math.random(-100,100)*0.001
		local z = math.random(-100,100)*0.001
		local spos = vector.add(pos, vector.new(x,y,z))
		local node = minetest.get_node(pos)
		local dir = minetest.facedir_to_dir(node.param2)
		local bit = minetest.add_entity(spos, "glitch_entities:falling_bit")
		if bit then
			local lua = bit:get_luaentity()
			lua:_set_fall_dir(dir)
		end
	end,
})
