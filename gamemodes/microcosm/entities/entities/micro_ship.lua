AddCSLuaFile()


ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_BOTH

local matFire = Material("effects/fire_cloud1")

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "InternalOrigin")
	self:NetworkVar("Float", 0, "Throttle")
	self:NetworkVar("Bool", 0, "IsHome")
	self:NetworkVar("Bool", 1, "IsHooked")
end

function ENT:Initialize()

	--self:SetModel("models/props_junk/watermelon01.mdl")

	--self:PhysicsInitStandard()]]

	if SERVER then
        self:PhysicsInitSphere(16,"metal")

		self:StartMotionController()
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableGravity(false)
			--print(">>",phys:GetMass())
			phys:SetMass(1000)
		end

		self.ctrl_v = 0
		self.ctrl_h = 0

		self.ctrl_p = 0
		self.ctrl_y = 0

		self.ctrl_t = 0

		self.hook_ents = {}
	else
		self.hulls = {}
	end

	--self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:DrawShadow(false)
end


--function ENT:DrawTranslucent()
--	print("ballsack")
--end

function ENT:Draw()
	if Entity(MICRO_SHIP_ID or -1)!=self then
		for _,hull in pairs(self.hulls) do
			hull:SetRenderOrigin(self:GetPos())
			hull:SetRenderAngles(self:GetAngles())

			hull:DrawModel()
			--print(hull:GetParent())
			--[[local matrix = Matrix()
			matrix:Translate(-self:GetInternalOrigin()+self:GetPos())
			cam.PushModelMatrix(matrix)
			hull:DrawModel()
			cam.PopModelMatrix()]]
		end

		--self:DrawModel()
	end
end

function ENT:DrawTranslucent()
	if self:GetThrottle()>0 then
		local throttle = self:GetThrottle()

		local scroll = -CurTime()*10*throttle

		local offsets = {
			Vector(-15,0,0),
			Vector(-14,7,0),
			Vector(-14,-7,0),
			Vector(-13,3,4),
			Vector(-13,-3,4)
		}
		local offset_mid = self:GetAngles():Forward()*-10*throttle
		local offset_end =  self:GetAngles():Forward()*-15*throttle

		render.SetMaterial(matFire)

		for i=1,5 do
			local thrust_base = self:LocalToWorld(offsets[i])
			render.StartBeam(3)
			render.AddBeam(thrust_base,3,scroll, Color(255,255,255))
			render.AddBeam(thrust_base+offset_mid,2,scroll+2, Color(255,255,255))
			render.AddBeam(thrust_base+offset_end,0,scroll+3, Color(255,255,255))
			render.EndBeam()
		end
	end

	--render.DrawScreenQuad()
end

function ENT:Think()
	if SERVER then
		self:PhysWake()

		self:SetThrottle(math.Clamp(self:GetThrottle() + self.ctrl_t*FrameTime()*10,-1,1))

		--debugoverlay.Sphere(self:GetPos(),100,1,Color(0,0,255),true)
		if self.ctrl_h!=0 or self.ctrl_v!=0 then
			self.speaker_strafe:Play()
		else
			self.speaker_strafe:Stop()
		end

		if self:GetThrottle()!=0 then
			self.speaker_engine:Play(50+math.abs(self:GetThrottle())*80)
		else
			self.speaker_engine:Stop()
		end

		if !IsValid(self.trail) and self:GetThrottle()>0 then
			self.trail = ents.Create("micro_trail")
			self.trail:SetParent(self)
			self.trail:SetLocalPos(Vector(-16,0,0))
			self.trail:Spawn()
			self.trail:Setup(self:GetColor())
		end

		if IsValid(self.trail) and self:GetThrottle()<=0 then
			self.trail:Stop()
			self.trail = nil
		end
		local tr = util.TraceLine{start=self:GetPos(),endpos=self:GetPos()+Vector(0,0,-30),filter=self}
		self:SetIsHome(tr.Entity==self.home)
	end
end

function ENT:PhysicsSimulate(phys, dt)
	--print("n")

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

function ENT:OnTakeDamage(dmg)
	local attacker = dmg:GetAttacker()

	if IsValid(attacker) and attacker:GetClass()=="micro_ship" then
		local pos = self:WorldToLocal(dmg:GetDamagePosition())
		sound.Play(table.Random(sounds_impact),self:GetInternalOrigin()+pos/MICRO_SCALE)--,75,100,1)
	end
end

function ENT:PhysicsCollide(data, phys)
	if ( data.Speed > 30 ) then
		local pos = self:WorldToLocal(data.HitPos)
		sound.Play(sound_crash,self:GetInternalOrigin()+pos/MICRO_SCALE,100,100,1)
	end
end

function ENT:UnHook()
	if self:GetIsHooked() then
		self:SetIsHooked(false)
		for _,v in pairs(self.hook_ents) do
			if IsValid(v) then
				v:Remove()
			end
		end
		self.hook_ents = {}
		sound.Play(sound_unhook,self:GetInternalOrigin(),100,100,1)
	end
end