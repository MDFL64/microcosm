AddCSLuaFile()

ENT.Base = "micro_component"

ENT.ComponentModel = "models/smallbridge/other/sbconsolelow.mdl"
ENT.ComponentHideName = true
ENT.ComponentScreenWidth = 216
ENT.ComponentScreenHeight = 150
ENT.ComponentScreenOffset = Vector(-14,-27,33)
ENT.ComponentScreenRotation = Angle(0,90,30)

ENT.ControlEyeLock = true

function ENT:GetComponentName()
	return "Helm Console"
end

function ENT:DrawScreen(ship,broken)
	local throttle = ship:GetThrottle()
	local ship_angs = ship:GetAngles()

	surface.SetDrawColor(Color( 100, 100, 100))
	surface.DrawOutlinedRect(58,25,100,30) -- compass
	surface.DrawOutlinedRect(15,25,30,100) -- throttle
	surface.DrawOutlinedRect(171,25,30,100) -- pitch

	local function drawDir(ang,letter)
		ang = math.NormalizeAngle(ang+180)
		if ang<60 and ang>-60 then
			draw.SimpleText(letter,"DermaLarge",108+ang*.65,40,Color(255,255,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		end
	end

	drawDir(ship_angs.y,"N")
	drawDir(ship_angs.y+90,"E")
	drawDir(ship_angs.y+180,"S")
	drawDir(ship_angs.y-90,"W")

	surface.SetDrawColor(Color( 255, 0, 0))
	surface.DrawRect(16, 75, 28, -49*throttle )

	surface.SetDrawColor(Color( 0, 255, 0))
	surface.DrawRect(172, 74+49*(ship_angs.p/90), 28, 3 )

	--centers
	surface.SetDrawColor(Color( 100, 100, 100))
	surface.DrawRect(108, 25, 1, 30 )
	surface.DrawRect(15, 75, 30, 1 )
	surface.DrawRect(171, 75, 30, 1 )

	if ship:GetIsHome() then
		draw.SimpleText(">DOCKED<","DermaDefault",108,70,Color(255,255,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	end

	if ship:GetIsHooked() then
		draw.SimpleText(">HOOKED<","DermaDefault",108,90,Color(255,255,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	end
end

function ENT:Use(activator, caller, useType, value)
	if not IsValid(self.controller) then
		caller:ProxyControls(self)
		self.controller = caller
	else
		self:EmitSound("buttons/button11.wav")
	end
end

function ENT:sendControls(buttons,buttons_pressed,x,y)

	local ship_info = self:GetShipInfo()

	if not IsValid(ship_info.entity) or self:IsBroken() then return end

	if bit.band(buttons,IN_FORWARD)!=0 then
		ship_info.entity.ctrl_v = 1
	elseif bit.band(buttons,IN_BACK)!=0 then
		ship_info.entity.ctrl_v = -1        
	else
		ship_info.entity.ctrl_v = 0
	end

	if bit.band(buttons,IN_MOVELEFT)!=0 then
		ship_info.entity.ctrl_h = 1
	elseif bit.band(buttons,IN_MOVERIGHT)!=0 then
		ship_info.entity.ctrl_h = -1        
	else
		ship_info.entity.ctrl_h = 0
	end

	ship_info.entity.ctrl_y = math.Clamp(-x/50,-1,1)
	ship_info.entity.ctrl_p = math.Clamp(y/50,-1,1)

	if bit.band(buttons,IN_JUMP)!=0 then
		ship_info.entity:SetThrottle(0)
	end

	if bit.band(buttons,IN_SPEED)!=0 then
		ship_info.entity.ctrl_t = 1
	elseif bit.band(buttons,IN_DUCK)!=0 then
		ship_info.entity.ctrl_t = -1
	else
		ship_info.entity.ctrl_t = 0
	end

	if bit.band(buttons,IN_RELOAD)!=0 then
		ship_info.entity:UnHook()
	end
end

function ENT:stopControl()
	local ship_info = self:GetShipInfo()

	if IsValid(ship_info.entity) then
		ship_info.entity.ctrl_v = 0
		ship_info.entity.ctrl_h = 0
		ship_info.entity.ctrl_y = 0
		ship_info.entity.ctrl_p = 0
		ship_info.entity.ctrl_t = 0
	end
	self.controller = nil
end

function ENT:Think()
	
	local broken = self:IsBroken()

	if SERVER and broken then
		local ship_info = self:GetShipInfo()

		ship_info.entity.ctrl_v = math.random()*2-1
		ship_info.entity.ctrl_h = math.random()*2-1
		ship_info.entity.ctrl_y = math.random()*2-1
		ship_info.entity.ctrl_p = math.random()*2-1
		ship_info.entity.ctrl_t = math.random()*2-1
	end
end