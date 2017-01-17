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

function ENT:GetThrustEffectOffsets()
	if self:GetModel()=="models/smallbridge/station parts/sbbridgevisort.mdl" then
		return {Vector(-6,0,-2)}
	else
		return {
			Vector(-15,0,0),
			Vector(-14,7,0),
			Vector(-14,-7,0),
			Vector(-13,3,4),
			Vector(-13,-3,4)
		}
	end
end
