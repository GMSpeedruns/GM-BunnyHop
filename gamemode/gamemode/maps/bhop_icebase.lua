-- Remove doors that open too slow

local DoorOpeners = {
	Vector( -5852, -4336, 84 ),
	Vector( -3872, -2488, 384 ),
	Vector( -2184, -1776, 384 ),
	Vector( -724, 1704, 64 ),
	Vector( 3732, 6456, 352 )
}

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		if string.find( v:GetName(), "door" ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if table.HasValue( DoorOpeners, v:GetPos() ) then
			v:Remove()
		end
	end
end