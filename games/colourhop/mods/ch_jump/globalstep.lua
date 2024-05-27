
local minetest, ch_colours = minetest, ch_colours

local function on_jump_land(player, ppos)
	if not minetest.check_player_privs(player, "interact") then return end
	local under_pos = vector.round({x = ppos.x, y = ppos.y - 0.95, z = ppos.z})
	local node_under = minetest.get_node_or_nil(under_pos)
	if node_under and minetest.registered_nodes[node_under.name]
	and node_under.name ~= "air" then
		ch_colours.set_and_trigger(player, node_under, under_pos)
	end
end

local states = {}
function states.stand(_, data)
	if data.vel.y > 1 then
		data.state = "jump"
		data.startpos = data.oldpos.y < data.pos.y
		and data.oldpos or data.pos
	end
end
function states.jump(_, data)
	if data.vel.y == 0 and data.oldvel.y == 0 then
		data.state = "stand"
	elseif data.vel.y < 0 then
		data.state = "fall"
	end
end
function states.fall(player, data)
	if data.vel.y < 0 then return end
	data.state = "stand"
	local minpos = data.oldpos.y < data.pos.y
	and data.oldpos or data.pos
	if minpos.y <= data.startpos.y + 0.5 then
		return on_jump_land(player, minpos)
	end
end

local function handle_jump(player, data)
	local vel = player:get_velocity()
	data.oldvel = data.vel or vel
	data.vel = vel
	local pos = player:get_pos()
	data.oldpos = data.pos or pos
	data.pos = pos
	return states[data.state or "stand"](player, data)
end

do
	local cache = {}
	minetest.register_globalstep(function()
		for _, player in pairs(minetest.get_connected_players()) do
			if minetest.get_player_privs(player).interact then
				local pname = player:get_player_name()
				local data = cache[pname]
				if not data then
					data = {}
					cache[pname] = data
				end
				handle_jump(player, data)
			end
		end
	end)
	minetest.register_on_leaveplayer(function(player)
		cache[player:get_player_name()] = nil
	end)
end
