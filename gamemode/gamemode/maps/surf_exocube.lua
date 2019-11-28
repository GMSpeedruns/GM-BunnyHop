-- Force to easy mode

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.GetAll() ) do
		local name = v:GetName()
		if name == "but_e" or name == "but_m" or name == "but_h" or name == "win_med" or name == "win_hard" or name == "movelinear" then
			v:Remove()
		elseif name == "lvl1_ha_me_e" or name == "lvl1_ha_e" or name == "lvl1_me_e" or name == "lvl5_ha_e" or name == "lvl5_ha_me_e" then
			v:Fire( "Disable" )
		elseif name == "01activ_EASY" or name == "01activ_MEDIUM" or name == "01activ_HARD" then
			v:Remove()
		elseif name == "win_knife" then
			v:Fire( "Disable" )
		elseif name == "break_4lvl_med" or name == "break_1lvl_ha_me" then
			v:Fire( "Break" )
		elseif name == "door_start" then
			v:Fire( "Close" )
		end
	end
end