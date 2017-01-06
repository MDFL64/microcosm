AddCSLuaFile()

ENT.Type = "anim"

function ENT:Initialize()
	self:DrawShadow(false)
end

function ENT:Setup(color)
	self.trail = util.SpriteTrail(self,0,color,true,5,2,1,.1,"trails/smoke.vmt" )
end

function ENT:Stop()
	self:SetParent(nil)
	timer.Simple(1,function()
		if IsValid(self) then
			self:Remove()
		end
	end)
end

function ENT:Draw() end