AddCSLuaFile()

ENT.Type = "anim"

ENT.ItemName = "Pizza Dogs"
ENT.ItemModel = "models/props_junk/watermelon01.mdl"
ENT.MaxCount = 100
ENT.Boxed = false

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Count")
end

function ENT:Initialize()
    self:SetModel(self.Boxed and "models/Items/item_item_crate.mdl" or self.ItemModel)
	self:PhysicsInitStandard()

    if self.Boxed then
        self.RenderGroup = RENDERGROUP_TRANSLUCENT
        self:SetRenderMode(RENDERMODE_TRANSALPHA)
        self:SetMaterial("phoenix_storms/cube")
        self:SetColor(Color(255,255,255,100))

        if CLIENT then
            self.cmodel = ClientsideModel(self.ItemModel)
            self.cmodel:SetNoDraw(true)

            local matrix = Matrix()
            matrix:Scale(Vector(10,10,10)/self.cmodel:GetModelRadius())
            self.cmodel:EnableMatrix("RenderMultiply", matrix)
        end
    end

    if SERVER then
        self:SetUseType(SIMPLE_USE)
        self:SetCount(self.MaxCount)
    end
end

if SERVER then
    function ENT:TryTake(amount)
        if amount>=self:GetCount() then
            -- prevent possible crash when this is called from a collision hook
            timer.Simple(0,function()
                if IsValid(self) then
                    self:Remove()
                end
            end)
            local count = self:GetCount()
            self:SetCount(0)
            return count
        else
            self:SetCount(self:GetCount()-amount)
            return amount
        end
    end
else
    function ENT:DrawTranslucent()
        self:DrawModel()
        if IsValid(self.cmodel) then
            self.cmodel:SetRenderOrigin(self:LocalToWorld(Vector(0,0,11)))
            self.cmodel:SetRenderAngles(self:GetAngles())
            self.cmodel:DrawModel()
        end
    end

    function ENT:GetMicroHudText()
        return self.ItemName..": "..self:GetCount().." / "..self.MaxCount
    end

    function ENT:OnRemove()
        if IsValid(self.cmodel) then
            self.cmodel:Remove()
        end
    end
end