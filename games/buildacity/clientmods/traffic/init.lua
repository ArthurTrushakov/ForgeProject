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

local cars = {}

minetest.register_on_punchnode(function (pos, node, puncher)
    --table.insert(cars, {pos = pos, last_update=0})
end)

minetest.register_globalstep(function (dtime)
    --[[for i, car in ipairs(cars) do
        local pos = car.pos

        if cars[i].last_update > 0.1 then
            --Damn, no mesh support. GG for now.
            minetest.add_particle({
                pos = pos,
                velocity = {x = 1, y = 0, z = 0},
                acceleration = {x = 0, y = 0, z = 0},
                expirationtime = 0.1,
                size = 1,
                collisiondetection = false,
                vertical = false,
                texture = "city_white.png",
            })
            pos.x = pos.x + 1*0.1
            cars[i].last_update = 0
        end

        cars[i].last_update = cars[i].last_update + dtime
       
    end]]--
end)