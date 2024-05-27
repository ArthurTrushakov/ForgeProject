-- Code for special move abilities, inlcuding:

-- Powerslide ability:
-- Allow powerslide with Aux1 + Up key.
-- Jump key MUST NOT be pressed (this is a workaround for awkwards physics behavior)
-- This gives a quick horitontal speed impulse.
-- Player must be on the floor for this to work.

-- Jump pad ability
-- Aux1 on a jumppad makes you jump
-- (param2 determines jump strength)


-- How fast the speed boost is
local POWERSLIDE_VELOCITY = 19

-- Usage cooldown in seconds
local COOLDOWN = 1.25

local cooldowns = {}

local ability_icons = {}

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local name = player:get_player_name()

		local ctrl = player:get_player_control()
		if not cooldowns[name] then
			cooldowns[name] = COOLDOWN
		end
		cooldowns[name] = cooldowns[name] - dtime
		if cooldowns[name] <= 0 and not glitch_utils.is_in_end_screen(player) then
			local ability_used = false
			do
				local pos_here = player:get_pos()
				local node_here = minetest.get_node(pos_here)
				local def_here = minetest.registered_nodes[node_here.name]
				local pos_below = vector.add(pos_here, vector.new(0,-0.5,0))
				local node_below = minetest.get_node(pos_below)
				local def_below = minetest.registered_nodes[node_below.name]
				local pos_below2 = vector.add(pos_here, vector.new(0,-1,0))
				local node_below2 = minetest.get_node(pos_below2)
				local def_below2 = minetest.registered_nodes[node_below2.name]

				local vel = player:get_velocity()

				-- Update ability status icon
				local abil_powerslide = glitch_abilities.has_ability(player, "glitch:powerslide")
				local abil_launch = glitch_abilities.has_ability(player, "glitch:jumppad")

				local action

				local new_icon
				if abil_launch and node_below.name == "glitch_nodes:jumppad" and math.abs(vel.y) < 0.1 then
					action = "launch"
					new_icon = "glitch_abilities_launch_ready.png"
				elseif node_below.name == "glitch_nodes:gateway" then
					if (ctrl.aux1) then
						new_icon = "glitch_abilities_gateway_ready2.png"
					else
						new_icon = "glitch_abilities_gateway_ready.png"
					end
				elseif abil_powerslide and minetest.get_item_group(node_here.name, "resetter") == 0 and
						((def_below and def_below.walkable) or (def_below2 and def_below2.walkable) or (def_here and def_here.walkable)) and
						vel.y <= 0.1 then
					action = "powerslide"
					if (ctrl.aux1 and not ctrl.jump) then
						new_icon = "glitch_abilities_powerslide_ready2.png"
					else
						new_icon = "glitch_abilities_powerslide_ready.png"
					end
				else
					new_icon = "blank.png"
				end
				if ability_icons[name] then
					player:hud_change(ability_icons[name], "text", new_icon)
				end

				-- Jump pad
				if action == "launch" and (ctrl.aux1 or ctrl.jump) then
					local yvel = node_below.param2 / 4
					player:add_velocity({x=0, y=yvel, z=0})
					minetest.sound_play({name="glitch_abilities_jumppad", gain=0.8}, {pos=pos_below}, true)
					cooldowns[name] = COOLDOWN
					ability_used = true
				end
				-- Powerslide
				if action == "powerslide" and (not ability_used) and (ctrl.aux1 and ctrl.up and not ctrl.jump) then
					-- Powerslide!
					local yaw = player:get_look_horizontal()
					local dir = minetest.yaw_to_dir(yaw)
					local vel = vector.multiply(dir, POWERSLIDE_VELOCITY)
					player:add_velocity(vel)
					minetest.sound_play({name="glitch_abilities_powerslide", gain=0.5}, {object=player}, true)

					minetest.add_particlespawner({
						amount = 12,
						exptime = { min = 0.9, max = 1.0 },
						size = 0.8,
						time = 0.5,
						texture = {
							name = "glitch_abilities_particle_powerslide.png",
							alpha_tween = { start = 0.85, 1, 0 },
						},
						pos = { min=vector.new(-0.4, -0.4, -0.4), max=vector.new(0.4,-0.3,0.4) },
						vel = { min=vector.new(-0.1,0.01,-0.1), max=vector.new(0.1,1.2,0.1)},
						acc = { min=vector.new(0,0,0), max=vector.new(0,0,0) },
						drag = vector.new(1, 1, 1),
						attached = player,
					})

					cooldowns[name] = COOLDOWN
					ability_used = true
				end
			end
		else
			if ability_icons[name] then
				player:hud_change(ability_icons[name], "text", "blank.png")
			end
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	if not glitch_editor.is_active() and minetest.settings:get_bool("glitch_show_ability_status", true) then
		-- Show ability status icon at the bottom
		local name = player:get_player_name()
		ability_icons[name] = player:hud_add({
			hud_elem_type = "image",
			z_index = 5,
			position = { x = 0.5, y = 1 },
			scale = { x = 4, y = 4 },
			text = "blank.png",
			alignment = { x = 0, y = -1 },
			offset = { x = 0, y = -20 },
		})
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	cooldowns[name] = nil
	ability_icons[name] = nil
end)
