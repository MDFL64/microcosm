AddCSLuaFile()


ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_BOTH

local SHIP_HEALTH = 2000
ENT.MaxHookHealth = 500
ENT.CritTime = 60

local matFire = Material("effects/fire_cloud1")

function ENT:SetupDataTables()
	--self:NetworkVar("Vector", 0, "InternalOrigin")
	self:NetworkVar("Int", 0, "ShipID")
	self:NetworkVar("Int", 1, "HookHealth")
	self:NetworkVar("Int", 2, "KillTime")
	self:NetworkVar("Float", 0, "Throttle")
	self:NetworkVar("Bool", 0, "IsHome")
	self:NetworkVar("Bool", 1, "IsHooked")
end

function ENT:Initialize()

	MICRO_SHIP_INFO[self:GetShipID()].entity = self
	self.info = MICRO_SHIP_INFO[self:GetShipID()]

	self.thrust_effect_offsets = {}

	if SERVER then
		--[[self:PhysicsInitSphere(16,"metal")

		self:StartMotionController()
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableGravity(false)
			phys:SetMass(1000)
		end]]

		self.rebuild_requested = true

		self.ctrl_v = 0
		self.ctrl_h = 0

		self.ctrl_p = 0
		self.ctrl_y = 0

		self.ctrl_t = 0

		self.hook_ents = {}

		self:SetHealth(SHIP_HEALTH)
		self:SetMaxHealth(SHIP_HEALTH)
	else
		self.external_client_models = {}

		for ep,_ in pairs(self.info.external_parts) do
			self:ExternalPartAdded(ep)
		end
	end


	self:DrawShadow(false)
end

function ENT:ExternalPartAdded(ep)
	if ep.GetThrustEffectOffsets then
		table.Add(self.thrust_effect_offsets,ep:GetThrustEffectOffsets())
	end

	if CLIENT then
		local matrix = Matrix()
		matrix:Scale(Vector(1,1,1)*MICRO_SCALE)

		local mdl = ClientsideModel(ep:GetModel(),RENDERGROUP_OPAQUE)
		mdl:SetSkin(ep:GetSkin())
		mdl:SetNoDraw(true)
		mdl:EnableMatrix("RenderMultiply",matrix)

		self.external_client_models[ep] = mdl
	else
		self.rebuild_requested = true
	end
end

function ENT:RebuildCollisions()

	local convexes = {}
	for ep,_ in pairs(self.info.external_parts) do
		local phys = ep:GetPhysicsObject()
		if !phys:IsValid() then continue end
		local convex = {}
		for i,v in pairs(phys:GetMesh()) do
			table.insert(convex,v.pos*MICRO_SCALE)
		end
		table.insert(convexes,convex)
	end
	self:PhysicsInitMultiConvex(convexes)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self:EnableCustomCollisions(true)
	self:StartMotionController()
	
	local phys = self:GetPhysicsObject()
	-- print(phys:GetVolume()) I WOULD BASE MASS ON THIS BUT I FEEL LIKE THAT COULD CAUSE MORE PROBLEMS THAN IT SOLVES.
	phys:EnableGravity(false)
	phys:SetMass(1000)

	self.rebuild_requested = false
end

function ENT:Draw()
	local ship_info = LocalPlayer():GetShipInfo()

	if self.info == ship_info then return end

	for ent,mdl in pairs(self.external_client_models) do
		mdl:SetRenderOrigin(self:LocalToWorld( (ent:GetPos()-self.info.origin)*MICRO_SCALE ))
		mdl:SetRenderAngles(self:LocalToWorldAngles(ent:GetAngles()))

		mdl:DrawModel()
	end
end

function ENT:DrawTranslucent()
	local hurt = self:IsBroken()

	if self:GetThrottle()>0 and !hurt then
		local throttle = self:GetThrottle()

		local scroll = -CurTime()*10*throttle

		local offsets = self.thrust_effect_offsets
		local offset_mid = self:GetAngles():Forward()*-10*throttle
		local offset_end =  self:GetAngles():Forward()*-15*throttle

		render.SetMaterial(matFire)

		for i=1,#offsets do
			local thrust_base = self:LocalToWorld(offsets[i])
			render.StartBeam(3)
			render.AddBeam(thrust_base,3,scroll, Color(255,255,255))
			render.AddBeam(thrust_base+offset_mid,2,scroll+2, Color(255,255,255))
			render.AddBeam(thrust_base+offset_end,0,scroll+3, Color(255,255,255))
			render.EndBeam()
		end
	end

	local ship_info = LocalPlayer():GetShipInfo()

	if self.info == ship_info then return end

	if self:GetIsHome() then
		render.DrawWireframeSphere(self:GetPos(),24,6,6,self:GetColor(),true)
	end

	--render.DrawScreenQuad()
end

local function id() end

local reset_whitelist = {
	info_target = id, -- we can actually safely delete this, but W/E

	micro_hull = id,
	micro_subhull = id,
	micro_detail = id,
	micro_speaker = id,

	micro_comp_cannon = function(ent)
		ent.fire = false
	end,

	micro_comp_shop = function(ent)
		ent:SetCash(math.max(ent:GetCash()/2,ent.StartingCash))
	end,

	micro_comp_comms = function(ent)
		ent.text_lines = {}
	end,

	player = function(ent)
		ent:Kill()
		ent.last_ship_info = nil
	end
}

local sound_dead = Sound("ambient/explosions/explode_1.wav")

function ENT:Think()
	if SERVER then
		if self:IsBroken() and CurTime()>self:GetKillTime() then
			-- Reset everything, pretty jank. In future just nuke everything and respawn.
			BroadcastComms(Color(255,0,255),"CENTRAL >>> ",MICRO_TEAM_COLORS[self:GetShipID()],string.upper(MICRO_TEAM_NAMES[self:GetShipID()]),Color(255,0,255)," GOT BLOWN UP! SAVAGE!")
			
			self:RepairAll()
			self:ReloadGuns()
			self:SetThrottle(0)
			self:UnHook()

			self.ctrl_v = 0
			self.ctrl_h = 0

			self.ctrl_p = 0
			self.ctrl_y = 0

			self.ctrl_t = 0

			-- kill stray ropes
			for _,c in pairs(constraint.FindConstraints(self,"Rope")) do
				if IsValid(c.Constraint) then c.Constraint:Remove() end
			end

			for _,ent in pairs(ents.FindInBox(self.info.mins,self.info.maxs)) do

				local f = reset_whitelist[ent:GetClass()]
				if f then
					f(ent)
				elseif ent:GetClass():sub(1,10) != "micro_comp" then
					ent:Remove()
				end
			end

			self:SetPos(self.home:GetPos()+Vector(0,0,25))
			self:SetAngles(self.home:GetAngles())

			sound.Play(sound_dead,self.info.origin)
		end

		if self.rebuild_requested then
			self:RebuildCollisions()
		end

		self:PhysWake()

		self:SetThrottle(math.Clamp(self:GetThrottle() + self.ctrl_t*FrameTime()*10,-1,1))

		local hurt = self:IsBroken()

		if (self.ctrl_h!=0 or self.ctrl_v!=0) and !hurt then
			self.speaker_strafe:Play()
		else
			self.speaker_strafe:Stop()
		end

		if self:GetThrottle()!=0 and !hurt then
			self.speaker_engine:Play(50+math.abs(self:GetThrottle())*80)
		else
			self.speaker_engine:Stop()
		end


		if !IsValid(self.trail) and self:GetThrottle()>0 and !hurt then
			local offset = self.thrust_effect_offsets[1]

			if offset!=nil then
				self.trail = ents.Create("micro_trail")
				self.trail:SetParent(self)
				self.trail:SetLocalPos(offset)
				self.trail:Spawn()
				self.trail:Setup(self:GetColor())
			end
		end

		if IsValid(self.trail) and (self:GetThrottle()<=0 or hurt) then
			self.trail:Stop()
			self.trail = nil
		end
		local tr = util.TraceLine{start=self:GetPos(),endpos=self:GetPos()+Vector(0,0,-30),filter=self}
		self:SetIsHome(tr.Entity==self.home)
	end
end

function ENT:PhysicsSimulate(phys, dt)

	if self:IsBroken() then
		local av = phys:GetAngleVelocity()
		return -av,Vector(0,0,-50000)*MICRO_SCALE*dt,SIM_GLOBAL_ACCELERATION
	end

	local angs = phys:GetAngles()
	
	local ctrl_v = self.ctrl_v
	local ctrl_h = self.ctrl_h

	local ctrl_r = -math.NormalizeAngle(angs.r)
	

	local ctrl_p = self.ctrl_p*100--math.Clamp(Player(2):EyeAngles().p,-45,45)
	local ctrl_y = self.ctrl_y*100--math.Clamp(Player(2):EyeAngles().y,-45,45)
	--print("-",self.ctrl_y)
	local av = phys:GetAngleVelocity()

	if math.abs(angs.p)>80 then
		ctrl_p=-av.y*10-angs.p
	end
	
	local dav = Vector(ctrl_r,ctrl_p,ctrl_y)

	local v = phys:WorldToLocalVector(phys:GetVelocity())

	local throttle = self:GetThrottle()
	if throttle > 0 then throttle=throttle*100 else throttle=throttle*25 end
	local dv = Vector(throttle,ctrl_h*25,ctrl_v*25)

	

	return dav-av,dv-v,SIM_LOCAL_ACCELERATION
end

local sounds_impact = {
	Sound("physics/metal/metal_canister_impact_hard1.wav"),
	Sound("physics/metal/metal_canister_impact_hard2.wav"),
	Sound("physics/metal/metal_canister_impact_hard3.wav")
}

local sound_crash = Sound("vehicles/v8/vehicle_impact_heavy1.wav")
local sound_unhook = Sound("npc/attack_helicopter/aheli_mine_drop1.wav")


local damage_whitelist = {
	micro_ship=true,
	micro_artifact=true
}

function ENT:OnTakeDamage(dmg)
	local attacker = dmg:GetAttacker()

	if IsValid(attacker) and damage_whitelist[attacker:GetClass()] then
		local pos = self:WorldToLocal(dmg:GetDamagePosition())
		sound.Play(table.Random(sounds_impact),self.info.origin+pos/MICRO_SCALE)
		self:ApplyDamage(dmg:GetDamage())
	end
end

function ENT:PhysicsCollide(data, phys)
	if ( data.Speed > 30 ) then
		local pos = self:WorldToLocal(data.HitPos)
		sound.Play(sound_crash,self.info.origin+pos/MICRO_SCALE,100,100,1)

		for i,ply in pairs(player.GetAll()) do
			if ply:GetShipInfo()==self.info then
				ply:ViewPunch( Angle(math.random()*2-1,math.random()*2-1,math.random()*2-1)*(data.Speed/2) )
			end
		end

		self:ApplyDamage(data.Speed)
	end
end

function ENT:UnHook()
	if self:GetIsHooked() then
		self:SetIsHooked(false)
		self:SetHookHealth(0)
		for _,v in pairs(self.hook_ents) do
			if IsValid(v) then
				v:Remove()
			end
		end
		self.hook_ents = {}
		sound.Play(sound_unhook,self.info.origin,100,100,1)
	end
end

if SERVER then
	local debug_class

	function ENT:ApplyDamage(dmg,iter)
		if self:GetIsHome() then return end

		iter = iter or 1

		if iter==1 then
			local hook_hp = self:GetHookHealth()
			if hook_hp>0 then
				hook_hp = hook_hp-dmg
				if hook_hp<=0 then
					self:UnHook()
				else
					self:SetHookHealth(hook_hp)
				end
			end
		end

		local damaged_ent
		
		if debug_class then
			for ent,_ in pairs(self.info.components) do
				if ent:GetClass()==debug_class then
					damaged_ent = ent
					break
				end
			end
		else
			local r = math.random()
			if r<(self:Health()/self:GetMaxHealth()) then
				damaged_ent = self
			else
				local dmg_table = {}

				for ent,_ in pairs(self.info.components) do
					table.insert(dmg_table,ent)
				end

				for i,ply in pairs(player.GetAll()) do
					if ply:GetShipInfo()==self.info then
						table.insert(dmg_table,ply)
					end
				end

				damaged_ent = table.Random(dmg_table)
			end
		end

		if IsValid(damaged_ent) then
			local hp = damaged_ent:Health()
			if damaged_ent:IsPlayer() then
				damaged_ent:TakeDamage(dmg)
			else
				local was_broken = damaged_ent:IsBroken()
				damaged_ent:SetHealth(math.max(hp - dmg,0))
				if damaged_ent == self and !was_broken and damaged_ent:IsBroken() then
					self:SetKillTime(math.floor(CurTime()+self.CritTime))
				end
			end

			dmg = dmg-hp
		end

		if dmg>0 and iter<3 then
			self:ApplyDamage(dmg,iter+1)
		end
	end

	function ENT:RepairAll()
		self:SetHealth(self:GetMaxHealth())
		for ent,_ in pairs(self.info.components) do
			ent:SetHealth(ent:GetMaxHealth())
		end
		for i,ply in pairs(player.GetAll()) do
			if ply:GetShipInfo()==self.info and ply:Alive() then
				ply:SetHealth(ply:GetMaxHealth())
			end
		end
	end

	function ENT:ReloadGuns()
		for ent,_ in pairs(self.info.components) do
			if ent:GetClass()=="micro_comp_cannon" then
				ent:SetAmmo1(ent.Ammo1Max)
				ent:SetAmmo2(ent.Ammo2Max)
				ent:SetAmmo3(ent.Ammo3Max)
			end
		end
	end
end