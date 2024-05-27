local S = minetest.get_translator("glitch_editor")

local is_editor_active = minetest.is_creative_enabled("")
glitch_editor = {}

-- Returns true if Editor Mode is active
glitch_editor.is_active = function()
	return is_editor_active
end

if glitch_editor.is_active() then
	minetest.register_on_joinplayer(function(player)
		player:hud_add({
			hud_elem_type = "text",
			position = { x=0, y=1 },
			scale = { x=100, y=100 },
			size = { x=2, y=2 },
			z_index = 100,
			text = S("Editor Mode"),
			number = 0x80FF00,
			alignment = { x=1, y=-1 },
			offset = { x=32, y=-32 },
			style = 4,
		})
	end)
end

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack)
	if placer and placer:is_player() then
		return glitch_editor.is_active()
	end
end)

-- Don't pick node up if the item is already in the inventory
local old_handle_node_drops = minetest.handle_node_drops
function minetest.handle_node_drops(pos, drops, digger)
	if not digger or not digger:is_player() or not glitch_editor.is_active() then
		return old_handle_node_drops(pos, drops, digger)
	end
	local inv = digger:get_inventory()
	if inv then
		for _, item in ipairs(drops) do
			if not inv:contains_item("main", item, true) then
				inv:add_item("main", item)
			end
		end
	end
end

minetest.register_tool("glitch_editor:entity_remover", {
	description = S("Entity Remover"),
	inventory_image = "glitch_editor_entity_remover.png",
	wield_image = "glitch_editor_entity_remover.png",
	groups = { disable_repair = 1 },
	on_use = function(itemstack, user, pointed_thing)
		if not glitch_editor.is_active() then
			minetest.chat_send_player(user:get_player_name(), S("This can only be used in Editor Mode!"))
			return
		end
		if pointed_thing.type == "object" then
			local obj = pointed_thing.ref
			if obj and not obj:is_player() then
				obj:remove()
			end
		end
	end,
})
