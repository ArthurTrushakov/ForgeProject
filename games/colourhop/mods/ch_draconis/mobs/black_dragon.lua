----------------
-- Black Dragon --
----------------

minetest.register_entity("ch_draconis:fire_eyes2", {
	hp_max = 1,
	armor_groups = {immortal = 1},
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "mesh",
	mesh = "draconis_eyes.b3d",
	visual_size = {x = 1.01, y = 1.01},
	textures = {"draconis_fire_eyes_orange.png"},
	is_visible = true,
	makes_footstep_sound = false,
	glow = 11,
	blink_timer = 18,
	on_step = function(self, dtime)
		if not self.object:get_attach() then
			self.object:remove()
			return
		end
		self.object:set_armor_groups({immortal = 1})
		if self.object:get_attach()
		and self.object:get_attach():get_luaentity() then
			local parent = self.object:get_attach():get_luaentity()
			self.blink_timer = self.blink_timer - dtime
				self.object:set_properties(
					{textures = {"draconis_fire_eyes_orange.png"}})
			if self.blink_timer <= 0 then
				local tex = self.object:get_properties().textures[1]
				self.object:set_properties({textures = {"transparency.png"}})
				minetest.after(0.25, function()
					 self.object:set_properties({textures = {tex}})
					self.blink_timer = math.random(6, 18)
				end)
			end
		end
	end
})

--------------
-- Behavior --
--------------

local function black_dragon_logic(self)

	if self.hp <= 0 then
	ch_draconis.dragon = nil
		--mob_core.on_die(self)
		ch_draconis.animate(self, "death")
		mobkit.clear_queue_high(self)
		mobkit.clear_queue_low(self)
		self.object:set_yaw(self.object:get_yaw())

	local pos = self.object:get_pos()
	minetest.add_particlespawner({
		amount = 64 * self.growth_scale,
		time = 0.25,
		minpos = {x = pos.x - (16 * self.growth_scale), y = pos.y - 2, z = pos.z - (16 * self.growth_scale)},
		maxpos = {x = pos.x + (16 * self.growth_scale), y = pos.y + (16 * self.growth_scale), z = pos.z + (16 * self.growth_scale)},
		minacc = {x = 0, y = 0.5, z = 0},
		maxacc = {x = 0, y = 0.25, z = 0},
		minvel = {x = math.random(-3, 3), y = 0.25, z = math.random(-3, 3)},
		maxvel = {x = math.random(-5, 5), y = 0.25, z = math.random(-5, 5)},
		minexptime = 2,
		maxexptime = 3,
		minsize = 4,
		maxsize = 4,
		texture = "draconis_smoke_particle.png",
		animation = {
			type = 'vertical_frames',
			aspect_w = 4,
			aspect_h = 4,
			length = 1
		},
		glow = 1
	})
	self.object:remove()
		return
	end

	mobkit.remember(self, "idle_timer", self.idle_timer)

	mobkit.remember(self, "greet_timer", self.greet_timer)

	mobkit.remember(self, "current_phase", self.current_phase)

	mobkit.remember(self, "hit_debouncer", self.hit_debouncer)

	mobkit.remember(self, "no_altar", self.no_altar)

	self.shield_regen_time = mobkit.remember(self, "shield_regen_time", self.shield_regen_time or 0)
	self.shielded = mobkit.remember(self, "shielded", self.shielded or false)

	if mobkit.timer(self, 1) then

		local pos = self.object:get_pos()
		local prty = mobkit.get_queue_priority(self)
		local player = mobkit.get_nearby_player(self)

		ch_draconis.handle_sounds(self)

	if self.hit_debouncer > 0 then
		-- count down until next time we can be hit
		self.hit_debouncer = self.hit_debouncer - 1
		if self.hit_debouncer == 0 then
			ch_draconis.play_sound(self, "roar", true)
			-- TODO: make a sound for shield re-activating?
			self.shield_regen_time = mobkit.remember(self, "shield_regen_time", 0)
			self.shielded = mobkit.remember(self, "shielded", true)
		end
	end

	if not self.shielded then
		-- Regen shield.
		self.shield_regen_time = self.shield_regen_time + 1
		if self.shield_regen_time > 20 or (self.current_phase > 3 and self.shield_regen_time > 15) then
			ch_draconis.play_sound(self, "roar", true)
			-- TODO: make a sound for shield re-activating?
			self.shield_regen_time = mobkit.remember(self, "shield_regen_time", 0)
			self.shielded = mobkit.remember(self, "shielded", true)
			ch_draconis.flashplayers(self, "#0000ff", 1)
		end
	end

	-- Black dragon should never land..
	-- TODO: maybe it should?
		if self.logic_state == "landed" then
		ch_draconis.lq_takeoff(self, 5)
			self.logic_state = "flying"
			return
		end

	-- night is finished, retreat up and despawn.
	local tod = minetest.get_timeofday()
	if (tod > 0.17 and tod < 0.76) or self.no_altar or ch_draconis.dragon == nil or ch_draconis.dragon ~= self then
		self.shield_regen_time = mobkit.remember(self, "shield_regen_time", 0)
		self.shielded = mobkit.remember(self, "shielded", true)
		ch_draconis.hq_fly_away(self, 20)
		return
	end

		if not self.isonground
		and self.logic_state == "landed" then
			self.fall_distance = self.fall_distance + 1
		else
			self.fall_distance = 0
		end

	if self.greet_timer == 0 then
		ch_draconis.globalroar(self, "roar", true)
	end

	if self.greet_timer < 10 then
		-- Wait around 10 seconds before doing anything.
		self.greet_timer = self.greet_timer + 1
	elseif self.current_phase == 0 then
		-- We just arrived, descend to low altitude
		if pos.y > 40 then
			if prty < 20 then
				ch_draconis.hq_goto_low_altitude(self, 20)
			end
		else
			-- Initial shield enablement
			self.shield_regen_time = mobkit.remember(self, "shield_regen_time", 0)
			self.shielded = mobkit.remember(self, "shielded", true)
			self.current_phase = 1
		end
	elseif self.current_phase == 1 then
		-- Fly around in low altitude, sometimes shooting, sometimes swooping
		if (pos.y > 40 or pos.y < 20) and prty < 4 then
			ch_draconis.hq_goto_low_altitude(self, 4)
		elseif prty < 4 then
			self.beam_charge = mobkit.remember(self, "beam_charge", self.beam_charge + 1)
			self.swoop_charge = mobkit.remember(self, "swoop_charge", self.swoop_charge + 1)
			if player then
				ch_draconis.hq_aerial_attack(self, 4, player)
			end
			ch_draconis.hq_aerial_wander(self, 3)
		end
	elseif self.current_phase == 2 then
		-- Fly around in high altitude, sometimes shooting
		-- TODO: should we descend after some time?? hmm..
		if (pos.y < 50 or pos.y > 70) and prty < 4 then
			ch_draconis.hq_goto_high_altitude(self, 4)
			return
		elseif prty < 4 then
			self.beam_charge = mobkit.remember(self, "beam_charge", self.beam_charge + 1)
			self.swoop_charge = mobkit.remember(self, "swoop_charge", 0)
			if player then
				ch_draconis.hq_aerial_attack(self, 4, player)
			end
			ch_draconis.hq_aerial_wander(self, 3)
		end
	elseif self.current_phase == 3 then
		-- Fly around in low altitude, sometimes shooting, often swooping
		-- basically same as 1, just a bit more agressive
		if (pos.y > 40 or pos.y < 20) and prty < 4 then
			ch_draconis.hq_goto_low_altitude(self, 4)
		elseif prty < 4 then
			self.beam_charge = mobkit.remember(self, "beam_charge", self.beam_charge + 1)
			self.swoop_charge = mobkit.remember(self, "swoop_charge", self.swoop_charge + 2)
			if player then
				ch_draconis.hq_aerial_attack(self, 4, player)
			end
			ch_draconis.hq_aerial_wander(self, 3)
		end
	elseif self.current_phase > 3 then
		-- Fly around, switch altitude randomly, sometimes shooting, sometimes swooping
		-- basically a mix of 1 and 2, caused by angering dragon by shooting it too early
		if math.random(1, 10) < 3 and prty < 4 then
			if math.random(1, 2) == 2 then
				ch_draconis.hq_goto_high_altitude(self, 4)
			else
				ch_draconis.hq_goto_low_altitude(self, 4)
			end
		elseif prty < 4 then
			self.beam_charge = mobkit.remember(self, "beam_charge", self.beam_charge + 1)
			if pos.y < 50 then
				self.swoop_charge = mobkit.remember(self, "swoop_charge", self.swoop_charge + 1)
			end
			if player then
				ch_draconis.hq_aerial_attack(self, 4, player)
			end
			ch_draconis.hq_aerial_wander(self, 3)
		end
	end

		if mobkit.is_queue_empty_high(self) then
			self.idle_timer = self.idle_timer + 1
			ch_draconis.hq_aerial_wander(self, 0)
			mobkit.remember(self, "flight_timer", self.flight_timer)
		elseif prty >= 1 then
			self.idle_timer = 0
		end
		mobkit.remember(self, "logic_state", self.logic_state)
	end
end

----------------
-- Definition --
----------------

ch_draconis.black_dragon = ch_draconis.register_dragon("black", {
	logic = black_dragon_logic,
	hp = 5
})

