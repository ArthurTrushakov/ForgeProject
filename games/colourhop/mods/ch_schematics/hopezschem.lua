-- LUALOCALS < ---------------------------------------------------------
local error, ipairs, minetest
 = error, ipairs, minetest
-- LUALOCALS > ---------------------------------------------------------


function ch_schematics.ezschematic(key, yslices, init)
	local size = {}
	local data = {}
	local def = {}
	size.y = #yslices
	for y, ys in ipairs(yslices) do
		if size.z and size.z ~= #ys then error("inconsistent z size") end
		size.z = #ys
		for z, zs in ipairs(ys) do
			if size.x and size.x ~= #zs then error("inconsistent x size") end
			size.x = #zs
			for x = 1, zs:len() do
				local node = key[zs:sub(x, x)]
				if not node.prob or node.prob > 0 then
					if not def[node.name] then
						def[node.name] = {}
					end
					table.insert(def[node.name], {x=x, y=y, z=z})
				end
				data[(z - 1) * size.x * size.y + (y - 1) * size.x + x] = node
			end
		end
	end
	init = init or {}
	init.size = size
	init.data = data

	return minetest.register_schematic(init), size, def
end
