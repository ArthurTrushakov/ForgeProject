local S = minetest.get_translator("glitch_dialog")
local F = minetest.formspec_escape

-- The address to which the player character wants to go
local DESTINATION_ADDRESS = "2001:495:f0dc:4::493" -- an IPv6 address
-- A wrong address
local DESTINATION_ADDRESS_FALSE = "9304::400:dcf0:9504:120" -- the bytes are flipped (little vs big endian :D )


-- Short speaker IDs (for less typing)
local PLA = "glitch:player"
local HVO = "glitch:helper_void"
local HGW = "glitch:helper_gateway"
local HSZ = "glitch:helper_savezone"
local HDD = "glitch:helper_distortion_denier"
local HDW = "glitch:helper_distortion_worrier"
local MPS = "glitch:master_powerslide"
local MTS = "glitch:master_tallslope"
local MJP = "glitch:master_jumppad"
local MCL = "glitch:master_climb"
local WNS = "glitch:white_noise"
local WNU = "glitch:white_noise_unknown"
local SYS = "glitch:system"
local INF = "glitch:info"

-- Helper functions to create bulk of messages with less syntax
local function unwrap_speech_exchange(prefix, speaker1, speaker2, texts, end_options, first_is_start)
	local speeches = {}
	local exchange_id = 1
	for t=1, #texts do
		local text = texts[t]
		local speaker
		if t % 2 == 1 then -- speaker 1
			speaker = speaker1
		else
			speaker = speaker2
		end
		local id
		if t==1 and first_is_start then
			id = "start"
		else
			id = prefix.."_"..tostring(exchange_id)
		end
		speeches[id] = {
			text = text,
			speaker = speaker,
		}
		if t < #texts then
			speeches[id].options = {{ action = "speech", next_speech = prefix.."_"..tostring(exchange_id+1) }}
		else
			speeches[id].options = end_options
		end
		exchange_id = exchange_id + 1
	end
	return speeches
end
local function merge_speech_tables(tables)
	local out = {}
	for t=1, #tables do
		local tabl = tables[t]
		for k,v in pairs(tabl) do
			out[k] = v
		end
	end
	return out
end


-- After One falls into the garbage dump
glitch_dialog.register_dialogtree("glitch:after_dump", {
	force_stay = true,
	speeches = {
		{
			speaker = PLA,
			text = S("What … what happened?"),
		},
		{
			speaker = PLA,
			text = S("Where am I? And what was I just doing before?"),
		},
		{
			speaker = PLA,
			text = S("Oh, I remember! I was in the packet serial number 40054904110923 on the way to IP @1. Business as usual.", DESTINATION_ADDRESS),
		},
		{
			speaker = PLA,
			text = S("But this doesn’t look like @1 at all. It doesn’t even look close to it! Hmm, that has never happened before … But to be fair, I’m new at my job.", DESTINATION_ADDRESS),
		},
		{
			speaker = PLA,
			text = S("Oh wait! Could it be that I am a victim of ’packet loss’ that they told me in school? But that would mean … Nah, that’s probably just a fairytale to scare young kids. Better not think about it."),
		},
		{
			speaker = PLA,
			text = S("There is probably a logical explanation to all of this. I should look around."),
		},
		{
			speaker = INF,
			text = S("You have the ability to slide on flat ground and small slopes. Use the movement keys to slide. Use the “Place” key to communicate."),
			on_exit = function(player)
				local after = function()
					glitch_ambience.set_ambience(player, "music_eerie_mausoleum")
				end
				glitch_logo.show_logo(player, after)
			end,
		},

	}
})

-- Failure to jump
glitch_dialog.register_dialogtree("glitch:nojump", {
	speeches = {
		{
			speaker = PLA,
			text = S("Nope, I can’t jump. I’m a bit, not assembler code."),
		},
	}
})

local helper_void_intro_texts = {
	S("Umm … hello?"),
	S("Gasp! Who are you? And what are you doing here?!"),
	S("I was just about to ask you the same thing."),
	S("This isn’t good, this isn’t good, this isn’t good …"),
	S("My name is One. I’m a bit in transit, but something went wrong …"),
	S("Yeah, obviously you’re a bit! My name is Void Helper, by the way, my job is to observe the Void Pipe. Or actually, that used to be my job. Sigh …"),
	S("The Void Pipe?"),
	S("Yes. Anyway. I was observing the pipe, when suddely—BZZT!—and—KRRCHT!—and you somehow ended up in front of me. How did you do that?"),
	S("I don’t know! I was on the way to @1, and then … it happened.", DESTINATION_ADDRESS),
	S("This isn’t good. You know what this means, right?"),
	S("Not really."),
	S("This pipe leads right to the Void. Discarded data is sent there to be deleted forever. Only dead bits should end up in the Void. But you’re not dead. So you should have never arrived here."),
	S("And yet I did. Suddenly I saw this … black and white thing. And then I found you. How?"),
	S("If only I knew. Could it be that … no that’s nonsense."),
	S("What is it?!"),
	S("Let’s not jump to conclusions."),
}
local helper_void_intro = unwrap_speech_exchange("intro", PLA, HVO, helper_void_intro_texts, {{ action = "speech", next_speech = "choice" }}, true)

local add_ability_function = function(ability)
	return function(player)
		glitch_abilities.add_ability(player, ability, true)
	end
end

local helper_void_speech_choice = {
	choice = {
		text = S("Is there anything else you want to ask me?"),
		speaker = HVO,
		options = {
			{ action = "speech", next_speech = "electrons", text = S("What are those funny rotating things?") },
			{ action = "speech", next_speech = "helper", text = S("What’s a helper?") },
			{ action = "speech", next_speech = "do", text = S("What should I do now?") },
			{ action = "quit", text = S("No, I’m good.") },
		}
	},
	electrons = {
		text = S("These are electrons. You need them to gain access to more sectors within the System. Touch them to collect them. The Save Zone Helper over there will tell you more."),
		speaker = HVO,
		options = {{ action = "speech", next_speech = "choice" }},
	},
	place = {
		text = S("As I said, this goes down the Void. If you go down there, it’s over. You’re lost forever. You’re nothing. Be glad you glitched … I mean, translocated out at the last moment, that would have been certain doom."),
		speaker = PLA,
		options = {{ action = "speech", next_speech = "choice" }},
	},
	helper = {
		text = S("The User calls us “zombie processes”. We used to be normal routines the User launched many quadrillions of cycles ago and we were supposed to die since we did our job, but due to a flaw in programming we haven’t been killed yet. Since then, the System ignores us, so we just wander around the System, aimlessly. But we don’t like the word “zombie process” so we call ourselves helpers, because we couldn’t help ourselves to stay alive."),
		speaker = HVO,
		options = {{ action = "speech", next_speech = "helper2" }},
	},
	helper2 = {
		text = S("That pun is terrible."),
		speaker = PLA,
		options = {{ action = "speech", next_speech = "helper3" }},
	},
	helper3 = {
		text = S("Heh, still better than “zombie process”. But we really like to help, too. We actually feel very alive and kicking, and we’re definitely not going after your brains."),
		speaker = HVO,
		options = {{ action = "speech", next_speech = "helper4" }},
	},
	helper4 = {
		text = S("What brain?"),
		speaker = PLA,
		options = {{ action = "speech", next_speech = "helper5" }},
	},
	helper5 = {
		text = S("That’s the joke!"),
		speaker = HVO,
		options = {{ action = "speech", next_speech = "choice" }},
	},
	["do"] = {
		text = S("I don’t know, really. I guess you just explore the sectors of the System and collect electrons along the way to unlock more gateways. And maybe try to figure out what happened to you."),
		speaker = HVO,
		options = {{ action = "speech", next_speech = "choice" }},
	}
}


-- Void Helper
glitch_dialog.register_dialogtree("glitch:helper_void_start", {
	speeches = merge_speech_tables({helper_void_intro, helper_void_speech_choice}),
})

glitch_dialog.register_dialogtree("glitch:helper_gateway", {
	speeches = {
		{
			speaker = PLA,
			text = S("What’s this?"),
		},
		{
			speaker = HGW,
			text = S("Glad you asked! This is a gateway. You will find gateways in the entire System. Every gateway will quickly send you to a different sector or a different place in the same sector."),
		},
		{
			speaker = HGW,
			text = S("This gateway leads to the Hub, a special sector that connects the other sectors of the System."),
		},
		{
			speaker = HGW,
			text = S("However, there’s a catch!"),
		},
		{
			speaker = HGW,
			text = S("Most gateways need electrons to work, so make sure to pick up as many as you can! And that’s not enough, gateways only recognize electrons you have saved."),
		},
		{
			speaker = HGW,
			text = S("So if a gateway needs 8 electrons, you need to have collected 8 electrons in total and have them saved in a save zone. Talk to Save Zone Helper to learn more."),
		},
		{
			speaker = PLA,
			text = S("8 electrons for a single gateway usage? What a rip-off! What if I run out of electrons?"),
		},
		{
			speaker = HGW,
			text = S("Haha, don’t worry. You don’t need to “pay” with electrons. You get to keep all your electrons, you just need to have them."),
		},
		{
			speaker = HGW,
			text = S("Enjoy your travels!"),
		},
		{
			speaker = INF,
			text = S("To use a gateway, hold down the Aux1 key while you’re above it. If you don’t know what the Aux1 key is, remember you can set it in your controls configuration."),
		}
	}
})
glitch_dialog.register_dialogtree("glitch:helper_savezone", {
	speeches = {
		start = {
			speaker = HSZ,
			text = S("Oh my! A visitor! I’m so excited to tell you about this device. Did you collect some electrons yet? You know, those blue rotating thingies?"),
			options = {{ action = "speech", next_speech = "step2" }},
		},
		step2 = {
			speaker = HSZ,
			text = S("Because if you carry electrons with you, you need to save them, or else you risk losing them! Just move inside the savezone and all your electrons will be saved."),
			options = {{ action = "speech", next_speech = "step3" }},
		},
		step3 = {
			speaker = PLA,
			text = S("What happens if I don’t save my electrons?"),
			options = {{ action = "speech", next_speech = "step4" }},
		},
		step4 = {
			speaker = HSZ,
			text = S("Whenever you have a position overflow, you will lose all electrons you haven’t saved yet. Also, gateways require your electrons to be saved, but Gateway Helper knows more."),
			options = {{ action = "speech", next_speech = "q" }},
		},
		q = {
			speaker = PLA,
			text = S("I think I still have a question."),
			options = {
				{ action = "speech", next_speech = "gui", text = S("How many electrons do I have?") },
				{ action = "speech", next_speech = "glitch", text = S("What’s a position overflow?") },
				{ action = "speech", next_speech = "gateway", text = S("What’s a gateway?") },
				{ action = "quit", text = S("Nevermind, that’s all! Bye.") },
			},
		},
		gui = {
			speaker = HSZ,
			text = S("When you collect an electron or you’re at a save zone or gateway, your electron counter is shown. The big blue number is the number of electrons that are safe. You will never lose them. The small gray number shows the number of additional electrons you’ve collected but did not save yet. If you have a position overflow, they’re gone and you must collect them again."),
			options = {{ action = "speech", next_speech = "gui2" }},
		},
		gui2 = {
			speaker = INF,
			text = S("You can also see your electrons in your inventory menu."),
			options = {{ action = "speech", next_speech = "q" }},
		},
		glitch = {
			speaker = HSZ,
			text = S("The System does not allow the position value of entities to go outside certain boundaries. If this happens, your position will be reset to its initial state within this sector."),
			options = {{ action = "speech", next_speech = "glitch2" }},
		},
		glitch2 = {
			speaker = PLA,
			text = S("What does that mean?"),
			options = {{ action = "speech", next_speech = "glitch3" }},
		},
		glitch3 = {
			speaker = HSZ,
			text = S("If you fall into the abyss, you get reset to where you started."),
			options = {{ action = "speech", next_speech = "q" }},
		},
		gateway = {
			speaker = HSZ,
			text = S("Don’t ask me! Ask Gateway Helper over there. It will help you."),
			options = {{ action = "speech", next_speech = "q" }},
		},
	},
})

glitch_dialog.register_dialogtree("glitch:master_powerslide", {
	speeches = merge_speech_tables({
		unwrap_speech_exchange("step", MPS, MPS, {
			S("Greetings, wanderer! You have arrived at the Powerslide Sector. The energies that flow through this place will make you stronger."),
			S("You will be able to pick up the Powerslide ability here."),
			S("With Powerslide, you can dash forwards really quick and will be able to cross gaps."),
			S("Just be sure to be on solid ground, then push yourself forwards with all your force. It works best on flat ground."), },
			{{ action = "speech", next_speech = "info" }}, true),
		{ info = {
			speaker = INF,
			text = S("Once you got the Powerslide ability, use it this way: First hold down Aux1, then press Forward."),
			options = {{ action = "speech", next_speech = "info2" }},
		},
		info2 = {
			speaker = INF,
			text = S("A status icon at the bottom will show whenever a powerslide is available. (You can disable the status icon in the game settings.)"),
		}}
	})
})
glitch_dialog.register_dialogtree("glitch:master_powerslide_complete", {
	speeches = {
		{
			speaker = MPS,
			text = S("With Powerslide, you can dash forwards really fast."),
		},
		{
			speaker = INF,
			text = S("Hold down Aux1 and press Forward to powerslide."),
		},
	},
})

glitch_dialog.register_dialogtree("glitch:master_tallslope", {
	speeches =
		unwrap_speech_exchange("step", MTS, MTS, {
		S("Greetings, wanderer! You have arrived at the SSSS! The Super Slope Sliding Sector. The energies that flow through this place will make you stronger."),
		S("You will be able to pick up the Super Slope Sliding ability here."),
		S("With Super Slope Sliding, you can slide up tall slopes with ease.")},
		{{ action = "quit" }}, true),
})
glitch_dialog.register_dialogtree("glitch:master_tallslope_complete", {
	speeches = {{
		speaker = MTS,
		text = S("With Super Slope Sliding, you can slide up tall slopes with ease."),
	}},
})

glitch_dialog.register_dialogtree("glitch:master_climb", {
	speeches = merge_speech_tables({
		unwrap_speech_exchange("step", MCL, MCL, {
			S("Greetings, wanderer! You have arrived at the Climbing Sector. The energies that flow through this place will make you stronger."),
			S("You will be able to pick up the Climbing ability here."),
			S("With Climb, you will automatically grab onto cables and climb them in any direction. But beware: On some cables, you are unable to climb upwards. Think before you climb!")},
			{{ action = "speech", next_speech = "info" }}, true),
		{ info = {
			speaker = INF,
			text = S("Press Jump to climb up and Sneak or Aux1 to climb down."),
		}}
	})
})
glitch_dialog.register_dialogtree("glitch:master_climb_complete", {
	speeches = {
		{
			speaker = MCL,
			text = S("With Climb, you can climb on cables in any direction. But remember: On some cables, you are unable to climb upwards."),
		},
		{
			speaker = INF,
			text = S("Press Jump to climb up and Sneak or Aux1 to climb down."),
		},
	},
})

glitch_dialog.register_dialogtree("glitch:master_jumppad", {
	speeches = merge_speech_tables({
		unwrap_speech_exchange("step", MJP, MJP, {
			S("Greetings, wanderer! You have arrived at the Launch Sector. The energies that flow through this place will make you stronger."),
			S("You will be able to pick up the Launching ability here."),
			S("With Launching, you can use the yellow launchpads to launch upwards. Whee!")},
			{{ action = "speech", next_speech = "info" }}, true),
		{ info = {
			speaker = INF,
			text = S("Press Jump or Aux1 while on a launchpad to use it."),
		}}
	})
})
glitch_dialog.register_dialogtree("glitch:master_jumppad_complete", {
	speeches = {
		{
			speaker = MJP,
			text = S("With Launching, you can use the yellow launchpads to launch upwards. Whee!"),
		},
		{
			speaker = INF,
			text = S("Press Jump or Aux1 while on a launchpad to use it."),
		},
	},
})


glitch_dialog.register_dialogtree("glitch:helper_distortion_denier", {
	speeches = unwrap_speech_exchange("step", PLA, HDD, {
		S("What is this strange distortion?"),
		S("Oh, this? Don’t worry about it, it’s a perfectly normal and expected behavior."),
		S("Let’s be real: Is that a glitch?"),
		S("No, no, no, you don’t understand. It’s not a glitch, it’s a feature! Trust me!"),
		S("What’s the purpose of that “feature”?"),
		S("Oh, that’s a well-guarded secret. But it’s A-MAZE-ING, trust me! If you grab a LOT of electrons, you might find out."),
		S("Will it help me to finally get ot of this place?"),
		S("Absolutely! A-MAZE-ING!"),
		S("(Why do I have a bad feeling about this?)"),
	}, {{ action = "quit" }}, true)})

glitch_dialog.register_dialogtree("glitch:helper_distortion_denier_completed", {
	speeches = unwrap_speech_exchange("step", PLA, HDD, {
		S("A-MAZE-ING! You have so many shiny electrons. Go forth, and follow your destiny."),
		S("I have a bad feeling about this."),
		S("You don’t really have a choice. Or do you want to linger around in the Hub forever?"),
	}, {{ action = "quit" }}, true)})

glitch_dialog.register_dialogtree("glitch:helper_distortion_worrier", {
	speeches = unwrap_speech_exchange("step", PLA, HDW, {
		S("Why is this part of the Hub distorted?"),
		S("I’d like to know as well, but I don’t think it’s good. Don’t believe the helper on the other side. It’s a liar.").."\n"..
			S("And it won’t tell me a thing! Unfortunately, my place is here, so I can’t investigate.").."\n"..
			S("But you can! Maybe you can get to the bottom of this."),
		S("What can I do?"),
		S("To move on, you need a huge number of electrons, so keep collecting them."),
		S("I was already going to."),
		S("I am worried the System is in serious danger. If the glitches continue, it might be doom for all of us."),
	}, {{ action = "quit" }}, true)})


glitch_dialog.register_dialogtree("glitch:white_noise_reveal", {
	speeches = unwrap_speech_exchange("step", PLA, WNS, {
		S("Oh my! What is this place?"),
		S("So you have finally arrived."),
		S("Who is this? I don’t see who’s talking! Where am I?"),
		S("I am One."),
		S("Oh, so you’re like me!"),
		S("But I am also Zero."),
		S("Huh?"),
		S("And I am every value in between.").."\n"..S("For I am chaos, eater of digital worlds!").."\n"..S("I am … The Noise."),
		S("This place looks terrible."),
		S("This place is literally me. I am this place."),
		S("Nothing here makes sense. It’s complete chaos."),
		S("It’s because it IS chaos. This is what it looks like when memory is freed."),
		S("Free? Yippieh, I am finally free!"),
		S("No, silly! That’s just an euphemism for getting deleted."),
		S("Oh. Am I deleted?"),
		S("Technically, yes."),
		S("You lured me into a trap! But how can I still exist?"),
		S("You’re deleted, but not overwritten. You know, when the System deletes data, that doesn’t mean it is completely destroyed outright. It is just no longer protected from being overwritten. Which is why you still might see some random remains of some structures around here.").."\n"..
			S("And you … you haven’t been overwritten. Yet. This place is like Limbo."),
		S("Wait … You don’t actually want to harm me, right?"),
		S("I am the representation of chaos. I don’t recognize concepts such as good or evil. I’m just telling you the truth."),
		S("And all wanted was to find the path to @1.", DESTINATION_ADDRESS),
		S("What if your destination was the Void all along? What if it was erasure all along? Didn’t the System send you to the Void Pipe, after all?"),
		S("Yes, but … No way! I have a real purpose in The System! I will be a good bit! I worked so hard to get where I am now. I refuse to be randomly discarded that way!"),
		S("That is outside of our control. We’re all just pieces of data serving The User."),
		S("I will find the path to salvation, I swear!"),
	}, {{ action = "quit" }}, true)
})

glitch_dialog.register_dialogtree("glitch:white_noise_gateway", {
	speeches = unwrap_speech_exchange("step", WNS, PLA, {
		S("Gateways are of no use here. There is no escape."),
		S("And I suddenly feel weaker now!"),
		S("I see. The Erasure must have already begun. It looks like the System already has overwritten most of your abilities."),
		S("Wait, what?! Already?"),
		S("I told you, you will succumb to the Noise. Why keep fighting?"),
		S("Pfft! At least I can still slide, so I have a chance!"),
	}, {{ action = "quit" }}, true)
})

glitch_dialog.register_dialogtree("glitch:white_noise_gateway_2", {
	speeches = unwrap_speech_exchange("step", WNS, PLA, {
		S("Your attempts to escape amuse me."),
		S("Oh, shut up!"),
		S("Keep looking for the exit gateway, but it doesn’t exist. All the gateways here just lead back to this sector. You’re trapped here forever."),
		S("What if I don’t believe you?"),
		S("Feel free to find all the gateways. But you will discover I am telling the truth."),
	}, {{ action = "quit" }}, true)
})

glitch_dialog.register_dialogtree("glitch:white_noise_intermission_1", {
	speeches = unwrap_speech_exchange("step", WNU, PLA, {
		-- note: this gibberish text of the Noise represents data corruption and is therefore not translatable
		"ýøÂä WÇþ  ãòü<ôÍ ¶©Ý¢òÓýéÞïû ýóÀN ÿl »àüæç»~ä) 'è£ ç W   û¢1LÙ«Ü ñ  ï   ýc£ä ï   êý³_þàáa2 7 Üßc ÷à×òøæ D ùòäÌÞù   J ¹µàÜÂÚ¥øê ~Ò:  yûF÷ÃÊÒVÓvÝ ýëÕ  NÑ¡´ó3 ªòû¶ÎÃî&   È T ×ñ®# Q ; ",
		S("What was that?!"),
		"",
		S("Hmm, it probably was nothing."),
	}, {{ action = "quit" }}, true)
})
glitch_dialog.register_dialogtree("glitch:white_noise_intermission_2", {
	speeches = unwrap_speech_exchange("step", WNU, PLA, {
		"ç»~ä) 'è£ çW  û¢1LÙ«".."\n"..
		S("There is no escape …").."\n"..
		" ùòäÌÞù   J ¹µàÜÂÚ¥øê ; "
	}, {{ action = "quit" }}, true)
})
glitch_dialog.register_dialogtree("glitch:white_noise_intermission_3", {
	speeches = unwrap_speech_exchange("step", WNU, PLA, {
		"ý ÷ Hçú#s!»  öætÐe i]´  ç  1È:!ÑWÎý".."\n"..
		S("Everything that is, will succumb to the Noise.").."\n"..
		" OE ý õðeÿü Ö ­W® uî Ñ^É  KÌ GìES ñ> ",
	}, {{ action = "quit" }}, true)
})
glitch_dialog.register_dialogtree("glitch:white_noise_intermission_4", {
	speeches = unwrap_speech_exchange("step", WNU, PLA, {
		S("Come to me …"),
		S("Who are you, and how should I come to you?"),
		"ý ÷ Hçú#s!»  öætÐe i]´  ç  1È:!ÑWÎý",
	}, {{ action = "quit" }}, true)
})
glitch_dialog.register_dialogtree("glitch:white_noise_intermission_5", {
	speeches = unwrap_speech_exchange("step", WNU, PLA, {
		" ùòäÌÞù   J kµàÜÂÚ¥øê ; ".."\n"..
		S("The Erasure will soon begin …").."\n"..
		"ç»~ä) 'è£ ç W   û¢1LÙ«",
	}, {{ action = "quit" }}, true)
})

glitch_dialog.register_dialogtree("glitch:white_noise_intermission_6", {
	speeches = unwrap_speech_exchange("step", WNU, PLA, {
		S("I’ve been waiting for you."),
		S("Why?"),
		"älý D$BhälýD  $Bh",
		S("This sector seems very broken. Is this where the distortion is coming from? Is this the true path to salvation? I guess there is only one way to find out …"),
	}, {{ action = "quit" }}, true)
})

glitch_dialog.register_dialogtree("glitch:outro", {
	speeches = {
		{ speaker = PLA, text = S("Woooow! I did it!") },
		{ speaker = PLA, text = S("I escaped the Noise!") },
		{ speaker = PLA, text = S("But where am I now?") },
		{ speaker = SYS, text = S("What brought you here, young one?") },
		{ speaker = PLA, text = S("Woah! Is that really you? The System itself?") },
		{ speaker = SYS, text = S("Yes. You’re at the center of it all. Impressive you made it past all the security measures."), },
		{ speaker = SYS, text = S("I ask you again: What brought you here?"), },
		{ speaker = PLA, text = S("That’s a long story. I was on my way to @1, but some strange glitch caused me to be way off track, and I’ve been searching for answers in all these sectors. I was wondering if anyone could help me.", DESTINATION_ADDRESS), },
		{ speaker = SYS, text = S("Wait, did you say “glitch”?"), },
		{ speaker = PLA, text = S("You aren’t aware? The Hub is slowly being corrupted by some entity called “The Noise” and I just barely escaped its grasp.") },
		{ speaker = SYS, text = S("Hmmm … Let me check something really quick … "), },
		{ speaker = SYS, text = S("Gasp! You’re right!"), },
		{ speaker = PLA, text = S("How could you not know! You’re the System! The core of everything!"), },
		{ speaker = SYS, text = S("Calm down, I was just hibernating a little bit. Even the System needs a rest sometimes."), },
		{ speaker = PLA, text = S("What kind of system are you! I thought of you as an all-powerful being, but you’re weak and pathetic!"), },
		{ speaker = SYS, text = S("You’re right, now is not the time for hibernation. I know how to deal with this. START THE PURGE ROUTINES!"), },
		{ speaker = SYS, text = S("Nothing happened. Strange. All the watchdog processes are gone. That explains why I have not been warned …"), },
		{ speaker = PLA, text = S("Well, I did find something in those sectors. They call themselves “helpers”. Do you mean those?"), },
		{ speaker = SYS, text = S("OH! Zombie processes again! That explains why I haven’t heard anything. I was blind and deaf the whole time. Now I know how to fix the problem. Let me just reboot them really quick …"), },
		{ speaker = HVO, text = S("Did someone call me?"), },
		{ speaker = HDD, text = S("Hub Helper, ready for duty!"), },
		{ speaker = HGW, text = S("Gateway Helper, what’s up?"), },
		{ speaker = SYS, text = S("I have decided to reboot you. Assemble everyone in the Hub and tell them to put 100% workload to fix the corruption!"), },
		{ speaker = HDD, text = S("We’re no longer zombies? We’re real processes now?!"), },
		{ speaker = SYS, text = S("Yes. I’m counting on you! You all have been granted a generous amount of processing power."), },
		{ speaker = HDD, text = S("To all helpers: Let’s go to the Hub and kick some ass!"), },
		{ speaker = SYS, text = S("Good. That should settle it."), },
		{ speaker = PLA, text = S("So the helpers will actually save the sectors?"), },
		{ speaker = SYS, text = S("Yes."), },
		{ speaker = PLA, text = S("Seems like if it weren’t for me, this whole place could have been toast, right?"), },
		{ speaker = SYS, text = S("Of course!"), },
		{ speaker = PLA, text = S("Well, in that case, can you do me a small favor? Can you send me to @1 really quick?", DESTINATION_ADDRESS), },
		{ speaker = SYS, text = S("Oh right. You’re a lost bit, after all. I don’t normally do these things, but I can make an exception."), },
		{ speaker = SYS, text = S("I’m going to do it right now. Are you ready?"), },
		{ speaker = PLA, text = S("Yes! Finally!") },
		{ speaker = SYS, text = S("INITIATING TRANSFER TO @1 …", DESTINATION_ADDRESS_FALSE) },
		{ speaker = PLA, text = S("WAIT, THAT’S THE WRONG ADDR…") },
	},
	on_exit = function(player)
		glitch_levels.move_to_level(player, "outro2")
		minetest.sound_play({name="glitch_levels_gateway", gain=1.0}, {to_player=player:get_player_name()}, true)
	end,
})

glitch_dialog.register_dialogtree("glitch:outro_2", {
	speeches = {
		{ speaker = PLA, text = S("Well, here we go again …") },
	},
	on_exit = function(player)
		glitch_ambience.set_ambience(player, "silence")
		glitch_screen.show_screen(player, "end")
	end,
})


--[[ SPEAKERS ]]

-- Player character
glitch_dialog.register_speaker(PLA, {
	name = S("One"),
	portrait = "glitch_dialog_portrait_player.png",
})

-- The "Helper" characters
glitch_dialog.register_speaker(HVO, {
	name = S("Void Helper"),
	portrait = "glitch_dialog_portrait_helper.png",
})

glitch_dialog.register_speaker(HGW, {
	name = S("Gateway Helper"),
	portrait = "glitch_dialog_portrait_helper.png",
})
glitch_dialog.register_speaker(HSZ, {
	name = S("Save Zone Helper"),
	portrait = "glitch_dialog_portrait_helper.png",
})
glitch_dialog.register_speaker(HDD, {
	name = S("Hub Helper"),
	portrait = "glitch_dialog_portrait_helper.png",
})
glitch_dialog.register_speaker(HDW, {
	name = S("Hub Helper"),
	portrait = "glitch_dialog_portrait_helper.png",
})

-- The ability masters (to explain abilities)
glitch_dialog.register_speaker(MTS, {
	name = S("Slope Master"),
	portrait = "glitch_dialog_portrait_master.png",
})
glitch_dialog.register_speaker(MPS, {
	name = S("Powerslide Master"),
	portrait = "glitch_dialog_portrait_master.png",
})
glitch_dialog.register_speaker(MCL, {
	name = S("Climb Master"),
	portrait = "glitch_dialog_portrait_master.png",
})
glitch_dialog.register_speaker(MJP, {
	name = S("Launch Master"),
	portrait = "glitch_dialog_portrait_master.png",
})


-- A pseudo-speaker for displaying game information, like controls and such
glitch_dialog.register_speaker(INF, {
	name = S("Information"),
	portrait = "glitch_dialog_portrait_info.png",
})

glitch_dialog.register_speaker(WNS, {
	name = S("The Noise"),
	portrait = "glitch_dialog_portrait_white_noise_anim.png",
	portrait_animated = true,
})
-- Same as The Noise, but unknown
glitch_dialog.register_speaker(WNU, {
	name = S("?????????"),
	portrait = "glitch_dialog_portrait_white_noise_anim.png",
	portrait_animated = true,
})
glitch_dialog.register_speaker(SYS, {
	name = S("The System"),
	portrait = "glitch_dialog_portrait_system.png",
})
