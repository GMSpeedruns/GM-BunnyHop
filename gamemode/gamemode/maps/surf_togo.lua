-- Remove jail teleports

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( -10280, 9888, -1184 ) or v:GetPos() == Vector( 128, 2752, -7568 ) then
			v:Remove()
		end
	end
end