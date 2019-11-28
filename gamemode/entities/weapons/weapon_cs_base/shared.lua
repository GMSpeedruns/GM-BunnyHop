if SERVER then
	AddCSLuaFile()
	
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
elseif CLIENT then
	SWEP.DrawAmmo			= true
	SWEP.DrawCrosshair		= false
	SWEP.ViewModelFOV		= 82
	SWEP.ViewModelFlip		= true
	
	surface.CreateFont("CSKillIcons", { font="csd", weight="500", size=ScreenScale(30),antialiasing=true,additive=true })
	surface.CreateFont("CSSelectIcons", { font="csd", weight="500", size=ScreenScale(60),antialiasing=true,additive=true })
end

SWEP.Author			= "Counter-Strike"
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false
SWEP.NextSecondaryAttack = 0
SWEP.LastFireTime = 0

SWEP.Primary.Sound			= Sound( "Weapon_AK47.Single" )
SWEP.Primary.Recoil			= 0 --1.5
SWEP.Primary.Damage			= 40
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.02
SWEP.Primary.Delay			= 0.15

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

function SWEP:Initialize()
	if SERVER then
		self:SetNPCMinBurst( 30 )
		self:SetNPCMaxBurst( 30 )
		self:SetNPCFireRate( 0.01 )
	elseif CLIENT then
		if Core then
			self.VarCrosshair = Core.CVar( "cross_disable", "0" )
			self.VarGap = Core.CVar( "cross_gap", "1" )
			self.VarThick = Core.CVar( "cross_thick", "0" )
			self.VarLength = Core.CVar( "cross_length", "1" )
			self.VarOpacity = Core.CVar( "cross_opacity", "255" )
			
			self.VarR = Core.CVar( "cross_colr", "0" )
			self.VarG = Core.CVar( "cross_colg", "255" )
			self.VarB = Core.CVar( "cross_colb", "0" )
		end
		
		self.VarBits = bit.bor( CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS, CONTENTS_GRATE, CONTENTS_AUX )
	end
	
	self:SetWeaponHoldType( self.HoldType )
end
SWEP.BaseInit = SWEP.Initialize

function SWEP:Reload()
	self.Weapon:DefaultReload( ACT_VM_RELOAD )
	self:SetIronsights( false )
end

function SWEP:Think()	
end

function SWEP:PrimaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if not self:CanPrimaryAttack() then return end
	
	if CLIENT and not GunSoundsDisabled then
		self.Weapon:EmitSound( self.Primary.Sound, 1 )
	end

	self:CSShootBullet( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone )
	self:TakePrimaryAmmo( 1 )
end

function SWEP.BulletCallbackFunc( a, b, c )
	if not SERVER or not b.HitPos then return end
	local tracedata = {}
	tracedata.start = b.StartPos
	tracedata.endpos = b.HitPos + (b.Normal * 2)
	tracedata.filter = a
	tracedata.mask = MASK_PLAYERSOLID
	
	local trace = util.TraceLine( tracedata )
	if IsValid( trace.Entity ) then
		if trace.Entity:GetClass() == "func_button" then
			trace.Entity:TakeDamage( dmg, a, c:GetInflictor() )
			trace.Entity:TakeDamage( dmg, a, c:GetInflictor() )
		elseif trace.Entity:GetClass() == "func_physbox_multiplayer" then
			trace.Entity:TakeDamage( dmg, a, c:GetInflictor() )
		end
	end
end

function SWEP:CSShootBullet( dmg, recoil, numbul, cone )
	numbul 	= numbul 	or 1
	cone 	= cone 		or 0.01

	local bullet = {}
	bullet.Num 		= numbul
	bullet.Src 		= self.Owner:GetShootPos()
	bullet.Dir 		= self.Owner:GetAimVector()
	bullet.Spread 	= Vector( cone, cone, 0 )
	bullet.Tracer	= 4
	bullet.Force	= 5
	bullet.Damage	= dmg
	bullet.Callback = self.BulletCallbackFunc

	if Core and Core.Config and Core.Config.IsBhop then
		self.Owner:FireBullets( bullet )
	end
	
	self.Weapon.LastFireTime = CurTime()
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
end

function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
	draw.SimpleText( self.IconLetter, "CSSelectIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )
	
	// try to fool them into thinking they're playing a Tony Hawks game
	draw.SimpleText( self.IconLetter, "CSSelectIcons", x + wide/2 + math.Rand(-4, 4), y + tall*0.2+ math.Rand(-14, 14), Color( 255, 210, 0, math.Rand(10, 120) ), TEXT_ALIGN_CENTER )
	draw.SimpleText( self.IconLetter, "CSSelectIcons", x + wide/2 + math.Rand(-4, 4), y + tall*0.2+ math.Rand(-9, 9), Color( 255, 210, 0, math.Rand(10, 120) ), TEXT_ALIGN_CENTER )
end

function SWEP:GetViewModelPosition( pos, ang )
	return pos, ang
end

function SWEP:SetIronsights( b )
end

function SWEP:DrawHUD()
	if not self.VarCrosshair or self.VarCrosshair:GetBool() then return end
	
	local x, y
	if self.Owner == LocalPlayer() and self.Owner:ShouldDrawLocalPlayer() then
		local tr = util.GetPlayerTrace( self.Owner )
		tr.mask = self.VarBits
		
		local trace = util.TraceLine( tr )
		local coords = trace.HitPos:ToScreen()
		x, y = coords.x, coords.y
	else
		x, y = ScrW() / 2, ScrH() / 2
	end
	
	local scale = 10 * (self.Primary.Cone or 0.02)
	local LastShootTime = self.Weapon.LastFireTime or 0
	scale = scale * (2 - math.Clamp( (CurTime() - LastShootTime) * 5, 0, 1 ))
	surface.SetDrawColor( self.VarR:GetInt(), self.VarG:GetInt(), self.VarB:GetInt(), self.VarOpacity:GetInt() )

	local gap = 40 * (scale * self.VarGap:GetInt())
	local length = gap + 20 * (scale * self.VarLength:GetInt())
	
	local thick = self.VarThick:GetInt()
	if thick > 0 then
		for i = -thick, thick do
			surface.DrawLine( x - length, y + i, x - gap, y + i )
			surface.DrawLine( x + length, y + i, x + gap, y + i )
			surface.DrawLine( x + i, y - length, x + i, y - gap )
			surface.DrawLine( x + i, y + length, x + i, y + gap )
		end
	else
		surface.DrawLine( x - length, y, x - gap, y )
		surface.DrawLine( x + length, y, x + gap, y )
		surface.DrawLine( x, y - length, x, y - gap )
		surface.DrawLine( x, y + length, x, y + gap )
	end
end

function SWEP:OnRestore()
	self.NextSecondaryAttack = 0
	self:SetIronsights( false )
end