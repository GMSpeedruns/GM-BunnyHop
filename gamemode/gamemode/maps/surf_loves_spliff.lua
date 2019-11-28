-- Remove jail teleports teleport

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetName() == "level_teleport" then
			v:Remove()
		elseif v:GetPos() == Vector( 672, 1248, -184 ) then
			v:Remove()
		end
	end
end