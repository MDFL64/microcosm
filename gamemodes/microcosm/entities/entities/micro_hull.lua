AddCSLuaFile()

ENT.Type = "anim"

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Ship")
    --self:SetNWVarProxy("Ship", function(_,old,new)
    --    print("rerr")
    --end)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:Initialize()
    self:SetModel("models/smallbridge/ships/hysteria_galapagos.mdl")

	self:PhysicsInitStandard()

    if SERVER then
        self:GetPhysicsObject():EnableMotion(false)
    end
end

local matBlack = Material("tools/toolsblack")

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
            print(cm:SetSubMaterial(5,"tools/toolsblack"))

            ship.hulls[self] = cm
            self.paired = true
        end
        --print(self:GetShip())
        --print("balls")
    end
end