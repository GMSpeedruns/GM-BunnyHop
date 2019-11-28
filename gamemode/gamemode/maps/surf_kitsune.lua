-- Remove rainbow button

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_button" ) ) do
		if v:GetPos() == Vector( 12288, 3584, -2444 ) then
			v:Remove()
		end
	end
end