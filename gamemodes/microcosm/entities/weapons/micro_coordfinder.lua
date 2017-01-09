AddCSLuaFile()

SWEP.PrintName = 	"Coordinate Finder"
SWEP.UseHands		= true

SWEP.ViewModel		= "models/weapons/c_toolgun.mdl"
SWEP.WorldModel		= "models/weapons/w_toolgun.mdl"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		    = "none"
 
SWEP.Secondary.ClipSize	    = -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		    = "none"

function SWEP:Initialize()
	if CLIENT then
		self.data = {}
		self.current_desc = "???"
	end
end

function SWEP:PrimaryAttack() --position 1
	x = self.Owner:GetEyeTrace().HitPos.x
	y = self.Owner:GetEyeTrace().HitPos.y
	z = self.Owner:GetEyeTrace().HitPos.z
	print("Position 1: "..x..", "..y..", "..z)
end

function SWEP:SecondaryAttack() --position 2
	x2 = self.Owner:GetEyeTrace().HitPos.x
	y2 = self.Owner:GetEyeTrace().HitPos.y
	z2 = self.Owner:GetEyeTrace().HitPos.z
	print("Position 2: "..x2..", "..y2..", "..z2.."")
end

function SWEP:Reload()
	print("Difference: #2 - #1: "..x2-x..", "..y2-y..", "..z2-z) --derivitive
end