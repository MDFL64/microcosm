AddCSLuaFile()

DEFINE_BASECLASS("micro_component")
ENT.Base = "micro_component"

function ENT:Initialize()
	BaseClass.Initialize(self)

	if CLIENT then
		self.sound_alarm = CreateSound(self,"npc/turret_floor/alarm.wav")
		self.sound_critical = CreateSound(self,"ambient/alarms/siren.wav")
	end
end

function ENT:GetComponentName()
	return "Integrity Monitor"
end

if CLIENT then
	function ENT:Think()
		local ship_info = self:GetShipInfo()

		if !IsValid(ship_info.entity) then return end

		local i = 1
		local broken = self:IsBroken()
		local alarm = 0
		local function check(ent)
			local current = ent:Health()

			if broken then current = math.floor((math.sin(CurTime()+i)/2+.5) *ent:GetMaxHealth()) end

			if ent:CheckBroken(current) then
				if ent:GetClass()=="micro_ship" then
					alarm=2
				else
					alarm=math.max(alarm,1)
				end
			end

			i=i+1
		end

		check(ship_info.entity)

		for ent,_ in pairs(ship_info.components) do
			check(ent)
		end

		if alarm==2 then
			self.sound_critical:Play()
		else
			self.sound_critical:Stop()
		end

		if alarm==1 then
			self.sound_alarm:Play()
			self.sound_alarm:ChangeVolume(.2)
		else
			self.sound_alarm:Stop()
		end
	end
end

function ENT:drawInfo(ship,broken)
	local i = 1

	local function drawBar(ent)
		local name = tostring(ent)

		if ent:GetClass()=="micro_ship" then
			name = "Hull + Engines"
		elseif ent.GetComponentName then
			name = ent:GetComponentName()
		end

		local current = ent:Health()

		if broken then current = math.floor((math.sin(CurTime()+i)/2+.5) *ent:GetMaxHealth()) end

		local fraction = current / ent:GetMaxHealth()

		surface.SetDrawColor(Color( (1-fraction)*255, (fraction)*150, 0))
		surface.DrawRect( 2, 30+i*20, 356*fraction, 16 )

		local text_color = Color(255,255,255)

		draw.SimpleText(name,"micro_shadow",40,30+i*20,text_color,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)

		local print_fraction = current.." / "..ent:GetMaxHealth()

		if ent:CheckBroken(current) then
			if math.floor(CurTime())%2==0 then
				print_fraction = "BROKEN!"
				text_color = Color(255,0,0)
			end
		end

		draw.SimpleText(print_fraction,"micro_shadow",240,30+i*20,text_color,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
		
		i=i+1
	end

	drawBar(ship)

	for ent,_ in pairs(ship.info.components) do
		drawBar(ent)
	end
end