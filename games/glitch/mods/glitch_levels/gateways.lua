local S = minetest.get_translator("glitch_levels")

-- Hold down Aux1 while on gateway node to teleport to other level

local COLOR_OK = 0x80FF00
local COLOR_FAIL = 0xFF8080

local hud_ids = {}
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	hud_ids[name] = player:hud_add({
		hud_elem_type = "text",
		position = { x=0.5, y=0.60 },
		scale = { x=100, y=100 },
		size = { x=2, y=2 },
		style = 4,
		offset = { x = 0, y = 0 },
		number = COLOR_OK,
		z_index = 100,
		text = "",
		alignment = { x=0, y=0 },
	})
end)
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	hud_ids[name] = nil
end)

local gateways_unlocked = false

local timer = 0
minetest.register_globalstep(function(dtime)
	if glitch_editor.is_active() then
		return
	end
	timer = timer + dtime
	if timer < 1 then
		return
	end
	timer = 0

	local players = minetest.get_connected_players()
	for p=1, #players do
		local player = players[p]
		local pname = player:get_player_name()
		local is_on_gateway, gateway_no = glitch_levels.is_on_gateway(player)
		if is_on_gateway then
			local ctrl = player:get_player_control()
			local current_level = glitch_levels.get_current_level(player)

			local dest_level, dest_spawn_no = glitch_levels.get_gateway_destination(current_level, gateway_no)
			local required_electrons = glitch_levels.get_gateway_required_electrons(current_level, gateway_no)
			local actual_electrons = glitch_entities.count_collected_electrons(player, true)
			local teleported = false

			local can_use = (actual_electrons >= required_electrons) or gateways_unlocked

			if ctrl.aux1 then
				if current_level then
					if can_use then
						minetest.sound_play({name="glitch_levels_gateway", gain=1}, {object=player}, true)
						minetest.log("action", "[glitch_levels] "..pname.." takes gateway to "..tostring(dest_level).."!")
						glitch_levels.move_to_level(player, dest_level, dest_spawn_no)
						player:hud_change(hud_ids[pname], "text", "")
						teleported = true
					else
						minetest.sound_play({name="glitch_levels_gateway_fail", gain=1}, {object=player}, true)
					end
				end
			end
			if not teleported and hud_ids[pname] then
				local desc = glitch_levels.get_level_description(dest_level)
				local text = S("Gateway to @1", desc)
				if required_electrons ~= 0 then
					local req
					if gateways_unlocked then
						req = S("@1 (bypassed)", required_electrons)
					else
						req = S("@1", required_electrons)
					end
					text = text .. "\n" .. S("Electrons required: @1", req)
				end
				player:hud_change(hud_ids[pname], "text", text)
				if can_use then
					player:hud_change(hud_ids[pname], "number", COLOR_OK)
					if current_level == glitch_levels.START_LEVEL then
						text = text .. "\n" .. S("Hold down Aux1 to use the gateway")
					end
				else
					player:hud_change(hud_ids[pname], "number", COLOR_FAIL)
				end
				glitch_entities.show_electron_gui(player)
			end
		else
			player:hud_change(hud_ids[pname], "text", "")
		end
	end
end)

-- The "Unlock Gateways" cheat, all gateways can be used.
minetest.register_chatcommand("unlock_gateways", {
	description = S("Unlock (or lock) all gateways"),
	params = "[ on | off ]",
	privs = { server = true },
	func = function(name, param)
		if param == "off" then
			gateways_unlocked = false
			return true, S("The gateways are now locked and may require electrons to work.")
		elseif param == "on" or param == "" then
			gateways_unlocked = true
			return true, S("All gateways are now unlocked.")
		else
			return false
		end
	end,
})

