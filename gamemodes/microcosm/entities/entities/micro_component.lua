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

function ENT:Use(activator, caller, useType, value)
	if isfunction(self.sendControls) then
		if not IsValid(self.controller) then
			caller:ProxyControls(self)
			self.controller = caller
		else
			self:EmitSound("buttons/button11.wav")
		end
	end
end

function ENT:Draw()
	local is_controlling = LocalPlayer().proxyctrls_ent == self

	local ship_info = self:GetShipInfo()

	if is_controlling then
		render.DrawWireframeBox(self:GetPos(), self:GetAngles(), self:OBBMins(), self:OBBMaxs(), ship_info.entity and ship_info.entity:GetColor() or Color(0,0,0) , true)
	else
		self:DrawModel()

		local broken = self:IsBroken()

		if ship_info and IsValid(ship_info.entity) then

			cam.Start3D2D(self:LocalToWorld(self.ComponentScreenOffset),self:LocalToWorldAngles(self.ComponentScreenRotation), .25 )
				self:drawScreen(ship_info.entity,broken)
			cam.End3D2D()
		end
	end
end

hook.easy("HUDPaint",function()
	local control_ent = LocalPlayer().proxyctrls_ent

	if IsValid(control_ent) and isfunction(control_ent.drawScreen) then

		local ship_info = control_ent:GetShipInfo()
		local broken = control_ent:IsBroken()

		if IsValid(ship_info.entity) then
			local matrix = Matrix()
			matrix:Translate(Vector((ScrW()-control_ent.ComponentScreenWidth)/2,ScrH()-control_ent.ComponentScreenHeight,0))
			--matrix:Scale(Vector(2,2,2))
			cam.PushModelMatrix(matrix)
			control_ent:drawScreen(ship_info.entity,broken)
			cam.PopModelMatrix()
		end
	end
end)

function ENT:drawScreen(ship,broken)
	local color = ship:GetColor()
	local width = self.ComponentScreenWidth
	local height = self.ComponentScreenHeight

	surface.SetDrawColor(color)
	surface.DrawRect( 0, 0, width, height)

	surface.SetDrawColor(Color(0,0,0))
	
	local function startStencil()
		render.SetStencilEnable(true)
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilFailOperation(STENCILOPERATION_ZERO)
		render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
	end


	if self.ComponentHideName then
		startStencil()
		surface.DrawRect( 3, 3, width-6, height-6)
	else
		surface.DrawRect( 3, 3, width-6, 35)
		draw.SimpleText(self:GetComponentName(),"micro_big",width/2,20,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		startStencil()
		surface.DrawRect( 3, 41, width-6, height-44)
	end

	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
	render.SetStencilPassOperation(STENCILOPERATION_KEEP)
	render.SetStencilFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(STENCILOPERATION_KEEP)

	self:drawInfo(ship,broken)

	render.SetStencilEnable(false)

	if broken then
		for i=1,20 do
			draw.SimpleText(string.char(math.random(33,126)),"DebugFixed",5+math.random()*(w-10),5+math.random()*(h-10),color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		end
	end
end

function ENT:drawInfo(ship,broken) end


--[[

function ENT:controlHUD()
	print("hood")
	local matrix = Matrix()
	matrix:Translate(Vector(ScrW()-400,ScrH()-200,0))
	matrix:Scale(Vector(2,2,2))
	cam.PushModelMatrix(matrix)
	self:drawInfo()
	cam.PopModelMatrix()
end
]]