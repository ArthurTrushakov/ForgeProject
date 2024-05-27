
local S = minetest.get_translator("blocks")


minetest.register_node(":buildings:black", {
	description = S("Permanent Black"),
	tiles = {"buildings_black.png"},
	groups = {stone = 1, building = 1, darkblack = 1},
	sounds = {
		footstep = {name = "buildings_black", gain = 0.2},
		dug = {name = "buildings_black", gain = 1.0},
		place = {name = "buildings_black", gain = 1.0}
	}
})

minetest.register_node(":buildings:blacka", {
	description = S("Permanent Black"),
	tiles = {"buildings_black.png^crack1.png"},
	groups = {stone = 1, building = 1, darkblack = 1},
	sounds = {
		footstep = {name = "buildings_black", gain = 0.2},
		dug = {name = "buildings_black", gain = 1.0},
		place = {name = "buildings_black", gain = 1.0}
	}
})

minetest.register_node(":buildings:blackb", {
	description = S("Permanent Black"),
	tiles = {"buildings_black.png^crack1.png^crack2.png"},
	groups = {stone = 1, building = 1, darkblack = 1},
	sounds = {
		footstep = {name = "buildings_black", gain = 0.2},
		dug = {name = "buildings_black", gain = 1.0},
		place = {name = "buildings_black", gain = 1.0}
	}
})

minetest.register_node(":buildings:red", {
	description = S("Permanent Red"),
	tiles = {"buildings_red.png"},
	groups = {stone = 1, building = 1, darkred = 1},
	sounds = {
		footstep = {name = "buildings_red", gain = 0.2},
		dug = {name = "buildings_red", gain = 1.0},
		place = {name = "buildings_red", gain = 1.0}
	}
})

minetest.register_node(":buildings:reda", {
	description = S("Permanent Red"),
	tiles = {"buildings_red.png^crack1.png"},
	groups = {stone = 1, building = 1, darkred = 1},
	sounds = {
		footstep = {name = "buildings_red", gain = 0.2},
		dug = {name = "buildings_red", gain = 1.0},
		place = {name = "buildings_red", gain = 1.0}
	}
})

minetest.register_node(":buildings:redb", {
	description = S("Permanent Red"),
	tiles = {"buildings_red.png^crack1.png^crack2.png"},
	groups = {stone = 1, building = 1, darkred = 1},
	sounds = {
		footstep = {name = "buildings_red", gain = 0.2},
		dug = {name = "buildings_red", gain = 1.0},
		place = {name = "buildings_red", gain = 1.0}
	}
})

minetest.register_node(":buildings:yellow", {
	description = S("Permanent Yellow"),
	tiles = {"buildings_yellow.png"},
	groups = {stone = 1, building = 1, darkyellow = 1},
	light_source = 5,
	sounds = {
		footstep = {name = "buildings_yellow", gain = 0.2},
		dug = {name = "buildings_yellow", gain = 1.0},
		place = {name = "buildings_yellow", gain = 1.0}
	}
})

minetest.register_node(":buildings:yellowa", {
	description = S("Permanent Yellow"),
	tiles = {"buildings_yellow.png^crack1.png"},
	groups = {stone = 1, building = 1, darkyellow = 1},
	light_source = 5,
	sounds = {
		footstep = {name = "buildings_yellow", gain = 0.2},
		dug = {name = "buildings_yellow", gain = 1.0},
		place = {name = "buildings_yellow", gain = 1.0}
	}
})

minetest.register_node(":buildings:yellowb", {
	description = S("Permanent Yellow"),
	tiles = {"buildings_yellow.png^crack1.png^crack2.png"},
	groups = {stone = 1, building = 1, darkyellow = 1},
	light_source = 5,
	sounds = {
		footstep = {name = "buildings_yellow", gain = 0.2},
		dug = {name = "buildings_yellow", gain = 1.0},
		place = {name = "buildings_yellow", gain = 1.0}
	}
})

minetest.register_node(":buildings:green", {
	description = S("Permanent Green"),
	tiles = {"buildings_green.png"},
	groups = {stone = 1, building = 1, darkgreen = 1},
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:greena", {
	description = S("Permanent Green"),
	tiles = {"buildings_green.png^crack1.png"},
	groups = {stone = 1, building = 1, darkgreen = 1},
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:greenb", {
	description = S("Permanent Green"),
	tiles = {"buildings_green.png^crack1.png^crack2.png"},
	groups = {stone = 1, building = 1, darkgreen = 1},
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:blue", {
	drawtype = "glasslike",
	use_texture_alpha = "blend",
	description = S("Permanent Blue"),
	tiles = {"buildings_blue.png"},
	groups = {stone = 1, building = 1, darkblue = 1},
	paramtype = "light",
	sunlight_propagates = true,
	sounds = {
		footstep = {name = "buildings_blue", gain = 0.2},
		dug = {name = "buildings_blue", gain = 1.0},
		place = {name = "buildings_blue", gain = 1.0}
	}
})

minetest.register_node(":buildings:bluea", {
	drawtype = "glasslike",
	use_texture_alpha = "blend",
	description = S("Permanent Blue"),
	tiles = {"buildings_blue.png^crack1.png"},
	groups = {stone = 1, building = 1, darkblue = 1},
	paramtype = "light",
	sunlight_propagates = true,
	sounds = {
		footstep = {name = "buildings_blue", gain = 0.2},
		dug = {name = "buildings_blue", gain = 1.0},
		place = {name = "buildings_blue", gain = 1.0}
	}
})

minetest.register_node(":buildings:blueb", {
	drawtype = "glasslike",
	use_texture_alpha = "blend",
	description = S("Permanent Blue"),
	tiles = {"buildings_blue.png^crack1.png^crack2.png"},
	groups = {stone = 1, building = 1, darkblue = 1},
	paramtype = "light",
	sunlight_propagates = true,
	sounds = {
		footstep = {name = "buildings_blue", gain = 0.2},
		dug = {name = "buildings_blue", gain = 1.0},
		place = {name = "buildings_blue", gain = 1.0}
	}
})

minetest.register_node(":buildings:purple", {
	description = S("Permanent Purple"),
	tiles = {"buildings_purple.png"},
	groups = {stone = 1, building = 1, darkpurple = 1},
	sounds = {
		footstep = {name = "buildings_purple", gain = 0.2},
		dug = {name = "buildings_purple", gain = 1.0},
		place = {name = "buildings_purple", gain = 1.0}
	}
})

minetest.register_node(":buildings:purplea", {
	description = S("Permanent Purple"),
	tiles = {"buildings_purple.png^crack1.png"},
	groups = {stone = 1, building = 1, darkpurple = 1},
	sounds = {
		footstep = {name = "buildings_purple", gain = 0.2},
		dug = {name = "buildings_purple", gain = 1.0},
		place = {name = "buildings_purple", gain = 1.0}
	}
})

minetest.register_node(":buildings:purpleb", {
	description = S("Permanent Purple"),
	tiles = {"buildings_purple.png^crack1.png^crack2.png"},
	groups = {stone = 1, building = 1, darkpurple = 1},
	sounds = {
		footstep = {name = "buildings_purple", gain = 0.2},
		dug = {name = "buildings_purple", gain = 1.0},
		place = {name = "buildings_purple", gain = 1.0}
	}
})

minetest.register_node(":buildings:altar1", {
	description = S("Altar Beacon"),
	tiles = {"buildings_altar1.png"},
	groups = {stone = 1, building = 1, altar = 1},
	light_source = 3,
	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		minetest.sound_play("altar", {
			pos = pos,
			gain = 1.0,
			max_hear_distance = 128,
			loop = false,
		})
		local altar1_particles = {
			time = 0.3,
			amount = 15,
			texture = "buildings_altar1p.png",
			minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
			maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
			minvel = {x = -2, y = -2, z = -2},
			maxvel = {x = 2, y = 2, z = 2},
			minacc = {x = 0, y = 5, z = 0},
			maxacc = {x = 0, y = 5, z = 0},
			glow = 10
		}
		local total_elapsed = meta:get_int("total_elapsed") + elapsed
		local tod = minetest.get_timeofday()
		minetest.add_particlespawner(altar1_particles)
		local tm = minetest.get_node_timer(pos)
		tm:start(10)
		if meta:get_int("spawned") == 1 then
			meta:set_int("total_elapsed", 0)
			if tod > 0.19 and tod < 0.77 then
				meta:set_int("spawned", 0)
			end
			return
		end
		if ch_draconis.dragon ~= nil or ch_draconis.dragon_spawning == 1 then
			-- we only allow one dragon at a time
			meta:set_int("spawned", 1)
			return
		end
		if total_elapsed > 100 and tod < 0.1  and tod >= 0 then
			cmsg.push_message_all(S("Blue dragon, Marundir, has arrived!"))
			ch_draconis.spawn_dragon({x = pos.x, y = pos.y, z = pos.z}, ch_draconis.blue_dragon)
			meta:set_int("spawned", 1)
		end
		meta:set_int("total_elapsed", total_elapsed)
	end,
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:altar2", {
	description = S("Altar Beacon"),
	tiles = {"buildings_altar2.png"},
	groups = {stone = 1, building = 1, altar = 2},
	light_source = 3,
	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		minetest.sound_play("altar", {
			pos = pos,
			gain = 1.0,
			max_hear_distance = 128,
			loop = false,
		})
		local altar1_particles = {
			time = 0.3,
			amount = 15,
			texture = "buildings_altar2p.png",
			minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
			maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
			minvel = {x = -2, y = -2, z = -2},
			maxvel = {x = 2, y = 2, z = 2},
			minacc = {x = 0, y = 5, z = 0},
			maxacc = {x = 0, y = 5, z = 0},
			glow = 10
		}
		local total_elapsed = meta:get_int("total_elapsed") + elapsed
		minetest.add_particlespawner(altar1_particles)
		local tm = minetest.get_node_timer(pos)
		tm:start(13)
		local tod = minetest.get_timeofday()
		if meta:get_int("spawned") == 1 then
			meta:set_int("total_elapsed", 0)
			if tod > 0.19 and tod < 0.77 then
				meta:set_int("spawned", 0)
			end
			return
		end
		if ch_draconis.dragon ~= nil or ch_draconis.dragon_spawning == 1 then
			-- we only allow one dragon at a time
			meta:set_int("spawned", 1)
			return
		end
		if total_elapsed > 150 and tod > 0.84 then
			cmsg.push_message_all(S("Purple dragon, Tyriral, has arrived!"))
			ch_draconis.spawn_dragon({x = pos.x, y = pos.y, z = pos.z}, ch_draconis.purple_dragon)
			meta:set_int("spawned", 1)
		end
		meta:set_int("total_elapsed", total_elapsed)
	end,
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:altar3", {
	description = S("Altar Beacon"),
	tiles = {"buildings_altar3.png"},
	groups = {stone = 1, building = 1, altar = 3},
	light_source = 3,
	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		minetest.sound_play("altar", {
			pos = pos,
			gain = 1.0,
			max_hear_distance = 128,
			loop = false,
		})
		local altar1_particles = {
			time = 0.3,
			amount = 15,
			texture = "buildings_altar3p.png",
			minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
			maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
			minvel = {x = -2, y = -2, z = -2},
			maxvel = {x = 2, y = 2, z = 2},
			minacc = {x = 0, y = 5, z = 0},
			maxacc = {x = 0, y = 5, z = 0},
			glow = 10
		}
		local total_elapsed = meta:get_int("total_elapsed") + elapsed
		minetest.add_particlespawner(altar1_particles)
		local tm = minetest.get_node_timer(pos)
		tm:start(13)
		local tod = minetest.get_timeofday()
		if meta:get_int("spawned") == 1 then
			meta:set_int("total_elapsed", 0)
			if tod > 0.19 and tod < 0.77 then
				meta:set_int("spawned", 0)
			end
			return
		end
		if ch_draconis.dragon ~= nil or ch_draconis.dragon_spawning == 1 then
			-- we only allow one dragon at a time
			meta:set_int("spawned", 1)
			return
		end
		if total_elapsed > 150 and tod > 0.84 then
			cmsg.push_message_all(S("Black dragon, Nowal, has arrived!"))
			ch_draconis.spawn_dragon({x = pos.x, y = pos.y, z = pos.z}, ch_draconis.black_dragon)
			meta:set_int("spawned", 1)
		end
		meta:set_int("total_elapsed", total_elapsed)
	end,
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:return_point", {
	description = S("Return Point"),
	tiles = {"buildings_return_point.png"},
	groups = {stone = 1, building = 1, utility = 1},
	light_source = 3,
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:snapshot_point", {
	description = S("Snapshot Point"),
	tiles = {
			{
				name = "buildings_snapshot_point.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0,
				},
			},
		},
	groups = {stone = 1, building = 1, utility = 2},
	light_source = 3,
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:storage_point", {
	description = S("Storage Point"),
	tiles = {"buildings_storage_point.png"},
	groups = {stone = 1, building = 1, utility = 3},
	light_source = 3,
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:exit_point", {
	description = S("Exit Point"),
	tiles = {"buildings_exit_point.png"},
	groups = {stone = 1, building = 1, utility = 4},
	light_source = 4,
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:automaton_lab_cut", {
	description = S("Lab Block Cut"),
	tiles = {"buildings_lab_cut.png"},
	groups = {stone = 1, building = 1, lab = 3},
	light_source = 4,
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:automaton_lab_paste", {
	description = S("Lab Block Paste"),
	tiles = {"buildings_lab_paste.png"},
	groups = {stone = 1, building = 1, lab = 2},
	light_source = 4,
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})

minetest.register_node(":buildings:automaton_lab_execute", {
	description = S("Lab Block Execute"),
	tiles = {"buildings_lab_execute.png"},
	groups = {stone = 1, building = 1, utility = 5, lab = 1},
	light_source = 4,
	sounds = {
		footstep = {name = "buildings_green", gain = 0.2},
		dug = {name = "buildings_green", gain = 1.0},
		place = {name = "buildings_green", gain = 1.0}
	}
})
