# ch_flashscreen

## API for showing screen flashes to players

This is used for e.g. special effects during boss fights, to cover
skybox transitions, etc.

Flash tiles that are registered internally within the mod are preloaded via node
definitions, for speed, and use ~6 node definitions per color.

The opacity of the flash effect is rounded to the nearest 1/32, instead of
the full 1/256 range, to reduce the number of tiles that need to be calculated.

### `ch_flashscreen.mktile(color, opacity)`

Get the texture string for a tile of the given color and opacity
as would be used on the screen.

- `color`: colorspec in string or table form, w/o alpha channel
- `opacity`: 0.0 to 1.0 in increments of 1/32 (rounded/clamped automatically)

### `ch_flashscreen.showflash(player, color, duration, opacity)`

Show a flash to a player, using the given color, for the given duration.
**Replaces** any previous/existing flash.

- `player`: which player to show flash to
- `color`: colorspec in string or table form, w/o alpha channel, default white
- `duration`: fade duration in seconds, default 2.0
- `opacity`: 0.0 to 1.0: initial/peak intensity of flash, default 1.0