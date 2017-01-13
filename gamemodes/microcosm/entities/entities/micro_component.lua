AddCSLuaFile()

ENT.Type = "anim"

ENT.ComponentModel = "models/props_phx/construct/metal_plate2x2.mdl"
ENT.ComponentMaxHealth = 100
ENT.ComponentHideName = false
ENT.ComponentScreenWidth = 360
ENT.ComponentScreenHeight = 360
ENT.ComponentScreenOffset = Vector(45,45,4)
ENT.ComponentScreenRotation = Angle(0,-90,0)

function ENT:GetComponentName()
	return "A Thing"
end

function ENT:Initialize()
	self:SetModel(self.ComponentModel)

	self:PhysicsInitStandard()

	if SERVER then
		self:GetPhysicsObject():EnableMotion(false)
		self:SetUseType(SIMPLE_USE)

		self:SetHealth(self.ComponentMaxHealth)
		self:SetMaxHealth(self.ComponentMaxHealth)
	end
end

function ENT:Draw()
	self:DrawModel()

	local ship_info = self:GetShipInfo()
	local broken = self:IsBroken()

	if ship_info and IsValid(ship_info.entity) then

		cam.Start3D2D(self:LocalToWorld(self.ComponentScreenOffset),self:LocalToWorldAngles(self.ComponentScreenRotation), .25 )
			local color = ship_info.entity:GetColor()
			local width = self.ComponentScreenWidth
			local height = self.ComponentScreenHeight

			surface.SetDrawColor(color)
			surface.DrawRect( 0, 0, width, height)

			surface.SetDrawColor(Color(0,0,0))
			
			if self.ComponentHideName then
				surface.DrawRect( 3, 3, width-6, height-6)
			else
				surface.DrawRect( 3, 3, width-6, 35)
				draw.SimpleText(self:GetComponentName(),"DermaLarge",width/2,20,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
				surface.DrawRect( 3, 41, width-6, height-44)
			end

			self:DrawScreen(ship_info.entity,broken)

			if broken then
				for i=1,20 do
					draw.SimpleText(string.char(math.random(33,126)),"DebugFixed",5+math.random()*(w-10),5+math.random()*(h-10),color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
				end
			end
		cam.End3D2D()
	end
end

function ENT:DrawScreen(ship,broken) end