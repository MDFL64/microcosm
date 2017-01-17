AddCSLuaFile()

ENT.Type = "anim"

function ENT:Initialize()
	self:AddToExternalShip()
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end