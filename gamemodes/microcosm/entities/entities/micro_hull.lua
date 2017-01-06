AddCSLuaFile()

ENT.Type = "anim"

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Ship")
	self:NetworkVar("Int", 0, "MicroHealth")
	--self:SetNWVarProxy("Ship", function(_,old,new)
	--    print("rerr")
	--end)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

ENT.MaxMicroHealth = 2000

function ENT:Initialize()
	--self:SetModel("models/smallbridge/ships/hysteria_galapagos.mdl")
	
	--do micro_hull:SetModel("") in init.lua
	
	self:PhysicsInitStandard()

	if SERVER then
		self:GetPhysicsObject():EnableMotion(false)
		self:SetMicroHealth(self.MaxMicroHealth)
	end
end

local matBlack = Material("tools/toolsblack")

function ENT:GetMicroHealthDisplayName()
	return "Hull & Engines"
end

if CLIENT then
	function ENT:Think()
		local ship = self:GetShip()
		if IsValid(ship) and !self.paired then
			
			local matrix = Matrix()
			matrix:Scale(Vector(1,1,1)*MICRO_SCALE)

			local cm = ClientsideModel(self:GetModel(),RENDERGROUP_OPAQUE)
			--cm:SetParent(ship)
			--cm:SetLocalPos(Vector(0,0,0))
			cm:SetNoDraw(true)
			cm:EnableMatrix("RenderMultiply",matrix)

			ship.hulls[self] = cm
			self.paired = true
		end
		--print(self:GetShip())
		--print("balls")
	end
end