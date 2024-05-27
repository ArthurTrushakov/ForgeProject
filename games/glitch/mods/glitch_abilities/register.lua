local F = minetest.formspec_escape
local S = minetest.get_translator("glitch_abilities")

glitch_abilities.register_ability("glitch:stepheight", {
	description = S("Super Slope Sliding"),
	explanation = S("Can slide up tall slopes"),
	-- With ability: Can climb tall slopes;
	-- without abolity: Can climb small slopes.
	activate = function(player)
		-- High enough for small+large slope;
		-- too low for climbing a slab.
		player:set_properties({stepheight = 0.4})
	end,
	deactivate = function(player)
		if not glitch_editor.is_active() then
			-- High enough for small slope;
			-- too low for tall slope and slab.
			player:set_properties({stepheight = glitch_nodeboxes.STEPHEIGHT_STEEP - 0.01})
		end
	end,
	order = 2,
})

glitch_abilities.register_ability("glitch:slide", {
	description = S("Sliding"),
	explanation = S("Can slide on flat ground and small slopes"),
	controls = S("Press Forward/Backward/Left/Right key"),
	activate = function(player)
		playerphysics.add_physics_factor(player, "speed", "ability_slide", 1)
	end,
	deactivate = function(player)
		if not glitch_editor.is_active() then
			playerphysics.add_physics_factor(player, "speed", "ability_slide", 0)
		end
	end,
	order = 1,
})
glitch_abilities.register_ability("glitch:powerslide", {
	description = S("Power-Sliding"),
	explanation = S("Can use small speed boosts on the floor"),
	controls = S("Hold down Aux1 and press Forward"),
	-- Handled in special_moves.lua
	order = 3,
})

glitch_abilities.register_ability("glitch:climb", {
	description = S("Climbing"),
	explanation = S("Can climb at certain places"),
	controls = S("Press Jump to climb up; press Sneak key to climb down"),
	needs_level_update = true,
	order = 5,
})

glitch_abilities.register_ability("glitch:jumppad", {
	description = S("Launching"),
	explanation = S("Can use launchpads"),
	controls = S("Hold down Aux1 or Jump key on a launchpad"),
	order = 4,
})
