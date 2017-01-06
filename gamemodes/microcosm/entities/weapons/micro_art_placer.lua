AddCSLuaFile()

SWEP.PrintName = "Artifact Placer"
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

function SWEP:PrimaryAttack()
	if SERVER or not IsFirstTimePredicted() then return end
	chat.AddText(Color(255,0,0),"Added: "..self.current_desc)
	table.insert(self.data,{self.current_desc,self.Owner:GetPos()})
end

function SWEP:SecondaryAttack()
	if SERVER or not IsFirstTimePredicted() then return end

	Derma_StringRequest("Artifact Placer","Enter a description.",self.current_desc, function(x)
		self.current_desc = x
		chat.AddText(Color(255,0,0),"Desc Set: "..x)
	end)
end

function SWEP:Think()
	if SERVER or not IsFirstTimePredicted() then return end
	for _,v in pairs(self.data) do
		local name = v[1]
		local pos = v[2]
		debugoverlay.Cross(pos,30,.1,Color(255,0,0),false)
		debugoverlay.Text(pos,name,.1,true)
	end
end

function SWEP:Reload()
	if SERVER or not IsFirstTimePredicted() or #self.data==0 then return end
	for _,v in pairs(self.data) do
		local name = v[1]
		local pos = v[2]
		print("{\""..name.."\",Vector("..pos.x..","..pos.y..","..pos.z..")},")
	end
	self.data = {}
	chat.AddText("Dumped Entries!")
end