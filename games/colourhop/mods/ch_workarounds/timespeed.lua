

ch_workarounds = {}
ch_workarounds.assumed_default_time_speed = 72

-- Set time_speed to what we think is default, if it has been set
minetest.after(0, function(x)
	local time_speed = minetest.settings:get("time_speed")
	local ts_string = "" .. ch_workarounds.assumed_default_time_speed

	if time_speed ~= nil and time_speed ~= ts_string then
		minetest.settings:set("time_speed", ch_workarounds.assumed_default_time_speed)
	end
end)
