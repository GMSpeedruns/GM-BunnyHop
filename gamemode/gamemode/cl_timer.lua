-- Prepare for mess!
local fl, fo, sf, ab, od, ot, cl, st, ct, lp, ts = math.floor, string.format, string.find, math.abs, os.date, os.time, math.Clamp, SysTime, CurTime, LocalPlayer, Core.Config.Team.Spectator
local Style, TimeBest, TimeLeft, TimeTop, TimeBegin, TimeEnd, TimeStage, TimeStageEnd, StageID, Bonus = Core.Config.Style.Normal, 0, 0, {}
local ActiveHUD, ActiveNote, IsSpec, IsSimple, IsDelay, IsCool, Is3DVel, IsShowTime, IsShowTimeLeft, IsShowStage, IsHideVel, IsDefault, IsSurfline, IsSpeedometer
local KeyCheck, FColor, StyleName, RankMode, ScrWidth, ScrHeight, Iv, DrawText, DrawBox, DrawBoxEx, DrawColor, DrawRect, DrawOut = input.IsKeyDown, Color, Core.StyleName, Core.Config.Modes, ScrW, ScrH, IsValid, draw.SimpleText, draw.RoundedBox, draw.RoundedBoxEx, surface.SetDrawColor, surface.DrawRect, surface.DrawOutlinedRect
local tal, tar, tac, tat, SimpleFont, SimpleFontS, KeyContext, SetAutoHop = TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, "FullscreenHeader", 30, KEY_C
local HUDBg, HUDPoint, HUDMiddle = Material( Core.Config.MaterialID .. "/hud_layout.png" ), Material( Core.Config.MaterialID .. "/hud_pointer.png" ), Vector( 25 + (165 / 2), 25 + (165 / 2), 0 )
local CBg, CDark, CLight, COldA, COldB, CCool, CCustom = FColor( 0, 0, 0, 160 ), FColor( 25, 25, 25 ), FColor( 255, 255, 255 ), FColor( 35, 35, 35 ), FColor( 42, 42, 42 ), FColor( 230, 126, 34 ), {}
local Vel = { Get = function( p ) return fl( Is3DVel and p:GetVelocity():Length() or p:GetVelocity():Length2D() ) end, Color = function( s, c, a ) return FColor( c.r, c.g, c.b, a or s.Opacity or 0 ) end, Timeout = function( s ) if IsValid( lp() ) and s.Get( lp() ) == 0 then s.Location = 0 s.Opacity = 255 s.Direction = false s.Moving = true s.Active = true else s.Counting = false end end }
local Note = { Max = 4, DisplayTime = 8, GetDeath = function( s, l ) local n = st() + (l or s.DisplayTime) if s.LastDeath then if n - s.LastDeath < 2 then n = s.LastDeath + 2 end end s.LastDeath = n return n end, ShouldBeAt = function( s, n, c ) return (c - n) * 40 + 8 end, History = {} }
local Spec = { List = {}, IsRemote = false, Title = "", Mode = 3, Count = 0, LastSet = st(), Sync = nil, SyncLocal = nil, Window = nil, Background = CBg, Modes = { "First Person", "Chase Cam", "Free Roam" }, Updates = { Resize = 1, Hide = 2 }, Data = { Contains = false, Bot = false, Player = "Unknown", Start = nil, Record = nil } } Spec.DefaultData = table.Copy( Spec.Data )


local function SetStyle( nStyle, nBonus, bPractice )
	if not Iv( lp() ) then Core.RequiredStyle = nStyle return false end
	
	if lp().Style == 13 and nStyle != lp().Style then
		lp().Gravity = true
	elseif nStyle == 13 then
		lp().Gravity = false
	end
	
	if nStyle == 8 or nStyle == 9 then
		SetAutoHop( { Bit = function() return true end } )
	else
		SetAutoHop( { Bit = function() return false end } )
	end
	
	Style = nStyle
	Bonus = nBonus > 0 and nBonus - 1
	Spec.Practice = bPractice
	
	lp().Style = Style
	lp().Bonus = Bonus
	lp().Practice = Spec.Practice
end

local function SetStart( ar )
	local t = ar:UInt( 2 )
	if t == 0 then
		TimeBegin = nil
	elseif t == 1 then
		TimeBegin = st()
	elseif t == 2 then
		TimeBegin = st() - ar:Double()
	end
	
	TimeEnd = nil
	
	if Iv( lp() ) then
		lp():SetJumps( 0 )
	end
end
Core.Register( "Timer/Start", SetStart )

local function SetFinish( ar )
	if not TimeBegin then return end

	TimeEnd = TimeBegin + ar:Double()
	
	local d1, d2, d3, bp = ar:UInt( 16 ), ar:UInt( 16 ), ar:Double(), ar:Bit()
	local str = " (" .. d1 .. " jumps, " .. d2 .. " strafes with " .. d3 .. "% sync" .. (bp and ", " .. ar:Double() .. " points" or "") .. (bp and ", " .. string.format( "%.1f", ar:Double() ) .. "% rank progress" or "") .. ")"
	Core.GetSettings():Misc( "Finish", { d1, d2, d3 } )
	
	local text = ar:ColorText()
	text[ #text + 1 ] = str
	
	Core.Print( "Timer", text )
end
Core.Register( "Timer/Finish", SetFinish )

local function SetRecord( ar )
	TimeBest = ar:Double()
	
	if ar:Bit() then SetStyle( ar:UInt( 8 ), ar:UInt( 4 ), ar:Bit() ) end
end
Core.Register( "Timer/Record", SetRecord )

local function SetInitial( ar )
	for i = 1, ar:UInt( 8 ) do
		TimeTop[ ar:Double() ] = ar:Double()
	end
end
Core.Register( "Timer/Initial", SetInitial )

local function SetTimeLeft( ar )
	TimeLeft = ct() + ar:Double()
end
Core.Register( "Timer/TimeLeft", SetTimeLeft )

SetAutoHop = function( ar )
	if Iv( lp() ) then
		local _,au = Core.GetDuckSet()
		au[ lp() ] = ar:Bit()
	end
end
Core.Register( "Timer/AutoHop", SetAutoHop )

local function ForceSetTimer( ar )
	if ar:Bit() then
		Spec.Data.Start = nil
		Spec.Data.Fixed = ar:Double()
	else
		TimeBegin = 0
		TimeEnd = ar:Double()
	end
end
Core.Register( "Timer/ForceTime", ForceSetTimer )

local function SetRankScalar( ar )
	local mp = math.pow
	local Exponential = function( c, n ) return c * mp( n, 2.9 ) end
	
	for i = 1, ar:UInt( 5 ) do
		local e = ar:Double()
		for j = 1, #Core.Config.Ranks do
			if not Core.Config.Ranks[ j ][ 3 ] then
				Core.Config.Ranks[ j ][ 3 ] = {}
			end
			
			Core.Config.Ranks[ j ][ 3 ][ i ] = Exponential( e, j )
		end
	end
end
Core.Register( "Timer/Ranks", SetRankScalar )

local function SetFreestyle( varArgs )
	if lp and Iv( lp() ) then
		lp().Freestyle = varArgs[ 1 ]
	end
end
Core.Register( "Timer/Freestyle", SetFreestyle )

local function ShowStats( data )
	if data.Specials then
		local t = {}
		t[ #t + 1 ] = data.Duck and "No duck" or nil
		t[ #t + 1 ] = data.TAS and "TAS" or nil
		t[ #t + 1 ] = data.Timescale and "Timescale" or nil
		
		data.Specials = "Specials: " .. string.Implode( ", ", t )
	end
	
	Core.SpawnWindow( { ID = "Stats", Dimension = { x = 200, y = 170, px = 20 }, Args = { Title = " Stats", Custom = data } } )
	
	print( "[" .. data.Title .. "] " .. data.Distance .. " units (Strafes: " .. #data.SyncValues .. ", Prestrafe: " .. data.Prestrafe .. " u/s, " .. (data.UpDist and "Up: " .. data.UpDist .. " u, " or "") .. (data.Edge and "Edge: " .. data.Edge .. " u, " or "") .. "Average Sync: " .. data.Sync .. "%" .. (data.Specials and ", " .. data.Specials or "") .. ")" )
	print( "#", "Speed", "\tGain", "Loss", "Sync", "Time" )
	
	local nThis = math.Round( data.Prestrafe )
	for i = 1, #data.SyncValues do
		local nGain, nLoss = 0, 0
		local nNext = data.SpeedValues[ i ]
		
		if nNext then
			if nNext > nThis then nGain = nNext - nThis
			elseif nNext < nThis then nLoss = nThis - nNext end
			
			nThis = nNext
		end
		
		print( i, nThis .. " u/s", "\t+" .. nGain, nLoss > 0 and "-" .. nLoss or 0, data.SyncValues[ i ] .. "%", data.TimeValues[ i ] .. " ms" )
	end
	
	if data.Title == "Long Jump" then
		local settings = Core.GetSettings()
		if data.Distance > settings:Get( "MaximumLJ", 0 ) then
			settings:Set( "MaximumLJ", data.Distance, true )
		end
	end
end
Core.Register( "Timer/Stats", ShowStats )

local SpaceToggle, SpaceEnabled
local function ToggleSpace( varArgs, bPress )
	local reset = varArgs and varArgs[ 1 ]
	if bPress or reset then
		if reset then
			SpaceEnabled = true
		end
		
		if not SpaceEnabled then
			SpaceEnabled = true
			lp():ConCommand( "+jump" )
		else
			SpaceEnabled = nil
			lp():ConCommand( "-jump" )
		end
	else
		SpaceToggle = not SpaceToggle
		Core.Print( "General", "Automatic space bar holding is now" .. (not SpaceToggle and " no longer" or "") .. " active" )
	end
end
Core.Register( "Timer/Space", ToggleSpace )


local leftbypass, fullbypass
local function BindTracker( ply, bind )
	if (sf( bind, "+left" ) or sf( bind, "+right" )) and not Core.Config.IsSurf then if not leftbypass then return true end
	elseif sf( bind, "+jump" ) and SpaceToggle then ToggleSpace( nil, true )
	elseif bind == "+zoom" or bind == "+strafe" then return true end
end
hook.Add( "PlayerBindPress", "BindPrevention", BindTracker )

local function BindToggler( varArgs )
	if fullbypass then return end
	leftbypass = varArgs[ 1 ]
	fullbypass = varArgs[ 2 ]
end
Core.Register( "Timer/BypassBind", BindToggler )

local ShowGUI = true
local function GUIVisibilityCallback( cv, pr, n )
	ShowGUI = tonumber( n ) == 1
end
cvars.AddChangeCallback( Core.CVar( "showgui" ), GUIVisibilityCallback )

local ShowSpec = true
local function SpecVisibilityCallback( cv, pr, n )
	ShowSpec = tonumber( n ) == 1
	
	if not SpowSpec and Iv( Spec.Window ) then
		Spec.Window:Close()
	elseif ShowSpec then
		Spec:Update( Spec.Updates.Resize, true )
	end
end
cvars.AddChangeCallback( Core.CVar( "showspec" ), SpecVisibilityCallback )

local function ZoneVisibilityCallback( cv, pr, n )
	if not Core.ZonePaint then
		Core.ZonePaint = {}
	end
	
	Core.ZonePaint.Active = tonumber( n ) == 1
	
	for _,data in pairs( Core.ClientEnts or {} ) do
		data[ 3 ] = { Core.ZonePaint.Active }
	end
end
cvars.AddChangeCallback( Core.CVar( "showzones" ), ZoneVisibilityCallback )


local HourTime, MinuteTime, LastDecimal = "%d:%.2d:%.2d.%.3d", "%.2d:%.2d.%.3d"
local function ConvertTime( ns )
	if ns >= 3600 then
		return fo( HourTime, fl( ns / 3600 ), fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
	else
		return fo( MinuteTime, fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
	end
end

function Core.GetTimeConvert()
	return ConvertTime
end

function Core.SetDecimalCount( c, get )
	c = tonumber( c ) or 3
	
	if not get then
		LastDecimal = c
	end
	
	if c == 3 then
		MinuteTime = "%.2d:%.2d.%.3d"
		HourTime = "%d:%.2d:%.2d.%.3d"
	else
		MinuteTime = "%.2d:%.2d" .. (c > 0 and ".%0" .. c .. "." .. c .. "s" or "")
		HourTime = "%d:" .. MinuteTime
	end
	
	return LastDecimal
end

local function GetCurrentTime()
	if not TimeEnd and TimeBegin then
		return st() - TimeBegin
	elseif TimeEnd and TimeBegin then
		return TimeEnd - TimeBegin
	else
		return 0
	end
end

local TimeFormat = { { " [-%.2d:%.2d]", " [+%.2d:%.2d]", " [WR]", " [PB]" }, { " %.2d:%.2d", " +%.2d:%.2d", " WR", " PB" }, { " [PB -%.2d:%.2d]", " [PB +%.2d:%.2d]", " [WR]", " [PB]" }, { " [WR -%.2d:%.2d]", " [WR +%.2d:%.2d]", " [WR]", " [PB]" } }
local function GetTimePiece( nCompare, nStyle, nComp, nFormat, bPB )
	local tFormat, nFirst = TimeFormat[ nFormat or 1 ]
	if nComp then
		nFirst = nComp
	else
		if nStyle then
			nFirst = TimeTop[ nStyle ]
		elseif Bonus then
			nFirst = TimeTop[ Core.MakeBonusStyle( Style, Bonus ) ]
		else
			nFirst = TimeTop[ Style ]
		end
	end
	
	if not nFirst then return nFormat == 2 and "No WR" or "" end
	
	local nDifference = nCompare - nFirst
	local nAbs = ab( nDifference )

	if nDifference < 0 then
		return fo( tFormat[ 1 ], fl( nAbs / 60 ), fl( nAbs % 60 ) )
	elseif nDifference == 0 then
		return tFormat[ bPB and 4 or 3 ]
	else
		return fo( tFormat[ 2 ], fl( nAbs / 60 ), fl( nAbs % 60 ) )
	end
end

local DateFormat = "%H:%M:%S"
local function GetDateTime( real, left )
	if left or (IsShowTimeLeft and not real) then
		left = TimeLeft - ct()
		return string.ToMinutesSeconds( math.Clamp( left, 0, left ) )
	end
	
	return od( DateFormat, ot() )
end

local function GetAmmo( p )
	local wep = p:GetActiveWeapon()
	if Iv( wep ) and wep.Clip1 then
		local nAmmo = p:GetAmmoCount( wep:GetPrimaryAmmoType() )
		return wep:Clip1() .. " / " .. nAmmo, nAmmo > 0
	else
		return "0 / 0"
	end
end

local function GetItemVisibility( nStyle, nID )
	local settings = Core.GetSettings()
	local tab = settings:Get( "NotifyPositions", {} )
	local bits = settings:Get( "NotifyStyles", 0 )
	
	local defv = tab[ Core.StyleName( nStyle ) ] or (nStyle > 1 and "Top #10" or "All")
	local get = tonumber( string.match( defv, "%d+" ) ) or 0
	
	return (get == 0 or nID <= get) and bit.band( bits, math.pow( 2, nStyle ) ) == 0
end

local function PrintHiddenItem( tab )
	if not tab then return end
	
	table.insert( tab, 1, "[Hidden notification]\t" )
	table.insert( tab, 1, color_white )
	table.insert( tab, "\n" )
	
	MsgC( unpack( tab ) )
end


function Spec.GetTitle( s, c )
	return "People " .. (s.IsRemote and "watching " .. (s.Data.Bot and "bot" or "player") or "spectating you") .. ": " .. c
end

function Spec.GetCount( s )
	local n = 0
	for _,i in pairs( s.List ) do
		n = n + 1
	end
	return n
end

function Spec.GetMode( s )
	return s.Modes[ s.Mode ]
end

function Spec.SetList( s, t, r )
	s.List = t
	s.IsRemote = r
	s.Title = s:GetTitle( #t )
	s:Update( #s.List > 0 and s.Updates.Resize or s.Updates.Hide )
end

function Spec.CanSee()
	return GetConVarNumber( Core.CVar( "showothers" ) )
end

function Spec.SetSee( v, d )
	if d then if SysTime() - Spec.LastSet > 0.1 then Spec.DefaultView = v end return end
	Spec.LastSet = SysTime()
	RunConsoleCommand( Core.CVar( "showothers" ), string.format( "%.0f", v ) )
end
Core.SetSpecVis = Spec.SetSee

function Spec.DoClear( varArgs, bSelf )
	Spec.List = {}
	Spec.Data = table.Copy( Spec.DefaultData )
	Spec.Mode = 3
	Spec.Count = 0
	Spec.Sync = nil

	Spec.IsRemote = true
	Spec.Title = ""
	
	if varArgs and varArgs[ 1 ] then
		Spec.DefaultView = Spec.CanSee()
	elseif not bSelf and Spec.DefaultView and Spec.CanSee() != Spec.DefaultView then
		Spec.SetSee( Spec.DefaultView )
	end
	
	local ply = lp()
	if IsValid( ply ) then
		ply.SpecMode = Spec.Mode
	end
	
	Spec:Update( Spec.Updates.Hide )
end
Core.Register( "Spectate/Clear", Spec.DoClear )

function Spec.SetMode( ar )
	Spec.Mode = ar:UInt( 4 )
	lp().SpecMode = Spec.Mode
	
	if Spec.Mode != 1 then
		if Spec.CanSee() < 1 then
			Spec.SetSee( 1 )
		end
		
		if Spec.Mode == 3 then
			Spec.DoClear( nil, true )
		end
	elseif Spec.DefaultView then
		if Spec.CanSee() > 0 and Spec.DefaultView < 1 then
			Spec.SetSee( 0 )
		end
	end
end
Core.Register( "Spectate/Mode", Spec.SetMode )

function Spec.Viewer( ar )
	local leave = ar:Bit()
	local name, uid, state = ar:String(), ar:String(), Spec.Updates.Hide
	
	if not leave then
		if not Spec.List[ uid ] or Spec.List[ uid ] != name then
			Spec.List[ uid ] = name
			state = Spec.Updates.Resize
		end
	else
		if Spec.List[ uid ] then
			Spec.List[ uid ] = nil
			state = Spec.Updates.Resize
		end
	end
	
	Spec.IsRemote = false
	Spec.Count = Spec:GetCount()
	Spec.Title = Spec:GetTitle( Spec.Count )
	Spec:Update( state )
end
Core.Register( "Spectate/Viewer", Spec.Viewer )

function Spec.Timer( ar )
	if ar:Bit() then
		local nTime = ar:Bit() and ar:Double()
		local szName = ar:String()
		local nBest = ar:Bit() and ar:Double()
		
		Spec.Data.Bot = true
		Spec.Data.Start = nTime and nTime > -10000 and st() - nTime
		Spec.Data.Player = szName != "" and szName or "Idle Bot"
		Spec.Data.Best = nBest or 0
		Spec.Data.Draw = false
		Spec.Data.Contains = true
		
		if Spec.Data.Contains and Spec.Data.Bot then
			if Spec.Data.Player != "Idle bot" then
				Spec.Data.OldPlayer = Spec.Data.Player .. " ("
				Spec.Data.Player = Spec.Data.Player .. " (Bot - "
				Spec.Data.Draw = true
			end
		else
			Spec.Data.Player = "Idle bot"
		end
	else
		Spec.Data.Bot = false
		Spec.Data.Start = ar:Bit() and st() - ar:Double()
		Spec.Data.Best = ar:Bit() and ar:Double()
		Spec.Data.Fixed = nil
		Spec.Data.Contains = true
	end

	local t = ar:UInt( 4 )
	if t == 2 then
		local list = {}
		
		for i = 1, ar:UInt( 8 ) do
			list[ i ] = ar:String()
		end
		
		if #list > 0 then
			Spec:SetList( list, true )
			Spec.Count = Spec:GetCount()
		end
	elseif t == 0 then
		Spec:SetList( {}, true )
		Spec.Count = 0
	end
	
	Spec.Data.Multi = nil
end
Core.Register( "Spectate/Timer", Spec.Timer )

function Spec.Update( s, state, special )
	if not Iv( s.Window ) then
		if not ShowSpec or not IsDefault or special then return end
		
		s.Window = vgui.Create( "DFrame" )
		s.Window:SetTitle( "" )
		s.Window:SetDraggable( false )
		s.Window:ShowCloseButton( false )
		
		s.Window:SetSize( 0, 0 )
		s.Window:SetPos( 0, 0 )
		
		s.Window.Think = function( s )
			if not ShowGUI or not IsDefault then s:Close() end
			
			local t = Iv( lp() ) and lp():Team() or -5
			if not s.Break then
				if t == ts and not Spec.IsRemote then
					s.Break = true
				elseif t != ts and Spec.IsRemote then
					s.Break = true
				end
			else
				if t == ts and Spec.IsRemote then
					s.Break = false
				elseif t != ts and not Spec.IsRemote then
					s.Break = false
				end
			end
		end
		
		s.Window.Background = s.Background
		s.Window.Paint = function( s, w, h )
			if s.Break then return end
			DrawBoxEx( 8, 0, 0, w, h, s.Background, true, true, false, false )
			
			DrawBoxEx( 8, 0, 0, w, 30, s.Background, true, true, false, false )
			DrawText( Spec.Title, "BottomHUDSemi", w / 2, 14, CLight, tac, tac )
			
			local nOffset = 48
			for _,name in pairs( Spec.List ) do
				DrawText( "- " .. name, "BottomHUDTiny", 10, nOffset, CLight, tal, tat )
				nOffset = nOffset + 20
			end
		end
	elseif not ShowSpec then
		s.Window:Close()
		return
	end

	local x, y = s.Window:GetSize()
	local dx, dy = x, y
	
	if state == s.Updates.Hide then
		x, y = 0, 0
	elseif state == s.Updates.Resize then
		local w, h = 0, 0
		s.List["custom"] = s.Title
		
		for _,t in pairs( s.List ) do
			surface.SetFont( "BottomHUDSemi" )
			local wx, wy = surface.GetTextSize( t )
			wx = wx + 16
			h = h + wy + 2
			if wx > w then w = wx end
		end
		
		s.List["custom"] = nil
		
		if w > 0 or h > 0 then
			x, y = w, h + 16
		else
			x, y = 0, 0
			state = s.Updates.Hide
		end
	end
	
	if s:GetCount() == 0 then
		x, y = 0, 0
		state = s.Updates.Hide
	end
	
	if x != dx or y != dy then
		if x > 0 and y > 0 then
			s.Window:SetPos( ScrWidth() - x - 20, ScrHeight() - 60 - y )
		end
		
		s.Window:SetSize( x, y )
	end
end

function Spec.SetSync( ar )
	local str = ar:String()
	if str == "" then
		str = nil
	end
	
	local args = {}
	if ar:Bit() then
		args[ 1 ] = ar:Double()
		args[ 2 ] = ar:UInt( 16 )
		args[ 3 ] = ar:UInt( 16 )
	end
	
	Spec.Sync = str
	Spec.SyncEx = args[ 1 ]
	Spec.Strafes = args[ 2 ]
	Spec.Jumps = args[ 3 ]
end
Core.Register( "Timer/SetSync", Spec.SetSync )


function Note.Remove( ctrl )
	ctrl.Details.Start = SysTime()
	ctrl.Think = function( s )		
		s:SetAlpha( Lerp( (SysTime() - s.Details.Start) * 2, 255, 0 ) )
		if s:GetAlpha() == 0 then
			table.remove( Note.List )
			s:Remove()
			
			if #Note.Queue > 0 then
				local queued = table.remove( Note.Queue, 1 )
				Note.Add( queued, #Note.List )
			end
		end
	end
end

function Note.Add( item, count )
	if not Iv( ActiveNote ) then return end

	surface.SetFont( "FullscreenSubtitle" )
	local mw, tw = ActiveNote:GetWide(), surface.GetTextSize( item.Title )
	
	local x, y = math.min( tw + 48, mw ), count * 40 + 8
	item.Start = x
	item.Top = y
	item.Final = mw - x
	item.Death = Note:GetDeath( item.Life )
	Note.History[ #Note.History + 1 ] = item.Title
	
	local ctrl = vgui.Create( "DButton", ActiveNote )
	ctrl:SetCursor( "hand" )
	ctrl:SetText( "" )
	ctrl:SetPos( mw, y )
	ctrl:SetSize( x, 32 )
	ctrl:SetPaintBackgroundEnabled( false )
	ctrl:SetPaintBorderEnabled( false )
	ctrl:MoveTo( item.Final, item.Top, 0.5, 0, 3, function( anim, se ) se.Details.Completed = true end )
	ctrl.Details = item
	
	if ctrl.Details.Flash then
		ctrl.Details.Flash = { SysTime(), 255, 0 }
	end
	
	ctrl.Think = function( s )
		if SysTime() > s.Details.Death and not s.Removing then
			s.Removing = true
			Note.Remove( s )
			return
		end
		
		local at, count = 0, #Note.List
		for i = 1, count do
			if Note.List[ i ] == s then
				at = i
				break
			end
		end
		
		if at > 0 and not s.IsMoving then
			local x, y = s:GetPos()
			local should = Note:ShouldBeAt( at, count )
			if y != should then
				s.IsMoving = true
				s:MoveTo( not s.Details.Completed and s.Details.Final or x, should, 0.5, 0, 3, function( anim, se ) se.IsMoving = false se.Details.Completed = true end )
			end
		end
	end
	
	ctrl.Paint = function( s, w, h )
		if not ShowGUI then return end
		
		local opacity
		if s.Details.Flash then
			opacity = Lerp( (SysTime() - ctrl.Details.Flash[ 1 ]) * 2, ctrl.Details.Flash[ 2 ], ctrl.Details.Flash[ 3 ] )
			
			if opacity == 0 or opacity == 255 then
				ctrl.Details.Flash[ 1 ] = SysTime()
				ctrl.Details.Flash[ 2 ] = opacity > 0 and 255 or 0
				ctrl.Details.Flash[ 3 ] = opacity > 0 and 0 or 255
			end
		end
	
		local c = s.Details.Color
		DrawColor( Color( c.r, c.g, c.b, opacity ) )
		DrawOut( 0, 0, w, h )
		DrawBox( 0, 1, 1, w - 2, h - 2, CBg )
		
		local o = 16
		if s.Details.Icon then
			surface.SetMaterial( s.Details.Icon )
			DrawColor( CLight )
			surface.DrawTexturedRect( 8, 8, 16, 16 )
			o = o + 16
		end
		
		DrawText( s.Details.Title, "FullscreenSubtitle", o, h / 2 - 1, CLight, tal, tac )
	end
	
	ctrl.DoClick = function( s )
		if #Note.History > 0 then
			for i = 1, #Note.History do
				print( "[Note history]", Note.History[ i ] )
			end
			
			Core.Print( "General", "A list of all previous notifications has been printed in your console." )
		end
	end
	
	table.insert( Note.List, 1, ctrl )
end

function Note.Receive( varArgs )
	if not Note.List then Note.List = {} end
	if not Note.Queue then Note.Queue = {} end

	local setting = Core.GetSettings():ToggleValue( "HUD_NOTIFICATION" )
	if setting == "None" then return print( "[Hidden pop-up]", varArgs[ 2 ] or "Blank" ) end
	
	local item = {}
	item.Title = varArgs[ 2 ] or ""
	item.Icon = varArgs[ 3 ] and Material( "icon16/" .. varArgs[ 3 ] .. ".png" )
	item.Color = Core.Config.Prefixes[ varArgs[ 1 ] ] or varArgs[ 1 ] or CLight
	item.Life = varArgs[ 4 ]
	item.Flash = varArgs[ 6 ]
	
	if setting == "Chat only" then print( "[Pop-up notification]", item.Title ) end
	if varArgs[ 5 ] and varArgs[ 5 ] != "" and (setting == "Chat only" or setting == "Both") then
		Core.Print( varArgs[ 1 ], varArgs[ 5 ] )
	end

	if setting == "Popups only" or setting == "Both" then
		local current = #Note.List
		if current >= Note.Max then
			table.insert( Note.Queue, 1, item )
			return false
		end
		
		Note.Add( item, current )
	end
end

function Note.ReceiveAr( ar )
	Note.Receive( { ar:String(), ar:String(), ar:String(), ar:UInt( 8 ), ar:String() } )
end
Core.Register( "Global/Notify", Note.ReceiveAr )

function Note.ReceiveMulti( ar )
	local settings = Core.GetSettings()
	local szType = ar:String()
	
	if settings:ToggleValue( "NOTIFY_NOTHING" ) then return PrintHiddenItem( { "Type " .. szType } ) end
	if szType == "BaseFinish" then
		if settings:ToggleValue( "NOTIFY_SPECMSG" ) then
			Core.Print( "Timer", ar:ColorText() )
		end
	elseif szType == "ImproveFinish" then
		local text = ar:ColorText()
		local pos, style, ent = ar:UInt( 16 ), ar:UInt( 8 ), ar:UInt( 16 )
		
		if ar:Bit() then
			local str = ar:String()
			if settings:ToggleValue( "NOTIFY_WRSOUND" ) and Core.Config.RemoteURL then
				sound.PlayURL( Core.Config.RemoteURL .. str, "", function( so )
					if not IsValid( so ) then return end
					if IsValid( Note.WR ) then
						Note.WR:SetVolume( 0 )
						Note.WR:Stop()
						Note.WR = nil
					end
					
					Note.WR = so
					Note.WR:Play()
				end )
			end
		end
		
		local top = ar:Bit() and ar:ColorText()
		if GetItemVisibility( style, pos ) or lp():EntIndex() == ent then
			Core.Print( "Timer", text )
			
			if top then
				Core.Print( "Timer", top )
				
				if pos == 1 then
					Note.Receive( { "Timer", "New map record" .. (style > 1 and " on " .. Core.StyleName( style ) or ""), "clock_go", 6, nil, true } )
				end
			end
		end
	elseif szType == "StageSlow" then
		if not settings:ToggleValue( "NOTIFY_STAGE" ) then return end
		local str, spec = ar:ColorText(), ar:Bit()
		if (not spec and settings:ToggleValue( "HUD_STAGE" )) or (spec and settings:ToggleValue( "NOTIFY_SPECMSG" ) and settings:ToggleValue( "NOTIFY_STAGESPEC" )) then
			Core.Print( "Timer", str )
		end
	elseif szType == "StageFast" then
		if not settings:ToggleValue( "NOTIFY_STAGE" ) then return end
		
		local texto, textr, textt = ar:ColorText(), ar:ColorText(), ar:Bit() and ar:ColorText()
		local pos, style, ent = ar:UInt( 16 ), ar:UInt( 8 ), ar:UInt( 16 )
		
		if lp():EntIndex() == ent then
			Core.Print( "Timer", texto )
			if textt then Core.Print( "Timer", textt ) end
		else
			if settings:ToggleValue( "NOTIFY_STAGETOP" ) then
				if textt then
					Core.Print( "Timer", textr )
					Core.Print( "Timer", textt )
				end
			elseif GetItemVisibility( style, pos ) then
				Core.Print( "Timer", textr )
				if textt then Core.Print( "Timer", textt ) end
			end
		end
	elseif szType == "TAS" then
		if settings:ToggleValue( "NOTIFY_TAS" ) then
			Core.Print( "Timer", ar:ColorText() )
		end
	elseif szType == "Popup" then
		if settings:ToggleValue( "NOTIFY_SPECMSG" ) then
			Note.ReceiveAr( ar )
		end
	elseif szType == "LJ" then
		if settings:ToggleValue( "NOTIFY_LJS" ) then
			local name, dist, pre, sync, strafes, duck, edge = ar:String(), ar:Double(), ar:Double(), ar:Double(), ar:UInt( 8 )
			if ar:Bit() then
				duck = ar:Bit()
				edge = ar:Double()
			end
			
			local text = ar:ColorText()
			local minimal = tonumber( settings:ToggleValue( "NOTIFY_LJMIN" ) ) or 0
			
			if dist >= minimal then
				Core.Print( "Timer", text )
				
				print( "[LJ by " .. name .. "] " .. dist .. " units (Strafes: " .. strafes .. ", Prestrafe: " .. pre .. " u/s, " .. (edge and "Edge: " .. edge .. " u, " or "") .. "Average Sync: " .. sync .. "%" .. (duck and ", Specials: No duck" or "") .. ")" )
			end
		end
	elseif szType == "OJ" then
		Core.Print( "Timer", ar:ColorText() )
	end
end
Core.Register( "Global/NotifyMulti", Note.ReceiveMulti )

local function ChangeMouseSetting( bool )
	if Core.ChangeContext( bool ) then return end	
	if not Iv( ActiveHUD ) then return end
	
	if bool then
		if not ActiveHUD.IsMouseEnabled then
			ActiveHUD.IsMouseEnabled = true
			ActiveHUD:MakePopup()
		end
	elseif ActiveHUD.IsMouseEnabled then
		ActiveHUD.IsMouseEnabled = false
		ActiveHUD:SetMouseInputEnabled( false )
		ActiveHUD:SetKeyboardInputEnabled( false )
	end
end

function Core.SetDefaultHud( bool )
	IsDefault = bool
end

function Core.SetSurflineHud( bool )
	IsSurfline = bool
end

function Core.SetSpeedometerHud( bool )
	IsSpeedometer = bool
end

function Core.SetSimpleHud( bool )
	IsSimple = bool
	
	if not Core.StartSend.Departed then
		Core.StartSend.Simple = bool
	else
		RunConsoleCommand( Core.CVar( "set_simple" ), bool and "1" or "0" )
	end
end

function Core.SetPermSync( bool )
	if not Core.StartSend.Departed then
		Core.StartSend.Sync = bool
	else
		RunConsoleCommand( Core.CVar( "set_sync" ), bool and "1" or "0" )
	end
end

function Core.SetThirdperson( bool )
	if not Core.StartSend.Departed then
		Core.StartSend.Third = bool
	else
		RunConsoleCommand( Core.CVar( "set_third" ), bool and "1" or "0" )
	end
end

function Core.SetCool( ar )
	local d = ar:UInt( 6 )
	if d == 0 then
		IsCool = nil
	else
		IsCool = ct() + d
	end
end
Core.Register( "Timer/UnrealReset", Core.SetCool )

local KickTime
function Core.SetKickFunc( varArgs )
	if varArgs and varArgs[ 1 ] then
		if varArgs[ 2 ] then
			return varArgs[ 1 ]
		end
		
		KickTime = varArgs[ 1 ]
		timer.Create( "PlayerKicker", 0.1, 0, function()
			if KickTime == GetDateTime( true ) then
				RunConsoleCommand( "say", "/remainingtries finalize " .. KickTime )
				Core.SetKickFunc()
			end
		end )
		
		Core.GetSettings():Set( "KickTime", KickTime, true )
	else
		KickTime = nil
		timer.Remove( "PlayerKicker" )
		
		if varArgs then
			Core.GetSettings():Set( "KickTime", KickTime, true )
		end
	end
end
Core.Register( "Timer/Kicker", Core.SetKickFunc )

local NameCache = {}
function Core.GetPlayerName( uid, fn, arg )
	if not uid or not fn then return end
	if NameCache[ uid ] then
		fn( uid, NameCache[ uid ], arg )
	else
		steamworks.RequestPlayerInfo( uid )
		
		timer.Simple( 1, function()
			local name = steamworks.GetPlayerName( uid )
			if not name or name == "[unknown]" then
				name = "Failed to load player name"
			else
				NameCache[ uid ] = name
			end
			
			fn( uid, name, arg )
		end )
	end
end

local FontNames = { ["Large"] = { 40, "BottomHUDVelocity" }, ["Medium"] = { 30, "FullscreenHeader" }, ["Small"] = { 20, "BottomHUDSemi" } }
function Core.SetSimpleFont( font )
	SimpleFont = FontNames[ font ][ 2 ]
	SimpleFontS = FontNames[ font ][ 1 ]
end

function Core.GetTimeDifference( b, t )
	t = t or GetCurrentTime()
	
	return t > 0 and GetTimePiece( t, nil, b, 1 ) or "", t
end

function Core.GetAllowedKeys()
	local tab, num = {}, {}
	for i = 65, 90 do
		tab[ #tab + 1 ] = string.char( i )
		num[ tab[ #tab ] ] = _G[ "KEY_" .. tab[ #tab ] ]
	end
	return tab, num
end

function Core.SetContextKey( key )
	local t,n = Core.GetAllowedKeys()
	KeyContext = n[ key ] or KEY_C
end

local Opacities = { ["Black"] = 255, ["Dark"] = 200, ["Default"] = 160, ["Vague"] = 100, ["Light"] = 40, ["Invisible"] = 0 }
function Core.GetHUDOpacities()
	local tab = {}
	for name,_ in pairs( Opacities ) do
		tab[ #tab + 1 ] = name
	end
	return tab
end

function Core.SetHUDOpacity( value )
	CBg.a = Opacities[ value ]
end

function Core.SetVelocityType( bool )
	Is3DVel = bool
end

function Core.SetShowDateTime( bool )
	IsShowTime = bool
end

function Core.SetShowTimeLeft( bool )
	IsShowTimeLeft = bool
end

function Core.SetShowStage( bool )
	IsShowStage = bool
end

function Core.SetShowVelocity( bool )
	IsHideVel = bool
end

function Core.SetUseCustomColors( bool )
	CCustom.Use = bool
end

function Core.SetCustomColor( key, value )
	CCustom[ key ] = Core.ParseColor( value )
end

function Core.TranslateColor( col, prefix )
	if CCustom.Use then
		if prefix then
			local translate = { ["Timer"] = 5, ["General"] = 6, ["Notification"] = 7, ["Radio"] = 8, [Core.Config.ServerName] = 9 }
			for p,c in pairs( Core.Config.Prefixes ) do
				if c == col then
					local i = translate[ p ]
					if CCustom[ i ] and CCustom[ i ] != Color( 255, 255, 255, 0 ) then
						return CCustom[ i ]
					end
				end
			end
		else
			for i = 1, #Core.Config.Colors do
				if Core.Config.Colors[ i ] == col then
					if CCustom[ i ] and CCustom[ i ] != Color( 255, 255, 255, 0 ) then
						return CCustom[ i ]
					end
				end
			end
		end
		
		return col
	end
	
	return col
end

function Core.ParseColor( str, def )
	local spl = string.Explode( " ", str )
	local col = def or Color( 255, 255, 255 )
	
	if #spl >= 3 and #spl <= 4 then
		local valid = true
		for i = 1, #spl do
			spl[ i ] = tonumber( spl[ i ] )
			
			if not spl[ i ] or spl[ i ] < 0 or spl[ i ] > 255 or math.floor( spl[ i ] ) != spl[ i ] then
				valid = false
			end
		end
		
		if valid then
			col = Color( spl[ 1 ], spl[ 2 ], spl[ 3 ], spl[ 4 ] )
		end
	end
	
	return col
end

function Core.TranslateString( str )
	local c = LastDecimal or 3
	if c == 3 then return str end
	
	for k in string.gmatch( str, "%d+:%d+.%d+" ) do
		str = string.gsub( str, k, string.sub( k, 1, #k - 4 ) .. (c > 0 and string.format( ".%0" .. c .. "." .. c .. "s", tonumber( string.sub( k, #k - 2, #k ) ) ) or "") )
	end
	
	return str
end

function Core.SetStage( ar )
	if not Core.GetSettings():ToggleValue( "HUD_STAGE" ) then return end
	
	local id = ar:UInt( 3 )
	if id == 0 then
		StageID = nil
		TimeStage = nil
	elseif id == 1 then
		StageID = "Stage " .. ar:UInt( 8 ) .. ": "
		TimeStage = st()
		TimeStageEnd = nil
	elseif id == 2 then
		StageID = "Stage " .. ar:UInt( 8 ) .. ": "
		TimeStageEnd = ar:Double()
		TimeStage = nil
	elseif id == 3 then
		StageID = "Checkpoint " .. ar:UInt( 8 ) .. ": "
		TimeStage = st()
		TimeStageEnd = nil
	elseif id == 4 then
		StageID = "Checkpoint " .. ar:UInt( 8 ) .. ": "
	end
end
Core.Register( "Timer/Stage", Core.SetStage )

function Core.SetCheckpointDelay( varArgs )
	if varArgs and varArgs[ 1 ] then
		if type( varArgs[ 1 ] ) == "string" then
			Core.SetPlayerMarkers()
		else
			IsDelay = ct() + 9.95
			
			Core.SetPlayerMarkers( varArgs )
		end
	else
		IsDelay = ct() + 1.5
	end
end
Core.Register( "Timer/RaceDelay", Core.SetCheckpointDelay )


function Core.CreateHUD()
	if Iv( ActiveHUD ) then
		ActiveHUD:Close()
		ActiveHUD = nil
	end
	
	ActiveHUD = vgui.Create( "DFrame" )
	ActiveHUD:SetTitle( "" )
	ActiveHUD:SetDraggable( false )
	ActiveHUD:ShowCloseButton( false )

	ActiveHUD:SetSize( ScrWidth(), 60 )
	ActiveHUD:SetPos( 0, ScrHeight() - ActiveHUD:GetTall() )
	
	ActiveHUD.Think = function( s )
		s.DrawVis = ShowGUI
		
		local lpc = lp()
		if not Iv( lpc ) then return end
		
		IsSpec = lpc:Team() == ts
		
		if lpc:IsTyping() or IsValid( DermaRequest ) or gui.IsConsoleVisible() then return end
		if KeyCheck( 1 ) then return Core.RequestClose( nil, true ) end
		if KeyCheck( KeyContext ) then
			if not s.Context then
				s.Context = true
				ChangeMouseSetting( true )
			end
		elseif s.Context then
			s.Context = nil
			ChangeMouseSetting( false )
		end
	end
	
	ActiveHUD.Paint = function( s )
		if not Iv( ActiveHUD ) then return end
		if not s.DrawVis or not IsDefault then return end
		
		local lpc = lp()
		local w, h = s:GetWide(), s:GetTall()
		DrawColor( CBg )
		DrawRect( 0, 0, w, h )
		
		if IsSpec then
			local ob = lpc:GetObserverTarget()
			if Iv( ob ) and ob:IsPlayer() then
				local nStyle, nRank = ob:VarNet( "Get", "Style", 1 ), ob:VarNet( "Get", "Rank", -1 )
				local szText = ob:IsBot() and (Spec.Data.Draw and Spec.Data.Player .. StyleName( nStyle ) .. ")" or Spec.Data.Player) or ob:Name() .. (RankMode[ nRank ] and " (" .. RankMode[ nRank ][ 1 ] .. " - " .. StyleName( nStyle ) .. ")" or " (" .. StyleName( nStyle ) .. " style)")
				DrawText( szText, "BottomHUDSpec", w / 2, 25, CDark, tac, tac )
				DrawText( szText, "BottomHUDSpec", w / 2, 24, CLight, tac, tac )
				
				local nCurrent, nRecord, szCurrent, szPbest = 0, 0, "", "Player's Best:"
				if Spec.Data.Contains then
					nCurrent = Spec.Data.Start and st() - Spec.Data.Start or Spec.Data.Fixed or 0
					szCurrent = ConvertTime( nCurrent ) .. GetTimePiece( nCurrent, nStyle, nil, 4 )
					nRecord = Spec.Data.Best and Spec.Data.Best or 0
					if Spec.Data.Bot then
						szPbest = "Run Duration:"
						if not Spec.Data.Multi and nStyle > 1 then Spec.Data.Multi = true end
					end
				end
				
				if nRecord > 0 and nRank != -10 then
					DrawText( "Current Time:", "BottomHUDTime", 20, 21, CDark, tal, tac )
					DrawText( "Current Time:", "BottomHUDTime", 20, 19, CLight, tal, tac )
					DrawText( szCurrent, "BottomHUDTime", 140, 21, CDark, tal, tac )
					DrawText( szCurrent, "BottomHUDTime", 140, 19, CLight, tal, tac )
					
					local szBest = ConvertTime( nRecord ) .. GetTimePiece( nCurrent, nStyle, nRecord, 3, true )
					DrawText( szPbest, "BottomHUDTime", 20, 41, CDark, tal, tac )
					DrawText( szPbest, "BottomHUDTime", 20, 39, CLight, tal, tac )
					DrawText( szBest, "BottomHUDTime", 140, 41, CDark, tal, tac )
					DrawText( szBest, "BottomHUDTime", 140, 39, CLight, tal, tac )
				else
					local szTime = nRank == -10 and "Practice Mode" or "Current Time:  " .. szCurrent
					DrawText( szTime, "BottomHUDVelocity", 20, 32, CDark, tal, tac )
					DrawText( szTime, "BottomHUDVelocity", 20, 30, CLight, tal, tac )
				end
				
				if not IsHideVel then
					local szSpeed = fo( "%.0f u/s", Vel.Get( ob ) )
					DrawText( szSpeed, "BottomHUDTiny", w / 2, h - 11, CDark, tac, tac )
					DrawText( szSpeed, "BottomHUDTiny", w / 2, h - 12, CLight, tac, tac )
				end
				
				if Spec.SyncLocal then
					Spec.SyncLocal = nil
				end
				
				if Spec.Data.Multi then
					local tx1, tx2 = "This is a multi bot. It can play multiple styles", "Type /mbot for more info"
					DrawText( tx1, "BottomHUDTime", w - 20, 8, CDark, tar )
					DrawText( tx1, "BottomHUDTime", w - 20, 6, CLight, tar )
					DrawText( tx2, "BottomHUDTime", w - 20, 28, CDark, tar )
					DrawText( tx2, "BottomHUDTime", w - 20, 26, CLight, tar )
				end
			end
		else
			if not Iv( lpc ) then return end
			
			local nCurrent = GetCurrentTime()
			local szCurrent = ConvertTime( nCurrent ) .. GetTimePiece( nCurrent, nil, nil, 4 )
			
			if TimeBest > 0 then
				DrawText( "Current Time:", "BottomHUDTime", 20, 21, CDark, tal, tac )
				DrawText( "Current Time:", "BottomHUDTime", 20, 19, CLight, tal, tac )
				DrawText( szCurrent, "BottomHUDTime", 140, 21, CDark, tal, tac )
				DrawText( szCurrent, "BottomHUDTime", 140, 19, CLight, tal, tac )
				
				local szBest = ConvertTime( TimeBest ) .. GetTimePiece( nCurrent, nil, TimeBest, 3, true )
				DrawText( "Personal Best:", "BottomHUDTime", 20, 41, CDark, tal, tac )
				DrawText( "Personal Best:", "BottomHUDTime", 20, 39, CLight, tal, tac )
				DrawText( szBest, "BottomHUDTime", 140, 41, CDark, tal, tac )
				DrawText( szBest, "BottomHUDTime", 140, 39, CLight, tal, tac )
			else
				local szTime = lpc.Practice and "Practice Mode" or "Current Time:  " .. szCurrent
				DrawText( szTime, "BottomHUDVelocity", 20, 32, CDark, tal, tac )
				DrawText( szTime, "BottomHUDVelocity", 20, 30, CLight, tal, tac )
			end
			
			local wep = lpc:GetActiveWeapon()
			if Iv( wep ) and wep.Clip1 then
				local nAmmo = lpc:GetAmmoCount( wep:GetPrimaryAmmoType() )
				local szWeapon = wep:Clip1() .. " / " .. nAmmo
				if nAmmo > 0 then
					DrawText( szWeapon, "BottomHUDVelocity", w - 20, 30, CDark, tar, tac )
					DrawText( szWeapon, "BottomHUDVelocity", w - 20, 28, CLight, tar, tac )
					
					if not Spec.SyncLocal then
						Spec.SyncLocal = true
					end
				elseif Spec.SyncLocal then
					Spec.SyncLocal = nil
				end
			elseif Spec.SyncLocal then
				Spec.SyncLocal = nil
			end
			
			if IsCool then
				local szText = fo( "%.1f", IsCool - ct() )
				if ct() > IsCool then szText = "0.0" IsCool = nil end
				szText = "Cooldown: " .. szText
				
				DrawText( szText, "BottomHUDVelocity", w / 2 + 350, 32, CDark, tac, tac )
				DrawText( szText, "BottomHUDVelocity", w / 2 + 350, 30, CLight, tac, tac )
			elseif IsShowStage and StageID then
				if not TimeStage then StageID = nil return end
				local szText = StageID .. ConvertTime( TimeStageEnd and TimeStageEnd or (st() - TimeStage) )
				DrawText( szText, "BottomHUDVelocity", w / 2 + 350, 32, CDark, tac, tac )
				DrawText( szText, "BottomHUDVelocity", w / 2 + 350, 30, CLight, tac, tac )
			end
			
			if not IsHideVel then
				local nSpeed = Vel.Get( lpc )
				local szSpeed = fo( "Velocity: %.0f u/s", nSpeed )
				DrawText( szSpeed, "BottomHUDVelocity", w / 2, 32, Vel:Color( CDark ), tac, tac )
				DrawText( szSpeed, "BottomHUDVelocity", w / 2, 30, Vel:Color( CLight ), tac, tac )
				
				if Vel.Active or Vel.Moving then
					if Vel.Moving then if Vel.Direction then if Vel.Location <= 0 then Vel.Location = Vel.Location + 0.1 Vel.Opacity = Vel.Opacity + 2.55 if Vel.Location >= 0 then Vel.Location = 0 Vel.Opacity = 255 Vel.Moving = false end end else if Vel.Location >= -10 then Vel.Location = Vel.Location - 0.1 Vel.Opacity = Vel.Opacity - 2.55 if Vel.Location <= -10 then Vel.Location = -10 Vel.Opacity = 0 Vel.Moving = false Vel.Active = false Vel.Counting = false end end end end
					
					local cp = cl( nSpeed, 0, 3500 ) / 3500
					local cw, ch = cp * 184, Vel.Location
					DrawColor( Color( 0, 0, 0, 150 ) )
					DrawRect( w / 2 - 92, h - 3 - ch, 184, 3 )
					DrawColor( Color( 52, 152, 219, 100 + cp * 155 ) )
					DrawRect( w / 2 - cw / 2, h - 3 - ch, cw, 3 )
					
					if not Vel.Counting and nSpeed == 0 and Vel.Active then
						Vel.Counting = true
						timer.Simple( 1, function() Vel:Timeout() end )
					end
				elseif not Vel.Active and nSpeed > 100 then
					Vel.Location = -10 Vel.Opacity = 0 Vel.Moving = true Vel.Direction = true Vel.Active = true
				end
			end
		end
		
		if Spec.Sync then
			if Spec.SyncLocal then
				DrawText( Spec.Sync, "BottomHUDTime", w - 180, 32, CDark, tar, tac )
				DrawText( Spec.Sync, "BottomHUDTime", w - 180, 30, CLight, tar, tac )
			elseif not Spec.Data.Bot then
				DrawText( Spec.Sync, "BottomHUDVelocity", w - 20, 30, CDark, tar, tac )
				DrawText( Spec.Sync, "BottomHUDVelocity", w - 20, 28, CLight, tar, tac )
			end
		end
		
		if IsShowTime then
			local tm = GetDateTime()
			DrawText( tm, "HUDLabelSmall", w - 20, h - 8, CDark, tar, tac )
			DrawText( tm, "HUDLabelSmall", w - 20, h - 10, CLight, tar, tac )
		end
	end
	
	if Iv( ActiveNote ) then
		ActiveNote:Close()
		ActiveNote = nil
	end
	
	ActiveNote = vgui.Create( "DFrame" )
	ActiveNote:SetTitle( "" )
	ActiveNote:SetDraggable( false )
	ActiveNote:ShowCloseButton( false )
	
	ActiveNote:SetSize( ScrWidth() * 0.5, ScrHeight() * 0.15 )
	ActiveNote:SetPos( ScrWidth() - ActiveNote:GetWide() - 10, 0 )
	
	ActiveNote.Think = function() end
	ActiveNote.Paint = function() end
end

local function BaseHUDDraw()
	if not ShowGUI then return end
	
	local lpc = lp()
	local spec = lpc:Team() == ts
	if spec then
		local text, subt, hw = Spec:GetMode() .. " - Press R to change spectate mode", "Cycle through players with left/right mouse", ScrW() / 2
		DrawText( text, "FullscreenHeader", hw, 22, CDark, tac )
		DrawText( text, "FullscreenHeader", hw, 20, CLight, tac )
		DrawText( subt, "FullscreenSubtitle", hw, 52, CDark, tac )
		DrawText( subt, "FullscreenSubtitle", hw, 50, CLight, tac )
	elseif IsDelay then
		local szText = fo( "%.1f", IsDelay - ct() )
		if ct() > IsDelay then szText = "" IsDelay = nil end
		
		DrawText( szText, "ScoreboardMassive", ScrWidth() / 2, ScrHeight() / 2 - 150, Color( 0, 120, 255 ), tac, tac )
	end
	
	if not IsSurfline and not IsSimple and not IsSpeedometer then return end
	local w, h = ScrWidth(), ScrHeight()
	local hw, nh = w / 2, h - 30
	
	if spec then
		local ob = lpc:GetObserverTarget()
		if Iv( ob ) and ob:IsPlayer() then
			local nStyle, nRank = ob:VarNet( "Get", "Style", 1 ), ob:VarNet( "Get", "Rank", -1 )
			
			if IsSimple then
				local x, y, a = 20, 30, SimpleFontS
				DrawText( "Spectating: " .. (ob:IsBot() and (Spec.Data.Draw and Spec.Data.Player .. StyleName( nStyle ) .. ")" or Spec.Data.Player) or ob:Name() .. (RankMode[ nRank ] and " (" .. RankMode[ nRank ][ 1 ] .. " - " .. StyleName( nStyle ) .. ")" or " (" .. StyleName( nStyle ) .. " style)")), SimpleFont, x, y, CLight, tal, tac ) y = y + a
				
				local nRecord, szCurrent = 0, ""
				if Spec.Data.Contains then
					local nCurrent = Spec.Data.Start and st() - Spec.Data.Start or Spec.Data.Fixed or 0
					szCurrent = ConvertTime( nCurrent ) .. GetTimePiece( nCurrent, nStyle )
					nRecord = Spec.Data.Best and Spec.Data.Best or 0
				end

				DrawText( nRecord > 0 and "Time:  " .. szCurrent .. " / " .. ConvertTime( nRecord ) .. GetTimePiece( nRecord, nStyle ) or "Time:  " .. szCurrent, SimpleFont, x, y, CLight, tal, tac ) y = y + a

				if Spec.Sync then
					local sync = Spec.SyncEx and Spec.Sync .. " / " .. Spec.SyncEx .. "%" or Spec.Sync
					DrawText( sync, SimpleFont, x, y, CLight, tal, tac ) y = y + a
					
					if Spec.Strafes then DrawText( "Strafes: " .. Spec.Strafes, SimpleFont, x, y, CLight, tal, tac ) y = y + a end
					if Spec.Jumps then DrawText( "Jumps: " .. Spec.Jumps, SimpleFont, x, y, CLight, tal, tac ) y = y + a end
				end
				
				DrawText( fo( "Velocity: %.0f u/s", Vel.Get( ob ) ), SimpleFont, x, y, CLight, tal, tac )
				if Spec.Count > 0 then DrawText( "Spectators: " .. Spec.Count, SimpleFont, x, y + a, CLight, tal, tac ) end
			end
			
			if IsSurfline then
				DrawColor( COldA )
				DrawRect( 20, h - 115, 230, 95 )
				DrawColor( COldB )
				DrawRect( 25, h - 115 + 5, 220, 55 )
				DrawRect( 25, h - 115 + 65, 220, 25 )
				
				DrawText( "Time:", "HUDTimer", 32, h - 115 + 20, CLight, tal, tac )
				DrawText( "PB:", "HUDTimer", 32, h - 115 + 45, CLight, tal, tac )

				local szRecord, szCurrent = "", ""
				if Spec.Data.Contains then
					local nCurrent = Spec.Data.Start and st() - Spec.Data.Start or Spec.Data.Fixed or 0
					local nRecord = Spec.Data.Best and Spec.Data.Best or 0
					szCurrent = ConvertTime( nCurrent ) .. GetTimePiece( nCurrent, nStyle )
					szRecord = ConvertTime( nRecord ) .. GetTimePiece( nRecord, nStyle )
				end
				
				DrawText( szCurrent, "HUDTimer", 96, h - 115 + 20, CLight, tal, tac )
				DrawText( szRecord, "HUDTimer", 96, h - 115 + 45, CLight, tal, tac )

				if not IsHideVel then
					local nSpeed = Vel.Get( ob )
					local cp = cl( nSpeed, 0, 3500 ) / 3500
					DrawColor( Color( 42 + cp * 213, 42, 42 ) )
					DrawRect( 25, h - 115 + 65, cp * 220, 25 )
					DrawText( fo( "%.0f u/s", nSpeed ), "HUDSpeed", 135, h - 115 + 77, CLight, tac, tac )
				else
					DrawText( "0 u/s", "HUDSpeed", 135, h - 115 + 77, CLight, tac, tac )
				end
			
				if Spec.Sync then
					DrawText( Spec.Sync, "HUDTimer", w - 20, h / 2 - 80, CLight, tar, tat )
				end
				
				local szHeader = ob:IsBot() and "Spectating Bot" or "Spectating"
				DrawText( szHeader, "HUDHeaderBig", hw + 2, nh - 58, CDark, tac )
				DrawText( szHeader, "HUDHeaderBig", hw, nh - 60, Color( 214, 59, 43, 255 ), tac )

				local szText = ob:IsBot() and (Spec.Data.Draw and Spec.Data.OldPlayer .. StyleName( nStyle ) .. ")" or Spec.Data.Player) or ob:Name() .. (RankMode[ nRank ] and " (" .. RankMode[ nRank ][ 1 ] .. " - " .. StyleName( nStyle ) .. ")" or " (" .. StyleName( nStyle ) .. " style)")
				DrawText( szText, "HUDHeader", hw + 2, nh - 18, CDark, tac )
				DrawText( szText, "HUDHeader", hw, nh - 20, CLight, tac )
			end
		end
		
		if IsShowTime then
			local tm = GetDateTime()
			DrawText( tm, "HUDLabelSmall", w - 20, h - 8, CDark, tar, tac )
			DrawText( tm, "HUDLabelSmall", w - 20, h - 10, CLight, tar, tac )
		end
		
		if not Spec.IsRemote then return end
	else		
		if not Iv( lpc ) then return end
		
		if IsSimple then
			local x, y, a = 20, 30, SimpleFontS
			local t = GetCurrentTime()
			DrawText( lpc.Practice and "Practice Mode" or "Time: " .. ConvertTime( t ) .. GetTimePiece( t, nil, TimeBest > 0 and TimeBest, 1 ), SimpleFont, x, y, CLight, tal, tac ) y = y + a
			DrawText( "To WR: " .. GetTimePiece( t, nil, nil, 2 ), SimpleFont, x, y, CLight, tal, tac ) y = y + a
			
			if Spec.Sync then
				local sync = Spec.SyncEx and Spec.Sync .. " / " .. Spec.SyncEx .. "%" or Spec.Sync
				DrawText( sync, SimpleFont, x, y, CLight, tal, tac ) y = y + a
				
				if Spec.Strafes then DrawText( "Strafes: " .. Spec.Strafes, SimpleFont, x, y, CLight, tal, tac ) y = y + a end
				if Spec.Jumps then DrawText( "Jumps: " .. Spec.Jumps, SimpleFont, x, y, CLight, tal, tac ) y = y + a end
			end
			
			if Spec.Count > 0 then DrawText( "Spectators: " .. Spec.Count, SimpleFont, x, y, CLight, tal, tac ) y = y + a end
			
			if IsCool then
				local szText = fo( "%.1f", IsCool - ct() )
				if ct() > IsCool then szText = "0.0" IsCool = nil end
				
				DrawText( "Unreal cooldown: " .. szText, SimpleFont, x, y, CLight, tal, tac ) y = y + a
			end

			DrawText( fo( "Velocity: %.0f u/s", Vel.Get( lpc ) ), SimpleFont, x, y, CLight, tal, tac )
			y = y + a

			local ammo, show = GetAmmo( lpc )
			if show then
				DrawText( "Ammo: " .. ammo, SimpleFont, x, y, CLight, tal, tac )
			end
		end
		
		if IsSurfline then
			DrawColor( COldA )
			DrawRect( 20, h - 115, 230, 95 )
			DrawColor( COldB )
			DrawRect( 25, h - 115 + 5, 220, 55 )
			DrawRect( 25, h - 115 + 65, 220, 25 )
			
			DrawText( "Time:", "HUDTimer", 32, h - 115 + 20, CLight, tal, tac )
			DrawText( "PB:", "HUDTimer", 32, h - 115 + 45, CLight, tal, tac )
			
			local nCurrent, nSpeed = GetCurrentTime(), Vel.Get( lpc )
			DrawText( lpc.Practice and "Practice Mode" or ConvertTime( nCurrent ) .. GetTimePiece( nCurrent ), "HUDTimer", 96, h - 115 + 20, CLight, tal, tac )
			DrawText( ConvertTime( TimeBest ) .. GetTimePiece( TimeBest ), "HUDTimer", 96, h - 115 + 45, CLight, tal, tac )

			if not IsHideVel then
				local cp = cl( nSpeed, 0, 3500 ) / 3500
				DrawColor( Color( 42 + cp * 213, 42, 42 ) )
				DrawRect( 25, h - 115 + 65, cp * 220, 25 )
				DrawText( fo( "%.0f u/s", nSpeed ), "HUDSpeed", 135, h - 115 + 77, CLight, tac, tac )
			else
				DrawText( "0 u/s", "HUDSpeed", 135, h - 115 + 77, CLight, tac, tac )
			end
		
			if Spec.Sync then
				DrawText( Spec.Sync, "HUDTimer", w - 20, h / 2 - 80, CLight, tar, tat )
				
				if Spec.SyncEx then
					DrawText( "Sync B: " .. Spec.SyncEx .. "%", "HUDTimer", w - 20, h / 2 - 60, CLight, tar, tat )
				end
			end
			
			if IsCool then
				local szText = fo( "%.1f", IsCool - ct() )
				if ct() > IsCool then szText = "0.0" IsCool = nil end
				
				DrawText( szText .. "s Unreal cooldown", "HUDTimer", w - 20, h - 60, CLight, tar, tac )
			end

			local ammo, show = GetAmmo( lpc )
			if show then
				DrawText( ammo, "BottomHUDVelocity", w - 20, h - 28, CDark, tar, tac )
				DrawText( ammo, "BottomHUDVelocity", w - 20, h - 30, CLight, tar, tac )
			end
		end
		
		if IsSpeedometer then
			surface.SetMaterial( HUDBg )
			DrawColor( CLight )
			surface.DrawTexturedRect( 25, h - 25 - 165, 394, 165 )
			
			local speed = Vel.Get( lpc )
			surface.SetMaterial( HUDPoint )
			DrawColor( CLight )
			surface.DrawTexturedRectRotated( HUDMiddle.x, h - HUDMiddle.y, 5, 140, 360 - 300 * cl( speed / 2000, 0, 1 ) )
			
			DrawText( "Time:", "HUDSpeedBase", 200, h - 136, CLight, tal, tac )
			DrawText( "Record:", "HUDSpeedBase", 200, h - 111, CLight, tal, tac )
			
			DrawText( ConvertTime( GetCurrentTime() ), "HUDSpeedBase", 290, h - 136, CLight, tal, tac )
			DrawText( ConvertTime( TimeBest ), "HUDSpeedBase", 290, h - 111, CLight, tal, tac )
			
			DrawText( "Remaining:", "HUDSpeedSmall", 200, h - 84, CLight, tal, tac )
			DrawText( "Velocity:", "HUDSpeedSmall", 200, h - 69, CLight, tal, tac )
			DrawText( "Ammunition:", "HUDSpeedSmall", 200, h - 54, CLight, tal, tac )
			
			DrawText( GetDateTime( nil, true ), "HUDSpeedSmall", 290, h - 84, CLight, tal, tac )
			DrawText( speed .. " u/s", "HUDSpeedSmall", 290, h - 69, CLight, tal, tac )
			DrawText( GetAmmo( lpc ), "HUDSpeedSmall", 290, h - 54, CLight, tal, tac )
			
			DrawText( string.sub( StyleName( Style ), 1, 1 ), "HUDSpeedSmall", 180, h - 54, CLight, tal, tac )
		end
		
		if IsShowTime then
			local tm = GetDateTime()
			DrawText( tm, "HUDLabelSmall", w - 20, h - 8, CDark, tar, tac )
			DrawText( tm, "HUDLabelSmall", w - 20, h - 10, CLight, tar, tac )
		end
		
		if Spec.IsRemote then return end
	end
	
	if IsSurfline and ShowSpec and Spec.Count > 0 then
		local nStart = h / 2 - 50
		local nOffset, bDrawn = nStart + 20, false
		for _,name in pairs( Spec.List ) do
			if not bDrawn then
				DrawText( Spec.Title, "HUDLabelSmall", w - 165, nStart, CLight, tal, tat )
				bDrawn = true
			end
			
			DrawText( "- " .. name, "HUDLabelSmall", w - 165, nOffset, CLight, tal, tat )
			nOffset = nOffset + 15
		end
	end
end
hook.Add( "HUDPaint", "BaseHUDDraw", BaseHUDDraw )