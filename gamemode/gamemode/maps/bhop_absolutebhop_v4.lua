-- Remove moving door

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		if v:GetName() == "ture" then
			v:Remove()
		end
	end
end