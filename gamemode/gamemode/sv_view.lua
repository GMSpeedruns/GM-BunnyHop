local ut, mm, Iv, GetVec, MainMask = util.TraceLine, math.min, IsValid, Vector, MASK_PLAYERSOLID
local PlayerData, DuckSet = Core.Config.Player, Core.GetDuckSet()
local HullDuck, HullStand = PlayerData.HullDuck, PlayerData.HullStand
local ViewStand, ViewDuck, ViewDiff, ViewBase = PlayerData.ViewStand, PlayerData.ViewDuck, PlayerData.ViewOffset, PlayerData.ViewBase
local TraceData, ActiveTrace, ViewOffset, ViewOffsetDuck, ViewTwitch = {}, {}, {}, {}, {}

--[[
	Description: Executes a trace on the player to see what their roof status is
--]]
local function ExecuteTrace( ply )
	local crouched = ply:Crouching()
	local maxs = crouched and HullDuck or HullStand
	local view = crouched and ViewDuck or ViewStand
	
	local s = ply:GetPos()
	s.z = s.z + maxs.z
	
	TraceData[ ply ].start = s
	
	local e = GetVec( s.x, s.y, s.z )
	e.z = e.z + (12 - maxs.z)
	e.z = e.z + view.z
	TraceData[ ply ].endpos = e
	
	local fraction = ut( TraceData[ ply ] ).Fraction
	if fraction < 1 then
		local est = s.z + fraction * (e.z - s.z) - ply:GetPos().z - 12
		if not crouched then
			local offset = ply:GetViewOffset()
			offset.z = est
			return offset, nil
		else
			local offset = ply:GetViewOffsetDucked()
			offset.z = mm( offset.z, est )
			return nil, offset
		end
	else
		return nil, nil
	end
end

--[[
	Description: This is the main move hook that sets their offset (HAS to be done every move update or things start looking weird)
--]]
local function InstallView( ply )
	if not Iv( ply ) then return end

	if ActiveTrace[ ply ] then
		local n, d = ExecuteTrace( ply )
		if n != nil or d != nil then
			ViewOffset[ ply ] = n
			ViewOffsetDuck[ ply ] = d
		else
			ActiveTrace[ ply ] = nil
			ViewOffset[ ply ] = nil
			ViewOffsetDuck[ ply ] = nil
		end
	end
	
	ply:SetViewOffset( (ViewOffset[ ply ] or ViewStand) + ViewDiff )
	
	if ViewTwitch[ ply ] then
		ply:SetViewOffsetDucked( ViewOffsetDuck[ ply ] or ViewDuck )
	else
		ply:SetViewOffsetDucked( (ViewOffsetDuck[ ply ] or ViewDuck) + (DuckSet[ ply ] and ViewBase or ViewDiff) )
	end
end
hook.Add( "Move", "InstallView", InstallView )

--[[
	Description: A timer that traces all players each 0.5 seconds rather than 100 times per second
--]]
local function ExecuteTraces()
	local players = player.GetAll()
	for i = 1, #players do
		local ply = players[ i ]
		
		if not TraceData[ ply ] then TraceData[ ply ] = { filter = ply, mask = MainMask } end
		if ActiveTrace[ ply ] then continue end
		
		local n, d = ExecuteTrace( ply )
		if n != nil or d != nil then
			ActiveTrace[ ply ] = true
			ViewOffset[ ply ] = n
			ViewOffsetDuck[ ply ] = d
		else
			ViewOffset[ ply ] = nil
			ViewOffsetDuck[ ply ] = nil
		end
	end
end
timer.Create( "TracePlayerViews", 0.5, 0, ExecuteTraces )

local function ReceiveTwitchUpdate( ply, cmd, args )
	if args == "bypass" then args = { 1 } elseif not Core.CanExecuteCommand( ply ) then return end
	ViewTwitch[ ply ] = tonumber( args[ 1 ] ) == 1
end
concommand.Add( Core.CVar( "set_twitch" ), ReceiveTwitchUpdate )