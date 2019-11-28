-- Badges Mini aids removal

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "weapon_glock" ) ) do
		ent:Remove()
	end
end