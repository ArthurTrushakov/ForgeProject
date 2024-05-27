
local minetest, ch_fireworks, ch_buildings, ch_ion_cannon = minetest, ch_fireworks, ch_buildings, ch_ion_cannon

ch_colours = {}

ch_colours.by_num = {
	"red",
	"yellow",
	"green",
	"blue",
	"purple",
	"black",
}
ch_colours.by_name = {}
for n, k in ipairs(ch_colours.by_num) do
	ch_colours.by_name[k] = n
	ch_colours[k] = n
end

setmetatable(ch_colours.by_num, {__index={[0] = "dummy"}})
setmetatable(ch_colours.by_name, {__index={dummy = 0}})

ch_colours.on_set_node = function(pos, by_player, delay_trigger, player_name)
	local new_node = minetest.get_node_or_nil(pos)
	if new_node == nil or new_node.name == "air" or not minetest.registered_nodes[new_node.name] then
		minetest.check_for_falling({x=pos.x, y=pos.y+1, z=pos.z})
		return
	end
	local new_name = new_node.name
	local new_def = minetest.registered_nodes[new_name]
	if new_name == "world:blue_active" or new_name == "world:purple_active" then
		local tm = minetest.get_node_timer(pos)
		tm:start(5)
	elseif new_name == "world:purple" then
		minetest.check_for_falling(pos)
	elseif new_name == "world:yellowb" or new_name == "world:yellowa" then
		local tm = minetest.get_node_timer(pos)
		tm:start(20)
	end
	if new_def.sounds and new_def.sounds.place then
		local gain = new_def.sounds.place.gain
		if not by_player then
			gain = 0.3
		end
		minetest.sound_play(new_def.sounds.place.name, {
			pos = pos,
			gain = gain,
			loop = false
		})
	end
	if new_def.trigger_on_set then
		if delay_trigger then
			minetest.after(0.1, function(pos, new_node)
				ch_colours.trigger(new_node, pos, 0, player_name)
			end, pos, new_node)
		else
			ch_colours.trigger(new_node, pos, 0, player_name)
		end
	end
end

ch_colours.remote_trigger_at = function(pos, dir, player_name)
	local node = minetest.get_node_or_nil(pos)
	if node == nil then
		return
	end
	local def = minetest.registered_nodes[node.name]
	if not def then return end
	if def.groups.green then
		if player_name and player_name ~= "" then
			if minetest.get_player_by_name(player_name) then
				ch_buildings.check_on_green(pos)
			end
		end
		return
	end
	if def.groups.black then
		return -- can't be remotely triggered
	end
	ch_colours.trigger(node, pos, dir, player_name)
end

ch_colours.cycle = function(pos, player_name)
	local old_node = minetest.get_node_or_nil(pos)
	if old_node == nil then
		return
	end
	local old_def = minetest.registered_nodes[old_node.name]
	if old_def.groups.building then
		return
	end
	if old_def.groups.red then
		minetest.set_node(pos, {name = "world:yellow"})
		ch_colours.on_set_node(pos, false, false, player_name)
	elseif old_def.groups.yellow then
		minetest.set_node(pos, {name = "world:green"})
		ch_colours.on_set_node(pos, false, false, player_name)
	elseif old_def.groups.green then
		minetest.set_node(pos, {name = "world:blue"})
		ch_colours.on_set_node(pos, false, false, player_name)
	elseif old_def.groups.blue then
		minetest.set_node(pos, {name = "world:purple"})
		ch_colours.on_set_node(pos, false, false, player_name)
	elseif old_def.groups.purple then
		minetest.set_node(pos, {name = "world:black"})
		ch_colours.on_set_node(pos, false, false, player_name)
	elseif old_def.groups.black then
		minetest.set_node(pos, {name = "world:red"})
		ch_colours.on_set_node(pos, false, false, player_name)
	end
end

local triggers = {}

ch_colours.register_trigger = function(nodename, trigger_function)
	triggers[nodename] = trigger_function
end

ch_colours.trigger = function(node, pos, dir, player_name)
	local trigger = triggers[node.name]
	if trigger then
		trigger(node, pos, dir, player_name)
	end
end
minetest.after(0, function()
	ch_colours.register_trigger("world:green",
		function(node, pos, dir, player_name)
			local a = {x = pos.x +1, y = pos.y, z = pos.z}
			local b = {x = pos.x -1, y = pos.y, z = pos.z}
			local c = {x = pos.x, y = pos.y, z = pos.z+1}
			local d = {x = pos.x, y = pos.y, z = pos.z-1}
			ch_colours.remote_trigger_at(a, 1, player_name)
			ch_colours.remote_trigger_at(b, 2, player_name)
			ch_colours.remote_trigger_at(c, 3, player_name)
			ch_colours.remote_trigger_at(d, 4, player_name)
			-- check for building activations
			ch_buildings.check_on_green(pos)
		end)
	ch_colours.register_trigger("world:blue_active",
		function(node, pos, dir, player_name)
			local meta = minetest.get_meta(pos)
			if meta:get_int("sent") == 1 then
				return
			end
			local a = {x = pos.x, y = pos.y, z = pos.z}
			if dir == 1 then
				a.x = a.x + 1
			elseif dir == 2 then
				a.x = a.x - 1
			elseif dir == 3 then
				a.z = a.z + 1
			elseif dir == 4 then
				a.z = a.z - 1
			end
			local an = minetest.get_node_or_nil(a)
			if an == nil or an.name == "air" then
				minetest.set_node(a, {name = "world:black"})
				ch_colours.on_set_node(a, false, false, player_name)
			end
		end)
	ch_colours.register_trigger("world:blue",
		function(node, pos, dir, player_name)
			minetest.set_node(pos, {name = "world:blue_active"})
			ch_colours.on_set_node(pos, false, false, player_name)

			local a = {x = pos.x +1, y = pos.y, z = pos.z}
			local b = {x = pos.x -1, y = pos.y, z = pos.z}
			local c = {x = pos.x, y = pos.y, z = pos.z+1}
			local d = {x = pos.x, y = pos.y, z = pos.z-1}
			local an = minetest.get_node_or_nil(a)
			local bn = minetest.get_node_or_nil(b)
			local cn = minetest.get_node_or_nil(c)
			local dn = minetest.get_node_or_nil(d)
			if dir == 1 and (an == nil or an.name == "air") then
				minetest.set_node(a, {name = "world:black"})
				ch_colours.on_set_node(a, false, false, player_name)
			elseif dir == 2 and (bn == nil or bn.name == "air") then
				minetest.set_node(b, {name = "world:black"})
				ch_colours.on_set_node(b, false, false, player_name)
			elseif dir == 3 and (cn == nil or cn.name == "air") then
				minetest.set_node(c, {name = "world:black"})
				ch_colours.on_set_node(c, false, false, player_name)
			elseif dir == 4 and (dn == nil or dn.name == "air") then
				minetest.set_node(d, {name = "world:black"})
				ch_colours.on_set_node(d, false, false, player_name)
			end

			minetest.after(0.3, function(pos, a, b, c, d, player_name)
				local meta = minetest.get_meta(pos)
				meta:set_int("sent", 1)
				local an = minetest.get_node_or_nil(a)
				ch_colours.remote_trigger_at(a, 1, player_name)
				ch_colours.remote_trigger_at(b, 2, player_name)
				ch_colours.remote_trigger_at(c, 3, player_name)
				ch_colours.remote_trigger_at(d, 4, player_name)
			end, pos, a, b, c, d, player_name)
		end)
	local black_cycling = function(node, pos, dir, player_name)
			if dir ~= 0 then return end
			-- Cycle color of nearby blocks
			local a = {x = pos.x +1, y = pos.y, z = pos.z}
			local b = {x = pos.x -1, y = pos.y, z = pos.z}
			local c = {x = pos.x, y = pos.y, z = pos.z+1}
			local d = {x = pos.x, y = pos.y, z = pos.z-1}
			ch_colours.cycle(a, player_name)
			ch_colours.cycle(b, player_name)
			ch_colours.cycle(c, player_name)
			ch_colours.cycle(d, player_name)
		end
	ch_colours.register_trigger("world:black", black_cycling)
	ch_colours.register_trigger("world:purple",
		function(node, pos, dir, player_name)
			local under_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
			local under_node = minetest.get_node_or_nil(under_pos)
			if under_node == nil or under_node.name == "air" then
				-- this should be impossible, but whatever..
				return
			end
			local def = minetest.registered_nodes[under_node.name]
			if def.groups.building then
				-- can't copy building
				return
			end
			if dir == 0 then
				ch_colours.purple_write(pos, nil, under_node, player_name)
			elseif dir == 1 then
				local a = {x = pos.x +1, y = pos.y, z = pos.z}
				ch_colours.purple_write(pos, a, under_node, player_name)
			elseif dir == 2 then
				local a = {x = pos.x -1, y = pos.y, z = pos.z}
				ch_colours.purple_write(pos, a, under_node, player_name)
			elseif dir == 3 then
				local a = {x = pos.x, y = pos.y, z = pos.z+1}
				ch_colours.purple_write(pos, a, under_node, player_name)
			elseif dir == 4 then
				local a = {x = pos.x, y = pos.y, z = pos.z-1}
				ch_colours.purple_write(pos, a, under_node, player_name)
			end
		end)
	ch_colours.register_trigger("world:red",
		function(node, pos, dir, player_name)
			local above_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
			local above_node = minetest.get_node_or_nil(above_pos)
			if above_node == nil or above_node.name == "air" then
				minetest.set_node(above_pos, {name = "world:black"})
				ch_colours.on_set_node(above_pos, false, false, player_name)
			else
				local def = minetest.registered_nodes[above_node.name]
				if def and def.groups.yellow and ch_buildings.only_air_above(above_pos) then
					-- Shoot rocket!
					ch_fireworks.launch(above_pos, "yellow", false, false)
					minetest.set_node(above_pos, {name = "air"})
					minetest.check_for_falling({x=above_pos.x, y=above_pos.y+1, z=above_pos.z})
				elseif def and def.groups.red then
					-- High altitude rocket?
					local above2_pos = {x = pos.x, y = pos.y + 2, z = pos.z}
					local above2_node = minetest.get_node_or_nil(above2_pos)
					if above2_node ~= nil then
						local def2 = minetest.registered_nodes[above2_node.name]
						if def2 and def2.groups.yellow and ch_buildings.only_air_above(above2_pos) then
							-- Shoot high altitude rocket!
							ch_fireworks.launch(above_pos, "red", true, false)
							minetest.set_node(above_pos, {name = "air"})
							minetest.set_node(above2_pos, {name = "air"})
							minetest.check_for_falling({x=above2_pos.x, y=above2_pos.y+1, z=above2_pos.z})
						end
					end
				elseif def and def.groups.blue then
					-- Shield breaking rocket?
					local above2_pos = {x = pos.x, y = pos.y + 2, z = pos.z}
					local above2_node = minetest.get_node_or_nil(above2_pos)
					if above2_node ~= nil then
						local def2 = minetest.registered_nodes[above2_node.name]
						if def2 and def2.groups.yellow and ch_buildings.only_air_above(above2_pos) then
							-- Shoot shield breaking rocket!
							ch_fireworks.launch(above_pos, "blue", false, true)
							minetest.set_node(above_pos, {name = "air"})
							minetest.set_node(above2_pos, {name = "air"})
							minetest.check_for_falling({x=above2_pos.x, y=above2_pos.y+1, z=above2_pos.z})
						end
					end
				elseif def and def.groups.purple then
					-- Ion Cannon?!?
					if ch_buildings.check_for_ion_cannon(pos) then
						-- Wahoo!
						ch_ion_cannon.fire(pos)
						local top1 = {x=pos.x, y=pos.y+3, z=pos.z}
						local top2 = {x=pos.x, y=pos.y+2, z=pos.z}
						local top3 = {x=pos.x, y=pos.y+1, z=pos.z}
						minetest.set_node(top1, {name = "air"})
						minetest.set_node(top2, {name = "air"})
						minetest.set_node(top3, {name = "air"})
						minetest.check_for_falling(top1)
						minetest.check_for_falling(top2)
						minetest.check_for_falling(top3)
					end
				end
			end
		end)
	ch_colours.register_trigger("world:yellow",
		function(node, pos, dir, player_name)
			minetest.set_node(pos, {name = "world:yellowa"})
			ch_colours.on_set_node(pos, false, false, player_name)
		end)
	ch_colours.register_trigger("world:yellowa",
		function(node, pos, dir, player_name)
			minetest.set_node(pos, {name = "world:yellowb"})
			ch_colours.on_set_node(pos, false, false, player_name)
		end)
	ch_colours.register_trigger("world:yellowb",
		function(node, pos, dir, player_name)
			local yellow_break_particles = {
				node = {name = "world:yellow"},
				size = 0,
				time = 0.05,
				amount = 30,
				minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
				maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
				minvel = {x = -2, y = -2, z = -2},
				maxvel = {x = 2, y = 2, z = 2},
				minacc = {x = 0, y = -5, z = 0},
				maxacc = {x = 0, y = -5, z = 0},
			}
			minetest.add_particlespawner(yellow_break_particles)
			minetest.set_node(pos, {name = "air"})
			minetest.check_for_falling({x=pos.x, y=pos.y+1, z=pos.z})
		end)
end)

ch_colours.purple_write = function(purplepos, topos, source_node, player_name)
	minetest.set_node(purplepos, {name = "world:purple_active"})
	ch_colours.on_set_node(purplepos, false, false, player_name)
	local old_node = nil
	if topos ~= nil then
		old_node = minetest.get_node_or_nil(topos)
	end
	if old_node == nil or old_node.name == "air" then
		-- trigger above and below itself
		ch_colours.remote_trigger_at({x=purplepos.x, y=purplepos.y-1, z=purplepos.z}, 0, player_name)
		ch_colours.remote_trigger_at({x=purplepos.x, y=purplepos.y+1, z=purplepos.z}, 0, player_name)
		return
	end
	local old_def = minetest.registered_nodes[old_node.name]
	if old_def.groups.building then
		return -- can't overwrite building
	end
	minetest.set_node(topos, {name = source_node.name})
	ch_colours.on_set_node(topos, false, false, player_name)
end

local baseheight = 8
local baseheight_storage = -3015
local baseheight_layer1 = -3115
local baseheight_layer2 = -3135
local baseheight_royal = -4015

ch_colours.set_and_trigger = function(player, node, pos)
	local meta = player:get_meta()
	local col = meta:get_int("colour")
	local colourname = ch_colours.colour_name(col)
	local new_name = "world:" .. colourname
	if node.name ~= new_name then
		local n = minetest.registered_nodes[node.name]
		local base = baseheight
		if pos.y < -3500 then
			base = baseheight_royal
		elseif pos.y < -3115-10 then
			base = baseheight_layer2
		elseif pos.y < -3100 then
			base = baseheight_layer1
		elseif pos.y < -3000 then
			base = baseheight_storage
		end
		if new_name == "world:yellow" and pos.y <= base-10 then
			-- can't dig that deep
			return
		end
		if new_name == "world:red" and pos.y >= base+10 then
			-- can't build that high
			return
		end
		if n.groups.building then
			-- can't modify buildings
			if new_name == "world:yellow" then
				-- Break the building?
				ch_buildings.incremental_break(node, pos, 0)
			end
			return
		end
		if new_name ~= "world:yellow" or not n.groups.yellow then
			minetest.set_node(pos, {name = new_name} )
			ch_colours.on_set_node(pos, true, false, player:get_player_name())
		end
	end
	local new_node = minetest.get_node_or_nil(pos)
	if new_node and minetest.registered_nodes[new_node.name] then
		local def = minetest.registered_nodes[new_node.name]
		-- Should we trigger it?
		if def.trigger_on_jump and new_node.name == node.name then
			ch_colours.trigger(new_node, pos, 0, player:get_player_name())
			if colourname == "red" then
				-- Send player up to new node
				local vel = player:get_velocity()
				if vel.y <= 0 then
					player:add_velocity({x=0, y=6.5, z=0})
				end
			end
		end
	end
end

ch_colours.colour_name = function(color_number)
	return ch_colours.by_num[color_number] or "green"
end


