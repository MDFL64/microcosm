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
			for _,info in pairs(MICRO_SHIP_INFO) do
				if !IsValid(info.entity) then continue end

				local dist = info.entity:GetPos():Distance(self:GetPos())
				if dist<150 then
					self:FireBullets{
						Src=self:GetPos(),
						Dir=info.entity:GetPos()-self:GetPos(),
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
			for _,info in pairs(MICRO_SHIP_INFO) do
				if !IsValid(info.entity) then continue end

				local dist = info.entity.home:GetPos():Distance(self:GetPos())
				if dist<25 then
					local shop_ent
					for comp,_ in pairs(info.components) do
						if comp:GetClass()=="micro_comp_shop" then
							shop_ent = comp
							break
						end
					end

					if IsValid(constraint.FindConstraintEntity(self,"Rope")) or !IsValid(shop_ent) or !shop_ent:AddCash(100) then
						hit = true
						self:SetColor(info.entity:GetColor())
					else
						BroadcastComms(Color(255,0,255),"CENTRAL >>> ",MICRO_TEAM_COLORS[info.entity:GetShipID()],string.upper(MICRO_TEAM_NAMES[info.entity:GetShipID()]),Color(255,0,255)," HAS RECOVERED AN ARTIFACT!")
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