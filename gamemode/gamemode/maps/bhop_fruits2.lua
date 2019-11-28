-- Fruits 2 booster fix

__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "trigger_multiple" then
		if key == "OnTrigger" then
			local check = string.match( value, "!activator,AddOutput,basevelocity 0 0 " )
			if check then
				return string.gsub( value, "%d+", function( d )
					d = tonumber( d )
					if d > 0 then
						return tostring( d + 80 )
					end
				end )
			end
		end
	end
end
