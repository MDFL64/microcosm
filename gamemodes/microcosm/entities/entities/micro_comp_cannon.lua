AddCSLuaFile()

DEFINE_BASECLASS("micro_component")
ENT.Base = "micro_component"

ENT.ComponentModel = "models/props_phx/construct/metal_plate1x2.mdl"
ENT.ComponentScreenHeight = 180
ENT.ComponentScreenOffset = Vector(22.5,45,4)

ENT.Ammo1Max = 200
ENT.Ammo2Max = 4
ENT.Ammo3Max = 8

ENT.drawScreenToHud = true

local sound_fire = Sound("weapons/ar2/fire1.wav")
local sound_fire_hook = Sound("weapons/crossbow/fire1.wav")
local sound_fire_hook_nope = Sound("buttons/button2.wav")
local sound_fire_use = Sound("weapons/airboat/airboat_gun_lastshot1.wav")
local sound_empty = Sound("weapons/ar2/ar2_empty.wav")
local sound_select = Sound("weapons/shotgun/shotgun_cock.wav")
local sound_reload = Sound("doors/door_latch1.wav")

function ENT:GetComponentName()
	return self:GetGunName().." Cannon"
end

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "GunName")
	
	self:NetworkVar("Int", 0, "SelectedAmmo")
	self:NetworkVar("Int", 1, "Ammo1")
	self:NetworkVar("Int", 2, "Ammo2")
	self:NetworkVar("Int", 3, "Ammo3")

	self:NetworkVar("Bool", 0,"HookTooFar")
end

function ENT:Initialize()
	BaseClass.Initialize(self)

	if SERVER then
		self.gun = ents.Create("micro_detail")
		self.gun:SetModel("models/slyfo/rover_snipercannon.mdl")
		self.gun:SetPos(self:LocalToWorld(Vector(0,0,-50))) -- originally 0,50,50
		self.gun:Spawn()

		self:SetSelectedAmmo(1)
		self:SetAmmo1(self.Ammo1Max)
		self:SetAmmo2(self.Ammo2Max)
		self:SetAmmo3(self.Ammo3Max)

		self.next_fire = 0
	end
end

function ENT:sendControls(key_down,key_pressed,key_released,angs)

	if self:IsBroken() then return end

	
	local tr = util.TraceLine{start=self.gun:GetPos(),endpos=self.gun:GetPos()+angs:Forward()*10000,filter=self}
	
	if key_pressed(IN_FORWARD) then
		if self:GetSelectedAmmo()==1 then
			self:SetSelectedAmmo(3)
		else
			self:SetSelectedAmmo(self:GetSelectedAmmo()-1)
		end
		sound.Play(sound_select,self.gun:GetPos(),75,150,1)
	end

	if key_pressed(IN_BACK) then
		self:SetSelectedAmmo(self:GetSelectedAmmo()%3+1)
		sound.Play(sound_select,self.gun:GetPos(),75,150,1)
	end
	
	if tr.Entity:IsWorld() then
		self.gun:SetAngles(angs)
		self.fire = key_down(IN_ATTACK)
	else
		self.fire = false
	end
end

function ENT:stopControl()
	self.controller = nil
	self.fire=false
end

function ENT:controlView(pos,angles,fov)
	local view = {}
	view.origin = self:LocalToWorld(Vector(50,0,-50))
	view.angles = angles
	view.fov = fov
	view.drawviewer = true
	return view
end

function ENT:Think()
	if SERVER then
		local hurt = self:IsBroken()

		if hurt then
			self:SetSelectedAmmo(1)
			self.fire = math.random()<.1
			local base_yaw = self:GetAngles().y
			local angs = self.gun:GetAngles()
			angs=angs+Angle(math.random()*2-1,math.random()*2-1,math.random()*2-1)*10
			angs.p = math.Clamp(angs.p,-30,30)
			--print(angs.y)
			angs.y = math.Clamp(angs.y,base_yaw+150,base_yaw+210)
			--angs.r = math.Clamp(angs.p,-10,10)
			self.gun:SetAngles(angs)
		end

		local ship_info = self:GetShipInfo()

		if self.fire and CurTime()>self.next_fire and IsValid(ship_info.entity) then
			local origin = ship_info.origin

			local real_pos = ship_info.entity:GetPos()
			local real_ang = ship_info.entity:GetAngles()

			local start_pos,start_ang = LocalToWorld((self.gun:GetPos()+self.gun:GetAngles():Forward()*150-origin)*MICRO_SCALE,self.gun:GetAngles(),real_pos,real_ang)
			
			if self:GetSelectedAmmo()==1 then
				if self:GetAmmo1()>0 then
					sound.Play(sound_fire,self.gun:GetPos(),75,50,1)
					
					self:SetAmmo1(self:GetAmmo1()-1)

					ship_info.entity:FireBullets{
						Src=start_pos,
						Dir=start_ang:Forward(),
						Spread=Vector(.03,.03,.03),
						Damage=10,
						Tracer=0,
						Callback=function(attacker,tr,dmg)
							SendTracer(1,tr.StartPos,tr.HitPos)
						end
					}
				else
					sound.Play(sound_empty,self.gun:GetPos(),75,50,1)
				end
				self.next_fire = CurTime()+.1
			elseif self:GetSelectedAmmo()==2 then
				if self:GetAmmo2()>0 then

					local tr = util.TraceLine{start=start_pos,endpos=start_pos+start_ang:Forward()*100,filter=ship_info.entity}

					--if tr.HitWorld then
					--    tr.Entity = game.GetWorld()
					--    print(tr.Entity)
					--end
					if IsValid(tr.Entity) or tr.Entity:IsWorld() then
						sound.Play(sound_fire_hook,self.gun:GetPos(),75,150,1)
						tr.Entity:Use(ship_info.entity,ship_info.entity,USE_ON,1)
						self:SetAmmo2(self:GetAmmo2()-1)

						-- fuck it, it's fucked, it is what it is
						local pos1 = ship_info.entity:LocalToWorld(ship_info.entity:GetPhysicsObject():GetMassCenter())
						local pos2 = tr.HitPos

						local rope_len = pos1:Distance(pos2)

						local a,b = constraint.Rope(ship_info.entity,tr.Entity,0,0,ship_info.entity:WorldToLocal(pos1),tr.Entity:WorldToLocal(pos2),rope_len,0,0,.1,"cable/cable2.vmt",false)
						
						if a then table.insert(ship_info.entity.hook_ents,a) end
						if b then table.insert(ship_info.entity.hook_ents,b) end
						
						if !ship_info.entity:GetIsHooked() then
							ship_info.entity:SetHookHealth(ship_info.entity.MaxHookHealth)
						end

						ship_info.entity:SetIsHooked(true)
					else
						sound.Play(sound_fire_hook_nope,self.gun:GetPos(),75,100,1)
						self:SetHookTooFar(true)
						timer.Simple(.8,function()
							if IsValid(self) then
								self:SetHookTooFar(false)
							end
						end)
					end
				else
					sound.Play(sound_empty,self.gun:GetPos(),75,50,1)
				end
				self.next_fire = CurTime()+1
			elseif self:GetSelectedAmmo()==3 then
				if self:GetAmmo3()>0 then
					sound.Play(sound_fire_use,self.gun:GetPos(),75,100,1)

					local tr = util.TraceLine{start=start_pos,endpos=start_pos+start_ang:Forward()*10000,filter=ship_info.entity}
					if IsValid(tr.Entity) then
						tr.Entity:Use(ship_info.entity,ship_info.entity,USE_ON,1)
					end
					SendTracer(2,tr.StartPos,tr.HitPos)

					self:SetAmmo3(self:GetAmmo3()-1)
				else
					sound.Play(sound_empty,self.gun:GetPos(),75,50,1)
				end
				self.next_fire = CurTime()+1
			end
		end
		
		self:NextThink( CurTime() )
		return true
	end
end

function ENT:PhysicsCollide(data, phys)
	--if self:IsBroken() then return end
	local class = data.HitEntity:GetClass()

	if class:sub(1,17)=="micro_item_shell_" then
		local type = tonumber(class:sub(18))

		local ammo_needed = self["Ammo"..type.."Max"] - self["GetAmmo"..type](self)
		local ammo_taken = data.HitEntity:TryTake(ammo_needed)

		if ammo_taken>0 then
			self:EmitSound(sound_reload)
			self["SetAmmo"..type](self,self["GetAmmo"..type](self)+ammo_taken)
		end
	end
end

function ENT:drawInfo(ship,broken)
	local color = ship:GetColor()

	local selected = self:GetSelectedAmmo()
	if broken then selected = math.random(3) end

	draw.SimpleText("->","micro_med",12,32+30*selected,color,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

	draw.SimpleText("Standard Shells: "..(broken and math.random(self.Ammo1Max) or self:GetAmmo1()).." / "..self.Ammo1Max,"micro_med",40,62,Color(255,100,0),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	
	if self:GetHookTooFar() then
		draw.SimpleText("Hook out of range!","micro_med",40,92,Color(255,0,0),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	else
		draw.SimpleText("Hook Shells: "..(broken and math.random(self.Ammo2Max) or self:GetAmmo2()).." / "..self.Ammo2Max,"micro_med",40,92,Color(100,100,100),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	end

	draw.SimpleText("Use Shells: "..(broken and math.random(self.Ammo3Max) or self:GetAmmo3()).." / "..self.Ammo3Max,"micro_med",40,122,Color(0,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
end