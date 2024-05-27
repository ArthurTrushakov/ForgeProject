local function spherand(radius, up)
	local l = math.acos(2 * math.random() - 1)
	if up then
		l = l / 2
	else
		l = l - math.pi / 2
	end
	local t = math.pi * 2 * math.random()
	return {
		x = math.cos(l) * math.sin(t) * radius,
		y = math.sin(l) * radius,
		z = math.cos(l) * math.cos(t) * radius
	}
end

local function bluestar(def)
	for k, v in pairs({
		expirationtime = 0.25,
		size = math.random() * 2 + 2,
		collisiondetection = false,
		vertical = false,
		animation = {type = "vertical_frames", aspect_w = 9, aspect_h = 9, length = 3.5},
		glow = 15,
		texture = "anim_blue_star.png",
	}) do def[k] = def[k] or v end
	minetest.add_particle(def)
end

local function weaponburst(self, pos)
	for _ = 1, 20 do
		bluestar({
			pos = pos,
			velocity = spherand(20)
		})
	end
	if self.sound then minetest.sound_stop(self.sound) end
	if self.spawner then minetest.delete_particlespawner(self.spawner) end
	minetest.sound_play("simple_fireworks_bang",
		{gain = 1, pos = pos, pitch = 2}, true)
	return self.object:remove()
end

local homingrate = 10
minetest.register_entity("ch_silver:royal_weapon", {
	hp_max = 1,
	armor_groups = {immortal = 1},
	physical = false,
	visual = "wielditem",
	textures = {"buildings:exit_point"},
	is_visible = true,
	glow = 8,
	static_save = false,
	visual_size = {x = 0.3, y = 0.3, z = 0.3},
	on_activate = function(self)
		self.object:set_properties({automatic_rotate = math.random() * 10 - 5})
		self.sound = minetest.sound_play("silver_weapon", {gain = 1, object = self.object})
		self.spawner = minetest.add_particlespawner({
			amount = 2,
			time = 0,
			attached = self.object,
			minexptime = 1,
			maxexptime = 2,
			minsize = 2,
			maxsize = 4,
			collisiondetection = false,
			vertical = false,
			animation = {type = "vertical_frames", aspect_w = 9, aspect_h = 9, length = 3.5},
			glow = 15,
			texture = "anim_blue_star.png",
		})
	end,
	on_step = function(self, dtime)
		local pos = self.object:get_pos()
		if not pos then return end
		local target
		local tdist = 40
		for _, player in ipairs(minetest.get_connected_players()) do
			local ppos = player:get_pos()
			ppos.y = ppos.y + 1
			local dist = vector.distance(pos, ppos)
			if dist < 1.3 then
				local player_meta = player:get_meta()
				local tptime = player_meta:get_float("rb_teleported") or 0
				if tptime < minetest.get_gametime() - 3 then
					ch_flashscreen.showflash(player, "#000099", 3)
					player:set_pos({
						x = player_meta:get_int("entrance_x"),
						y = player_meta:get_int("entrance_y") + 1,
						z = player_meta:get_int("entrance_z")
					})
					minetest.sound_play("blue_special",
						{gain = 1, pos = ppos}, true)
					minetest.sound_play("blue_special",
						{gain = 1, to_player = player:get_player_name()}, true)
				end
				return weaponburst(self, ppos)
			end
			if dist < tdist then
				dist = tdist
				target = ppos
			end
		end
		if not target then return self.object:remove() end
		local node = minetest.get_node(pos)
		if node.name ~= "air" then return weaponburst(self, pos) end
		if not self.homing then return end
		self.homing = self.homing - dtime
		if self.homing > 0 then return end
		if not self.homestopped then
			self.object:set_velocity({x = 0, y = 0, z = 0})
			self.homestopped = true
		end
		local dv = vector.subtract(target, pos)
		local drate = homingrate * dtime
		if vector.length(dv) > drate then
			dv = vector.multiply(vector.normalize(dv), drate)
		end
		self.object:add_velocity(dv)
	end
})

local royalstates = {}

local function chargeparticle(pos)
	local rel = spherand(4, true)
	bluestar({
		pos = vector.add(pos, rel),
		velocity = vector.multiply(rel, -4),
	})
end
local chargetime = 10
local particlerate = 30 / chargetime

function royalstates.charge(self, dtime, pos)
	if not self.chargetime then
		self.chargetime = chargetime
	end
	local oldcount = math.floor(self.chargetime * particlerate)
	self.chargetime = self.chargetime - dtime
	local newcount = math.floor(self.chargetime * particlerate)
	if self.chargetime <= 0 then
		self.chargetime = nil
		for _ = 1, 40 do
			chargeparticle(pos)
		end
		for i = 1, 5 do
			local t = math.pi * 2 / 5 * i
			minetest.sound_play("altar",
				{gain = 1, pos = {
					x = pos.x + math.cos(t) * 10,
					y = pos.y,
					z = pos.z + math.sin(t) * 10
				}, pitch = 0.75 + math.random() * 0.02}, true)
		end
		self.weaponstate = "postcharge"
	end
	for _ = newcount, oldcount - 1 do
		chargeparticle(pos)
	end
end

local attacktypes = {
	"normal",
	"normal",
	"normal",
	"normal",
	"homers",
	"homers",
	"spiral"
}
function royalstates.postcharge(self, dtime)
	if not self.posttime then
		self.posttime = 2 + math.random()
	end
	self.posttime = self.posttime - dtime
	if self.posttime > 0 then return end
	self.posttime = nil
	self.weaponstate = attacktypes[math.random(1, #attacktypes)]
end

local function shoot(pos, vel)
	minetest.sound_play("simple_fireworks_rocket",
		{gain = 1, pos = pos}, true)
	local obj = minetest.add_entity(pos, "ch_silver:royal_weapon")
	if obj then
		obj:set_velocity(vel)
		return obj:get_luaentity()
	end
end

function royalstates.normal(self, _, pos)
	local targets = {}
	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		ppos.y = ppos.y + 1
		local dist = vector.distance(pos, ppos)
		if dist < 40 then
			targets[#targets + 1] = vector.subtract(ppos, pos)
		end
	end
	if #targets < 1 then targets[1] = {x = 0, y = 0, z = 0} end
	for _ = 1, math.random(#targets * 5, #targets * 7) do
		local t = targets[math.random(1, #targets)]
		t = {
			x = t.x + math.random() * 5 - 2.5,
			y = t.y + math.random() - 0.5,
			z = t.z + math.random() * 5 - 2.5,
		}
		shoot(pos, vector.multiply(vector.normalize(t), 5))
	end
	self.weaponstate = "charge"
end

function royalstates.homers(self, _, pos)
	for _ = 1, math.random(3, 5) do
		local ent = shoot(pos, spherand(10, true))
		if ent then
			ent.homing = math.random()
		end
	end
	self.weaponstate = "charge"
end

local spiraltime = 12
local spiralcount = 40
function royalstates.spiral(self, dtime, pos)
	if not self.spiraltime then
		self.spiraltime = spiraltime
		self.dtheta = math.pi * 2 * math.random()
		self.spiraldir = math.random(1, 2) * 2 - 3
	end
	local oldcount = math.floor(self.spiraltime / spiraltime * spiralcount)
	self.spiraltime = self.spiraltime - dtime
	local newcount = math.floor(self.spiraltime / spiraltime * spiralcount)
	if self.spiraltime <= 0 then
		self.spiraltime = nil
		self.weaponstate = "charge"
	end
	for i = newcount, oldcount - 1 do
		local theta = i / spiralcount * math.pi * 4 * self.spiraldir + self.dtheta
		shoot(pos, {
			x = math.cos(theta) * 3,
			y = 0,
			z = math.sin(theta) * 3
		})
	end
end

local repeldist = 2
local springconst = 5
local function royal_weapon(self, dtime)
	local pos = self.object:get_pos()
	if not pos then return end
	pos.y = pos.y + 1
	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		ppos.y = ppos.y + 1
		local diff = vector.subtract(ppos, pos)
		local dist = vector.length(diff)
		if dist < repeldist then
			local dv = vector.multiply(vector.normalize(diff),
				(repeldist - dist) * springconst)
			player:add_velocity(dv)
		end
	end
	self.weaponstate = self.weaponstate or "charge"
	(royalstates[self.weaponstate])(self, dtime, pos)
end

return royal_weapon
