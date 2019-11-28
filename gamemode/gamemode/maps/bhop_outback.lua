-- Remove the slowly opening doors

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		if v:GetName() == "door_level2" then
			v:Remove()
		end
	end
end