

ch_ion_cannon = {}

texture = "[combine:144x144"
for y = 0, 128, 32 do
	texture = texture .. ":64," .. y .. "=ion_cannonp.png\\^[resize\\:16x16"
end

ch_ion_cannon.fire = function(from_pos)
	minetest.sound_play("ion_cannon", {pos=from_pos, max_hear_distance = 128, gain = 1})
	minetest.add_particlespawner({
			amount = 50,
			time = 2,
			minpos = from_pos,
			maxpos = {x = from_pos.x, y = from_pos.y + 5, z = from_pos.z},
			minvel = {x=0, y=200, z=0},
			maxvel = {x=0, y=200, z=0},
			minacc = {x = 0, y = 0, z = 0},
			maxacc = {x = 0, y = 0, z = 0},
			minexptime = 0.1,
			maxexptime = 0.1,
			minsize = 90,
			maxsize = 90,
			collisiondetection = false,
			vertical = true,
			glow = 8,
			texture = texture
	})
	ch_draconis.check_ioncannon_hit(from_pos)
end
