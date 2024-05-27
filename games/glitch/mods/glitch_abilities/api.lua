local S = minetest.get_translator("glitch_abilities")

glitch_abilities = {}

glitch_abilities.registered_abilities = {}

--[[ Register
def: {
    description: Human-readable ability name
    explanation: Brief explanation about what this ability does
    controls: Optional explanation of the controls / how to use this ability
    needs_level_update: If true, the level nodes needs to be updated for this ability to take effect
    activate(player): (optional) Called when player receives the ability
    deactivate(player): (optional) Called when player loses the ability
    order: Number for sorting abilities in inventory screen. (lowest number comes first)
}
]]
glitch_abilities.register_ability = function(name, def)
	glitch_abilities.registered_abilities[name] = def
end

local hud_ids = {}
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	hud_ids[name] = {}
	-- background
	hud_ids[name].bgimg = player:hud_add({
		hud_elem_type = "image",
		position = { x=0.5, y=0.3 },
		scale = { x=20, y=20 },
		z_index = 90,
		text = "blank.png",
		alignment = { x=0, y=0 },
	})
	-- ability icon
	hud_ids[name].icon = player:hud_add({
		hud_elem_type = "image",
		position = { x=0.5, y=0.3 },
		scale = { x=8, y=8 },
		z_index = 100,
		text = "blank.png",
		alignment = { x=0, y=-1 },
	})
	-- message
	hud_ids[name].text = player:hud_add({
		hud_elem_type = "text",
		position = { x=0.5, y=0.3 },
		scale = { x=100, y=100 },
		size = { x=2, y=2 },
		style = 4,
		offset = { x = 0, y = 32 },

		number = 0xFF000000,
		z_index = 101,
		text = "",
		alignment = { x=0, y=1 },
	})
end)
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	hud_ids[name] = nil
end)

-- Returns the ordered list of abilities
local get_abilities_ordered = function()
	local abils = {}
	for name,_ in pairs(glitch_abilities.registered_abilities) do
		table.insert(abils, name)
	end
	local compare = function(abil1, abil2)
		local def1 = glitch_abilities.registered_abilities[abil1]
		local def2 = glitch_abilities.registered_abilities[abil2]
		local order1 = def1.order or 10000
		local order2 = def2.order or 10000
		return order1 < order2
	end
	table.sort(abils, compare)
	return abils
end

local msg_sequence_number = 0

local show_ability_message = function(player, message, icon, is_lost)
	local name = player:get_player_name()
	local ids = hud_ids[name]
	if not ids then
		return
	end
	if is_lost then
		player:hud_change(ids.bgimg, "text", "glitch_abilities_notify_lost_bg.png")
	else
		player:hud_change(ids.bgimg, "text", "glitch_abilities_notify_bg.png")
	end
	player:hud_change(ids.icon, "text", icon)
	player:hud_change(ids.text, "text", message)
	msg_sequence_number = msg_sequence_number + 1
	minetest.after(5, function(param)
		if param.seq ~= msg_sequence_number then
			return
		end
		if not param.player:is_player() then
			return
		end
		param.player:hud_change(ids.bgimg, "text", "blank.png")
		param.player:hud_change(ids.icon, "text", "blank.png")
		param.player:hud_change(ids.text, "text", "")
	end, {player=player, seq=msg_sequence_number})
end

local update_level = function(player)
	local level = glitch_levels.get_current_level(player)
	if level then
		local minpos, maxpos = glitch_levels.get_level_bounds(level)
		if minpos then
			glitch_utils.update_ability_nodes(player, minpos, maxpos)
		end
	end
end

local get_abilities_for_formspec = function(player)
	local abils = {}
	local ordered = get_abilities_ordered()
	for o=1, #ordered do
		local name = ordered[o]
		local def = glitch_abilities.registered_abilities[name]
		if glitch_abilities.has_ability(player, name) then
			table.insert(abils, {
				name = name,
				description = def.description,
				explanation = def.explanation,
				controls = def.controls,
			})
		end
	end
	return abils
end

-- Add ability to player
glitch_abilities.add_ability = function(player, ability_name, notify)
	local meta = player:get_meta()
	local def = glitch_abilities.registered_abilities[ability_name]
	if def.activate then
		def.activate(player)
	end
	-- Meta value 1 means the ability is active,
	-- 0 means it is inactive
	meta:set_int("glitch_abilities:"..ability_name, 1)
	if def.needs_level_update then
		update_level(player)
	end

	-- Report abilities to inventory formspec
	local abilities_for_formspec = get_abilities_for_formspec(player)
	glitch_inventory_formspec.set_value(player, "abilities", abilities_for_formspec)
	glitch_inventory_formspec.update(player)

	minetest.log("action", "[glitch_abilities] Player ability added to "..player:get_player_name()..": "..ability_name)
	if notify then
		show_ability_message(player, S("Ability gained:").."\n"..def.description, "glitch_abilities_icon_default.png")
		minetest.sound_play({name="glitch_abilities_ability_added", gain=1}, {to_player=player:get_player_name()}, true)
	end
end

-- Remove ability from player
glitch_abilities.remove_ability = function(player, ability_name, notify)
	local meta = player:get_meta()
	local def = glitch_abilities.registered_abilities[ability_name]
	if def.deactivate then
		def.deactivate(player)
	end
	meta:set_int("glitch_abilities:"..ability_name, 0)
	if def.needs_level_update then
		update_level(player)
	end

	local abilities_for_formspec = get_abilities_for_formspec(player)
	glitch_inventory_formspec.set_value(player, "abilities", abilities_for_formspec)
	glitch_inventory_formspec.update(player)

	minetest.log("action", "[glitch_abilities] Player ability removed from "..player:get_player_name()..": "..ability_name)
	if notify then
		show_ability_message(player, S("Ability lost:").."\n"..def.description, "glitch_abilities_icon_default_lost.png", true)
		minetest.sound_play({name="glitch_abilities_ability_lost", gain=1}, {to_player=player:get_player_name()}, true)
	end
end

-- Returns true if player has ability
glitch_abilities.has_ability = function(player, ability_name)
	local meta = player:get_meta()
	local state = meta:get_int("glitch_abilities:"..ability_name)
	return state == 1
end


minetest.register_on_joinplayer(function(player)
	-- Initialize all abilities on join
	local meta = player:get_meta()
	for aname, adef in pairs(glitch_abilities.registered_abilities) do
		local state = meta:get_int("glitch_abilities:"..aname)
		if state == 1 then
			glitch_abilities.add_ability(player, aname)
		else
			glitch_abilities.remove_ability(player, aname)
		end
	end
end)

