AddCSLuaFile()

SWEP.PrintName = "Fixer"
SWEP.UseHands		= true

SWEP.ViewModel		= "models/weapons/c_toolgun.mdl"
SWEP.WorldModel		= "models/weapons/w_toolgun.mdl"

SWEP.Primary.ClipSize		= 100
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo		    = "AR2"
 
SWEP.Secondary.ClipSize	    = -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		    = "none"

function SWEP:Initialize()
	if SERVER then
		local timer_name = "fixer_regen_"..self:EntIndex()
		timer.Create(timer_name,1,0, function()
			if IsValid(self) then
				if self:Clip1()<self.Primary.ClipSize then
					self:SetClip1(self:Clip1()+1)
				end
			else
				timer.Destroy(timer_name)
			end
		end)
	end
end

function SWEP:Reload() end

function SWEP:PrimaryAttack()
	if CLIENT or not self:CanPrimaryAttack() then return end

	local tr = self.Owner:GetEyeTrace()

	if tr.Fraction > .003 or !IsValid(tr.Entity) or !tr.Entity.GetMicroHealth or !tr.Entity.MaxMicroHealth or tr.Entity:GetMicroHealth()>=tr.Entity.MaxMicroHealth then return end

	tr.Entity:SetMicroHealth(tr.Entity:GetMicroHealth()+1)

	sound.Play("weapons/physcannon/superphys_small_zap1.wav",tr.HitPos,70,120,1)

	local ed = EffectData()
	ed:SetOrigin(tr.HitPos+tr.HitNormal*5)
	util.Effect("cball_bounce", ed,false, true)

	self:SetNextPrimaryFire(CurTime() + .1)
	self:TakePrimaryAmmo(1)
end

function SWEP:SecondaryAttack() end