-- Attempt exact selection
local Servers = include( "modules/sh_config.lua" )
local CurrentDL, Public, Vars = GetConVar( "sv_downloadurl" ):GetString(), Servers and Servers._public
if not Public then return error( "Unable to load base config" ) end

-- Check for single server setup
local ResolveType = Public.Single

-- Find matching
if not ResolveType then
	for gt,details in pairs( Servers ) do
		if details.FastDL == CurrentDL then
			ResolveType = gt
		end
	end
end

-- Alternative resolve types
if not Servers[ ResolveType ] then
	if SERVER then
		Vars = include( "modules/sv_config.lua" )
		CurrentDL = Vars and Vars.Get( "ServerDL" ) or ""

		for gt,details in pairs( Servers ) do
			if details.FastDL == CurrentDL then
				ResolveType = gt
			end
		end
	end

	if not Servers[ ResolveType ] then
		if SERVER then
			timer.Simple( 1, function()
				RunConsoleCommand( "changelevel", game.GetMap() )
			end )
		end

		return error( "Unable to determine gamemode type!" )
	end
elseif CLIENT then
	if not acthink then
		return error( "Unable to load dependencies!" )
	elseif debug.getinfo( acthink ).source != string.reverse( "aul.taehcitna_lc/tneilc/nurotua/aul@" ) then
		return error( "Unable to load required dependency!" )
	elseif file.IsDir( string.reverse( "koohtpircs" ), string.reverse( "HTAP_ELBATUCEXE" ) ) then
		return error( "Unable to initialize core!" )
	end
elseif SERVER then
	Vars = include( "modules/sv_config.lua" )
end

-- Final verification
if SERVER and not Vars then
	return error( "Failed to load config module!" )
end


-- Begin with the real config table
local _C = {}
_C.Var = Vars
_C.GameType = ResolveType
_C.ResolveType = Servers[ ResolveType ]
_C.BaseType = _C.ResolveType.Base
_C.FullName = _C.ResolveType.Name
_C.DisplayName = _C.ResolveType.Short
_C.ServerName = Public.ServerName
_C.MaterialID = Public.Material
_C.Prefix = Public.Prefix
_C.Identifier = Public.Identifier
_C.BasePath = _C.MaterialID .. "/"
_C.IsSurf = _C.BaseType == "surf"
_C.IsBhop = _C.BaseType == "bhop"
_C.IsPack = _C.IsSurf and _C.Var and _C.Var.GetBool( "UseJumpPack" )
_C.IsDebug = _C.Var and _C.Var.GetBool( "ServerDebug" )
_C.PageSize = _C.Var and _C.Var.GetInt( "PageSize" )
_C.Version, _C.MaxZones, _C.NetReceive = 8.50, 256, 0

_C.Team = { Players = 1, Spectator = TEAM_SPECTATOR }
_C.Style = { Normal = 1, SW = 2, HSW = 3, ["W-Only"] = 4, ["A-Only"] = 5, ["D-Only"] = 6, ["S-Only"] = 7, Legit = 8, ["Easy Scroll"] = 9, [_C.IsPack and "Jump Pack" or "Stamina"] = 10, Unreal = 11, Backwards = 12, ["Low Gravity"] = 13 }
_C.MaxStyle, _C.PracticeStyle, _C.BonusStyle = _C.Style["Low Gravity"], -10, 0

_C.Player = {
	DefaultModel = "models/player/group01/male_01.mdl",
	DefaultBot = "models/player/kleiner.mdl",
	DefaultWeapon = "weapon_glock",

	ScrollPower = 268.4,
	StepSize = 18,

	JumpPower = _C.Var and _C.Var.GetBool( "CSSJumps" ) and math.sqrt( 2 * 800 * 57.81 ) or 290,
	LowGravity = _C.Var and _C.Var.GetFloat( "GravityMultiplier" ) or 0,
	JumpPack = _C.Var and _C.Var.GetFloat( "PackMultiplier" ) or 0,
	StrafeMultiplier = _C.Var and _C.Var.GetBool( "CSSGains" ) and 30 or 32.4,
	StartSpeed = _C.Var and _C.Var.GetInt( "StartLimit" ) or 0,
	AirAcceleration = _C.IsBhop and (_C.Var and _C.Var.GetBool( "CSSGains" ) and 1200 or 500) or 120,

	HullMin = Vector( -16, -16, 0 ),
	HullDuck = Vector( 16, 16, 45 ),
	HullStand = Vector( 16, 16, _C.Var and _C.Var.GetBool( "CSSDuck" ) and 54 or 62 ),
	HullMax = Vector( 16, 16, 62 ),
	ViewDuck = Vector( 0, 0, 47 ),
	ViewStand = Vector( 0, 0, _C.Var and _C.Var.GetBool( "CSSDuck" ) and 56 or 64 ),
	ViewOffset = Vector( 0, 0, _C.Var and _C.Var.GetBool( "CSSDuck" ) and 8 or 0 ),
	ViewBase = Vector( 0, 0, 0 )
}

_C.Prefixes = {
	["Timer"] = Color( 52, 152, 219 ),
	["General"] = Color( 46, 204, 113 ),
	["Admin"] = Color( 76, 60, 231 ),
	["Notification"] = Color( 231, 76, 60 ),
	["Radio"] = Color( 230, 126, 34 ),
	[_C["ServerName"]] = Color( 52, 73, 94 ),

	["[SQL] "] = Color( 0, 255, 255 ),
	["[Startup] "] = Color( 200, 0, 0 ),
	["[Error] "] = Color( 255, 0, 255 ),
	["[Event] "] = Color( 255, 255, 0 ),
	["[Load] "] = Color( 0, 200, 0 ),
	["[Control] "] = Color( 200, 200, 0 )
}

_C.Colors = {
	Color( 168, 230, 161 ),
	Color( 161, 203, 230 ),
	Color( 230, 188, 161 ),
	Color( 223, 161, 230 )
}

_C.Ranks = {
	{ "Unranked", Color( 255, 255, 255 ) },
	{ "Pleb", Color( 166, 166, 166 ) },
	{ "Commoner", Color( 255, 255, 98 ) },
	{ "Amateur", Color( 0, 8, 8 ) },
	{ "Inept", Color( 101, 67, 33 ) },
	{ "Humbled", Color( 250, 218, 221 ) },
	{ "Getting There", Color( 196, 255, 196 ) },
	{ "Respectable", Color( 0, 50, 32 ) },
	{ "Adept", Color( 128, 128, 128 ) },
	{ "Experienced", Color( 96, 16, 176 ) },
	{ "Skilful", Color( 255, 192, 203 ) },
	{ "Noteworthy", Color( 0, 0, 139 ) },
	{ "Impressive", Color( 0, 0, 60 ) },
	{ "Prestigious", Color( 206, 255, 157 ) },
	{ "Exceptional", Color( 255, 128, 0 ) },
	{ "Phenomenal", Color( 30, 166, 48 ) },
	{ "Masterful", Color( 52, 152, 219 ) },
	{ "Supreme", Color( 231, 76, 60 ) },
	{ "Elite", Color( 255, 255, 0 ) },
	{ "Renowned", Color( 142, 68, 173 ) },
	{ "Famous", Color( 0, 168, 255 ) },
	{ "Illustrious", Color( 255, 101, 0 ) },
	{ "Wicked", Color( 0, 255, 128 ) },
	{ "Insane", Color( 255, 0, 0 ) },
	{ "Beast", Color( 253, 182, 50 ) },
	{ "Unreal", Color( 52, 73, 94 ) },
	{ "Unstoppable", Color( 0, 255, 191 ) },
	{ "Legendary", Color( 190, 255, 0 ) },
	{ "Mythical", Color( 255, 0, 255 ) },
	{ "Fabled", Color( 129, 222, 8 ) },
	{ "Supernatural", Color( 92, 196, 207 ) },
	{ "Almighty", Color( 0, 255, 0 ) },
	{ "Divine", Color( 255, 235, 0 ) },
	{ "Supersonic", Color( 0, 255, 191 ) },
	{ "Super Saiyan", Color( 255, 0, 64 ) },
	{ "Angelic", Color( 150, 255, 255 ) },
	{ "God", Color( 0, 255, 255 ) }
}

_C.Modes = {
	[-10] = { "Practice", Color( 255, 255, 255 ) },
	[-20] = { "TAS", Color( 82, 123, 188 ) }
}

Core = {}
Core.Config = _C

GM.Name = _C.IsBhop and "Bunny Hop" or (_C.IsSurf and "Surf")
GM.DisplayName = "Prestige Gaming"
GM.Author = "Gravious"
GM.Email = ""
GM.Website = ""
GM.TeamBased = true

local PLAYER = FindMetaTable( "Player" ), DeriveGamemode( "base" ), util.PrecacheModel( _C.Player.DefaultModel ), util.PrecacheModel( _C.Player.DefaultBot )
local mc, mad, bn, ba, bo, sl, mf, ib, paa, pmv, pjp, plg = math.Clamp, math.AngleDifference, bit.bnot( IN_JUMP ), bit.band, bit.bor, string.lower, math.floor, _C.IsBhop, _C.Player.AirAcceleration, _C.Player.StrafeMultiplier, _C.Player.JumpPack, _C.Player.LowGravity
local lp, Iv, Ip, ft, ic, is, isl, ct, gf, ds, du, pj, og, tv, at, ac, au = LocalPlayer, IsValid, IsFirstTimePredicted, FrameTime, CLIENT, SERVER, MOVETYPE_LADDER, CurTime, {}, {}, {}, {}, {}, {}, {}, {}, {}

function GM:CreateTeams()
	team.SetUp( _C.Team.Players, "Players", Color( 255, 50, 50, 255 ), false )
	team.SetUp( _C.Team.Spectator, "Spectators", Color( 50, 255, 50, 255 ), true )
	team.SetSpawnPoint( _C.Team.Players, { "info_player_terrorist", "info_player_counterterrorist" } )
end

function GM:PlayerNoClip( ply )
	if not ply:Alive() then return false end
	if ply:Team() == _C.Team.Spectator then return false end

	if not ply.Practice then
		if SERVER then
			Core.Print( ply, "Timer", Core.Text( "StyleNoclip" ) )
		end

		return false
	end

	return not not ply.Practice
end

function GM:PlayerUse( ply )
	if not ply:Alive() then return false end
	if ply:Team() == _C.Team.Spectator then return false end
	if ply:GetMoveType() != MOVETYPE_WALK then return false end

	return true
end

function GM:Move( ply, data )
	if ply:IsOnGround() or not ply:Alive() or ply:IsBot() then return end

	local aa, mv = paa, pmv
	local aim = data:GetMoveAngles()
	local forward, right = aim:Forward(), aim:Right()
	local fmove = data:GetForwardSpeed()
	local smove = data:GetSideSpeed()

	local st = ply.Style
	if st == 1 then
		if data:KeyDown( 1024 ) then smove = smove + 500 end
		if data:KeyDown( 512 ) then smove = smove - 500 end
	elseif st == 2 then
		if data:KeyDown( 8 ) then fmove = fmove + 500 end
		if data:KeyDown( 16 ) then fmove = fmove - 500 end
	elseif st == 8 then
		aa = ply:Crouching() and 20 or 50
	elseif st == 9 or st == 10 then
		aa = 120
	elseif st == 11 then
		aa, mv = 2000, 50

		if data:KeyDown( 512 ) or data:KeyDown( 1024 ) then
			smove = smove * 500
		end
	elseif st == 13 and is then
		local g = ply:GetGravity()
		if ply.Freestyle then
			ply:SetGravity( 0 )
		elseif mf( g * 10 ) / 10 != plg then
			if g == 0 then
				ply:SetGravity( plg )
			elseif g == 1 then
				timer.Simple( 0.1, function()
					ply:SetGravity( plg )
				end )
			end
		end
	end

	forward.z, right.z = 0,0
	forward:Normalize()
	right:Normalize()

	local vel = data:GetVelocity()
	local wishvel = forward * fmove + right * smove
	wishvel.z = 0

	local wishspeed = wishvel:Length()
	if wishspeed > data:GetMaxSpeed() then
		wishvel = wishvel * (data:GetMaxSpeed() / wishspeed)
		wishspeed = data:GetMaxSpeed()
	end

	local wishspd = wishspeed
	wishspd = mc( wishspd, 0, mv + (mc( vel:Length2D() - 500, 0, 500 ) / 1000) * 1.4 )

	local wishdir = wishvel:GetNormal()
	local current = vel:Dot( wishdir )

	local addspeed = wishspd - current
	if addspeed <= 0 then return end

	local accelspeed = aa * ft() * wishspeed
	if accelspeed > addspeed then
		accelspeed = addspeed
	end

	vel = vel + (wishdir * accelspeed)
	data:SetVelocity( vel )

	return false
end

local function ChangeMove( ply, data )
	if ply:IsBot() then return end
	if not ply:IsOnGround() then
		if not du[ ply ] then
			gf[ ply ] = 0
			ds[ ply ] = nil
			du[ ply ] = true

			ply:SetDuckSpeed( 0 )
			ply:SetUnDuckSpeed( 0 )

			if _C.Player.HullStand != _C.Player.HullMax then
				ply:SetHull( _C.Player.HullMin, _C.Player.HullStand )
			end
		end

		local st = ply.Style
		if st > 1 and st < 8 and not ply.Freestyle and ply:GetMoveType() != 8 then
			if st == 2 or st == 4 or st == 7 then
				data:SetSideSpeed( 0 )

				if st == 4 and data:GetForwardSpeed() < 0 then
					data:SetForwardSpeed( 0 )
				elseif st == 7 and data:GetForwardSpeed() > 0 then
					data:SetForwardSpeed( 0 )
				end
			elseif st == 5 then
				data:SetForwardSpeed( 0 )

				if data:GetSideSpeed() > 0 then
					data:SetSideSpeed( 0 )
				end
			elseif st == 6 then
				data:SetForwardSpeed( 0 )

				if data:GetSideSpeed() < 0 then
					data:SetSideSpeed( 0 )
				end
			elseif st == 3 then
				if ib and ba( data:GetButtons(), 16 ) > 0 then
					local bd = data:GetButtons()
					if ba( bd, 512 ) > 0 or ba( bd, 1024 ) > 0 then
						data:SetForwardSpeed( 0 )
						data:SetSideSpeed( 0 )
					end
				end

				if data:GetForwardSpeed() == 0 or data:GetSideSpeed() == 0 then
					data:SetForwardSpeed( 0 )
					data:SetSideSpeed( 0 )
				end
			end
		end

		if ic and ply.Gravity != nil then
			if ply.Gravity or ply.Freestyle then
				ply:SetGravity( 0 )
			else
				ply:SetGravity( plg )
			end
		end

		local v = data:GetVelocity():Length2D()
		if v > tv[ ply ] then tv[ ply ] = v end

		at[ ply ] = at[ ply ] + v
		ac[ ply ] = ac[ ply ] + 1
	else
		local st = ply.Style
		if gf[ ply ] > 12 then
			if not ds[ ply ] then
				if st == 9 then
					ply:SetJumpPower( _C.Player.JumpPower )
				end

				ply:SetDuckSpeed( 0.4 )
				ply:SetUnDuckSpeed( 0.2 )

				if _C.Player.HullStand != _C.Player.HullMax and not util.TraceLine( { filter = ply, mask = MASK_PLAYERSOLID, start = ply:EyePos(), endpos = ply:EyePos() + Vector( 0, 0, 24 ) } ).Hit then
					ply:SetHull( _C.Player.HullMin, _C.Player.HullMax )
				end

				ds[ ply ] = true
			end
		else
			gf[ ply ] = gf[ ply ] + 1

			if gf[ ply ] == 1 then
				du[ ply ] = nil

				if st == 9 then
					ply:SetJumpPower( _C.Player.ScrollPower )
				end

				if pj[ ply ] then
					pj[ ply ] = pj[ ply ] + 1
				end
			elseif gf[ ply ] > 1 and data:KeyDown( 2 ) and not au[ ply ] then
				if ic and gf[ ply ] < 4 then return end

				local vel = data:GetVelocity()
				vel.z = ply:GetJumpPower()

				ply:SetDuckSpeed( 0 )
				ply:SetUnDuckSpeed( 0 )
				gf[ ply ] = 0

				data:SetVelocity( vel )
			end
		end
	end
end
hook.Add( "SetupMove", "ChangeMove", ChangeMove )

local function ChangePlayerAngle( ply, cmd )
	if ply:IsBot() then return end
	if ply.Style == 12 and not ply:IsOnGround() then
        local d = mad( cmd:GetViewAngles().y, ply:GetVelocity():Angle().y )
		if d > -100 and d < 100 then
			cmd:SetForwardMove( 0 )
			cmd:SetSideMove( 0 )
		end
	end
end
hook.Add( "StartCommand", "ChangeAngles", ChangePlayerAngle )

local function AutoHop( ply, data )
	if ply:IsBot() or au[ ply ] then return end
	if ba( data:GetButtons(), 2 ) > 0 then
		if not ply:IsOnGround() and ply:WaterLevel() < 2 and ply:GetMoveType() != 9 then
			data:SetButtons( ba( data:GetButtons(), bn ) )
		end
	end
end
hook.Add( "SetupMove", "DoAutoHop", AutoHop )

local function ProcessFire( ply )
	if not ply.IsGlock then return end

	local weapon = ply:GetActiveWeapon()
	if Iv( weapon ) and weapon.IsGlock then
		weapon:FireExtraBullets()
	end
end
hook.Add( "PlayerPostThink", "ProcessFire", ProcessFire )

local function SetInitialFrames( ply )
	gf[ ply ] = 0
	tv[ ply ] = 0
	at[ ply ] = 0
	ac[ ply ] = 0
end
hook.Add( "PlayerInitialSpawn", "SetInitialFrames", SetInitialFrames )

local function JumpPack( ply, data )
	if ply.Style != 10 then return end
	if ba( data:GetButtons(), 2 ) > 0 then
		local jpv = data:GetVelocity()
		jpv.z = jpv.z + pjp * ft()
		data:SetVelocity( jpv )
	end
end

if _C.IsPack then
	hook.Add( "SetupMove", "ProcessJumpPack", JumpPack )
end

function GM:CreateMove() end
function GM:SetupMove() end
function GM:FinishMove() end

local MainStand, IdleActivity, round = ACT_MP_STAND_IDLE, ACT_HL2MP_IDLE, math.Round
function GM:CalcMainActivity() return MainStand, -1 end
function GM:TranslateActivity() return IdleActivity end

local StyleNames = {}
local CustomNames = { [2] = "Sideways", [3] = "Half Sideways" }

for name,id in pairs( _C.Style ) do
	StyleNames[ id ] = CustomNames[ id ] or name
end

function Core.StyleName( nID )
	return StyleNames[ nID ] or "Invalid"
end

function Core.IsValidStyle( nStyle )
	if not nStyle then return false end
	return not not StyleNames[ nStyle ]
end

function Core.GetBonusStyle( nStyle )
	local st,id = math.modf( math.abs( nStyle ) )
	return st, round( id * 10 )
end

function Core.MakeBonusStyle( nStyle, nID )
	return -nStyle - (nID + 1) / 10
end

function Core.GetStyleID( szStyle, bFind )
	for id,s in pairs( StyleNames ) do
		if bFind and string.find( sl( szStyle ), sl( s ), 1, true ) or (sl( s ) == sl( szStyle )) then
			return id
		end
	end

	return 0
end

function Core.SetStyle( nID, data )
	StyleNames[ nID ] = data
end

function Core.GetStyles()
	local tab = {}
	for name,id in pairs( _C.Style ) do
		tab[ id ] = StyleNames[ id ]
	end
	return tab
end

function Core.ObtainRank( nID, nStyle, bScore )
	local mode = _C.Modes[ nID ]
	local data = mode or _C.Ranks[ nID ]

	if not data then
		return "Retrieving...", color_white
	end

	local rank = data[ 1 ]
	if mode then
		if nID == -20 and nStyle > 50 then nStyle = nStyle - 50 end
		rank = rank .. " - " .. Core.StyleName( nStyle )
	elseif nStyle != _C.Style.Normal then
		rank = Core.StyleName( nStyle ) .. " - " .. rank
	end

	return bScore and data[ 1 ] or rank, data[ 2 ]
end

function Core.GetRandomColor()
	return Color( math.random( 0, 255 ), math.random( 0, 255 ), math.random( 0, 255 ) )
end

function Core.GetRandomString( n, s )
	local c = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"
	for i = 1, n or 8 do s = (s or "") .. c[ math.random( 1, #c ) ] end
	return s
end

function Core.RoundTo( v, n, z )
	return Vector( round( v.x / n ) * n, round( v.y / n ) * n, z and round( v.z / n ) * n or v.z )
end

function Core.ParseBytes( b )
	local mb = b / 1024
	if mb > 1024 then
		return round( mb / 1024, 2 ) .. " GB"
	else
		return round( mb, 2 ) .. " MB"
	end
end

function Core.ToDate( n, s )
	return os.date( s and "%Y-%m-%d" or "%Y-%m-%d %H:%M:%S", n or os.time() )
end

function Core.CVar( name, default, save )
	if not default then
		return _C.Prefix .. "_" .. name
	else
		return CreateClientConVar( _C.Prefix .. "_" .. name, default, save == nil and true, false )
	end
end

function Core.GetDuckSet()
	return ds, au
end


local CacheFunctions = {}
local CacheTypes = {
	["Reloading"] = { "Bool" }, ["Type"] = { "Bool" }, ["Spectating"] = { "Bool" },
	["BotName"] = { "String" }, ["ProfileURI"] = { "String" }, ["RunDate"] = { "String" },
	["Rank"] = { "Int", 7 }, ["Style"] = { "UInt", 10 }, ["TrueStyle"] = { "UInt", 10 }, ["Bonus"] = { "UInt", 4 }, ["WRPos"] = { "UInt", 10 }, ["SubGlow"] = { "UInt", 2 },
	["Position"] = { "UInt", 20 }, ["SpecialRank"] = { "UInt", 3 }, ["SubRank"] = { "UInt", 4 }, ["Access"] = { "UInt", 4 }, ["Record"] = { "Double" }
}

local function CallFunction( szIdentifier, varArgs, varParam )
	local func = CacheFunctions[ szIdentifier ]
	if func then
		if varParam then
			func( varParam, varArgs )
		else
			func( varArgs )
		end
	end
end

function Core.Register( szIdentifier, fExecutable )
	CacheFunctions[ szIdentifier ] = fExecutable
end

function Core.GetNetTypes()
	return CacheTypes
end

function Core.GetNetBits( n )
	return math.ceil( math.log10( n ) / math.log10( 2 ) )
end

include( "core_player.lua" )
include( "core_move.lua" )

function PLAYER:GetJumps()
	return pj[ self ] or 0
end

function PLAYER:SetJumps( nValue )
	self:SpeedValues( true )

	if self.RTSF then
		self:RTSF()
	end

	pj[ self ] = nValue
end

function PLAYER:SpeedValues( r, ... )
	if r != nil then
		local ltv, lat, lac = unpack( { ... } )
		tv[ self ], at[ self ], ac[ self ] = r and 0 or ltv, r and 0 or lat, r and 0 or lac
	else
		return tv[ self ], ac[ self ] > 0 and at[ self ] / ac[ self ] or 0, at[ self ], ac[ self ]
	end
end


if SERVER then

Core.Ext = _C.Var.GetExtension

function Core.Trigger( ... )
	CallFunction( ... )
end

local function CoreReceive( _, ply )
	local szAction = net.ReadString()
	local varArgs = net.ReadBool() and net.ReadTable() or {}

	if Iv( ply ) and ply:IsPlayer() then
		CallFunction( "Global/" .. szAction, varArgs, ply )
	end
end
net.Receive( "SecureTransfer", CoreReceive )

elseif CLIENT then

Core.ClientEnts = {}
Core.ServerSettings = {}
Core.SetInitialFrames = SetInitialFrames

local NetObj = {}
NetObj.Int = function( t, b ) return net.ReadInt( b ) end
NetObj.UInt = function( t, b ) return net.ReadUInt( b ) end
NetObj.String = function() return net.ReadString() end
NetObj.Bit = function() return net.ReadBool() end
NetObj.Double = function() return net.ReadDouble() end
NetObj.Color = function() return net.ReadColor() end
NetObj.ColorText = function( t ) local d = {} for i = 1, t:UInt( 8 ) do d[ #d + 1 ] = t:Bit() and Core.TranslateColor( t:Color() ) or Core.TranslateString( t:String() ) end return d end

function Core.Send( szAction, varArgs )
	net.Start( "SecureTransfer" )
	net.WriteString( szAction )

	if varArgs and type( varArgs ) == "table" then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end

	net.SendToServer()
end

local function CoreReceive( l )
	_C.NetReceive = _C.NetReceive + l
	CallFunction( net.ReadString(), net.ReadBool() and net.ReadTable() or {} )
end
net.Receive( "SecureTransfer", CoreReceive )

local function ManualReceive( l )
	_C.NetReceive = _C.NetReceive + l
	CallFunction( net.ReadString(), NetObj )
end
net.Receive( "QuickNet", ManualReceive )

local ManualCall, Bytes = net.Incoming, 0
local function ManualOverride( l )
	ManualCall( l )
	Bytes = Bytes + l
end
net.Incoming = ManualOverride

local function NetworkChecker()
	_C.NetRate = math.Round( Bytes / 1024, 2 ) .. " kbps"
	Bytes = 0
end
timer.Create( "NetworkStats", 1, 0, NetworkChecker )

function Core.Trigger( szType, varArgs )
	CallFunction( "Inner/" .. szType, varArgs )
end

function Core.UpdateSetting( k, v )
	local o = Core.ServerSettings
	v = tonumber( v )

	if k == "GravityMultiplier" then
		plg = v
		o[ k ] = plg .. "x"
		_C.Player.LowGravity = plg
	elseif k == "PackMultiplier" then
		pjp = v
		o[ k ] = pjp .. "x"
		_C.Player.JumpPack = pjp
	elseif k == "UseJumpPack" then
		if v != 1 then return end
		o[ k ] = true

		_C.IsPack = true
		_C.Style["Jump Pack"] = _C.Style["Stamina"]
		_C.Style["Stamina"] = nil

		hook.Add( "SetupMove", "ProcessJumpPack", JumpPack )

		for name,id in pairs( _C.Style ) do
			StyleNames[ id ] = CustomNames[ id ] or name
		end
	elseif k == "CSSJumps" then
		o[ k ] = v == 1
		_C.Player.JumpPower = v == 1 and math.sqrt( 2 * 800 * 57.81 ) or 290
	elseif k == "CSSGains" then
		if not _C.IsBhop or v != 1 then return end
		o[ k ] = true

		paa, pmv = 1200, 30
		_C.Player.AirAcceleration = paa
		_C.Player.StrafeMultiplier = pmv
	elseif k == "CSSDuck" then
		if v != 1 then return end
		o[ k ] = true

		_C.Player.HullStand.z = 54
		_C.Player.ViewStand.z = 56
		_C.Player.ViewOffset.z = 8

		Core.SetDuckDiff()
		Core.UpdateClientViews()

		local lpc = lp()
		if IsValid( lpc ) then
			lpc:SetViewOffset( _C.Player.ViewStand )
			lpc:SetViewOffsetDucked( _C.Player.ViewDuck )
			lpc:SetHull( _C.Player.HullMin, _C.Player.HullStand )
			lpc:SetHullDuck( _C.Player.HullMin, _C.Player.HullDuck )
		end
	elseif k == "Checkpoints" then
		o[ k ] = true

		for i = 1, 100 do
			StyleNames[ 100 + i ] = "Checkpoint " .. i
		end
	elseif k == "StartLimit" or k == "SpeedLimit" or k == "WalkSpeed" then
		o[ k ] = v .. " u/s"
	end
end

for i = 1, 100 do
	StyleNames[ 100 + i ] = "Stage " .. i
end

end

return true
