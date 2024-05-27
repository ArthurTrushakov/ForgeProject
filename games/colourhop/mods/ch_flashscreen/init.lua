-- LUALOCALS < ---------------------------------------------------------
local ch_util, math, minetest, rawset, string, type
	= ch_util, math, minetest, rawset, string, type
local math_ceil, math_floor, string_format
	= math.ceil, math.floor, string.format
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()

local myapi = {}
rawset(_G, modname, myapi)

------------------------------------------------------------------------
-- Tile definition:

do
	local function clamp(x)
		if x < 0 then return 0 end
		if x > 255 then return 255 end
		return math_floor(x)
	end
	function myapi.mktile(color, qty)
		if qty <= 0 then return "[combine:1x1" end
		if type(color) == "table" then
			color = string_format("#%02x%02x%02x",
				clamp(color.r),
				clamp(color.g),
				clamp(color.b))
		end
		qty = math_ceil(qty * 32) * 8
		return "[combine:1x1^[noalpha^[colorize:" .. color .. ":255"
		.. (qty < 255 and ("^[opacity:" .. qty) or "")
	end
end

------------------------------------------------------------------------
-- Pre-create all known tiles:

-- If the client doesn't have the white flash tiles pre-loaded,
-- it has to draw them dynamically, then upload them to the GPU,
-- which can cause a noticeable framerate drop on some systems.
-- To work around this, register each as a node texture, so the
-- game should preload them during the "initializing nodes" phase
-- and have them ready to go as soon as you're in the game. This
-- should use a minimal number of node IDs, and without an
-- inventory we don't have to worry much about "creative mode".

do
	local seen = {}
	local tiles = {}
	local idx = 0
	local function flush()
		if #tiles < 1 then return end
		idx = idx + 1
		minetest.register_node(modname .. ":preload" .. idx, {
				tiles = tiles
			})
		tiles = {}
	end
	local function preload(color)
		for i = 0, 1, 1/32 do
			local tile = myapi.mktile(color, i)
			if not seen[tile] then
				seen[tile] = true
				tiles[#tiles + 1] = tile
			end
			if #tiles >= 6 then flush() end
		end
	end

	-- Colors to preload:
	preload("#ffffff") -- white = dragon arrive/leave
	preload("#ff0000") -- red = dragon damage
	preload("#ffff00") -- yellow = shield down
	preload("#0000ff") -- blue = shield regen

	flush()
end

------------------------------------------------------------------------
-- Player state loop, showflash API:

local getdata = ch_util.register_playerstep(function(player, data, dtime)
		-- Figure out which flash tile should be visible.
		local qty = 0
		if data.qty then
			qty = data.qty - data.rate * dtime
			data.qty = qty > 0 and qty or nil
		end
		local tile = myapi.mktile(data.color, qty)

		-- Display tile.
		if tile ~= data.tile then
			if data.hudid then
				player:hud_change(data.hudid, "text", tile)
			else
				data.hudid = player:hud_add({
						hud_elem_type = "image",
						position = {x = 0.5, y = 0.5},
						text = tile,
						direction = 0,
						scale = {x = -100, y = -100},
						offset = {x = 0, y = 0}
					})
			end
			data.tile = tile
		end
	end)

function myapi.showflash(player, color, duration, opacity)
	color = color or "#ffffff"
	duration = duration or 2
	opacity = opacity or 1
	local data = getdata(player)
	if opacity <= 0 or duration <= 0 then
		data.qty = nil
	else
		data.qty = opacity
		data.rate = opacity / duration
		data.color = color
	end
end
