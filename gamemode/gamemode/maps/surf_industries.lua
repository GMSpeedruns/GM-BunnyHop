-- Remove jail teleporters

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( 3224, 1896, 4432 ) then
			v:SetKeyValue( "target", "start_1" )
		end
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if v:GetPos() == Vector( 3224, 1896, 4472 ) then
			v:Remove()
		end
	end
end