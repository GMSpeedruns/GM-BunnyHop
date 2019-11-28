if CLIENT then
	SWEP.PrintName			= "Glock"			
	SWEP.Author				= "Counter-Strike"
	SWEP.Slot				= 1
	SWEP.SlotPos			= 0
	SWEP.IconLetter			= "c"
	
	killicon.AddFont( "weapon_glock", "CSKillIcons", SWEP.IconLetter, Color( 255, 80, 0, 255 ) )
elseif SERVER then
	AddCSLuaFile()
end

SWEP.PrintName = "Glock"
SWEP.HoldType			= "pistol"
SWEP.Base				= "weapon_cs_base"
SWEP.Category			= "Counter-Strike"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel			= "models/weapons/v_pist_glock18.mdl"
SWEP.WorldModel			= "models/weapons/w_pist_glock18.mdl"

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Primary.Sound			= Sound( "Weapon_Glock.Single" )
SWEP.Primary.Recoil			= 0 --1.8
SWEP.Primary.Damage			= 16
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.03
SWEP.Primary.ClipSize		= 16
SWEP.Primary.Delay			= 0.05
SWEP.Primary.DefaultClip	= 21
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "pistol"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.IronSightsPos 		= Vector( 4.3, -2, 2.7 )

function SWEP:Initialize()
	self.IsGlock = true
	
	if self.BaseInit then
		self:BaseInit()
	end
end

function SWEP:CSSGlockShoot( dmg, recoil, numbul, cone, anim )
	numbul 	= numbul 	or 1
	cone 	= cone 		or 0.01

	local bullet = {}
	bullet.Num 		= numbul
	bullet.Src 		= self.Owner:GetShootPos()
	bullet.Dir 		= self.Owner:GetAimVector()
	bullet.Spread 	= Vector( 0, 0, 0 )
	bullet.Tracer	= 4
	bullet.Force	= 5
	bullet.Damage	= dmg
	bullet.Callback = self.BulletCallbackFunc
	
	if Core and Core.Config and Core.Config.IsBhop then
		self.Owner:FireBullets( bullet )
	end
	
	if anim then
		if self:VarNet( "GetPrivate", "Type", false ) == true then
			self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
		else	
			self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		end
	end
	
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
end

function SWEP:FireExtraBullets()
	if self:VarNet( "GetPrivate", "Type", false ) == true and self.ShootNext and self.NextShoot < CurTime() and self.ShotsLeft > 0 then
		self:GlockShoot( false )
	end
end

function SWEP:GlockShoot( showanim )
	if self:VarNet( "GetPrivate", "Type", false ) == true then self.ShootNext = false end
	if not self:CanPrimaryAttack() then return end
	
	if CLIENT and not GunSoundsDisabled then
		self.Weapon:EmitSound( self.Primary.Sound, 1 )
	end
	
	self:CSSGlockShoot( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone, showanim )
	self:TakePrimaryAmmo( 1 )
	
	if self.Owner:IsNPC() then return end
	
	self.Weapon.LastFireTime = CurTime()
	
	if self:VarNet( "GetPrivate", "Type", false ) == true and self.ShotsLeft > 0 and not self.ShootNext then
		self.ShootNext = true
		self.ShotsLeft = self.ShotsLeft - 1
	end
	
	self.NextShoot = CurTime() + 0.04
end

function SWEP:PrimaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	
	if self:VarNet( "GetPrivate", "Type", false ) == true then
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.5 )
		self.ShotsLeft = 3
		self.NextShoot = CurTime() + 0.04
	else
		self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	end
	
	if IsValid( self.Owner ) then
		self.Owner.IsGlock = true
		timer.Simple( 0.5, function()
			if IsValid( self ) and IsValid( self.Owner ) then
				self.Owner.IsGlock = nil
			end
		end )
	end
	
	self:GlockShoot( true )
end

function SWEP:SecondaryAttack()
	if CLIENT or self.NextSecondaryAttack > CurTime() or not IsValid( self.Owner ) then return end
	
	if self:VarNet( "GetPrivate", "Type", false ) == true then
		self:VarNet( "SetPrivate", "Type", false, self.Owner )
		self.Owner:PrintMessage( HUD_PRINTCENTER, "Switched to semi-automatic" )
	else
		self:VarNet( "SetPrivate", "Type", true, self.Owner )
		self.Owner:PrintMessage( HUD_PRINTCENTER, "Switched to burst-fire mode" )
	end
	
	self.NextSecondaryAttack = CurTime() + 0.3
end