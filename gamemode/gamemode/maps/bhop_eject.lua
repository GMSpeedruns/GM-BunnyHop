__HOOK[ "InitPostEntity" ] = function()
	-- Make sure we can use +left and +right
	Core.BypassStrafeBinds( true )
	
	-- Remove all annoying sounds
	for _,ent in pairs( ents.FindByClass( "ambient_generic" ) ) do
		ent:Remove()
	end
end