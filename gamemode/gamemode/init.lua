-- Make the files downloadable by the client
AddCSLuaFile( "core.lua" )
AddCSLuaFile( "core_move.lua" )
AddCSLuaFile( "core_player.lua" )
AddCSLuaFile( "cl_gui.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_score.lua" )
AddCSLuaFile( "cl_timer.lua" )
AddCSLuaFile( "cl_view.lua" )
AddCSLuaFile( "modules/sh_config.lua" )
AddCSLuaFile( "modules/cl_admin.lua" )
AddCSLuaFile( "modules/cl_varnet.lua" )

-- Include the core of the gamemode
if not include( "core.lua" ) then
	return error( "Something went wrong while trying to load the gamemode core" )
end

-- Include all files for the server in correct order
include( "core_lang.lua" )
include( "core_data.lua" )
include( "sv_view.lua" )
include( "sv_command.lua" )
include( "sv_timer.lua" )
include( "modules/sv_admin.lua" )
include( "modules/sv_varnet.lua" )
include( "modules/sv_spectator.lua" )

-- Makes BaseClass accessible
DEFINE_BASECLASS( "gamemode_base" )
Core.AddResources( Core.Config.MaterialID )

local Styles, PlayerData, Teams = Core.Config.Style, Core.Config.Player, Core.Config.Team
local DefaultStyle, DefaultStep, CustomStyleFunc = Styles.Normal, PlayerData.StepSize
local ResetClass = player_manager.SetPlayerClass

--[[
	Description: Loads the essential data from the database
	Notes: Calls after the gamemode is ready
--]]
local function Startup()
	-- Loads all important game data
	Core.LoadCommands()
	Core.LoadRecords()
	Core.LoadAdminPanel()
end
hook.Add( "Initialize", "Startup", Startup )

--[[
	Description: Proceeds with all entity initialization and the rest of the gamemode loading mechanism
--]]
local function LoadEntities()
	-- Load everything related to the map
	Core.SetupMap()
end
hook.Add( "InitPostEntity", "LoadEntities", LoadEntities )


--[[
	Description: Fully resets the player
	Notes: Base gamemode override
--]]
function GM:PlayerSpawn( ply )
	-- Inherit data from the player_move class
	ResetClass( ply, "player_move" )
	BaseClass:PlayerSpawn( ply )
	
	-- Spawn the player on the first spot and set variables
	if not ply:IsBot() then
		-- Set normal movement settings for the player
		ply:SetMoveType( 2 )
		ply:SetJumpPower( PlayerData.JumpPower )
		ply:SetStepSize( DefaultStep )
		ply:SetJumps( 0 )
		
		-- Reset the player to a random location
		ply:ResetSpawnPosition()
		
		-- Reset LJ stats if we have a valid player
		Core.Ext( "Stats", "ResetPlayer" )( ply )
		
		-- Enable strafe manager
		Core.Ext( "SMgr", "SetStrafeStats" )( ply )
	else
		-- Handle bot spawning
		Core.Ext( "Bot", "HandleSpawn" )( ply )
	end
end

--[[
	Description: Makes the player ready for combat. I mean uh, playing...
	Notes: Base gamemode override
--]]
function GM:PlayerInitialSpawn( ply )
	-- Set default shmook
	ply:SetTeam( Teams.Players )
	ply:SetJumpPower( PlayerData.JumpPower )
	ply:SetHull( PlayerData.HullMin, PlayerData.HullStand )
	ply:SetHullDuck( PlayerData.HullMin, PlayerData.HullDuck )
	ply:SetNoCollideWithTeammates( true )
	ply:SetAvoidPlayers( false )
	
	-- Set default data
	ply.Style = DefaultStyle
	ply.Record = 0
	ply.Leaderboard = 0
	ply.Rank = -1
	ply.UID = ply:SteamID()

	if not ply:IsBot() then
		-- First do a lockdown check, otherwise, test the SQL connection
		if Core.Lockdown and ply.UID != Core.LockExclude then
			return ply:Kick( Core.Lockdown )
		else
			Core.TestSQLConnection()
		end
		
		-- Sets the model and hides shadows
		ply:SetModel( PlayerData.DefaultModel )
		ply:DrawShadow( false )
		
		-- Load the player's details
		local UpdateTime = ply:LoadTime( true )
		local UpdateRank = ply:LoadRank( true, true )
		ply:NotifyBeatenTimes()
		
		-- Get the list of variables to update
		local UpdateItems = { "Style", "Record", "Position", "SpecialRank" }
		if UpdateRank then
			UpdateItems[ #UpdateItems + 1 ] = "Rank"
			UpdateItems[ #UpdateItems + 1 ] = "SubRank"
		end
		
		-- Send the top times for displaying
		Core.SendTopTimes( ply )
		
		-- Check if the player is an admin or not
		ply:CheckAdminStatus()
		
		-- Set the connection time
		ply.ConnectedAt = SysTime()
		
		-- Check map type
		if Core.GetMapVariable( "IsBindBypass" ) then
			Core.Send( ply, "Timer/BypassBind", true, true )
		end
		
		-- Set custom style if applicable
		if CustomStyleFunc then
			ply.CustomStyleFunc = CustomStyleFunc
		end
		
		-- Publish the player to the rest
		ply:VarNet( "Set", "Style", ply.Style )
		ply:VarNet( "UpdateKeys", UpdateItems )
		
		-- Make sure the player is recorded by the bot
		Core.Ext( "Bot", "AddPlayer" )( ply )
	else
		-- Handle bot settings
		Core.Ext( "Bot", "HandleInitialSpawn" )( ply )
	end
end

--[[
	Description: Collection of functions that we want to return a fixed value
	Notes: Base gamemode override
--]]
function GM:CanPlayerSuicide() return false end
function GM:PlayerShouldTakeDamage() return false end
function GM:GetFallDamage() return false end
function GM:PlayerCanHearPlayersVoice() return true end
function GM:IsSpawnpointSuitable() return true end
function GM:PlayerDeathThink( ply ) end
function GM:PlayerSetModel( ply ) end

--[[
	Description: Makes sure stripped players can't do anything as well as to avoid weapon pickup lag
	Notes: Base gamemode override
--]]
function GM:PlayerCanPickupWeapon( ply, weapon )
	if PlayerData.SurfWeapons and not PlayerData.SurfWeapons[ weapon:GetClass() ] then return false end
	
	if ply.WeaponStripped or ply.WeaponPickupProhibit then return false end
	if ply:HasWeapon( weapon:GetClass() ) then return false end
	if ply:IsBot() then return false end
	
	-- For Bhop we'll want to stock up their ammo to the max
	if Core.Config.IsBhop then
		timer.Simple( 0.1, function()
			if IsValid( ply ) and IsValid( weapon ) then
				ply:SetAmmo( 999, weapon:GetPrimaryAmmoType() )
			end
		end )
	end
	
	return true
end

--[[
	Description: Disallows players to take damage
	Notes: Base gamemode override
--]]
function GM:EntityTakeDamage( ent, dmg )
	if ent:IsPlayer() then return false end
	return BaseClass:EntityTakeDamage( ent, dmg )
end

--[[
	Description: Changes the default spawning style and/or the default step size
	Notes: Uses prints because I think it's cool
--]]
function GM:SetDefaultStyle( nStyle, nStepSize )
	if nStyle then
		GAMEMODE.CustomStyle = nStyle
		
		CustomStyleFunc = function( ply )
			concommand.Run( ply, "style", tostring( GAMEMODE.CustomStyle ), "" )
		end
		
		Core.PrintC( "[Event] Default style changed to", Core.StyleName( nStyle ) .. " - ID: " .. nStyle )
	end
	
	if nStepSize then
		DefaultStep = nStepSize
		Core.PrintC( "[Event] Default step size changed to", nStepSize )
	end
end

--[[
	Description: Central unloading function from which we destruct the game step by step
	Notes: Created so we can have this in a central place
--]]
function GM:UnloadGamemode( szReason, fCallback )
	-- Show a message
	Core.PrintC( "[Event] Gamemode unload requested with reason '" .. szReason .. "'" )
	
	-- Try saving bots
	if Core.Ext( "Bot" ) then
		Core.Ext( "Bot", "Save" )( szReason != "VoteEnd", nil, fCallback )
	elseif fCallback then
		fCallback()
	end
end