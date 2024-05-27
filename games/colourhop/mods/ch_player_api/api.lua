-- Minetest 0.4 mod: player
-- See README.txt for licensing and other information.

ch_player_api = {}

local S = minetest.get_translator("ch_player_api")

-- Player animation blending
-- Note: This is currently broken due to a bug in Irrlicht, leave at 0
local animation_blend = 0

ch_player_api.registered_models = { }

-- Local for speed.
local models = ch_player_api.registered_models

function ch_player_api.register_model(name, def)
	models[name] = def
end

-- Player stats and animations
local player_model = {}
local player_textures = {}
local player_anim = {}
local player_sneak = {}
ch_player_api.player_attached = {}

function ch_player_api.get_animation(player)
	local name = player:get_player_name()
	return {
		model = player_model[name],
		textures = player_textures[name],
		animation = player_anim[name],
	}
end

function ch_player_api.set_colour(player, colour)
	ch_player_api.player_attached[player:get_player_name()] = false
	ch_player_api.set_model(player, colour .. ".b3d")
	player:set_local_animation(
		{x = 0,   y = 48},
		{x = 55, y = 85},
		{x = 0,   y = 48},
		{x = 55, y = 85},
		30
	)
end

local eye_height_time = {}

-- Called when a player's appearance needs to be updated
function ch_player_api.set_model(player, model_name)
	local name = player:get_player_name()
	local model = models[model_name]
	if model then
		if player_model[name] == model_name then
			return
		end
		player:set_properties({
			mesh = model_name,
			textures = player_textures[name] or model.textures,
			visual = "mesh",
			visual_size = model.visual_size or {x = 1, y = 1},
			collisionbox = model.collisionbox or {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
			stepheight = model.stepheight or 0.6,
		})
		ch_player_api.set_animation(player, "stand")
	else
		player:set_properties({
			textures = {"player.png", "player_back.png"},
			visual = "upright_sprite",
			visual_size = {x = 1, y = 2},
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.75, 0.3},
			stepheight = 0.6,
		})
	end
	player_model[name] = model_name
	eye_height_time[name] = 0
end

local function closenuff(a, b) return math.abs(a - b) < 0.001 end
minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local model_name = player_model[name]
		local model = model_name and models[model_name]
		local eye_height = model and model.eye_height or 1.625
		local old_height = player:get_properties().eye_height
		local fulltime = dtime + (eye_height_time[name] or 0)
		local prop = 0.05 ^ fulltime
		local new_height = old_height * prop + eye_height * (1 - prop)
		if closenuff(new_height, eye_height) then
			new_height = eye_height
		end
		local avg_rtt = minetest.get_player_information(name).avg_rtt or 1
		if not closenuff(new_height, old_height) and fulltime >= avg_rtt then
			player:set_properties({eye_height = new_height})
			eye_height_time[name] = 0
		else
			eye_height_time[name] = fulltime
		end
	end
end)

function ch_player_api.set_textures(player, textures)
	local name = player:get_player_name()
	local model = models[player_model[name]]
	local model_textures = model and model.textures or nil
	player_textures[name] = textures or model_textures
	player:set_properties({textures = textures or model_textures})
end

function ch_player_api.set_animation(player, anim_name, speed)
	local name = player:get_player_name()
	if player_anim[name] == anim_name then
		return
	end
	local model = player_model[name] and models[player_model[name]]
	if not (model and model.animations[anim_name]) then
		return
	end
	local anim = model.animations[anim_name]
	player_anim[name] = anim_name
	player:set_animation(anim, speed or model.animation_speed, animation_blend)
end

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	player_model[name] = nil
	player_anim[name] = nil
	player_textures[name] = nil
	player_sneak[name] = nil
	ch_player_api.player_attached[name] = nil
end)

-- Localize for better performance.
local player_set_animation = ch_player_api.set_animation
local player_attached = ch_player_api.player_attached

-- Prevent knockback for attached players
local old_calculate_knockback = minetest.calculate_knockback
function minetest.calculate_knockback(player, ...)
	if player_attached[player:get_player_name()] then
		return 0
	end
	return old_calculate_knockback(player, ...)
end

function ch_player_api.get_colours(player)
	local colours = player:get_meta():get_string("colours")
	colours = colours and colours ~= "" and minetest.deserialize(colours, true)
	or {red = true, yellow = true, green = true}
	return colours
end

function ch_player_api.set_colours(player, colours)
	local old = ch_player_api.get_colours(player)
	for k in pairs(ch_colours.by_name) do
		if colours[k] and not old[k] then
			cmsg.push_message_player(player, S("You have learned the " ..k.." colour."))
			minetest.add_particlespawner({
				time = 2,
				amount = 100,
				minpos = {x = -2, y = 0, z = -2},
				maxpos = {x = 2, y = 3, z = 2},
				minvel = {x = 0, y = 0, z = 0},
				maxvel = {x = 0, y = 0, z = 0},
				minacc = {x = 0, y = 2, z = 0},
				maxacc = {x = 0, y = 2, z = 0},
				minexptime = 2,
				maxexptime = 2,
				minsize = 2,
				maxsize = 4,
				collisiondetection = false,
				vertical = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 9,
					aspect_h = 9,
					length = 2.25
				},
				glow = 14,
				attached = player,
				texture = "ch_player_star_"..k..".png",
			})
		end
	end
	player:get_meta():set_string("colours", minetest.serialize(colours))
end

-- Check each player and apply animations
minetest.register_globalstep(function()
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local model_name = player_model[name]
		local model = model_name and models[model_name]
		if model and not player_attached[name] then
			local controls = player:get_player_control()
			local animation_speed_mod = model.animation_speed or 30

			-- Determine if the player is sneaking, and reduce animation speed if so
			if controls.sneak then
				animation_speed_mod = animation_speed_mod / 2
			end

			-- Apply animations based on what the player is doing
			-- Determine if the player is walking
			if controls.up or controls.down or controls.left or controls.right then
				if player_sneak[name] ~= controls.sneak then
					player_anim[name] = nil
					player_sneak[name] = controls.sneak
				end
				player_set_animation(player, "walk", animation_speed_mod)
			else
				player_set_animation(player, "stand", animation_speed_mod)
			end
		end
	end
end)
