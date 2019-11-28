local Doors = {
	["bhop_monster_jam"] = true,
	["bhop_bkz_goldbhop"] = true,
	["bhop_aoki_final"] = true,
	["bhop_areaportal_v1"] = true,
	["bhop_ytt_space"] = true
}

local NoDoors = {
	["bhop_hive"] = true,
	["bhop_fury"] = true,
	["bhop_mcginis_fix"] = true
}

local Boosters = {
	["bhop_challenge2"] = 1,
	["bhop_ytt_space"] = 1.1,
	["bhop_dan"] = 1.5
}

local PlatformIndexes, PlatformBooster = {}, {}
function IndexPlatform( nID, bBooster )
	local Target = bBooster and PlatformBooster or PlatformIndexes
	local Value = bBooster or true
	
	Target[ nID ] = Value
end

local function GroundHook( ply )
	local ent = ply:GetGroundEntity()
	if IsValid( ent ) and PlatformIndexes[ ent:EntIndex() ] then
		if (ent:GetClass() == "func_door" or ent:GetClass() == "func_button") and PlatformBooster[ ent:EntIndex() ] then
			local dl = (ply.Style == 7 or ply.Style == 8) and 0.02 or 0.01
			ply.BoosterValue = PlatformBooster[ ent:EntIndex() ] * (Boosters[ game.GetMap() ] or 1.3)
			
			timer.Simple( dl, function()
				if IsValid( ply ) and ply.BoosterValue then
					local vel = ply:GetVelocity()
					if vel.z < 0 then
						ply.BoosterValue = ply.BoosterValue + math.abs( vel.z )
						ply:SetVelocity( Vector( 0, 0, -vel.z ) )
					elseif vel.z == 0 and ply:KeyDown( IN_JUMP ) then
						ply.BoosterValue = ply.BoosterValue + math.random( 234, 248 )
					end
					
					ply:SetVelocity( Vector( 0, 0, ply.BoosterValue ) )
					ply.BoosterValue = nil
				end
			end )
		elseif ent:GetClass() == "func_door" or ent:GetClass() == "func_button" then
			local dl = (ply.Style == 7 or ply.Style == 8) and 0.08 or 0.04
			if CLIENT then
				timer.Simple( dl, function()
					ent:SetOwner( ply )
					ent:SetColor( Color( 255, 255, 255, 125 ) )
				end )
				timer.Simple( 0.9, function()
					ent:SetOwner( nil )
					ent:SetColor( Color( 255, 255, 255, 255 ) )
				end )
			else
				timer.Simple( dl, function() ent:SetOwner( ply ) end )
				timer.Simple( 0.9, function() ent:SetOwner( nil ) end )
			end
		end
	end
end
hook.Add( "OnPlayerHitGround", "GroundHook", GroundHook )

local sf, sl, tn = string.find, string.lower, tonumber
local function KeyValueHook( ent, key, value )
	local map = game.GetMap()
	if NoDoors[ map ] then return end
	if sf( value, "modelindex" ) and sf( value, "AddOutput" ) then return "" end
	
	if ent:GetClass() == "func_door" then
		if Doors[ map ] then
			ent.IsP = true
		end
		if sf( sl( key ), "movedir" ) then
			if value == "90 0 0" then
				ent.IsP = true
			end
		end
		if sf( sl( key ), "noise1" ) then
			ent.BHS = value
		end
		if sf( sl( key ), "speed" ) then
			if tn( value ) > 100 then
				ent.IsP = true
			end
			ent.BHSp = tn( value )
		end
	elseif ent:GetClass() == "func_button" then
		if Doors[ map ] then
			ent.IsP = true
		end
		if sf( sl( key ), "movedir" ) then
			if value == "90 0 0" then
				ent.IsP = true
			end
		end
		if key == "spawnflags" then ent.SpawnFlags = value end
		if sf( sl( key ), "sounds" ) then
			ent.BHS = value
		end
		if sf( sl( key ), "speed" ) then
			if tn( value ) > 100 then
				ent.IsP = true
			end
			ent.BHSp = tn( value )
		end
	end
end
hook.Add( "EntityKeyValue", "KeyValueHook", KeyValueHook )