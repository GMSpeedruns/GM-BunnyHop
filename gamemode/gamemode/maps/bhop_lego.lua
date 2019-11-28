-- Remove stupid start zone triggers

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if v:GetPos() == Vector( -264, 384, 232 ) or v:GetPos() == Vector( 2304, -256, 512 ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( -58.49, 267, 129 ) or v:GetPos() == Vector( 2327.47, -32.36, 417 ) then
			v:Remove()
		end
	end
end