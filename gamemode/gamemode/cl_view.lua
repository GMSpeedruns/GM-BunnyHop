local lp, ut, ct, mm, Iv, GetVec, MainMask = LocalPlayer, util.TraceLine, CurTime, math.min, IsValid, Vector, MASK_PLAYERSOLID
local PlayerData, DuckSet = Core.Config.Player, Core.GetDuckSet()
local HullDuck, HullStand = PlayerData.HullDuck, PlayerData.HullStand
local ViewStand, ViewDuck, ViewDiff, ViewBase = PlayerData.ViewStand, PlayerData.ViewDuck, PlayerData.ViewOffset, PlayerData.ViewBase
local TraceData, ActiveTrace, ViewOffset, ViewOffsetDuck, ViewTwitch = {}, {}, {}, {}

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
	
	if ViewTwitch then
		ply:SetViewOffsetDucked( ViewOffsetDuck[ ply ] or ViewDuck )
	else
		ply:SetViewOffsetDucked( (ViewOffsetDuck[ ply ] or ViewDuck) + (DuckSet[ ply ] and ViewBase or ViewDiff) )
	end
end
hook.Add( "Move", "InstallView", InstallView )

local function ExecuteTraces()
	local ply = lp()
	if not Iv( ply ) then return end
	
	if not TraceData[ ply ] then TraceData[ ply ] = { filter = ply, mask = MainMask } end
	if ActiveTrace[ ply ] then return end
	
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
timer.Create( "TracePlayerViews", 0.5, 0, ExecuteTraces )

function Core.SetViewTwitch( value )
	ViewTwitch = value
	
	if not Core.StartSend.Departed then
		Core.StartSend.Twitch = value
	else
		RunConsoleCommand( Core.CVar( "set_twitch" ), value and "1" or "0" )
	end
end

function Core.UpdateClientViews()
	HullStand = PlayerData.HullStand
	ViewStand = PlayerData.ViewStand
	ViewDiff = PlayerData.ViewOffset
end

local LastCheck, Players, StyleName = ct()
local DrawCol, DrawPos, DrawIcon, ts = Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, Material( "icon16/exclamation.png" ), TEAM_SPECTATOR
local Styles, Names, Markers = {}, {}, {}
local IsEnabled, IsPlayers, IsIDs

local function PlayerVisibilityCallback( CVar, Previous, New )
	IsPlayers = tonumber( New ) == 1
	IsEnabled = IsPlayers and IsIDs
end
cvars.AddChangeCallback( Core.CVar( "showothers" ), PlayerVisibilityCallback )

local function IDVisibilityCallback( CVar, Previous, New )
	IsIDs = tonumber( New ) == 1
	IsEnabled = IsPlayers and IsIDs
end
cvars.AddChangeCallback( Core.CVar( "targetids" ), IDVisibilityCallback )

local function InitLabelCallback()
	IsPlayers = GetConVar( Core.CVar( "showothers" ) ):GetBool()
	IsIDs = GetConVar( Core.CVar( "targetids" ) ):GetBool()
	IsEnabled = IsPlayers and IsIDs
end
hook.Add( "InitPostEntity", "LabelVisibilityCheck", InitLabelCallback )

local function DrawPlayerMarkers()
	if not IsPlayers then return end
	
	local lpc = lp()
	if not Iv( lpc ) then return end
	if not Markers[ lpc ] then return end
	
	render.DepthRange( 0, 0 )
	
	for v,_ in pairs( Markers ) do
		v:DrawModel()
	end
	
	render.DepthRange( 0, 1 )
end

function Core.SetPlayerMarkers( list )
	Markers = {}
	
	if list then
		for _,id in pairs( list ) do
			local ply = Entity( id )
			if IsValid( ply ) then
				Markers[ ply ] = true
			end
		end
	end
	
	local valid = 0
	for _,p in pairs( Markers ) do
		if IsValid( p ) then
			valid = valid + 1
		end
	end
	
	if valid > 0 then
		hook.Add( "PostDrawOpaqueRenderables", "PlayerMarkers", DrawPlayerMarkers )
	else
		hook.Remove( "PostDrawOpaqueRenderables", "PlayerMarkers" )
	end
end

local function DrawTargetIDs()
	if not IsEnabled then return end
	
	local lpc = lp()
	if not Iv( lpc ) then return end
	if lpc:Team() == ts and lpc.SpecMode != 3 then return end
	
	if not Players or ct() - LastCheck > 2 then
		Players = player.GetAll()
		
		if not StyleName then
			StyleName = Core and Core.StyleName
		end
		
		if StyleName then
			for i = 1, #Players do
				local ply = Players[ i ]
				Styles[ ply ] = StyleName( ply:VarNet( "Get", "Style", 1 ) )
				
				if ply:IsBot() then
					Names[ ply ] = ply:VarNet( "Get", "BotName", "" )
				end
			end
		end
	end
	
	local pos = lpc:GetPos()
	for i = 1, #Players do
		local ply = Players[ i ]
		if ply == lpc or not ply:Alive() then continue end
		
		local ppos = ply:GetPos()
		local diff = (ppos - pos):Length()
		
		if diff < 200 then
			local pos2d = Vector( ppos.x, ppos.y, ppos.z + 50 ):ToScreen()
			if ply:IsBot() then
				local set = Names[ ply ] or ""
				local additional
				
				if set == "" then
					set = ply:Name() .. " (Idle)"
				else
					additional = "Run by: " .. set
					set = ply:Name() .. " (" .. (Styles[ ply ] or "") .. " Bot)"
				end
				
				draw.SimpleText( set, "BottomHUDTiny", pos2d.x, pos2d.y, DrawCol, DrawPos )
				
				if additional then
					draw.SimpleText( additional, "BottomHUDTiny", pos2d.x, pos2d.y + 20, DrawCol, DrawPos )
				end
			else
				draw.SimpleText( ply:Name() .. " (" .. (Styles[ ply ] or "") .. ")", "BottomHUDTiny", pos2d.x, pos2d.y, DrawCol, DrawPos )
			end
		end
		
		if Markers[ ply ] then
			local pos2d = Vector( ppos.x, ppos.y, ppos.z + 90 ):ToScreen()
			if pos2d.visible then
				surface.SetMaterial( DrawIcon )
				surface.SetDrawColor( DrawCol )
				surface.DrawTexturedRect( pos2d.x - 8, pos2d.y, 16, 16 )
			end
		end
	end
end
hook.Add( "HUDPaint", "TargetIDDraw", DrawTargetIDs )