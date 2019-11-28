-- Remove rotating parts

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_rotating" ) ) do
		if v:GetPos() == Vector( 718, -112, -12297 ) or v:GetPos() == Vector( 718, -2256.38, -12447 ) or v:GetPos() == Vector( 718, -4560, -12608 ) then
			v:Remove()
		end
	end
end