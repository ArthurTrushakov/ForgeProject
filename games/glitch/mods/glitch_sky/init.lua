glitch_sky = {}

local skies = {}

glitch_sky.set_sky = function(player, skyname)
	local sky = skies[skyname]
	if sky.sky then
		player:set_sky(sky.sky)
	end
	if sky.sun then
		player:set_sun(sky.sun)
	end
	if sky.moon then
		player:set_moon(sky.moon)
	end
	if sky.stars then
		player:set_stars(sky.stars)
	end
	if sky.clouds then
		player:set_clouds(sky.clouds)
	end
	if sky.day_night_ratio then
		player:override_day_night_ratio(sky.day_night_ratio)
	end
end

glitch_sky.register_sky = function(skyname, def)
	skies[skyname] = def
end

glitch_sky.register_sky("homeworld", {
	sky = {
		type = "regular",
		clouds = true,
		sky_color = {
			day_sky = "#4bc2f7",
			day_horizon = "#3bb2e7",
			night_sky = "#d0bd6f",
			night_horizon = "#907d2f",
			fog_moon_tint = "#00000000",
			fog_sun_tint = "#00000000",
		},
	},
	stars = {
		visible = true,
		scale = 0.5,
		count = 2000,
		color = "#ffffff80",
	},
	sun = { visible = true },
	moon = { visible = true },
	clouds = {
		density = 0.5,
		ambient = "#000000",
		height = 100,
		thickness = 4,
		color = "#ffffffe0",
	},
	day_night_ratio = 1,
})

glitch_sky.register_sky("glitchworld_green", {
	sky = {
		type = "regular",
		clouds = true,
		sky_color = {
			day_sky = "#bfffb9",
			day_horizon = "#74ff74",
			dawn_sky = "#bfffb9",
			dawn_horizon = "#74ff74",
			night_sky = "#bfffb9",
			night_horizon = "#74ff74",
			fog_sun_tint = "#74ff74",
			fog_moon_tint = "#74ff74",
			fog_tint_type = "custom",
		},
	},
	sun = { visible = false },
	moon = { visible = false },
	clouds = {
		density = 0.25,
		ambient = "#004f00c0",
		height = 170,
		thickness = 25,
		speed = { x = 10, y = 0 },
		color = "#00ff00c0",
	},
	stars = { visible = false },
	day_night_ratio = 1,
})

glitch_sky.register_sky("glitchworld_gray", {
	sky = {
		type = "regular",
		clouds = false,
		sky_color = {
			day_sky = "#bfbfbf",
			day_horizon = "#747474",
			dawn_sky = "#bfbfbf",
			dawn_horizon = "#747474",
			night_sky = "#bfbfbf",
			night_horizon = "#747474",
			fog_sun_tint = "#747474",
			fog_moon_tint = "#747474",
			fog_tint_type = "custom",
		},
	},
	sun = { visible = false },
	moon = { visible = false },
	stars = { visible = false },
	day_night_ratio = 1,
})

glitch_sky.register_sky("glitchworld_darkgreen", {
	sky = {
		type = "regular",
		clouds = true,
		sky_color = {
			day_sky = "#008f4f",
			day_horizon = "#007f3f",
			dawn_sky = "#008f4f",
			dawn_horizon = "#007f3f",
			night_sky = "#008f4f",
			night_horizon = "#007f3f",
			fog_sun_tint = "#007f3f",
			fog_moon_tint = "#007f3f",
			fog_tint_type = "custom",
		},
	},
	sun = { visible = false },
	moon = { visible = false },
	clouds = {
		density = 0.25,
		ambient = "#004f2fc0",
		height = 170,
		thickness = 25,
		speed = { x = 10, y = 0 },
		color = "#00ff88c0",
	},
	stars = { visible = false },
	day_night_ratio = 0.98,
})



glitch_sky.register_sky("glitchworld_temple", {
	sky = {
		type = "regular",
		clouds = true,
		sky_color = {
			day_sky = "#00b9b9",
			day_horizon = "#007474",
			dawn_sky = "#00b9b9",
			dawn_horizon = "#007474",
			night_sky = "#00b9b9",
			night_horizon = "#007474",
			fog_sun_tint = "#007474",
			fog_moon_tint = "#007474",
			fog_tint_type = "custom",
		},
	},
	sun = { visible = false },
	moon = { visible = false },
	clouds = {
		density = 0.35,
		ambient = "#004f4fc0",
		height = 170,
		thickness = 25,
		speed = { x = 10, y = 0 },
		color = "#00ffffc0",
	},
	stars = { visible = false },
	day_night_ratio = 0.5,
})

glitch_sky.register_sky("gray_noise", {
	sky = {
		type = "skybox",
		clouds = true,
		textures = {
			"glitch_sky_gray_noise.png",
			"glitch_sky_gray_noise.png",
			"glitch_sky_gray_noise.png",
			"glitch_sky_gray_noise.png",
			"glitch_sky_gray_noise.png",
			"glitch_sky_gray_noise.png",
		},
		base_color = "#808080",
	},
	sun = { visible = false },
	moon = { visible = false },
	clouds = {
		density = 0.75,
		height = 40,
		thickness = 5,
		speed = { x = 2, y = 0 },
		color = "#808080c0",
		ambient = "#808080c0",
	},
	stars = { visible = false },
	day_night_ratio = 1,
})

glitch_sky.register_sky("dark", {
	sky = {
		type = "regular",
		clouds = true,
		base_color = "#808080",
		sky_color = {
			day_sky = "#808080",
			day_horizon = "#808080",
			dawn_sky = "#808080",
			dawn_horizon = "#808080",
			night_sky = "#808080",
			night_horizon = "#808080",
			fog_sun_tint = "#808080",
			fog_moon_tint = "#808080",
			fog_tint_type = "custom",
		},
	},
	sun = { visible = false },
	moon = { visible = false },
	clouds = {
		density = 0.25,
		height = 108,
		thickness = 09,
		speed = { x = 0, y = 7 },
		color = "#008080c0",
		ambient = "#008080c0",
	},
	stars = { visible = false },
	day_night_ratio = 0.4,
})





minetest.register_on_joinplayer(function(player)
	glitch_sky.set_sky(player, "glitchworld_green")
end)
