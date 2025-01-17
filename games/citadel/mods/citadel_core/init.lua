-- *sigh*
-- if only i knew how to actually code

cc = "citadel_core:"
citadel = {}
citadel.schems = {"schemfinal1alt.mts", "schemfinal2alt.mts","schemfinal3.mts","schemfinal4alt.mts","schemfinal5.mts"}
citadel.ghost_data = {
	{1,{x=16.5,y=3,z=22.5},{5,6,7,8}},
	{2,{x=12.5,y=10,z=33.5},{17,18,19,20}},
	{3,{x=34.5,y=10,z=18.5},{9,10,11,12,13}},
	{3,{x=9.5,y=15,z=17.5},{22,23,24}},
	{4,{x=20,y=29,z=20},{14,15,16,21}},
	{5,{x=5,y=2,z=11},{1,2,3,4}}
 }
citadel.crystal_pos = {x=22.5, y=30.5, z = 22.5}
citadel.sounds = {
	{file="background", gain=1, offset=true},
	{file="ghost1", gain=0.6},
	{file="ghost2", gain=0.6}
}
data = minetest.get_mod_storage()


local path = minetest.get_modpath("citadel_core")
dofile(path.."/guidence.lua")
dofile(path.."/ambience.lua")
dofile(path.."/functions.lua")
dofile(path.."/nodes.lua")
dofile(path.."/stones.lua")
dofile(path.."/plants.lua")
dofile(path.."/ghost.lua")
dofile(path.."/endgame.lua")
dofile(path.."/mapgen.lua")

--hand
minetest.override_item("", {
	wield_scale = {x=1,y=1,z=2.5},
	tool_capabilities = {
		groupcaps = {
			--cracky = {times={[1]=0.1,[2]=0.1,[3]=0.1}, maxlevel=0},
			breakable = {times={[1]=0.1,[2]=0.1,[3]=0.1}, maxlevel=0}
		},
	},
	range = 3,
})
--don't drop things please
minetest.item_drop = function(itemstack, dropper, pos)
	return itemstack
end
-- --no cheating! At least not without a little bit of effort
-- minetest.registered_privileges["fly"] = nil
-- minetest.registered_privileges["noclip"] = nil
-- minetest.registered_privileges["teleport"] = nil

-- lock pulverize command behind a non-default priv to
-- prevent accidental activation, making the game unwinnable
minetest.register_privilege("pulverize", {
	description = "Can pulverize inventory items",
	give_to_singleplayer = false,
	give_to_admin = false
})

local wrap = {pulverize = true, clearinv = true}
for k, v in pairs(minetest.registered_chatcommands) do
	if wrap[k] then
		v.privs = v.privs or {}
		v.privs.pulverize = true
		minetest.override_chatcommand(k, v)
	end
end

--light level
minetest.register_on_mods_loaded(function()
	local light_level = minetest.settings:get("light_level")
	for name, def in pairs(minetest.registered_nodes) do
		minetest.override_item(name, { light_source = light_level })
	end
end)