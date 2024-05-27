local nodename = "world:ambient"

local def = {}
for k, v in pairs(minetest.registered_nodes.air) do
	def[k] = v
end
def.light_source = 4
minetest.register_node(":" .. nodename, def)

-- Hack to make all get/set/swap node opertions treat world:ambient
-- exactly like ordinary air automatically, so we don't need to
-- adjust a whole bunch of logic elsewhere and check for y value
-- in every other mod.  This does NOT cover schematics or mapgen
-- hooks so those need to be smarter, but it should cover everything
-- else.

do
	local function tweak(node, ...)
		if node and node.name == nodename then
			node.name = "air"
		end
		return node, ...
	end
	for k in pairs({get_node = true, get_node_or_nil = true}) do
		local oldget = minetest[k]
		minetest[k] = function(pos, ...)
			return tweak(oldget(pos, ...))
		end
	end
end

for k in pairs({set_node = true, swap_node = true}) do
	local oldfunc = minetest[k]
	minetest[k] = function(pos, node, ...)
		if node.name == "air" and pos.y < -3000 then
			local function helper(...)
				node.name = "air"
				return ...
			end
			node.name = nodename
			return helper(oldfunc(pos, node, ...))
		end
		return oldfunc(pos, node, ...)
	end
end

function minetest.remove_node(pos)
	return minetest.set_node(pos, {name = "air"})
end