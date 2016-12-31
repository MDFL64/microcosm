GM.Name = ""
GM.Author = ""
GM.Email = ""
GM.Website = ""

DeriveGamemode( "base" )

team.SetUp(1,"Nerds",Color(0,255,255),false)

MICRO_SCALE = 1/32

MICRO_TEAM_NAMES = {"Red","Green","Blue","Yellow",[0]="None"}

MICRO_TEAM_COLORS = {
	Color(255,0,0),
	Color(0,255,0),
	Color(0,0,255),
	Color(255,255,0),
	[0]=Color(255,255,255)
}

--util.PrecacheSound("ambient/fire/fire_small1.wav")

-- no noclip
function GM:PlayerNoClip()
	return true
	--return false
end

local ENTITY = FindMetaTable("Entity")

function ENTITY:PhysicsInitStandard()
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)

		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
		end
	end
end

local PLAYER = FindMetaTable("Player")
if SERVER then
	util.AddNetworkString("micro_setship")

	function PLAYER:SetShip(ship)
		if ship then
			if !IsValid(ship) then error("Ship does not exist!") end
			if ship:GetClass() != "micro_ship" then error("Ship is not a ship!") end
		end

		self.micro_ship = ship

		net.Start("micro_setship")
		net.WriteEntity(ship)
		net.Send(self)
	end
else
	net.Receive("micro_setship",function()
		local id = net.ReadUInt(16)
		if id == 0 then id=nil end
		MICRO_SHIP_ID = id
	end)
end

if SERVER then
	util.AddNetworkString("micro_enablecontrol")
	util.AddNetworkString("micro_controls")

	function PLAYER:ProxyControls(ent)
		self.controlled_ent = ent
		self.control_ready_exit = false
		net.Start("micro_enablecontrol")
		net.WriteEntity(ent or NULL)
		net.Send(self)
	end

	net.Receive("micro_controls",function(_,ply)


		local buttons = net.ReadUInt(32)

		local bad_controlled_ent = !IsValid(ply.controlled_ent) or !isfunction(ply.controlled_ent.sendControls)

		-- really shitty solution, make user release USE before they can press it to exit.
		if bit.band(buttons,IN_USE)==0 and not ply.control_ready_exit then
			ply.control_ready_exit=true
		end

		
		if
			!ply:Alive() or
			bad_controlled_ent or
			ply:GetPos():DistToSqr(ply.controlled_ent:GetPos())>150^2 or
			(bit.band(buttons,IN_USE)!=0 and ply.control_ready_exit)
		then
			net.Start("micro_enablecontrol")
			net.WriteEntity(nil)
			net.Send(ply)

			if !bad_controlled_ent then
				ply.controlled_ent:stopControl()
				ply.controlled_ent = nil
			end
		else
			if ply.controlled_ent.ControlEyeLock then
				local x = net.ReadInt(16)
				local y = net.ReadInt(16)
				ply.controlled_ent:sendControls(buttons,x,y)
			else
				local angs = ply:EyeAngles()
				ply.controlled_ent:sendControls(buttons,angs)
			end
		end
	end)
else
	MICRO_CONTROLLING = MICRO_CONTROLLING
	MICRO_LAST_EYE = MICRO_LAST_EYE or Angle(0,0,0)

	net.Receive("micro_enablecontrol",function()
		MICRO_CONTROLLING = net.ReadEntity()
		if MICRO_CONTROLLING:IsWorld() then MICRO_CONTROLLING = nil end
	end)

	function GM:CreateMove(cmd)
		if IsValid(MICRO_CONTROLLING) then
			if MICRO_CONTROLLING.ControlEyeLock then
				local angs_unlocked = cmd:KeyDown(IN_WALK)
				
				net.Start("micro_controls")
				net.WriteUInt(cmd:GetButtons(),32)
				net.WriteInt(angs_unlocked and 0 or cmd:GetMouseX(),16)
				net.WriteInt(angs_unlocked and 0 or cmd:GetMouseY(),16)
				net.SendToServer()
				
				cmd:ClearButtons()
				cmd:ClearMovement()

				if angs_unlocked then
					MICRO_LAST_EYE = cmd:GetViewAngles()
				else
					cmd:SetViewAngles(MICRO_LAST_EYE)
				end
			else
				net.Start("micro_controls")
				net.WriteUInt(cmd:GetButtons(),32)
				net.SendToServer()

				cmd:ClearButtons()
				cmd:ClearMovement()
			end
		else
			MICRO_LAST_EYE = cmd:GetViewAngles()
		end
	end
end

if SERVER then
	util.AddNetworkString("micro_tracer")
	function SendTracer(type,start,stop)
		net.Start("micro_tracer")
		net.WriteUInt(type,8)
		net.WriteVector(start)
		net.WriteVector(stop)
		net.Broadcast()
	end
else
	local tracers = {}

	net.Receive("micro_tracer",function()
		local type = net.ReadUInt(8)
		local start = net.ReadVector()
		local stop = net.ReadVector()

		tracers[{type,start,stop}]=0
	end)

	local matShot = Material("trails/laser")

	function GM:PostDrawOpaqueRenderables(depth,sky)
		if (MICRO_DRAW_EXTERNAL or not IsValid(Entity(MICRO_SHIP_ID or -1))) and not sky then
			render.SetMaterial(matShot)
			for k,v in pairs(tracers) do

				local type,start,stop = k[1],k[2],k[3]

				local d = start:Distance(stop)

				local start2 = LerpVector(math.max(v-100/d,0),start,stop)
				local stop2 = LerpVector(v,start,stop)

				--render.DrawBeam(start2,stop2,.1,0,1,Color(255,0,0)) 
				local color
				if type==1 then
					color = Color(255,100,0)
				elseif type==2 then
					color = Color(0,255,255)
				end

				render.StartBeam(2)
				render.AddBeam(start2,4,0, color)
				render.AddBeam(stop2,4,1, color)
				render.EndBeam()

				if v>1 then
					tracers[k]=nil
				else
					tracers[k]=v + 2000*FrameTime()/d
				end
				--print(k,v)
			end
		end
	end


	--[[
		render.SetMaterial(matShot)
		for k,v in pairs(self.tracers) do
			
			local start,stop = k[1],k[2]

			local d = start:Distance(stop)

			local start2 = LerpVector(math.max(v-100/d,0),start,stop)
			local stop2 = LerpVector(v,start,stop)

			--render.DrawBeam(start2,stop2,.1,0,1,Color(255,0,0)) 
			render.StartBeam(2)
			render.AddBeam(start2,4,0, Color(255,100,0))
			render.AddBeam(stop2,4,1, Color(255,100,0))
			render.EndBeam()

			if v>1 then
				self.tracers[k]=nil
			else
				self.tracers[k]=v + 2000*FrameTime()/d
			end
			--print(k,v)
		end
	]]
end