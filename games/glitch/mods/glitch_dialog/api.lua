local S = minetest.get_translator("glitch_dialog")
local F = minetest.formspec_escape
local MAX_OPTIONS = 4

glitch_dialog = {}

glitch_dialog.registered_speakers = {}
glitch_dialog.registered_dialogtrees = {}

local dialog_state = {}

--[[
dialogtree def: {
	speeches = {
		speech1 = <speech def> 
		speech2 = <speech def>
		...
		-- speech ID "start" is the first one
	},
	force_stay = <bool> -- if true, dialog window is forced to stay open
				-- (reopens on quitting) (default: false)
	on_exit = function(player), -- optional, called when the entire dialogtree was left.
					-- not called when the current speech has its own on_exit
}
FIXME: force-keeping a dialog open does not work reliably if you spam
the Esc key. Workaround: Don't have any required dialogues.

speech def: simple speech def or complex speech def

simple speech def: {
	speaker = <speaker id>,
	text = <text>,
	on_enter = function(player), -- optional, called when this speech is entered
	on_exit = function(player), -- optional, called when this speech is left (takes precedence over dialogtree's on_exit)

	-- Always needs at least 1 option
	options = { -- selectable dialog options (player replies) (max. 4)
		{
			text = <text>, -- default: "Continue"
			action = "quit" or "speech", -- default: "quit"
			next_speech = <speech id>, -- only if action is "speech"
		}
	},
}

speaker def: {
	name = <human-readable name>,
	portrait = <texture> or <table of textures>, -- if a table, portrait will be random
	portrait_animated = <bool>,
}
]]

glitch_dialog.register_dialogtree = function(name, def)
	glitch_dialog.registered_dialogtrees[name] = def
end
glitch_dialog.register_speaker = function(name, def)
	glitch_dialog.registered_speakers[name] = def
end

local show_single_speech = function(player, dialogtree_id, speech_id)
	local dialogtree = glitch_dialog.registered_dialogtrees[dialogtree_id]
	local speech = dialogtree.speeches[speech_id]
	if speech.on_enter then
		speech.on_enter(player)
	end
	local text = speech.text
	local options = speech.options
	local buttons = ""
	if (not options) or (options and options[1] and not options[1].text) then
		-- Continue button if no options or 1 option with no text
		buttons = buttons .. "set_focus[dialog_continue]"..
		"button[0.5,6.5;11,0.7;dialog_continue;"..F(S("Continue")).."]"
	else
		local y = 3.5
		buttons = "set_focus[dialog_1]"
		for o=1, math.min(#speech.options, MAX_OPTIONS) do
			buttons = buttons ..
			"button[0.5,"..y..";11,0.7;dialog_"..o..";"..F(options[o].text).."]"
			y = y + 1
		end
	end

	local speaker = glitch_dialog.registered_speakers[speech.speaker]
	local speaker_img
	local speaker_img_def = speaker.portrait
	if type(speaker_img_def) == "table" then
		-- Random speaker image
		speaker_img = speaker_img_def[math.random(1, #speaker_img_def)]
	else
		speaker_img = speaker_img_def
	end
	local form_image
	if speaker.portrait_animated then
		form_image = "animated_image[0.5,0.5;2,2;speaker_img;"..speaker_img..";8;200]"
	else
		form_image = "image[0.5,0.5;2,2;"..speaker_img.."]"
	end

	local form = "formspec_version[6]size[12,7.75]"..
		"position[0.5,0.95]"..
		"anchor[0.5,1]"..
		"box[0,0;3,3;#00FF004F]"..
		"box[3,0;9,3;#00FF002F]"..
		form_image..
		"label[0.5,2.75;"..F(speaker.name).."]"..
		"textarea[3.5,0.5;8,2;;;"..F(text).."]"..
		buttons
	local speech_id_formname
	if type(speech_id) == "number" then
		speech_id_formname = "__n"..tostring(speech_id)
	else
		speech_id_formname = speech_id
	end
	local formname = "glitch_dialog:speech|"..dialogtree_id.."|"..speech_id_formname
	minetest.show_formspec(player:get_player_name(), formname, form)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local start = string.sub(formname, 1, 14)
	if start ~= "glitch_dialog:" then
		return
	end
	local rest = string.sub(formname, 15)
	local splits = string.split(rest, "|")
	if not splits[1] == "speech" then
		minetest.log("error", "[glitch_speech] Invalid formname: "..formname)
		return
	end
	local dialogtree_id, speech_id = splits[2], splits[3]
	if not dialogtree_id or not speech_id then
		minetest.log("error", "[glitch_speech] Invalid formname: "..formname)
		return
	end
	if string.sub(speech_id, 1, 3) == "__n" then
		speech_id = tonumber(string.sub(speech_id, 4))
	end

	local dialogtree = glitch_dialog.registered_dialogtrees[dialogtree_id]

	-- Applies the speech options. Returns true if dialog was closed
	local function do_option_action(options, selected_option)
		if not options then
			if type(speech_id) == "number" then
				local next_speech = speech_id + 1
				if dialogtree.speeches[next_speech] then
					show_single_speech(player, dialogtree_id, next_speech)
				else
					minetest.close_formspec(player:get_player_name(), formname)
					return true
				end
			else
				minetest.close_formspec(player:get_player_name(), formname)
				return true
			end
		else
			local option = options[selected_option]
			if option.action == "speech" then
				show_single_speech(player, dialogtree_id, option.next_speech)
			else
				minetest.close_formspec(player:get_player_name(), formname)
				return true
			end
		end
		return false
	end

	if fields.dialog_continue then
		minetest.log("action", "[glitch_dialog] Player selects 'continue' option (dialogtree="..dialogtree_id..", speech="..speech_id..")")
		-- Continue button was pressed
		local speech = dialogtree.speeches[speech_id]
		if not speech then
			speech = dialogtree.speeches[tonumber(speech_id)]
		end
		if speech.on_exit then
			speech.on_exit(player)
		end
		local quit = do_option_action(speech.options, 1, speech_id)
		if quit and (not speech.on_exit) and dialogtree.on_exit then
			dialogtree.on_exit(player)
		end
	elseif fields.quit then
		-- Force dialogtree to stay open
		if dialogtree.force_stay then
			show_single_speech(player, dialogtree_id, speech_id)
		else
			local speech = dialogtree.speeches[speech_id]
			if speech.on_exit then
				speech.on_exit(player)
			elseif dialogtree.on_exit then
				dialogtree.on_exit(player)
			end
		end
		return
	else
		-- Dialog option was selected
		for o=1, MAX_OPTIONS do
			if fields["dialog_"..o] then
				minetest.log("action", "[glitch_dialog] Player selects option "..o.." (dialogtree="..dialogtree_id..", speech="..speech_id..")")
				local speech = dialogtree.speeches[speech_id]
				if speech.on_exit then
					speech.on_exit(player)
				end
				local quit = do_option_action(speech.options, o, speech_id)
				if quit and (not speech.on_exit) and dialogtree.on_exit then
					dialogtree.on_exit(player)
				end
				return
			end
		end
	end
end)

-- Show a registered dialog tree to player
glitch_dialog.show_dialogtree = function(player, dialogtree_name)
	local dialogtree = glitch_dialog.registered_dialogtrees[dialogtree_name]
	local start
	if dialogtree.speeches.start then
		start = "start"
	else
		start = 1
	end
	show_single_speech(player, dialogtree_name, start)
end


-- Show a temporary message in the HUD with a fadeout effect
-- (The "fadeout" effect is by changing the font size from big to small)
local FADEOUT_TIME_BEGIN = 3
local FADEOUT_TIME_STEP = 0.8
local FADEOUT_SIZE_START = 3
local short_message_sequence_number = 0
glitch_dialog.show_short_message = function(player, short_message, pos)
	local name = player:get_player_name()
	if not dialog_state[name] then
		dialog_state[name] = {}
	end
	local hid = player:hud_add({
		hud_elem_type = "text",
		style = 4, -- mono
		position = pos,
		size = { x = FADEOUT_SIZE_START, y = FADEOUT_SIZE_START },
		scale = { x = 100, y = 100 },
		z_level = 90,
		number = 0xFFFFFF,
		text = short_message,
	})
	local fadeout
	fadeout = function(param)
		local size = param.size
		local hud_id = param.hud_id
		if not player:is_player() then
			return
		end
		size = size - 1
		if size <= 0 then
			player:hud_remove(hud_id)
		else
			player:hud_change(hud_id, "size", {x=size, y=size})
			minetest.after(FADEOUT_TIME_STEP, fadeout, {size=size, hud_id=hud_id})
		end
	end
	minetest.after(FADEOUT_TIME_BEGIN, fadeout, {size=FADEOUT_SIZE_START, hud_id=hid})
end

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	dialog_state[name] = nil
end)
