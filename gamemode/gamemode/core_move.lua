-- Base by Mehis, released on https://github.com/TotallyMehis/GMODLUA-CSS-Stamina

local STAMINA_USE = {}
local STAMINA_SET = {}
local STAMINA_MAX = 100.0
local STAMINA_COST_JUMP = 25.0
local STAMINA_COST_FALL = 20.0
local STAMINA_RECOVER_RATE = 19.0
local STAMINA_STYLES = { [Core.Config.Style.Legit] = true, [Core.Config.Style.Stamina or "Jump Pack"] = true }
local SCROLL_STYLES = { [Core.Config.Style.Legit] = true, [Core.Config.Style["Easy Scroll"]] = true }
local REFERENCE_FRAMETIME = 1.0 / 70.0
local DT_VELMODF, DT_STAM, MODF_ONLAND_DAMAGE = 0, 1, 0.5
local MT_WALK, IN_JP = MOVETYPE_WALK, IN_JUMP, CLIENT
local FN_FT, FN_ST, FN_P, FN_R, FN_S = FrameTime, SysTime, math.pow, math.random, math.sqrt

local function OnVelocityMod( ply )
	if not STAMINA_USE[ ply ] then return end
	ply:SetDTFloat( DT_VELMODF, MODF_ONLAND_DAMAGE )
end

local function OnStaminaMove( ply, mv, cmd )
	if not STAMINA_USE[ ply ] then return end
	if ply:GetMoveType() != MT_WALK then return end
	
	local flStamina = ply:GetDTFloat( DT_STAM )
	if flStamina > 0 then
		flStamina = flStamina - 1000.0 * FN_FT()
		
		if flStamina < 0 then
			flStamina = 0
		end
		
		ply:SetDTFloat( DT_STAM, flStamina )
	end
	
	local flVelModf = ply:GetDTFloat( DT_VELMODF )
	if not flVelModf or flVelModf <= 0 then flVelModf = 1 end

	if flVelModf < 1 then
		flVelModf = flVelModf + FN_FT() / 3.0
		
		if flVelModf >= 1.0 then
			flVelModf = 1.0
		else
			local maxspeed = mv:GetMaxSpeed()
			maxspeed = maxspeed * flVelModf
			
			mv:SetMaxSpeed( maxspeed )
			
			local f_speed = mv:GetForwardSpeed()
			local s_speed = mv:GetSideSpeed()
			local u_speed = mv:GetUpSpeed()
			local spd = f_speed * f_speed + s_speed * s_speed + u_speed * u_speed
			
			if spd != 0.0 and spd > (maxspeed * maxspeed) then
				local ratio = maxspeed / FN_S( spd )
				
				mv:SetForwardSpeed( f_speed * ratio )
				mv:SetSideSpeed( s_speed * ratio )
				mv:SetUpSpeed( u_speed * ratio )
			end
		end
		
		ply:SetDTFloat( DT_VELMODF, flVelModf )
	end

	if ply:WaterLevel() > 1 then return end
	
	if ply:IsOnGround() then
		if cmd:KeyDown( IN_JP ) and ((not STAMINA_SET[ ply ] or FN_ST() - STAMINA_SET[ ply ] > 0.1) or not SCROLL_STYLES[ ply.Style ]) then
			ply:SetJumpPower( (flStamina == 0 or not STAMINA_STYLES[ ply.Style ]) and Core.Config.Player.JumpPower or Core.Config.Player.ScrollPower )
			ply:SetDTFloat( DT_STAM, (STAMINA_COST_JUMP / STAMINA_RECOVER_RATE) * 1000.0 )
			
			STAMINA_SET[ ply ] = FN_ST()
		elseif flStamina > 0 then
			local flRatio = FN_P( (STAMINA_MAX - (flStamina / 1000.0) * STAMINA_RECOVER_RATE) / STAMINA_MAX, FN_FT() / REFERENCE_FRAMETIME )
			local vel = mv:GetVelocity()
			
			vel.x = vel.x * flRatio
			vel.y = vel.y * flRatio
			
			mv:SetVelocity( vel )
		end
	end
end
hook.Add( "SetupMove", "CSS_Stamina", OnStaminaMove )

if SERVER then
	hook.Add( "GetFallDamage", "CSS_VelMod", OnVelocityMod )
	
	function Core.EnableStamina( ply, bool )
		STAMINA_USE[ ply ] = bool
	end
elseif CLIENT then
	Core.Register( "Timer/Stamina", function( ar )
		if IsValid( LocalPlayer() ) then
			STAMINA_USE[ LocalPlayer() ] = ar:Bit()
		end
	end )
end