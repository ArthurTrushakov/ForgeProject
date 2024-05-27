-- Remove pulverization command
minetest.unregister_chatcommand("pulverize")

-- Overwrite item dropping
minetest.item_drop = function(itemstack, dropper, pos)
	-- Destroy item in Editor Mode, prevent dropping in Game Mode
	if glitch_editor.is_active() then
		return ""
	else
		return itemstack
	end
end
