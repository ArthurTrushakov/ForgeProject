local groupcaps, range
if glitch_editor.is_active() then
	groupcaps = {
		dig_creative = { times = { [3] = 0, [2] = 0, [1] = 0 }, maxlevel = 0 },
	}
	range = 20
else
	groupcaps = {}
	range = 6
end

minetest.override_item("", {
	wield_scale = { x=1, y=1, z=2.5 },
	tool_capabilities = {
		groupcaps = groupcaps,
	},
	range = range,
})
