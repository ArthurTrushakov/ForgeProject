local ch_colours, ch_projectors, ch_draconis, ch_util, ch_automata, ch_flashscreen = ch_colours, ch_projectors, ch_draconis, ch_util, ch_automata, ch_flashscreen

ch_ability = {}

local baseheight = 8
local baseheight_storage = -3015
local baseheight_royal = -4015
ch_ability.cooldown = 1.5
ch_ability.cooldown_purple = 3
ch_ability.cooldown_blue_special = 15
ch_ability.cooldown_black_special = 15
ch_ability.cooldown_trigger = 0.3
ch_ability.cooldown_teleport = 3

local function find_height(pos)
	local base = baseheight
	if pos.y < -3500 then
		base = baseheight_royal
	elseif pos.y < -3125 then
		base = -3135
	elseif pos.y < -3100 then
		base = -3116
	elseif pos.y < -3000 then
		base = baseheight_storage
	end
	local found_height = nil
	for i=base+11,base-11,-1 do
		local n = minetest.get_node({x=pos.x, y=i, z=pos.z})
		if n == nil or n.name == "air" then
			found_height = i
		elseif n.name == "ignore" and pos.y >= -3000 then
			found_height = base+11
			break
		else
			break
		end
	end
	return found_height
end

ch_ability.teleclimb = function(player, pos)
	local meta = player:get_meta()
	local teleclimbing_already = meta:get_int("teleclimbing")
	if teleclimbing_already == 1 then
		-- stop spamming! :<
		return
	end
	meta:set_int("teleclimbing", 1)
	minetest.after(0.3, function(player, pos)
		local meta = player:get_meta()
		local col = meta:get_int("colour")
		meta:set_int("teleclimbing", 0)
		if col ~= ch_colours.green then
			return -- You are a sneek!
		end
		local found_height = find_height(pos)
		if found_height and found_height >= pos.y then
			player:set_pos({x=pos.x, y=found_height, z=pos.z})
		end
	end, player, pos)
end

ch_ability.red_beat = function(player, pos)
	local dist = 10
	if pos.y > -3000 then
		dist = ch_projectors.scan(pos)
	end
	local selected = nil
	if dist == nil or dist > 21 then
		selected = 16
	elseif dist > 18 then
		selected = 15
	elseif dist > 10 then
		selected = 10 + math.ceil((dist-10) / 2)
	else
		selected = math.floor(dist)
	end
	minetest.sound_play("red_beat_" .. selected, {
		object = player,
		gain = 1.0,
		loop = false
	})
	ch_draconis.check_red_hit(pos)
	local sv = 1 - selected / 25
	minetest.add_particlespawner({
		time = 0.1,
		amount = 60-selected*2,
		minpos = {x = -0.1, y = 0.7, z = -0.1},
		maxpos = {x = 0.1, y = 0.7, z = 0.1},
		minvel = {x = -15*sv, y = -15*sv, z = -15*sv},
		maxvel = {x = 15*sv, y = 15*sv, z = 15*sv},
		minacc = {x = -5, y = -5, z = -5},
		maxacc = {x = 5, y = 5, z = 5},
		minexptime = 2,
		maxexptime = 2,
		minsize = 1,
		maxsize = 2,
		collisiondetection = false,
		vertical = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 9,
			aspect_h = 9,
			length = 2.25
		},
		glow = 25-selected,
		attached = player,
		texture = "ch_ability_red.png",
	})
end

ch_ability.yellow_rocket = function(player, pos)
	local particle_def = {
		time = 0.9,
		amount = 30,
		minpos = {x = 0.0, y = 0.2, z = 0.0},
		maxpos = {x = 0.0, y = 0.2, z = 0.0},
		minvel = {x = -1.5, y = -3, z = -1.5},
		maxvel = {x = 1.5, y = -3, z = 1.5},
		minacc = {x = 0, y = 0, z = 0},
		maxacc = {x = 0, y = 0, z = 0},
		minexptime = 1.5,
		maxexptime = 1.5,
		minsize = 3,
		maxsize = 3,
		collisiondetection = true,
		vertical = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 9,
			aspect_h = 9,
			length = 1.6
		},
		glow = 10,
		attached = player,
		texture = "anim_white_star.png",
	}

	local under_pos = vector.round({x = pos.x, y = pos.y, z = pos.z})
	under_pos.y = under_pos.y - 1
	local node_under = minetest.get_node_or_nil(under_pos)
	if node_under and minetest.registered_nodes[node_under.name] and node_under["name"] ~= "air" then
		local def = minetest.registered_nodes[node_under.name]
		if def.groups.red then
			-- launch!
			player:add_velocity({x=0, y=30, z=0})
			-- TODO: custom animation? (transforms into a rocket shape?) hmmm..
			minetest.add_particlespawner(particle_def)
			minetest.sound_play("yellow_full", {
				object = player,
				gain = 1.0,
				loop = false
			})
			return
		end
	end
	player:add_velocity({x=0, y=8, z=0})
	local xrand = math.random(-15, 15) / 10
	local zrand = math.random(-15, 15) / 10
	particle_def.time = 0.2
	particle_def.amount = 3
	minetest.add_particlespawner(particle_def)
	minetest.sound_play("yellow_mini", {
		object = player,
		gain = 1.0,
		loop = false
	})
end

local use_exit_point = function(player, core_pos)
	if math.abs(player:get_pos().y - core_pos.y) > 100 then
		return false
	end
	local node = minetest.get_node_or_nil(core_pos)
	if node and minetest.registered_nodes[node.name] then
		local def = minetest.registered_nodes[node.name]
		if def.groups.building and def.groups.utility == 4 then
			-- Activate an exit point.
			local meta = minetest.get_meta(core_pos)
			local exit_dest = {x=0, y=11, z=0}
			if not meta:get("exit_x") then
				-- Unaligned exit point, set to ours
				local player_meta = player:get_meta()
				meta:set_int("exit_x", player_meta:get_int("entrance_x"))
				meta:set_int("exit_y", player_meta:get_int("entrance_y"))
				meta:set_int("exit_z", player_meta:get_int("entrance_z"))
			end
			exit_dest.x = meta:get_int("exit_x")
			exit_dest.z = meta:get_int("exit_z")
			player:set_pos(exit_dest)
			ch_flashscreen.showflash(player, "#000099", 3)
			minetest.sound_play("blue_normal", {
				pos = core_pos,
				gain = 1.0,
				loop = false
			})
			return true
		end
	end
	return false
end

local use_storage_point = function(player, core_pos)
	if math.abs(player:get_pos().y - core_pos.y) > 100 then
		return false
	end
	local node = minetest.get_node_or_nil(core_pos)
	if node and minetest.registered_nodes[node.name] then
		local def = minetest.registered_nodes[node.name]
		if def.groups.building and def.groups.utility == 3 then
			-- Activate a storage point.
			local meta = minetest.get_meta(core_pos)
			local storage_dest = {x=0, y=baseheight_storage+2, z=0}
			storage_dest.x = meta:get_int("storage_x")
			storage_dest.z = meta:get_int("storage_z")
			local player_meta = player:get_meta()
			player_meta:set_int("entrance_x", core_pos.x)
			player_meta:set_int("entrance_y", core_pos.y)
			player_meta:set_int("entrance_z", core_pos.z)
			player:set_pos(storage_dest)
			ch_flashscreen.showflash(player, "#000099", 3)
			minetest.sound_play("blue_normal", {
				pos = core_pos,
				gain = 1.0,
				loop = false
			})
			return true
		end
	end
	return false
end

local use_snapshot_point = function(player, core_pos)
	local node = minetest.get_node_or_nil(core_pos)
	if node and minetest.registered_nodes[node.name] then
		local def = minetest.registered_nodes[node.name]
		if def.groups.building and def.groups.utility == 2 then
			-- Activating a snapshot point!
			local meta = minetest.get_meta(core_pos)
			local snapshot = meta:get_string("snapshot")
			if snapshot and snapshot ~= "" then
				local snap_nodes = minetest.deserialize(snapshot)
				for name,tab in pairs(snap_nodes) do
					for _,pos in pairs(tab) do
						local old_node = minetest.get_node_or_nil(pos)
						local old_building = false
						local old_unchanged = false
						if old_node and minetest.registered_nodes[old_node.name] then
							local old_def = minetest.registered_nodes[old_node.name]
							old_building = old_def.groups.building
							old_unchanged = (name == old_node.name)
						end
						if not old_building and not old_unchanged then
							minetest.set_node(pos, {name=name})
						end
					end
				end
			end
			ch_buildings.destroy_building(core_pos)
			minetest.set_node(core_pos, {name="air"})
			return true
		end
	end
	return false
end

ch_ability.blue_action = function(player, pos)
	local special = false
	local teleport = false
	local under_pos = vector.round({x = pos.x, y = pos.y, z = pos.z})
	under_pos.y = under_pos.y - 1
	if use_exit_point(player, under_pos) then
		teleport = true
		special = true
	elseif use_storage_point(player, under_pos) then
		teleport = true
		special = true
	elseif use_snapshot_point(player, under_pos) then
		special = true
	end
	if not special and (pos.y < -3000 or not ch_draconis.dragon) then
		special = ch_projectors.activate_at(player, pos, false)
	end

	if special then
		minetest.sound_play("blue_special", {
			object = player,
			gain = 1.0,
			loop = false
		})
		local player_meta = player:get_meta()
		if teleport then
			player_meta:set_int("ability_cooldown", ch_ability.cooldown_teleport)
		else
			player_meta:set_int("ability_cooldown", ch_ability.cooldown_blue_special)
		end
	else
		minetest.sound_play("blue_normal", {
			object = player,
			gain = 1.0,
			loop = false
		})
	end
	ch_draconis.check_blue_hit(pos)
	minetest.add_particlespawner({
		time = 0.05,
		amount = 40,
		minpos = {x = -0.1, y = 0.7, z = -0.1},
		maxpos = {x = 0.1, y = 0.7, z = 0.1},
		minvel = {x = -15, y = -15, z = -15},
		maxvel = {x = 15, y = 15, z = 15},
		minacc = {x = -2, y = -2, z = -2},
		maxacc = {x = 2, y = 2, z = 2},
		minexptime = 2,
		maxexptime = 2,
		minsize = 1,
		maxsize = 2,
		collisiondetection = false,
		vertical = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 9,
			aspect_h = 9,
			length = 2.25
		},
		glow = 14,
		attached = player,
		texture = "ch_ability_blue.png",
	})
end

local function on_teleport(pos, is_inbound)
	local sound = "purple_teleport"
	if is_inbound then
		sound = sound .. "_in"
	else
		sound = sound .. "_out"
	end
	minetest.sound_play(sound, {
		pos = pos,
		gain = 1.0,
		loop = false
	})
	minetest.add_particlespawner({
		time = 0.1,
		amount = 30,
		minpos = {x = pos.x-0.1, y = pos.y+0.7, z = pos.z-0.1},
		maxpos = {x = pos.x+0.1, y = pos.y+0.7, z = pos.z+0.1},
		minvel = {x = -2, y = -2, z = -2},
		maxvel = {x = 2, y = 2, z = 2},
		minacc = {x = -2, y = -2, z = -2},
		maxacc = {x = 2, y = 2, z = 2},
		minexptime = 1,
		maxexptime = 1,
		minsize = 0.5,
		maxsize = 1,
		collisiondetection = false,
		vertical = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 9,
			aspect_h = 9,
			length = 2.25
		},
		glow = 14,
		texture = "ch_ability_purple.png",
	})
end

local function teleport_to(player, topos, frompos, dest_is_return_point)
	minetest.forceload_block(topos, true)
	minetest.after(0.1, function()
		local loop = false
		local teleported = false
		local dest_node = minetest.get_node(topos)
		if not dest_node or dest_node.name == "ignore" then
			teleport_to(player, topos, frompos, dest_is_return_point)
		elseif dest_node and minetest.registered_nodes[dest_node.name] then
			local meta = player:get_meta()
			if dest_is_return_point then
				local def = minetest.registered_nodes[dest_node.name]
				if def.groups.building and def.groups.utility == 1 then
					local above_point = {}
					above_point.x = topos.x
					above_point.y = topos.y+0.5
					above_point.z = topos.z
					local rounded_pos = vector.round(frompos)
					meta:set_int("return_prev_x", rounded_pos.x)
					meta:set_int("return_prev_y", rounded_pos.y)
					meta:set_int("return_prev_z", rounded_pos.z)
					player:set_pos(above_point)
					ch_flashscreen.showflash(player, "#660066", 3)
					on_teleport(frompos, false)
					on_teleport(above_point, true)
					teleported = true
				end
			else
				topos.y = topos.y+0.5
				local inside_node = minetest.get_node_or_nil(topos)
				if inside_node and inside_node.name ~= "air" then
					local found_height = find_height(topos)
					if found_height then
						topos.y = found_height
					end
				end
				player:set_pos(topos)
				on_teleport(frompos, false)
				on_teleport(topos, true)
				teleported = true
				ch_flashscreen.showflash(player, "#660066", 3)
			end
			if not teleported then
				minetest.sound_play("purple_failed", {
					object = player,
					gain = 1.0,
					loop = false
				})
			end
			minetest.forceload_free_block(topos, true)
		end
	end)
end

local use_return_point = function(player, core_pos)
	local meta = player:get_meta()
	local node = minetest.get_node_or_nil(core_pos)
	if node and minetest.registered_nodes[node.name] then
		local def = minetest.registered_nodes[node.name]
		if def.groups.building and def.groups.utility == 1 then
			local remote_usage = (vector.distance(player:get_pos(), core_pos) > 3)
			local old_point = {}
			old_point.x = meta:get_int("return_point_x")
			old_point.y = meta:get_int("return_point_y")
			old_point.z = meta:get_int("return_point_z")

			if remote_usage or (old_point.x ~= core_pos.x and old_point.y ~= core_pos and old_point.z ~= core_pos.z) then
				-- Set return point
				minetest.sound_play("purple_set", {
					object = player,
					gain = 1.0,
					loop = false
				})
				meta:set_int("return_point_x", core_pos.x)
				meta:set_int("return_point_y", core_pos.y)
				meta:set_int("return_point_z", core_pos.z)
				minetest.add_particlespawner({
					time = 0.5,
					amount = 30,
					minpos = {x = -0.1, y = 0.7, z = -0.1},
					maxpos = {x = 0.1, y = 0.7, z = 0.1},
					minvel = {x = -1, y = 3, z = -1},
					maxvel = {x = 1, y = 10, z = 1},
					minacc = {x = -5, y = -5, z = -5},
					maxacc = {x = 5, y = 5, z = 5},
					minexptime = 2,
					maxexptime = 2,
					minsize = 0.5,
					maxsize = 1,
					collisiondetection = false,
					vertical = false,
					animation = {
						type = "vertical_frames",
						aspect_w = 9,
						aspect_h = 9,
						length = 2.25
					},
					glow = 14,
					attached = player,
					texture = "ch_ability_purple.png",
				})
				return true
			end
			local prev_pos = {}
			prev_pos.x = meta:get_int("return_prev_x")
			prev_pos.y = meta:get_int("return_prev_y")
			prev_pos.z = meta:get_int("return_prev_z")
			teleport_to(player, prev_pos, player:get_pos(), false)
			return true
		end
	end
	return false
end

ch_ability.purple_return = function(player, pos)
	local meta = player:get_meta()
	local under_pos = vector.round({x = pos.x, y = pos.y, z = pos.z})
	under_pos.y = under_pos.y - 1
	if not use_return_point(player, under_pos) then
		local return_point = {}
		return_point.x = meta:get_int("return_point_x")
		return_point.y = meta:get_int("return_point_y")
		return_point.z = meta:get_int("return_point_z")
		teleport_to(player, return_point, pos, true)
	end
end

local use_automaton_lab = function(player, core_pos)
	local meta = player:get_meta()
	local node = minetest.get_node_or_nil(core_pos)
	if node and minetest.registered_nodes[node.name] then
		local def = minetest.registered_nodes[node.name]
		if def.groups.building and def.groups.lab then
			local center_pos = {x=core_pos.x, y=core_pos.y, z=core_pos.z+4}
			if def.groups.lab == 2 then
				center_pos.x = center_pos.x + 1
			elseif def.groups.lab == 3 then
				center_pos.x = center_pos.x - 1
			end
			local rx = 3
			local ry = 3
			local rz = 3
			local minpos = {x=center_pos.x-rx, y=center_pos.y+4-ry, z=center_pos.z-rz}
			local maxpos = {x=center_pos.x+rx, y=center_pos.y+4+ry, z=center_pos.z+rz}
			if def.groups.lab == 1 then
				-- run automaton on buffer
				ch_automata.run_automaton(center_pos, player:get_player_name())
			elseif def.groups.lab == 2 then
				-- paste to buffer (copy from player)
				local old_nodes = minetest.find_nodes_in_area(minpos, maxpos, {"group:world"}, false)
				for _,pos in pairs(old_nodes) do
					minetest.set_node(pos, {name="air"})
				end
				local clipboard = meta:get_string("lab_clipboard")
				if clipboard and clipboard ~= "" then
					local snap_nodes = minetest.deserialize(clipboard)
					for name,tab in pairs(snap_nodes) do
						for _,localized_pos in pairs(tab) do
							local pos = {x=localized_pos.x+center_pos.x, y=localized_pos.y+center_pos.y, z=localized_pos.z+center_pos.z}
							local old_node = minetest.get_node_or_nil(pos)
							local old_building = false
							if old_node and minetest.registered_nodes[old_node.name] then
								local old_def = minetest.registered_nodes[old_node.name]
								old_building = old_def.groups.building
							end
							if not old_building then
								minetest.set_node(pos, {name=name})
							end
						end
					end
				end
			elseif def.groups.lab == 3 then
				-- cut buffer (write to player)
				local snapshot = minetest.find_nodes_in_area(minpos, maxpos, {"group:world"}, true)
				local localized_snapshot = {}
				for name,tab in pairs(snapshot) do
					local localized_tab = {}
					for _,pos in pairs(tab) do
						minetest.set_node(pos, {name="air"})
						localized_tab[#localized_tab+1] = {x=pos.x-center_pos.x, y=pos.y-center_pos.y, z=pos.z-center_pos.z}
					end
					localized_snapshot[name] = localized_tab
				end
				meta:set_string("lab_clipboard", minetest.serialize(localized_snapshot))
			end
			return true
		end
	end
	return false
end

ch_ability.black_automaton = function(player, pos)
	local under_pos = vector.round({x = pos.x, y = pos.y, z = pos.z})
	under_pos.y = under_pos.y - 1
	if not use_automaton_lab(player, under_pos) and not ch_draconis.dragon then
		local meta = player:get_meta()
		ch_projectors.activate_at(player, pos, true)
		meta:set_int("ability_cooldown", ch_ability.cooldown_black_special)
	end
end

ch_ability.use = function(player, pos)
	local meta = player:get_meta()

	local ability_cooldown = meta:get_int("ability_cooldown")
	if ability_cooldown > 0 then
		return
	end
	meta:set_int("ability_cooldown", ch_ability.cooldown)

	local col = meta:get_int("colour")
	if col == ch_colours.green then
		return ch_ability.teleclimb(player, pos)
	elseif col == ch_colours.red then
		return ch_ability.red_beat(player, player:get_pos())
	elseif col == ch_colours.yellow then
		return ch_ability.yellow_rocket(player, player:get_pos())
	elseif col == ch_colours.blue then
		return ch_ability.blue_action(player, player:get_pos())
	elseif col == ch_colours.purple then
		meta:set_int("ability_cooldown", ch_ability.cooldown_purple)
		return ch_ability.purple_return(player, player:get_pos())
	elseif col == ch_colours.black then
		return ch_ability.black_automaton(player, player:get_pos())
	end
end

local function ability_is_ready(player, colour)
	local meta = player:get_meta()
	if meta:get_int("ability_cooldown") > 0 then return false end
	local colours = ch_player_api.get_colours(player)
	if not colours[colour] then return false end
	return true
end

minetest.after(0, function()
	local lab_trigger = function(node, pos, dir, player_name)
			local player = minetest.get_player_by_name(player_name)
			if player and ability_is_ready(player, "black") then
				if use_automaton_lab(player, pos) then
					local meta = player:get_meta()
					meta:set_int("ability_cooldown", ch_ability.cooldown_trigger)
				end
			end
		end
	ch_colours.register_trigger("buildings:automaton_lab_cut", lab_trigger)
	ch_colours.register_trigger("buildings:automaton_lab_paste", lab_trigger)
	ch_colours.register_trigger("buildings:automaton_lab_execute", lab_trigger)
	ch_colours.register_trigger("buildings:return_point", function(node, pos, dir, player_name)
			local player = minetest.get_player_by_name(player_name)
			if player and ability_is_ready(player, "purple") then
				if use_return_point(player, pos) then
					local meta = player:get_meta()
					meta:set_int("ability_cooldown", ch_ability.cooldown_purple)
				end
			end
		end)
	local blue_special_effects = function(player)
			minetest.sound_play("blue_special", {
				object = player,
				gain = 1.0,
				loop = false
			})
			minetest.add_particlespawner({
				time = 0.05,
				amount = 40,
				minpos = {x = -0.1, y = 0.7, z = -0.1},
				maxpos = {x = 0.1, y = 0.7, z = 0.1},
				minvel = {x = -15, y = -15, z = -15},
				maxvel = {x = 15, y = 15, z = 15},
				minacc = {x = -2, y = -2, z = -2},
				maxacc = {x = 2, y = 2, z = 2},
				minexptime = 2,
				maxexptime = 2,
				minsize = 1,
				maxsize = 2,
				collisiondetection = false,
				vertical = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 9,
					aspect_h = 9,
					length = 2.25
				},
				glow = 14,
				attached = player,
				texture = "ch_ability_blue.png",
			})
		end
	ch_colours.register_trigger("buildings:exit_point", function(node, pos, dir, player_name)
			local player = minetest.get_player_by_name(player_name)
			if player and ability_is_ready(player, "blue") then
				if use_exit_point(player, pos) then
					local meta = player:get_meta()
					meta:set_int("ability_cooldown", ch_ability.cooldown_blue_special)
					blue_special_effects(player)
				end
			end
		end)
	ch_colours.register_trigger("buildings:storage_point", function(node, pos, dir, player_name)
			local player = minetest.get_player_by_name(player_name)
			if player and ability_is_ready(player, "blue") then
				if use_storage_point(player, pos) then
					local meta = player:get_meta()
					meta:set_int("ability_cooldown", ch_ability.cooldown_blue_special)
					blue_special_effects(player)
				end
			end
		end)
	ch_colours.register_trigger("buildings:snapshot_point", function(node, pos, dir, player_name)
			local player = minetest.get_player_by_name(player_name)
			if player and ability_is_ready(player, "blue") then
				if use_snapshot_point(player, pos) then
					local meta = player:get_meta()
					meta:set_int("ability_cooldown", ch_ability.cooldown_blue_special)
					blue_special_effects(player)
				end
			end
		end)
end)

-- Modify "hand"
minetest.override_item("", {
	on_use = function() end,
	on_place = function(itemstack, placer, pointed_thing)
		ch_ability.use(placer, pointed_thing.under)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		ch_ability.use(user, user:get_pos())
	end,
	wield_image = "ch_hand_blank.png"
})

-- ability cooldowns
ch_util.register_playerstep(function(player, data, dtime)
	local meta = player:get_meta()
	local stored_cooldown = meta:get_int("ability_cooldown")
	if not data.ability_cooldown then
		if stored_cooldown > 0 then
			data.ability_cooldown = stored_cooldown
		end
		return
	end
	data.ability_cooldown = data.ability_cooldown - dtime
	if data.ability_cooldown <= 0 then
		meta:set_int("ability_cooldown", 0)
		data.ability_cooldown = nil
	end
end)
