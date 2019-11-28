-- Remove lag at third stage

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_smokevolume" ) ) do
		v:Remove()
	end
end

-- Fix power jumps

__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "trigger_multiple" then
		if key == "OnTrigger" then
			if value == "!activator,AddOutput,gravity -10,0,-1" then
				return "!activator,AddOutput,gravity -12,0,-1"
			end
		end
	end
end