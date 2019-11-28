if CLIENT then
	SWEP.PrintName			= "Auto Shotgun"			
	SWEP.Author				= "Counter-Strike"
	SWEP.Slot				= 2
	SWEP.SlotPos			= 0
	SWEP.IconLetter			= "k"
	
	killicon.AddFont( "weapon_xm1014", "CSKillIcons", SWEP.IconLetter, Color( 255, 80, 0, 255 ) )
elseif SERVER then
	AddCSLuaFile()
end

SWEP.HoldType			= "ar2"
SWEP.Base				= "weapon_cs_base"
SWEP.Category			= "Counter-Strike"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel			= "models/weapons/v_shot_xm1014.mdl"
SWEP.WorldModel			= "models/weapons/w_shot_xm1014.mdl"

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Primary.Sound 		    = Sound("Weapon_XM1014.Single")
SWEP.Primary.Recoil			= 6
SWEP.Primary.Damage			= 7.5
SWEP.Primary.NumShots		= 12
SWEP.Primary.Cone 	    	= 0.045
SWEP.Primary.ClipSize 		= 6
SWEP.Primary.Delay 		    = 0.25
SWEP.Primary.DefaultClip 	= 6
SWEP.Primary.Automatic 		= false
SWEP.Primary.Ammo 		    = "buckshot"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.IronSightsPos 		= Vector(5.1536, -3.817, 2.1621)
SWEP.IronSightsAng 		= Vector(-0.1466, 0.7799, 0)

function SWEP:Reload()
	self:SetIronsights( false )
	
	if self:VarNet( "GetPrivate", "Reloading", false ) then return end
	if self.Weapon:Clip1() < self.Primary.ClipSize and self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 then
		self:VarNet( "SetPrivate", "Reloading", true, self.Owner )
		self.Weapon.ReloadTimer = CurTime() + 0.3
		self.Weapon:SendWeaponAnim( ACT_VM_RELOAD )
		self.Owner:DoReloadEvent()
	end
end

function SWEP:Think()
	if self:VarNet( "GetPrivate", "Reloading", false ) then
		if (self.Weapon.ReloadTimer or 0) < CurTime() then
			if self.Weapon:Clip1() >= self.Primary.ClipSize or self.Owner:GetAmmoCount( self.Primary.Ammo ) <= 0 then
				return self:VarNet( "SetPrivate", "Reloading", false, self.Owner )
			end
			
			self.Weapon.ReloadTimer = CurTime() + 0.3
			self.Weapon:SendWeaponAnim( ACT_VM_RELOAD )
			self.Owner:DoReloadEvent()
			
			self.Owner:RemoveAmmo( 1, self.Primary.Ammo, false )
			self.Weapon:SetClip1( self.Weapon:Clip1() + 1 )
			
			if self.Weapon:Clip1() >= self.Primary.ClipSize or self.Owner:GetAmmoCount( self.Primary.Ammo ) <= 0 then
				self.Weapon:SendWeaponAnim( ACT_SHOTGUN_RELOAD_FINISH )
				self.Owner:DoReloadEvent()
			end
		end
	end
end