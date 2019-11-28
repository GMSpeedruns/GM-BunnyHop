-- Militia V2 fixes

__HOOK[ "InitPostEntity" ] = function()
	for _,v in pairs( ents.FindByClass( "func_breakable" ) ) do
		v:Remove()
	end
end