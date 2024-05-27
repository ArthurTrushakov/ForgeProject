local hash = minetest.hash_node_position

local transform = {
	[minetest.CONTENT_AIR] = minetest.get_content_id("world:ambient"),
	[minetest.get_content_id("world:blacka")] = minetest.get_content_id("world:black"),
}

local function processblock(bpos)
	local minp = {
		x = bpos.x * 16,
		y = bpos.y * 16,
		z = bpos.z * 16
	}
	if minp.y > 3000 then return end
	local maxp = {
		x = minp.x + 15,
		y = minp.y + 15,
		z = minp.z + 15
	}
	if maxp.y > 3000 then maxp.y = 3000 end
	local vm = minetest.get_voxel_manip(minp, maxp)
	local area = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm:get_data()
	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			local offs = area:index(0, y, z)
			for x = minp.x, maxp.x do
				local i = offs + x
				local subst = transform[data[i]]
				if subst then data[i] = subst end
			end
		end
	end
	vm:set_data(data)
	vm:write_to_map()
end

local done = {}
minetest.register_abm({
	name = minetest.get_current_modname() .. ":convert_ambient",
	nodenames = {"world:blacka"},
	action = function(pos)
		pos = {
			x = math.floor(pos.x / 16),
			y = math.floor(pos.y / 16),
			z = math.floor(pos.z / 16),
		}
		local key = hash(pos)
		if done[key] then return end
		done[key] = true
		processblock(pos)
	end
})