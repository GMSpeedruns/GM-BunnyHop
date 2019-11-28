-- Make Lost World speedrunnable

local walls = {
	"cave_toggle10",
	"cave_toggle06",
	"cave_toggle01",
	"vr_toggle1",
	"vr_toggle2",
	"vr_toggle6",
	"vr_toggle7",
	"labs_tog023",
--	"labs_tog024", -- Dropdown part
--	"labs_tog025",
	"labs_tog019",
	"labs_tog020",
	"labs_tog021"
}

local teles = {
	Vector( -8532, -1412, 64 ),
	Vector( -9872, -1516, -92 ),
	Vector( -7312, -9780, -91 ),
	Vector( -9744, -7596, -300 ),
	Vector( 8232, 4792, -768 ),
	Vector( 4824, -3536, 5292 ),
--	Vector( 9040, 4392, -144 ), -- Dropdown part
--	Vector( 9040, 4392, -320 ),
	Vector( 8656, 5064, 80 ),
	Vector( 7760, 5064, -144 ),
	Vector( 8720, 5064, -399.91 )
}

local enable = {
	"vr_toggle3",
	"vr_toggle4",
	"vr_toggle5",
	"labs_tog09",
	"labs_tog010"
}

local brush = {
	"labs_tog02",
	"labs_tog04",
	"labs_tog07",
	"labs_tog012",
	"labs_tog013",
	"labs_tog016"
}

local lasertele = {
	Vector( -9744, -8232, -256 ),
	Vector( -9408, -9780, -148 ),
	Vector( -10128, -9780, -148 ),
	Vector( -8592, -9780, -148 ),
	Vector( -8242, -9780, -148 ),
	Vector( -9744, -5160, -896 )
}

local laserobj = {
	Vector( -9744, -8232.5, -256.5 ),
	Vector( -9408.5, -9780, -148.5 ),
	Vector( -10128.5, -9780, -148.5 ),
	Vector( -8592.5, -9780, -148.5 ),
	Vector( -8242.5, -9780, -148.5 ),
	Vector( -9744, -5160.5, -896.5 )
}

local enabletp = Vector( 8028, -8192, 5116 )
local sf, sl, tn = string.find, string.lower, tonumber

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if table.HasValue( teles, v:GetPos() ) then
			v:Remove()
		end
		
		if table.HasValue( lasertele, v:GetPos() ) then
			v:Remove()
		end
		
		if v:GetPos() == enabletp then
			v:Fire( "Enable" )
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_wall_toggle" ) ) do
		if table.HasValue( walls, v:GetName() ) then
			v:Remove()
		end
		
		if table.HasValue( enable, v:GetName() ) then
			v:Fire( "Toggle" )
			v:SetName( v:GetName() .. "_rename" )
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_brush" ) ) do
		if table.HasValue( brush, v:GetName() ) then
			v:Fire( "Enable" )
			v:SetName( v:GetName() .. "_rename" )
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_movelinear" ) ) do
		if v:GetPos() == Vector( 6912, 7504, -128 ) then
			v:Fire( "Open" )
			v:SetName( v:GetName() .. "_rename" )
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		if v:GetPos() == Vector( 6912, 6168, 168 ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if v:GetPos() == Vector( 8032, -8192, 5116 ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_button" ) ) do
		if table.HasValue( laserobj, v:GetPos() ) then
			v:Remove()
		end
	end
end

__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "trigger_push" then
		if sf( sl( key ), "speed" ) then
			if tn( value ) == 1200 then
				return "1500"
			end
		end
	end
end