-- Regularily resets the time of day to 12:00.
--
-- This mod is a hack for the sky graphics to make sure
-- the sky color does not awkwardly
-- change at "dusk" time.
--
-- Setting time_speed is not an option since this may mess with the
-- GLOBAL Minetest config.
--
-- FIXME: Remove this mod when there is a cleaner method to
-- disable sky color change at "dusk" time.

local RESET_TIME = 10
local timer = RESET_TIME

minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer >= RESET_TIME then
		minetest.set_timeofday(0.5)
		timer = 0
	end
end)
