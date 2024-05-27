--[[
    Builda City, a multiplayer city building game.
    Copyright (C) 2021 Quentin Quaadgras

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

    Additional Terms according section 7 of GNU/GPL V3: 

        "Builda City", "Splizard" and "Build a City" are trademarks of 
        Quentin Quaadgras. If the licensee distributes modified copies 
        of the Software then the licensee has to: Replace/remove 
        all terms, images and files containing the marks "Builda City", 
        "Splizard", "Build a City" and the Builda City logo. The copyright 
        notices within the source code files may not be removed and have 
        to be left fully intact. In addition, licensees that modify the 
        Software must give the modified Software a new name that is not 
        confusingly similar to "Builda City", "Splizard" or "Build a City" 
        and may not distribute it under the names "Builda City", "Splizard" 
        and/or "Build a City". The names "Builda City", "Splizard" and 
        "Build a City" must not be used to endorse or promote products 
        derived from this Software without prior written permission of 
        Quentin Quaadgras.
]]

--Load the guide from the file.
local guide = io.open(minetest.get_modpath("builda").."/guide.txt", "r"):read("*a")

city.guide = function(player)
    local name = player:get_player_name()
    if name == "singleplayer" then
        name = "builda"
    end

    --replace [name] with the player's name
    guide = guide:gsub("%[name%]", name)

    player:set_inventory_formspec(
        "size[8,7.2,false]"..
        "hypertext[0.5,0;4.75,8.5;guide;"..guide.."]"..
        "image[4.5,0.2;4,8;builda_guide.png]"..
        "button_exit[1.3,6.2;1.5,0.8;close;OK]"
    )
end

minetest.register_on_joinplayer(city.guide)
