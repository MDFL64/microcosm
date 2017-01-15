AddCSLuaFile()

ENT.Type = "anim"

function ENT:Initialize()

	self:PhysicsInitStandard()

	if SERVER then
		self:GetPhysicsObject():EnableMotion(false)
		self:SetUseType(SIMPLE_USE)
	end
end