AddCSLuaFile()

ENT.Type = "anim"

function ENT:Initialize()

	self:PhysicsInitStandard()

	if SERVER then
		self:GetPhysicsObject():EnableMotion(false)
	end

	self:AddToExternalShip()
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end