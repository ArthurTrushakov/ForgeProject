-- LUALOCALS < ---------------------------------------------------------
local ch_colours, ch_player_api, ipairs, math, string, table, tostring
	= ch_colours, ch_player_api, ipairs, math, string, table, tostring
local math_floor, string_gsub, table_concat
	= math.floor, string.gsub, table.concat
-- LUALOCALS > ---------------------------------------------------------

local function resize(n)
	return "^[resize:" .. n .. "x" .. n
end
local function txesc(s)
	return string_gsub(string_gsub(tostring(s), "%^", "\\^"), ":", "\\:")
end

local barres = 32
local pad = 1

ch_util.register_playerstep(function(player, data)
		local meta = player:get_meta()

		local nointeract = not minetest.get_player_privs(player).interact
		local sel = nointeract and "[combine:1x1" or "hopbar_sel.png"
		if data.hudsel ~= sel then
			data.hudsel = sel
			player:hud_set_hotbar_selected_image(sel)
		end

		local colours = ch_player_api.get_colours(player)
		local list = {}
		for i, k in ipairs(ch_colours.by_num) do
			if colours[k] then list[#list + 1] = i end
		end

		local txr = {"[combine:", (#list * barres + pad * 2),
			"x", barres + pad * 2}
		for i = 1, nointeract and 0 or #list do
			txr[#txr + 1] = ":"
			txr[#txr + 1] = (i - 1) * barres + pad
			txr[#txr + 1] = ","
			txr[#txr + 1] = pad + math_floor(barres / 2)
			txr[#txr + 1] = "="
			txr[#txr + 1] = txesc(ch_colours.colour_name(list[i])
				.. ".png^[noalpha" .. resize(barres)
				.. "^[mask:hopbar_mask.png"
				.. "^[opacity:160")
		end
		if data.txr ~= txr then
			data.txr = txr
			player:hud_set_hotbar_itemcount(nointeract and 0 or #list)
			player:hud_set_hotbar_image(table_concat(txr))
		end

		local col = meta:get_int("colour")
		local wcol = nointeract and 0 or list[player:get_wield_index()] or 1
		if wcol ~= col then
			meta:set_int("colour", wcol)
			col = wcol
			ch_player_api.set_colour(player, ch_colours.colour_name(col))
		end
	end)
