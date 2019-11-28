__HOOK[ "InitPostEntity" ] = function()
	-- Remove all annoying sounds
	for _,ent in pairs( ents.FindByClass( "ambient_generic" ) ) do
		ent:Remove()
	end
end