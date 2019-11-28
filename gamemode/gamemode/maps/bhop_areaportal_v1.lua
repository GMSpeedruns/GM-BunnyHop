-- Fixes for Areaportal Moving platform

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector( -1032, -2696.5, -455 ) then
			ent:SetKeyValue( "target", "level_redcorridor7" )
		elseif ent:GetPos() == Vector( -6947,-3655.5,-455 ) then
			ent:SetKeyValue( "target", "level_greencorridor3" )
		end
	end
end

-- Set the map to have special func_doors

__MAP[ "SpecialDoorMaps" ] = true