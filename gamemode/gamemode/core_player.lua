local PLAYER, PMETA = {}, FindMetaTable( "Player" )
PLAYER.DisplayName				= "Player"
PLAYER.WalkSpeed 				= Core.Config.Var and Core.Config.Var.GetInt( "WalkSpeed" ) or 250
PLAYER.RunSpeed				= PLAYER.WalkSpeed
PLAYER.DefaultSpeed			= 250
PLAYER.CrouchedWalkSpeed 	= 0.34
PLAYER.DuckSpeed				= 0.4
PLAYER.UnDuckSpeed			= 0.2
PLAYER.AvoidPlayers				= false
PLAYER.JumpPower				= Core.Config.Player.JumpPower
PMETA.OldStripWeapons		= PMETA.StripWeapons

function PLAYER:Loadout()
	if #self.Player:GetWeapons() > 0 then
		self.Player:StripWeapons()
	end

	if Core.Config.IsBhop then
		self.Player:Give( "weapon_glock" )
		self.Player:Give( "weapon_usp" )
		self.Player:Give( "weapon_knife" )

		self.Player:SetAmmo( 999, "pistol" ) 
		self.Player:SetAmmo( 999, "smg1" )
		self.Player:SetAmmo( 999, "buckshot" )
	end
end

function PLAYER:SetModel()
	self.Player:SetModel( self.Player:IsBot() and Core.Config.Player.DefaultBot or Core.Config.Player.DefaultModel )
end

function PMETA:StripWeapons()
	self:SetWalkSpeed( PLAYER.WalkSpeed )
	self:OldStripWeapons()
end

local function PLAYER_WalkSpeed( ply, old, new )
	if IsValid( new ) then
		ply:SetWalkSpeed( new:GetClass() == "weapon_scout" and PLAYER.WalkSpeed or PLAYER.DefaultSpeed )
	else
		ply:SetWalkSpeed( PLAYER.WalkSpeed )
	end
end

player_manager.RegisterClass( "player_move", PLAYER, "player_default" )
hook.Add( "PlayerSwitchWeapon", "PlayerWalkSpeeds", PLAYER_WalkSpeed )