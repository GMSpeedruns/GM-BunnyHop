-- Fucking traps

__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "infodecal" then
		if key == "texture" then
			if string.find( value, "trap" ) then
				return "real_dev/dev_gray4"
			end
		end
	end
end