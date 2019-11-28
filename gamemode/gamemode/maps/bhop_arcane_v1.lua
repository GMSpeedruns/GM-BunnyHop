-- Remove those silly pushdown triggers

local pushes = {
	Vector( -14848, 9216, -6664 ),
	Vector( -13824, -9216, -7688 ),
	Vector( -5632, -9216, -8584 )
}

local buttons = {
	Vector( -14848, 9216, -6668 ),
	Vector( -13824, -9216, -7692 ),
	Vector( -5632, -9216, -8588 )
}

local deagles = {
	Vector( -4448, 12784, 14048 ),
	Vector( 1760, -1472, 3424 ),
	Vector( -1280, -1408, 2208 ),
	Vector( -2048, -6368, -4704 ),
	Vector( -9728, -14592, -14176 )
}

local weaponroom = {
	Vector( 11136, -11392, 13440 ),
	Vector( 11136, -11520, 13440 ),
	Vector( 11136, -11648, 13440 ),
	Vector( 11136, -11904, 13440 ),
	Vector( 11136, -12032, 13440 ),
	Vector( 11136, -12160, 13440 ),
	
	Vector( 11136, -12416, 13440 ),
	Vector( 11136, -12544, 13440 ),
	Vector( 11136, -12672, 13440 ),
	
	Vector( 8192, -12288, 13600 ),
	Vector( -2816, -7680, 15648 )
}

__HOOK[ "InitPostEntity" ] = function()
	for _,v in pairs( ents.FindByClass( "trigger_push" ) ) do
		if table.HasValue( pushes, v:GetPos() ) then
			v:Remove()
		end
	end
	
	for _,v in pairs( ents.FindByClass( "func_button" ) ) do
		if table.HasValue( buttons, v:GetPos() ) then
			v:Remove()
		end
	end
	
	for _,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if table.HasValue( deagles, v:GetPos() ) or table.HasValue( weaponroom, v:GetPos() ) then
			v:Remove()
		end
	end
end