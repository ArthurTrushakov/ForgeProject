local cmsg = cmsg

ch_projectors = {}

ch_projectors.seed_x = 0
ch_projectors.seed_z = 0
ch_projectors.selected = {}
ch_projectors.buildings = {}
ch_projectors.cooldown = 0

local rate = 20
local chance = 60

minetest.after(0, function()
	ch_projectors.seed_x = math.random(0, rate)
	ch_projectors.seed_z = math.random(0, rate)
end)


ch_projectors.has_projector = function(block_pos)
	if block_pos.y ~= 0 then return false end
	if block_pos.x % rate ~= ch_projectors.seed_x then return false end
	if block_pos.z % rate ~= ch_projectors.seed_z then return false end
	if (block_pos.x + block_pos.z) % 100 > chance then return false end
	return true
end

local scan_range = 16

ch_projectors.scan = function(pos)
	local block_pos = {x=math.floor(pos.x/16), y=0, z=math.floor(pos.z/16)}
	local closest
	for i=-scan_range, scan_range do
		for j = -scan_range, scan_range do
			local check_pos = {x=block_pos.x+i, y=0, z=block_pos.z+j}
			if ch_projectors.has_projector(check_pos) then
				local dist = vector.distance(check_pos, block_pos)
				if closest == nil or dist < closest then
					closest = dist
					if closest == 0 then
						minetest.add_particle({
							pos = {x=(block_pos.x*16)+8, y=block_pos.y+8, z=(block_pos.z*16)+8},
							velocity = {x=0, y=15, z=0},
							acceleration = {x=0, y=0, z=0},
							expirationtime = 10,
							size = 25,
							collisiondetection = false,
							vertical = false,
							glow = 30,
							texture = "projector_hint.png",
						})
					end
				end
			end
		end
	end
	return closest
end

ch_projectors.activate_at = function(player, pos, black_special)
	local block_pos = {x=math.floor(pos.x/16), y=0, z=math.floor(pos.z/16)}
	local did_activate = false
	local exit_point_only = (pos.y < -3000)
	if (black_special or exit_point_only or ch_projectors.has_projector(block_pos)) and ch_projectors.cooldown == 0 then
		local found
		if black_special then
			found = ch_projectors.automaton_lab
		elseif exit_point_only then
			found = ch_projectors.exit_point
		else
			for i,j in pairs(ch_projectors.selected) do
				if i.x == block_pos.x and i.z == block_pos.z then
					found = j
					break
				end
			end
		end
		if not found then
			if player then
				local meta = player:get_meta()
				local not_found_projs = {}
				for index=1,#ch_projectors.buildings do
					if meta:get_int("found_proj" .. index) ~= 1 then
						not_found_projs[#not_found_projs+1] = index
					end
				end
				if #not_found_projs == 0 then
					found = ch_projectors.buildings[math.random(#ch_projectors.buildings)]
				else
					local sel = not_found_projs[math.random(#not_found_projs)]
					found = ch_projectors.buildings[sel]
				end
			else
				found = ch_projectors.buildings[math.random(#ch_projectors.buildings)]
			end
			ch_projectors.selected[block_pos] = found
		end
		local pp = {x=block_pos.x*16+8, y=block_pos.y+8+15, z=block_pos.z*16+8}
		if black_special or exit_point_only then
			pp = {x = pos.x, y = pos.y+7, z = pos.z}
		end
		local ent = minetest.add_entity(pp, found.ent)
		if ent then
			if player then
				if found.index > 0 then
					local meta = player:get_meta()
					meta:set_int("found_proj" .. found.index, 1)
				end
				cmsg.push_message_player(player, found.text)
			end
			minetest.add_particlespawner({
				time = 15,
				amount = 300,
				minpos = {x = -0.1, y = 0.7, z = -0.1},
				maxpos = {x = 0.1, y = 0.7, z = 0.1},
				minvel = {x = -20, y = -20, z = -20},
				maxvel = {x = 20, y = 20, z = 20},
				minacc = {x = -1, y = -1, z = -1},
				maxacc = {x = 1, y = 1, z = 1},
				minexptime = 2,
				maxexptime = 2,
				minsize = 1,
				maxsize = 1,
				collisiondetection = false,
				vertical = false,
				glow = 10,
				attached = ent,
				texture = "projector_dust.png",
			})
			minetest.add_particlespawner({
				time = 14,
				amount = 100,
				minpos = {x = -0.1, y = -20, z = -0.1},
				maxpos = {x = 0.1, y = -20, z = 0.1},
				minvel = {x = -5, y = 40, z = -5},
				maxvel = {x = 5, y = 40, z = 5},
				minacc = {x = -1, y = -1, z = -1},
				maxacc = {x = 1, y = 1, z = 1},
				minexptime = 2,
				maxexptime = 2,
				minsize = 1,
				maxsize = 1,
				collisiondetection = false,
				vertical = false,
				glow = 10,
				attached = ent,
				texture = "projector_dust.png",
			})
			did_activate = true
			-- TODO: smarter cooldown, perhaps per projector?
			if not black_special then
				ch_projectors.cooldown = 15
			end
		end
	end
	return did_activate
end

ch_projectors.add_building = function(basename, mesh, text, textures)
	local name = "ch_projectors:proj_" .. basename
	minetest.register_entity(name, {
		initial_properties = {
			visual = "mesh",
			visual_size = {x = 8, y = 8, z = 8},
			mesh = mesh,
			physical = false,
			collide_with_objects = false,
			pointable = false,
			textures = textures,
			use_texture_alpha = true,
			automatic_rotate = 0.8,
			backface_culling = false,
			glow = 10,
			static_save = false,
			shaded = false,
		},
		on_activate = function(self)
			minetest.after(15, function()
				if self then
					self.object:remove()
				end
			end)
		end,
	})
	local index = #ch_projectors.buildings+1
	ch_projectors.buildings[index] = {ent=name, text=text, index=index}
end

ch_projectors.add_building("return_point", "return_point.b3d",
	"Return Point (1/4)",
	{
		"projector_green.png",
		"projector_purple.png", "projector_purple.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png"
	})


ch_projectors.add_building("snapshot_point", "snapshot_point.b3d",
	"Snapshot Point (2/4)",
	{
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_green.png", "projector_green.png", "projector_green.png",
		"projector_purple.png", "projector_purple.png", "projector_purple.png", "projector_purple.png",
		"projector_purple.png"
	})

ch_projectors.add_building("storage_point", "storage_point.b3d",
	"Personal Storage (3/4)",
	{
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_green.png", "projector_green.png",
		"projector_red.png", "projector_red.png", "projector_red.png", "projector_red.png",
		"projector_red.png", "projector_red.png", "projector_red.png", "projector_red.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png"
	})

ch_projectors.add_building("ion_cannon", "ion_cannon.b3d",
	"Ion Cannon (4/4)",
	{
		"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_blue.png", "projector_blue.png", "projector_blue.png", "projector_blue.png",
		"projector_purple.png", "projector_purple.png", "projector_purple.png",
		"projector_red.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
		"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png"
	})

local exit_point_name = "ch_projectors:proj_exit_point"
minetest.register_entity(exit_point_name, {
	initial_properties = {
		visual = "mesh",
		visual_size = {x = 8, y = 8, z = 8},
		mesh = "exit_point.b3d",
		physical = false,
		collide_with_objects = false,
		pointable = false,
		textures = {"projector_blue.png", "projector_blue.png", "projector_blue.png",
			"projector_blue.png", "projector_green.png", "projector_green.png"},
		use_texture_alpha = true,
		automatic_rotate = 0.8,
		backface_culling = false,
		glow = 10,
		static_save = false,
		shaded = false,
	},
	on_activate = function(self)
		minetest.after(15, function()
			if self then
				self.object:remove()
			end
		end)
	end,
})
ch_projectors.exit_point = {ent=exit_point_name, text="Exit Point (1/1)", index=0}

local automaton_lab_name = "ch_projectors:proj_automaton_lab"
minetest.register_entity(automaton_lab_name, {
	initial_properties = {
		visual = "mesh",
		visual_size = {x = 8, y = 8, z = 8},
		mesh = "automaton_lab.b3d",
		physical = false,
		collide_with_objects = false,
		pointable = false,
		textures = {
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_black.png", "projector_black.png", "projector_black.png", "projector_black.png",
			"projector_green.png", "projector_green.png", "projector_green.png", "projector_green.png",
			"projector_green.png",
			"projector_purple.png", "projector_purple.png", "projector_purple.png", "projector_purple.png",
			"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
			"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
			"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
			"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
			"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
			"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png",
			"projector_yellow.png", "projector_yellow.png", "projector_yellow.png", "projector_yellow.png"
		},
		use_texture_alpha = true,
		automatic_rotate = 0.8,
		backface_culling = false,
		glow = 10,
		static_save = false,
		shaded = false,
	},
	on_activate = function(self)
		minetest.after(15, function()
			if self then
				self.object:remove()
			end
		end)
	end,
})
ch_projectors.automaton_lab = {ent=automaton_lab_name, text="Automaton Lab (1/1)", index=0}


minetest.register_globalstep(function(dtime)
	if ch_projectors.cooldown > 0 then
		ch_projectors.cooldown = ch_projectors.cooldown - dtime
		if ch_projectors.cooldown < 0 then
			ch_projectors.cooldown = 0
		end
	end
end)
