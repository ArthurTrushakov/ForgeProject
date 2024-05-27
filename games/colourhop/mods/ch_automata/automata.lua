local minetest = minetest

local radx=3
local rady=3
local radz=3

local function get_colour(name)
	if name == "world:yellow" or name == "world:yellowa" or name == "world:yellowb" then
		return ch_colours.yellow
	elseif name == "world:red" then
		return ch_colours.red
	elseif name == "world:blue" or name == "world:blue_active" then
		return ch_colours.blue
	elseif name == "world:green" then
		return ch_colours.green
	elseif name == "world:purple" or name == "world:purple_active" then
		return ch_colours.purple
	elseif name == "world:black" then
		return ch_colours.black
	else
		return 0
	end
end

local nn = {{x=-1,y=0,z=0}, {x=1,y=0,z=0}, {x=0,y=-1,z=0}, {x=0,y=1,z=0}, {x=0,y=0,z=-1}, {x=0,y=0,z=1}}

local function neighbours(pos, center_pos, has_rules)
	local count = 0
	local found = {}
	for _,dir in ipairs(nn) do
		local ppos = {x=pos.x+dir.x, y=pos.y+dir.y, z=pos.z+dir.z}
		local dx = pos.x - center_pos.x + dir.x
		local dy = pos.y - center_pos.y + dir.y
		local dz = pos.z - center_pos.z + dir.z
		if not (dx > radx or dx < -radx or dy > rady or dy < -rady or dz > radz or dz < -radz) then
			local node = minetest.get_node_or_nil(ppos)
			if node and node.name ~= "air" then
				local col = get_colour(node.name)
				if col ~= 0 and has_rules[col] then
					local colourname = ch_colours.colour_name(col)
					found[colourname] = (found[colourname] or 0) + 1
					count = count + 1
				end
			end
		end
	end
	return found,count
end

local function read_rules_from_row(start_pos, rules)
	local brule = false
	local current = 0
	local count = 0
	for c=0,6 do
		local node = minetest.get_node_or_nil({x=start_pos.x+c, y=start_pos.y, z=start_pos.z})
		local next = 0
		if node and node.name ~= "air" then
			next = get_colour(node.name)
		end
		if current ~= 0 and current == next then
			count = count + 1
		elseif current ~= 0 then
			-- ending the sequence
			local colourname = ch_colours.colour_name(current)
			local rule_name = colourname .. "_survival"
			if brule then
				rule_name = colourname .. "_birth"
			end
			local crules = rules[rule_name]
			if not crules then
				crules = {}
			end
			if brule then
				count = count + 1
			end
			brule = false
			crules[count] = (crules[count] or 0) + 1
			rules[rule_name] = crules
			count = 0
		end
		if next == 0 then
			brule = true
		end
		current = next
	end
	if current ~= 0 then
		-- sequnce must end then..
		local colourname = ch_colours.colour_name(current)
		local rule_name = colourname .. "_survival"
		if brule then
			rule_name = colourname .. "_birth"
		end
		local crules = rules[rule_name]
		if not crules then
			crules = {}
		end
		if brule then
			count = count + 1
		end
		crules[count] = (crules[count] or 0) + 1
		rules[rule_name] = crules
	end
	return rules
end

function ch_automata.run_automaton(bottom_center_pos, player_name)
	local read_pos = {x=bottom_center_pos.x-3, y=bottom_center_pos.y, z=bottom_center_pos.z-3}
	local rules = {}
	local has_rules = {}
	for row=0,6 do
		rules = read_rules_from_row({x=read_pos.x, y=read_pos.y, z=read_pos.z+row}, rules)
	end
	for col=1,6 do
		local colourname = ch_colours.colour_name(col)
		if rules[colourname .. "_survival"] or rules[colourname .. "_birth"] then
			has_rules[col] = true
		end
	end

	local center_pos = {x=bottom_center_pos.x, y=bottom_center_pos.y+4, z=bottom_center_pos.z}
	local minpos = {x=center_pos.x-radx, y=center_pos.y-rady, z=center_pos.z-radz}
	local maxpos = {x=center_pos.x+radx, y=center_pos.y+rady, z=center_pos.z+radz}
	local automata_nodes = minetest.find_nodes_in_area(minpos, maxpos, {"group:world", "air"}, true)

	local altered_nodes = {}

	for _,tab in pairs(automata_nodes) do
		for _,pos in pairs(tab) do
			local old_node = minetest.get_node_or_nil(pos)
			if old_node and old_node.name ~= "air" then
				-- Check survival rules
				local col = get_colour(old_node.name)
				if has_rules[col] then
					local colourname = ch_colours.colour_name(col)
					local n,nc = neighbours(pos, center_pos, has_rules)
					local crules = rules[colourname .. "_survival"]
					if not crules or not crules[nc] then
						altered_nodes[pos] = "air"
					else
						-- Check for transformation
						local pri = crules[nc] + (n[colourname] or 0)
						local biggest = colourname
						for oc=1,6 do
							if oc ~= col then
								local ocname = ch_colours.colour_name(oc)
								local orules = rules[ocname .. "_survival"]
								if orules and orules[nc] then
									local opri = orules[nc] + (n[ocname] or 0)
									if opri > pri then
										pri = opri
										biggest = ocname
									end
								end
							end
						end
						if biggest ~= colourname then
							altered_nodes[pos] = biggest
						end
					end
				end
			else
				-- Check birth rules
				local n,nc = neighbours(pos, center_pos, has_rules)
				local pri = 0
				local biggest = "air"
				for col=1,6 do
					if has_rules[col] then
						local colourname = ch_colours.colour_name(col)
						local crules = rules[colourname .. "_birth"]
						if crules and crules[nc] then
							local cpri = crules[nc] + (n[colourname] or 0)
							if cpri > pri then
								pri = cpri
								biggest = colourname
							end
						end
					end
				end
				if biggest ~= "air" then
					altered_nodes[pos] = biggest
				end
			end
		end
	end
	for pos,name in pairs(altered_nodes) do
		if name == "air" then
			minetest.set_node(pos, {name="air"})
			ch_colours.on_set_node(pos, false, true, player_name)
		else
			minetest.set_node(pos, {name="world:" .. name})
			ch_colours.on_set_node(pos, false, true, player_name)
		end
	end
end
