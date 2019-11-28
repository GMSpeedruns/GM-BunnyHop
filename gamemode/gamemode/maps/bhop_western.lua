-- Remove dust stuff

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "func_dustcloud" ) ) do
		ent:Remove()
	end
end