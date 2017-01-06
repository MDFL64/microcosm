AddCSLuaFile()

ENT.Type = "anim"

ENT.MaxMicroHealth = 100
function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "MicroHealth")
end

function ENT:GetMicroHealthDisplayName()
	return "Ship Integrity Monitor"
end

function ENT:Initialize()
	self:SetModel("models/props_phx/construct/metal_plate2x2.mdl")

	self:PhysicsInitStandard()

	if SERVER then
		self:GetPhysicsObject():EnableMotion(false)
		self:SetUseType(SIMPLE_USE)

		self:SetMicroHealth(self.MaxMicroHealth)
	else
		self.sound_alarm = CreateSound(self,"npc/turret_floor/alarm.wav")
		self.sound_critical = CreateSound(self,"ambient/alarms/siren.wav")
	end

	self.tracked_ents = {}

	timer.Simple(1,function()
		for _,ent in pairs(ents.FindInSphere(self:GetPos(),2000)) do
			if ent.GetMicroHealth then
				if SERVER and ent:GetClass()=="micro_hull" then
					self.hull = ent
				else
					table.insert(self.tracked_ents,ent)
				end
			end
		end
		--ship:GetInternalOrigin()
	end)


end

function ENT:Draw()
	self:DrawModel()

	local hurt = IsComponentHurt(self)

	cam.Start3D2D(self:LocalToWorld(Vector(-45,-45,4)),self:GetAngles()+Angle(90,90,90), .25 )
		local ship = Entity(MICRO_SHIP_ID or -1)
		if IsValid(ship) then
			local color = ship:GetColor()

			surface.SetDrawColor(Color( 0, 0, 0))
			surface.DrawRect( 0, 0, 360, 360 )

			surface.SetDrawColor(color)
			surface.DrawOutlinedRect(0,0,360,360)
			surface.DrawOutlinedRect(1,40,358,319)

			draw.SimpleText("SHIP INTEGRITY","DermaLarge",180,20,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			
			local alarm = 0

			for i,ent in pairs(self.tracked_ents) do
				local name = tostring(ent)
				if ent.GetMicroHealthDisplayName then
					name = ent:GetMicroHealthDisplayName()
				end

				local current = ent:GetMicroHealth()

				if hurt then current = math.floor((math.sin(CurTime()+i)/2+.5) *ent.MaxMicroHealth) end

				local fraction = current / ent.MaxMicroHealth

				surface.SetDrawColor(Color( (1-fraction)*255, (fraction)*150, 0))
				surface.DrawRect( 2, 30+i*20, 356*fraction, 16 )

				local text_color = Color(255,255,255)

				draw.SimpleText(name,"micro_shadow",40,30+i*20,text_color,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)

				local print_fraction = current.." / "..ent.MaxMicroHealth

				if IsComponentHurt(ent) then
					if ent:GetClass()=="micro_hull" then
						alarm=2
					else
						alarm=math.max(alarm,1)
					end

					if math.floor(CurTime())%2==0 then
						print_fraction = "BROKEN!"
						text_color = Color(255,0,0)
					end
				end

				draw.SimpleText(print_fraction,"micro_shadow",240,30+i*20,text_color,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)


				-- ent:GetMicroHealth().." / "..ent.MaxMicroHealth
			end

			if hurt then
				DoHurtScreenEffect(color,360,360)
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
	cam.End3D2D()
end

function IsComponentHurt(comp)
	return comp:GetMicroHealth() < comp.MaxMicroHealth*.3
end

if SERVER then
	local debug_class

	function ENT:ApplyDamage(dmg,iter)
		iter = iter or 1

		local damaged_ent
		
		if debug_class then
			for k,v in pairs(self.tracked_ents) do
				if v:GetClass()==debug_class then
					damaged_ent = v
					break
				end
			end
		else
			local r = math.random()
			if r<(self.hull:GetMicroHealth()/self.hull.MaxMicroHealth) then
				damaged_ent = self.hull
			else
				local dmg_table = {}
				table.Add(dmg_table,self.tracked_ents)
				table.Add(dmg_table,team.GetPlayers(self.ship.team_id))

				damaged_ent = table.Random(dmg_table)
			end
		end

		if IsValid(damaged_ent) then
			local hp =  damaged_ent:IsPlayer() and damaged_ent:Health() or damaged_ent:GetMicroHealth()
			if damaged_ent:IsPlayer() then
				damaged_ent:TakeDamage(dmg)
				if hp>0 then
					damaged_ent:EmitSound("vo/npc/male01/pain0"..math.random(9)..".wav")
				end
			else
				damaged_ent:SetMicroHealth(math.max(hp - dmg,0))
			end

			dmg = dmg-hp
		end

		if dmg>0 and iter<3 then
			self:ApplyDamage(dmg,iter+1)
		end
	end

	function ENT:RepairAll()
		self.hull:SetMicroHealth(self.hull.MaxMicroHealth)
		for k,v in pairs(self.tracked_ents) do
			v:SetMicroHealth(v.MaxMicroHealth)
		end
	end
end