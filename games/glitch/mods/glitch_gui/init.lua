minetest.register_on_joinplayer(function(player)
	player:set_formspec_prepend(
		"listcolors[#404040FF;#00A000FF;#404040FF;#000000FF;#00FF00FF]"..
		"bgcolor[#00000000]"..
		"background9[0,0;9,9;glitch_gui_formspec_bg.png;true;8]"..
		"style_type[button;bgimg=glitch_gui_button.png;bgimg_middle=1;font=mono;textcolor=#00FF00FF]"..
		"style_type[button:hovered;bgimg=glitch_gui_button_hovered.png;bgimg_middle=1;font=mono;textcolor=#FFFFFFFF]"..
		"style_type[button:pressed;bgimg=glitch_gui_button_pressed.png;bgimg_middle=1;font=mono;textcolor=#000000FF;content_offset=0]"..
		"style_type[button;sound=glitch_gui_button_press]"..
		"style_type[label,vertlabel;font=mono;textcolor=#00FF00FF]"..
		"style_type[field,textarea;font=mono;textcolor=#00FF00FF]"
	)
end)
