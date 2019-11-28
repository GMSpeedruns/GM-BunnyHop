-- Set WJ and legit force

__HOOK[ "InitPostEntity" ] = function()
	GAMEMODE:SetDefaultStyle( Core.Config.Style.Legit, 16 )
end

__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "trigger_teleport" then
		if key == "OnStartTouch" then
			if value == "knife,Use,,0.1,-1" or value == "strip,Strip,,0,-1" then
				return ""
			end
		end
	end
end