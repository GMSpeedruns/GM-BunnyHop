-- Remove bonus teleport

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( 8716, -5888, -11516 ) then
			v:Remove()
		end
	end
end