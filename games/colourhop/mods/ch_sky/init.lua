-- LUALOCALS < ---------------------------------------------------------
local ch_draconis, ch_flashscreen, ipairs, minetest, pairs, type,
      vector
    = ch_draconis, ch_flashscreen, ipairs, minetest, pairs, type,
      vector
-- LUALOCALS > ---------------------------------------------------------

local function gray(x) return {r = x, g = x, b = x, a = 255} end

-- Standard sky that the player starts with.
local basesky = {
	set_sky = {
		type = "regular",
		clouds = true,
		sky_color = {
			day_sky = gray(0x99),
			day_horizon = gray(0xaa),
			dawn_sky = gray(0xcc),
			dawn_horizon = gray(0xdd),
			night_sky = gray(0x22),
			night_horizon = gray(0x33),
			indoors = gray(0x44),
			fog_sun_tint = gray(0x33),
			fog_moon_tint = gray(0x2a),
			fog_tint_type = "custom"
		}
	},
	set_sun = {
		visible = true,
		texture = "ch_sky_sun.png",
		sunrise_visible = false,
	},
	set_moon = {
		visible = true,
		texture = "ch_sky_moon.png",
	},
	set_stars = {
		visible = true,
		count = 500,
		star_color = gray(0xcc),
	},
	set_clouds = {
		density = 0.4,
		color = gray(0xff),
		ambient = gray(0x11),
	}
}

local function deepcopy(t)
	if type(t) ~= "table" then return t end
	local u = {}
	for k, v in pairs(t) do u[k] = deepcopy(v) end
	return u
end

local function deepcompare(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for k, v in pairs(a) do
		if not deepcompare(v, b[k]) then return end
	end
	for k in pairs(b) do
		if a[k] == nil then return end
	end
	return true
end

-- Colors for colorizing the sky during each boss fight.
local dragon_sky = {
	-- Marundir uses a deep blue on black.
	[ch_draconis.blue_dragon] = {
		fg = "#000040",
		bg = "#000000",
		moon = "#000080"
	},
	-- Tyrirol uses a mix of clashing purples/plums/violets.
	[ch_draconis.purple_dragon] = {
		fg = "#400030",
		bg = "#080010",
		moon = "#600060"
	},
	-- Nowal has a reversed/solarized sky with deep black.
	[ch_draconis.black_dragon] = {
		fg = "#000000",
		bg = "#404040",
		moon = "#606060"
	},
}

local function checkplayer(player, data)
	local skydata

	-- Detect if we are within range of a dragon. Apply a slight
	-- histerisis to this so that we don't flash back and forth too
	-- rapidly.
	local dragon
	if ch_draconis.dragon and ch_draconis.dragon.altar_pos_x
	and ch_draconis.dragon.altar_pos_z then
		local dragonpos = {
			x = ch_draconis.dragon.altar_pos_x,
			y = 0,
			z = ch_draconis.dragon.altar_pos_z
		}
		local ppos = player:get_pos()
		ppos.y = 0
		dragon = vector.distance(ppos, dragonpos)
		< (data.dragon and 136 or 128)
		and ch_draconis.dragon.name
	end
	data.dragon = dragon

	-- If a (recognized) dragon is present, override the sky.
	-- Hide unnecessary things like sun/clouds/stars, keep
	-- (but stylize) the moon as it acts like a countdown
	-- timer for the player.
	local dcolor = dragon and dragon_sky[dragon]
	if dcolor then
		local base = "[combine:256x256^[noalpha"
		local bg = base .. "^[colorize:" .. dcolor.bg
		local fg = base .. "^[colorize:" .. dcolor.fg
		local side = fg .. "^(" .. bg .. "^[mask:ch_sky_mask.png)"
		local top = bg .. "^(" .. fg .. "^[mask:ch_sky_swirl.png)"
		skydata = {
			set_sky = {
				type = "skybox",
				textures = {
					top, bg, side, side, side, side
				},
				base_color = dcolor.fg,
				clouds = false
			},
			set_stars = {visible = false},
			set_sun = {visible = false},
			set_moon = {
				visible = true,
				texture = "ch_sky_dragon_moon.png^[multiply:" .. dcolor.moon,
			}
		}
	else
		local colours = ch_player_api.get_colours(player)
		if colours.blue then
			skydata = deepcopy(basesky)
			skydata.set_sky.sky_color.day_sky = "#61b5f5"
			skydata.set_sky.sky_color.day_horizon = "#90d3f6"
			skydata.set_sky.sky_color.dawn_sky = "#b4bafa"
			skydata.set_sky.sky_color.dawn_horizon = "#bac1f0"

		end
		if colours.purple then
			skydata = skydata or deepcopy(basesky)
			skydata.set_sky.sky_color.night_sky = "#9525ff"
			skydata.set_sky.sky_color.night_horizon = "#af5bff"
			skydata.set_stars.count = 2000
		end
		if colours.black then
			skydata = skydata or deepcopy(basesky)
			skydata.set_sun.texture = ""
			skydata.set_sun.sunrise_visible = true
			skydata.set_moon.texture = ""
			skydata.set_clouds.density = 0.3
		end
		skydata = skydata or basesky
	end

	-- Change to/from dragon causes screen flash effect.
	if not deepcompare(dcolor, data.dcolor) then
		data.dcolor = dcolor
		ch_flashscreen.showflash(player, "#ffffff", 2)
	end

	-- Apply all calculated sky effects, if they're different
	-- from previous.
	if not deepcompare(skydata, data.sky) then
		data.sky = skydata
		for k, v in pairs(skydata) do player[k](player, v) end
	end
end

do
	local cache = {}
	local function cacheget(player)
		local pname = player:get_player_name()
		local found = cache[pname]
		if found then return found end
		found = {pname = pname}
		cache[pname] = found
		return found
	end
	minetest.register_on_joinplayer(function(player)
			checkplayer(player, cacheget(player))
		end)
	minetest.register_on_leaveplayer(function(player)
			cache[player:get_player_name()] = nil
		end)
	minetest.register_globalstep(function(dtime)
			for _, player in ipairs(minetest.get_connected_players()) do
				checkplayer(player, cacheget(player))
			end
		end)
end
