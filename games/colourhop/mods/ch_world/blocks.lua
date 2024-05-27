
local S = minetest.get_translator("blocks")


minetest.register_node(":world:black", {
	description = S("Black"),
	tiles = {"black.png"},
	groups = {stone = 1, world = 1, black = 1},
	trigger_on_jump = 1,
	sounds = {
		footstep = {name = "black", gain = 0.2},
		dug = {name = "black", gain = 1.0}
	},
})
minetest.register_node(":world:blacka", {
	description = S("Black"),
	tiles = {"black.png"},
	groups = {stone = 1, world = 1, black = 1},
	trigger_on_jump = 1,
	light_source = 4,
	paramtype = "light",
	sounds = {
		footstep = {name = "black", gain = 0.2},
		dug = {name = "black", gain = 1.0}
	},
})

minetest.register_node(":world:red", {
	description = S("Red"),
	tiles = {"red.png"},
	groups = {stone = 1, world = 1, red = 1},
	trigger_on_jump = 1,
	sounds = {
		footstep = {name = "red", gain = 0.2},
		dug = {name = "red", gain = 1.0},
		place = {name = "red", gain = 1.0}
	},
})

minetest.register_node(":world:yellow", {
	description = S("Yellow"),
	tiles = {"yellow.png"},
	groups = {stone = 1, world = 1, yellow = 1},
	trigger_on_jump = 1,
	light_source = 5,
	paramtype = "light",
	sounds = {
		footstep = {name = "yellow", gain = 0.2},
		dug = {name = "yellow", gain = 1.0},
		place = {name = "yellow", gain = 1.0}
	},
})

minetest.register_node(":world:yellowa", {
	description = S("Yellow"),
	tiles = {"yellow.png^crack1.png"},
	groups = {stone = 1, world = 1, yellow = 1},
	trigger_on_jump = 1,
	light_source = 5,
	paramtype = "light",
	on_timer = function(pos, elapsed)
		minetest.set_node(pos, {name = "world:yellow"})
	end,
	sounds = {
		footstep = {name = "yellow", gain = 0.2},
		dug = {name = "yellow", gain = 1.0},
		place = {name = "yellow", gain = 1.0}
	},
})

minetest.register_node(":world:yellowb", {
	description = S("Yellow"),
	tiles = {"yellow.png^crack1.png^crack2.png"},
	groups = {stone = 1, world = 1, yellow = 1},
	trigger_on_jump = 1,
	light_source = 5,
	paramtype = "light",
	on_timer = function(pos, elapsed)
		minetest.set_node(pos, {name = "world:yellowa"})
		local tm = minetest.get_node_timer(pos)
		tm:start(20)
	end,
	sounds = {
		footstep = {name = "yellow", gain = 0.2},
		dug = {name = "yellow", gain = 1.0},
		place = {name = "yellow", gain = 1.0}
	},
})

minetest.register_node(":world:green", {
	description = S("Green"),
	tiles = {"green.png"},
	groups = {stone = 1, world = 1, green = 1},
	trigger_on_set = 1,
	trigger_on_jump = 1,
	sounds = {
		footstep = {name = "green", gain = 0.2},
		dug = {name = "green", gain = 1.0},
		place = {name = "green", gain = 1.0}
	},
})

minetest.register_node(":world:blue", {
	drawtype = "glasslike",
	use_texture_alpha = "blend",
	description = S("Blue"),
	tiles = {"blue.png"},
	groups = {stone = 1, world = 1, blue = 1},
	sunlight_propagates = true,
	paramtype = "light",
	sounds = {
		footstep = {name = "blue", gain = 0.2},
		dug = {name = "blue", gain = 1.0},
		place = {name = "blue", gain = 1.0}
	},
})

minetest.register_node(":world:blue_active", {
	drawtype = "glasslike",
	use_texture_alpha = "blend",
	description = S("Blue"),
	tiles = {"blue_active.png"},
	groups = {stone = 1, world = 1, blue = 1},
	light_source = 3,
	sunlight_propagates = true,
	paramtype = "light",
	on_timer = function(pos, elapsed)
		minetest.set_node(pos, {name = "world:blue"})
	end,
	sounds = {
		footstep = {name = "blue", gain = 0.2},
		dug = {name = "blue", gain = 1.0},
		place = {name = "blue", gain = 1.0}
	},
})

minetest.register_node(":world:purple", {
	description = S("Purple"),
	tiles = {"purple.png"},
	groups = {stone = 1, world = 1, purple = 1, falling_node = 1},
	sounds = {
		footstep = {name = "purple", gain = 0.2},
		dug = {name = "purple", gain = 1.0},
		place = {name = "purple", gain = 1.0}
	},
})

minetest.register_node(":world:purple_active", {
	description = S("Purple"),
	tiles = {"purple_active.png"},
	groups = {stone = 1, world = 1, purple = 1},
	light_source = 3,
	paramtype = "light",
	on_timer = function(pos, elapsed)
		minetest.set_node(pos, {name = "world:purple"})
	end,
	sounds = {
		footstep = {name = "purple", gain = 0.2},
		dug = {name = "purple", gain = 1.0},
		place = {name = "purple", gain = 1.0}
	},
})
