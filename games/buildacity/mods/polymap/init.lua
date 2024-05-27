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

local S = minetest.get_translator("polymap")

minetest.register_alias("mapgen_stone", "polymap:stone")
minetest.register_alias("mapgen_water_source", "polymap:water")
minetest.register_alias("mapgen_river_water_source", "polymap:water")

minetest.register_node("polymap:grass", {
    description = "Grass",
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
})

minetest.register_node("polymap:stone", {
    description = "Stone",
    tiles = {"polymap_stone.png"},
    is_ground_content = true,
})

minetest.register_node("polymap:water", {
    description = "Water",
    tiles = {"polymap_water.png"},
    pointable = false,
    is_ground_content = true,
})

slopeslib.register_slope("polymap:grass", {
        description = S("Grass Slope"),
        pointable = false, --because selection box is ugly.
    },
    200,
    {mapgen = 0.33, place = 0.5}
)

minetest.register_biome({
    name = "grassland",
    node_top = "polymap:grass",
    depth_top = 1,
    node_filler = "polymap:grass",
    depth_filler = 1,
    node_riverbed = "polymap:grass",
    depth_riverbed = 2,
    node_dungeon = "air",
    node_dungeon_alt = "air",
    node_dungeon_stair = "air",
    y_max = 31000,
    y_min = 0,
    heat_point = 50,
    humidity_point = 35,
})