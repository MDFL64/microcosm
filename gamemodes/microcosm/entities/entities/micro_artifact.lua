AddCSLuaFile()

ENT.Type = "anim"

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
    self:SetModel("models/props_combine/breenbust.mdl")

	self:PhysicsInitStandard()

    if SERVER then
        self:GetPhysicsObject():EnableMotion(false)
        self:SetColor(Color(255,0,255,1))
    end

    self:SetMaterial("models/shiny")
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
end

if SERVER then
    function ENT:Think()
        local a = self:GetColor().a
        local phys = self:GetPhysicsObject()

        if a<255 then
            self:SetColor(Color(255,0,255,a+1))
            for _,ent in pairs(MICRO_SHIP_ENTS) do
                local dist = ent:GetPos():Distance(self:GetPos())
                if dist<250 then
                    self:FireBullets{
                        Src=self:GetPos(),
                        Dir=ent:GetPos()-self:GetPos(),
                        Spread=Vector(.03,.03,.03),
                        Damage=MICRO_ARTIFACT_SPAWN_TIME/6,
                        Tracer=0,
                        Callback=function(attacker,tr,dmg)
                            SendTracer(3,tr.StartPos,tr.HitPos)
                        end
                    }
                end
            end
        elseif !phys:IsMotionEnabled() then
            phys:EnableMotion(true)
            phys:Wake()
        else
            local hit = false
            for _,ent in pairs(MICRO_SHIP_ENTS) do
                local dist = ent.home:GetPos():Distance(self:GetPos())
                if dist<25 then
                    --local xx = constraint.FindConstraintEntity(self,"Rope")
                    --print(xx)
                    if IsValid(constraint.FindConstraintEntity(self,"Rope")) or !ent.shop_ent:AddCash(200) then
                        hit = true
                        self:SetColor(ent.home:GetColor())
                    else
                        self:Remove()
                    end
                end
            end

            if !hit then
                self:SetColor(Color(255,0,255))
            end
        end
        self:NextThink(CurTime()+(MICRO_ARTIFACT_SPAWN_TIME/255))
        return true
    end
end

function ENT:DrawTranslucent()
    local a = self:GetColor().a
    if a<255 then
        render.DrawWireframeSphere(self:GetPos(),16,6,6,Color(255,0,255),true)
    end
	self:Draw()
end