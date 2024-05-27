-- LUALOCALS < ---------------------------------------------------------
local PcgRandom, VoxelArea, ipairs, math, minetest, table
	= PcgRandom, VoxelArea, ipairs, math, minetest, table
local math_floor, math_random, table_insert
	= math.floor, math.random, table.insert
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local hgapi = _G[modname]

local mapgens = {}
hgapi.registered_mapgen_shared = mapgens

local counters = {}
function hgapi.register_mapgen_shared(def)
	local label = def.label
	if not label then
		label = minetest.get_current_modname()
		local i = (counters[label] or 0) + 1
		counters[label] = i
		label = label .. ":" .. i
	end

	local prio = def.priority or 0
	def.priority = prio
	local min = 1
	local max = #mapgens + 1
	while max > min do
		local try = math_floor((min + max) / 2)
		local oldp = mapgens[try].priority
		if (prio < oldp) or (prio == oldp)
		or (prio == oldp and label > mapgens[try].label) then
			min = try + 1
		else
			max = try
		end
	end
	table_insert(mapgens, min, def)
end

local mapperlin
minetest.after(0, function() mapperlin = minetest.get_perlin(0, 1, 0, 1) end)

minetest.register_on_mapgen_init(function(mapgen_params)
	mapgen_params["flags"] = "nocaves,nodungeons"
	minetest.set_mapgen_params(mapgen_params)
	minetest.set_mapgen_setting("mgflat_spflags", "nolakes,nohills", true)
end)

local stats = {}

local function stattime(label, func)
	local start = minetest.get_us_time() / 1000000
	func()
	local finish = minetest.get_us_time() / 1000000
	local statdata = stats[label]
	if not statdata then
		statdata = {time = 0, count = 0}
		stats[label] = statdata
	end
	statdata.time = statdata.time + finish - start
	statdata.count = statdata.count + 1
end

minetest.register_on_generated(function(minp, maxp)
		local vm, emin, emax, rng

		local function lazy()
			vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
			if PcgRandom then
				local seed = mapperlin:get_3d(minp)
				seed = math_floor((seed - math_floor(seed)) * 2 ^ 32 - 2 ^ 31)
				local pcg = PcgRandom(seed)
				rng = function(a, b)
					if b then
						return pcg:next(a, b)
					elseif a then
						return pcg:next(1, a)
					end
					return (pcg:next() + 2 ^ 31) / 2 ^ 32
				end
			else
				rng = math_random
			end
		end

		for _, def in ipairs(mapgens) do
			if (def.enabled or (def.enabled == nil))
			and ((not def.ymin) or maxp.y >= def.ymin)
			and ((not def.ymax) or minp.y <= def.ymax) then
				local myminp = def.ymin and minp.y < def.ymin
				and {x = minp.x, y = def.ymin, z = minp.z} or minp
				local mymaxp = def.ymax and maxp.y > def.ymax
				and {x = maxp.x, y = def.ymax, z = maxp.z} or maxp
				if not vm then lazy() end
				stattime(
					def.label,
					function()
						return def.func(myminp, mymaxp, vm,
							rng, emin, emax)
					end)
			end
		end

		if not vm then return end

		stattime(
			"commit",
			function()
				vm:calc_lighting(minp, maxp, true)
				vm:write_to_map()
			end)
	end)

minetest.register_chatcommand("mapgenstats", {
	privs = {debug = true},
	func = function()
		local tbl = {}
		for k in pairs(stats) do tbl[#tbl + 1] = k end
		table.sort(tbl, function(a, b)
			return stats[a].time < stats[b].time
		end)
		for i = 1, #tbl do
			local k = tbl[i]
			local v = stats[k]
			tbl[i] = string.format("avg %0.5f x%04d total %0.2f %q",
				v.time / v.count, v.count, v.time, k)
		end
		return true, table.concat(tbl, "\n")
	end
})
