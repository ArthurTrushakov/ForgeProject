local S = minetest.get_translator("glitch_inventory_formspec")
local F = minetest.formspec_escape
glitch_inventory_formspec = {}

local states = {}

function glitch_inventory_formspec.set_value(player, key, value)
	local name = player:get_player_name()
	if not states[name] then
		states[name] = {}
	end
	states[name][key] = value
end

local BOX_COLOR_TITLE = "#00FF004F"
local BOX_COLOR = "#00FF002F"

function glitch_inventory_formspec.update(player)
	local name = player:get_player_name()
	if glitch_editor.is_active() then
		player:set_inventory_formspec("formspec_version[6]size[14,7]list[current_player;main;1,1;10,4;]")
	else
		if not states[name] then
			player:set_inventory_formspec("")
		else
			local form = ""
			local y = 0 -- global y
			local cy = 0 -- y within a container
			local ty = 0 -- total y

			-->> BEGIN of info section <<
			form = form .. "container[3,0]"

			-- Electron counter
			local has_electron_info = states[name].electrons_total_temp or states[name].electrons_level_temp
			if has_electron_info then
				form = form .. "container[0,0.25]"
				form = form .. "box[0.25,"..cy..";5.5,1.5;"..BOX_COLOR .."]"
				form = form .. "box[0.25,"..cy..";5.5,0.5;"..BOX_COLOR_TITLE.."]"
				form = form .. "image[0.3,"..(cy+0.05)..";0.4,0.4;glitch_entities_electron_icon.png]"
				cy = cy + 0.25
				form = form .. "label[0.8,"..cy..";"..F(S("Electrons")).."]"
			end
			if states[name].electrons_total_temp and states[name].electrons_total_safe and states[name].electrons_total_game then
				cy = cy + 0.5
				local text, tt
				local extra = states[name].electrons_total_temp - states[name].electrons_total_safe
				if extra == 0 then
					text = S("Total: @1/@2", states[name].electrons_total_safe, states[name].electrons_total_game)
				else
					text = S("Total: @1+@2/@3", states[name].electrons_total_safe, extra, states[name].electrons_total_game)
				end
				form = form .. "label[1,"..cy..";"..F(text).."]"
			end
			if states[name].electrons_level_temp and states[name].electrons_level_safe and states[name].electrons_level_game then
				cy = cy + 0.5
				local text
				local extra = states[name].electrons_level_temp - states[name].electrons_level_safe
				if extra == 0 then
					text = S("This sector: @1/@2", states[name].electrons_level_safe, states[name].electrons_level_game)
				else
					text = S("This sector: @1+@2/@3", states[name].electrons_level_safe, extra, states[name].electrons_level_game)
				end
				form = form .. "label[1,"..cy..";"..F(text).."]"
			end
			if has_electron_info then
				form = form .. "container_end[]"
				y = y + cy
			end

			-- Ability list
			if states[name].abilities then
				local abils = states[name].abilities
				y = y + 1
				form = form .. "container[0,"..y.."]"
				cy = 0
				local box_height = 0.5 + 0.5 * math.max(1, #abils)
				form = form .. "box[0.25,"..cy..";5.5,"..box_height..";"..BOX_COLOR.."]"
				form = form .. "box[0.25,"..cy..";5.5,0.5;"..BOX_COLOR_TITLE .."]"
				form = form .. "image[0.3,"..(cy+0.05)..";0.4,0.4;glitch_entities_ability_icon.png]"
				cy = cy + 0.25
				form = form .. "label[0.8,"..cy..";"..F(S("Abilities")).."]"

				for a=1, #abils do
					cy = cy + 0.5
					local def = abils[a]
					form = form .. "label[1,"..cy..";"..F(def.description).."]"
					local tooltip = ""
					if def.explanation then
						tooltip = tooltip .. def.explanation
						if def.controls then
							tooltip = tooltip .. "\n" .. S("(Usage: @1)", def.controls)
						end
					end
					if tooltip ~= "" then
						form = form .. "tooltip[0.25,"..(cy-0.25)..";5.5,0.5;"..F(tooltip).."]"
					end
				end
				if #abils == 0 then
					cy = cy + 0.5
					form = form .. "label[1,"..cy..";"..F(S("None")).."]"
				end
				form = form .. "container_end[]"
				y = y + cy
			end

			-->> END of info section <<
			form = form .. "container_end[]"

			if y > 0 then
				-->> BEGIN Player icon section <<
				form = form .. "container[0.25,0.25]"
				-- Display the player face

				-- Small border
				form = form .. "box[0,0;2.5,2.5;"..BOX_COLOR.."]"
				-- Using a button element with special styling options;
				-- Makes a happy and sound face when clicked (small easter-egg)
				-- The button is purely decorative (no formspec action triggered
				form = form .. "style[player_icon;sound=glitch_player_joy]"
				form = form .. "style[player_icon:hovered,player_icon:pressed;sound=]"
				form = form .. "style[player_icon,player_icon:hovered;bgimg=glitch_player_player_front.png;bgimg_middle=0]"
				form = form .. "style[player_icon:pressed;bgimg=glitch_player_player_front_happy.png;bgimg_middle=0]"
				form = form .. "button[0.25,0.25;2,2;player_icon;]"
				-->> END of player icon section <<
				form = form .. "container_end[]"

				-- Prepend formspec header
				y = y + 0.5
				form = "formspec_version[6]size[9,"..y.."]" .. form
			end
			player:set_inventory_formspec(form)
		end
	end
end

minetest.register_on_joinplayer(function(player)
	glitch_inventory_formspec.update(player)
end)
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	states[name] = nil
end)
