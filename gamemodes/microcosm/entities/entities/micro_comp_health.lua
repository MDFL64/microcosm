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

			if ent:IsBroken() then
				if ent:GetClass()=="micro_ship" then
					alarm=2
				else
					alarm=math.max(alarm,1)
				end
			end

			i=i+1
		end

		if !broken then
			check(ship_info.entity)

			for ent,_ in pairs(ship_info.components) do
				check(ent)
			end
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
	
	local hurr = "PARTYTIME!"

	local function drawBar2(name,current,max,crit_txt,verybad)

		if broken then current = math.floor((math.sin(CurTime()+i)/2+.5) *max) end

		local fraction = current / max

		if verybad then
			surface.SetDrawColor(Color(150,0,0))
		else
			surface.SetDrawColor(Color( (1-fraction)*255, (fraction)*150, 0))
		end
		surface.DrawRect( 2, 30+i*20, 356*fraction, 16 )

		local text_color = Color(255,255,255)

		draw.SimpleText(name,"micro_shadow",40,30+i*20,text_color,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)

		local print_fraction = current.." / "..max

		if broken then
			print_fraction = hurr[i]
			text_color = HSVToColor(CurTime()*100%360,.5,1)
		elseif isstring(crit_txt) then
			print_fraction = crit_txt
			if !verybad then 
				text_color = Color(255,0,0)
			end
		end

		draw.SimpleText(print_fraction,"micro_shadow",240,30+i*20,text_color,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
		
		i=i+1
	end

	if broken or ship:IsBroken() then
		local count = math.floor(ship:GetKillTime()-CurTime())
		drawBar2("INTEGRITY CRITICAL",count,ship.CritTime,count.." SECONDS",true)
	end

	drawBar2("Hull + Engines",ship:Health(),ship:GetMaxHealth(),ship:IsBroken() and math.floor(CurTime())%2==0 and "BROKEN!")
	drawBar2("Hooks",ship:GetHookHealth(),ship.MaxHookHealth)

	for ent,_ in pairs(ship.info.components) do
		drawBar2(ent:GetComponentName(),ent:Health(),ent:GetMaxHealth(),ent:IsBroken() and math.floor(CurTime())%2==0 and "BROKEN!")
	end
end