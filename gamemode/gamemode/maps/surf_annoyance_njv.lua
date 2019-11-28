-- Remove auto jail

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( 11712, -6528, -1360 ) then
			v:Remove()
		end
	end
end