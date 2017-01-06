AddCSLuaFile()

ENT.Type = "anim"

ENT.ControlEyeLock = true


ENT.MaxMicroHealth = 100
function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "MicroHealth")
end


function ENT:Initialize()
	self:SetModel("models/smallbridge/other/sbconsolelow.mdl")
	self:PhysicsInitStandard()
	if SERVER then
		self:GetPhysicsObject():EnableMotion(false)
		
		self:SetUseType(SIMPLE_USE)
		self:SetMicroHealth(self.MaxMicroHealth)
	end
end

function ENT:GetMicroHealthDisplayName()
	return "Helm Console"
end

function ENT:Use(activator, caller, useType, value)
	if not IsValid(self.controller) then
		caller:ProxyControls(self)
		self.controller = caller
	else
		self:EmitSound("buttons/button11.wav")
	end
end

function ENT:Think()
	local hurt = IsComponentHurt(self)
	if SERVER and hurt then
		self.ship.ctrl_v = math.random()*2-1
		self.ship.ctrl_h = math.random()*2-1
		self.ship.ctrl_y = math.random()*2-1
		self.ship.ctrl_p = math.random()*2-1
		self.ship.ctrl_t = math.random()*2-1
	end
end

function ENT:sendControls(buttons,buttons_pressed,x,y)
	local hurt = IsComponentHurt(self)
	if not IsValid(self.ship) or hurt then return end

	if bit.band(buttons,IN_FORWARD)!=0 then
		self.ship.ctrl_v = 1
	elseif bit.band(buttons,IN_BACK)!=0 then
		self.ship.ctrl_v = -1        
	else
		self.ship.ctrl_v = 0
	end

	if bit.band(buttons,IN_MOVELEFT)!=0 then
		self.ship.ctrl_h = 1
	elseif bit.band(buttons,IN_MOVERIGHT)!=0 then
		self.ship.ctrl_h = -1        
	else
		self.ship.ctrl_h = 0
	end

	self.ship.ctrl_y = math.Clamp(-x/50,-1,1)
	self.ship.ctrl_p = math.Clamp(y/50,-1,1)

	if bit.band(buttons,IN_JUMP)!=0 then
		self.ship:SetThrottle(0)
	end

	if bit.band(buttons,IN_SPEED)!=0 then
		self.ship.ctrl_t = 1
	elseif bit.band(buttons,IN_DUCK)!=0 then
		self.ship.ctrl_t = -1
	else
		self.ship.ctrl_t = 0
	end

	if bit.band(buttons,IN_RELOAD)!=0 then
		self.ship:UnHook()
	end
end

function ENT:stopControl()
	if IsValid(self.ship) then
		self.ship.ctrl_v = 0
		self.ship.ctrl_h = 0
		self.ship.ctrl_y = 0
		self.ship.ctrl_p = 0
		self.ship.ctrl_t = 0
	end
	self.controller = nil
end

function ENT:Draw()

	self:DrawModel()

	local ship = Entity(MICRO_SHIP_ID or -1)
	if IsValid(ship) then
		local color = ship:GetColor()
		local paur = ship:GetThrottle()
		local pitch = ship:GetAngles().p/90
		local yaw = ship:GetAngles().y
		
		local hurt = IsComponentHurt(self)

		if hurt then
			yaw=math.NormalizeAngle(CurTime()*180)
			pitch=math.sin(CurTime())
		end

		cam.Start3D2D(self:GetPos()+Vector(13,25,33),Angle(0,-90,30), .5 )
			
			surface.SetDrawColor(Color( 0, 0, 0))
			surface.DrawRect( 0, 0, 100, 70 )

			surface.SetDrawColor(color)
			surface.DrawOutlinedRect(0,0,100,70)

			surface.SetDrawColor(Color( 100, 100, 100))
			surface.DrawOutlinedRect(5,5,20,60)
			surface.DrawOutlinedRect(30,5,20,60)
			surface.DrawOutlinedRect(55,25,40,20)


			surface.SetDrawColor(Color( 255, 0, 0))
			surface.DrawRect(6, 35, 18, -29*paur )

			surface.SetDrawColor(Color( 0, 255, 0))
			surface.DrawRect(31, 34+29*pitch, 18, 3 )

			local function drawDir(ang,letter)
				if ang<80 and ang>-80 then
					draw.SimpleText(letter,"DermaDefault",75+ang/5,35,Color(255,255,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
				end
			end

			yaw = math.NormalizeAngle(yaw+180)

			drawDir(yaw,"N")
			drawDir(yaw+90,"E")
			drawDir(math.NormalizeAngle(yaw+180),"S")
			drawDir(yaw-90,"W")

			surface.SetDrawColor(Color( 100, 100, 100))
			surface.DrawRect(6, 35, 18, 1 )
			surface.DrawRect(31, 35, 18, 1 )
			surface.DrawRect(75, 25, 1, 20 )

			if ship:GetIsHome() then
				draw.SimpleText("DOCKED","DermaDefault",75,12,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			end

			if ship:GetIsHooked() then
				draw.SimpleText("HOOKED","DermaDefault",75,55,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			end

			if hurt then
				DoHurtScreenEffect(color,100,70)
			end

		cam.End3D2D()
	end
end

--[[
function ENT:SetDriver(ply)
	if ply==self.driver then return end

	if IsValid(ply) then
		if ply.driven_ent.driver == ply then
			ply.driven_ent.driver = nil
		end
	end

	if IsValid(self.driver) then
		if self.driver.driven_ent == self then
			self.driver.driven_ent = nil
		end
	end
end]]
--[[function ENT:Draw()
	self:DrawModel()
end]]

-- models/spacebuild/chair.mdl