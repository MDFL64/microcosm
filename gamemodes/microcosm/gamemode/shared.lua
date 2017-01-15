GM.Name = "Microcosm"
GM.Author = "Adam Coggeshall"
GM.Email = ""
GM.Website = "http://cogg.rocks"

DeriveGamemode( "base" )

-- Constants and team related stuff.
MICRO_SCALE = 1/32

MICRO_TEAM_NAMES = {"Red","Green","Blue","Yellow",[0]="None"}
 
MICRO_TEAM_COLORS = {
	Color(255,0,0),
	Color(0,255,0),
	Color(0,0,255),
	Color(255,255,0),
	[0]=Color(150,150,150)
}

MICRO_HOME_SPOTS = {
	{Vector(-2805.373047,-2629.304932,176.031250),Angle(0,90,0)}, -- top of spawn
	{Vector(-1225.940552,1025.711182,232.031250),Angle(0,-90,0)}, -- above subway
	{Vector(1089.395142,1840.912476,-203.968750),Angle(0,-90,0)}, -- warehouse
	{Vector(1888.408936,-1887.610718,-495.968750),Angle(0,180,0)} -- back of train tunnel
}

for i=1,5 do
	local n = i%5
	team.SetUp(i,MICRO_TEAM_NAMES[n],MICRO_TEAM_COLORS[n],false)
end

-- Easy hook function.
function hook.easy(event,callback)
	local source = debug.getinfo(2,"S").source
	hook.Add(event,"easyhook"..source,callback)
end

-- Module loader.
local modules = file.Find("micro_modules/*.lua","LUA")
for _,module in pairs(modules) do
	local start = module:sub(1,3)
	local path = "micro_modules/"..module
	if SERVER then
		if start=="sv_" then
			include(path)
		elseif start=="sh_" then
			include(path)
			AddCSLuaFile(path)
		elseif start=="cl_" then
			AddCSLuaFile(path)
		else
			ErrorNoHalt("Not sure what to do with Microcosm module: "..module.."\n")
		end
	else
		if start=="cl_" or start=="sh_" then
			include(path)
		else
			ErrorNoHalt("Not sure what to do with Microcosm module: "..module.."\n")
		end
	end
end

-- Dev setting.
local cfg_dev

if SERVER then
	cfg_dev = CreateConVar("micro_cfg_dev","0",FCVAR_REPLICATED,"Enables noclip, fast respawn, and other developer features.")
else
	cfg_dev = GetConVar("micro_cfg_dev")
end


<<<<<<< HEAD
MICRO_TEAM_NAMES = {"Red","Green","Blue","Yellow",[0]="None"}
 
MICRO_TEAM_COLORS = {
	Color(255,0,0),
	Color(0,255,0),
	Color(0,0,255),
	Color(255,255,0),
	[0]=Color(150,150,150)
}

MICRO_HOME_SPOTS = {
	{Vector(-2805.373047,-2629.304932,176.031250),Angle(0,90,0)}, -- top of spawn
	{Vector(-1225.940552,1025.711182,232.031250),Angle(0,-90,0)}, -- above subway
	{Vector(1089.395142,1840.912476,-203.968750),Angle(0,-90,0)}, -- warehouse
	{Vector(1888.408936,-1887.610718,-495.968750),Angle(0,180,0)} -- back of train tunnel
}

for i=1,5 do
	local n = i%5
	team.SetUp(i,MICRO_TEAM_NAMES[n],MICRO_TEAM_COLORS[n],false)
end
--PrintTable(team.GetAllTeams())

--util.PrecacheSound("ambient/fire/fire_small1.wav")

-- no noclip.  UNLESS sv_cheats = 1 :)
=======
>>>>>>> unstable
function GM:PlayerNoClip()
	return cfg_dev:GetBool()
end

if SERVER then
	function GM:PostPlayerDeath(ply)
		local spawntime = cfg_dev:GetBool() and 0 or 10
		ply.respawn_time = CurTime()+spawntime
	end

	function GM:PlayerDeathThink(ply)
		if ply.respawn_time==nil or CurTime()>ply.respawn_time then
			ply:Spawn()
		end
	end
end

-- Rerr
function GM:GravGunPunt()
	return false
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

--local PLAYER = FindMetaTable("Player")
--[[
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
end]]

-- Control system, needs to be refactored later.
--if SERVER then
	--[[util.AddNetworkString("micro_enablecontrol")
	util.AddNetworkString("micro_controls")

	function PLAYER:ProxyControls(ent)
		self.controlled_ent = ent
		self.control_last_buttons = IN_USE
		net.Start("micro_enablecontrol")
		net.WriteEntity(ent or NULL)
		net.Send(self)
	end

	net.Receive("micro_controls",function(_,ply)


		local buttons = net.ReadUInt(32)

		local bad_controlled_ent = !IsValid(ply.controlled_ent) or !isfunction(ply.controlled_ent.sendControls)

		-- really shitty solution, make user release USE before they can press it to exit.
		--[[if bit.band(buttons,IN_USE)==0 and not ply.control_ready_exit then
			ply.control_ready_exit=true
		end
		local buttons_pressed = bit.band(bit.bxor(ply.control_last_buttons,buttons),buttons)

		if
			!ply:Alive() or
			bad_controlled_ent or
			ply:GetPos():DistToSqr(ply.controlled_ent:GetPos())>150^2 or
			bit.band(buttons_pressed,IN_USE)!=0
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
				ply.controlled_ent:sendControls(buttons,buttons_pressed,x,y)
			else
				local angs = ply:EyeAngles()
				ply.controlled_ent:sendControls(buttons,buttons_pressed,angs)
			end

			ply.control_last_buttons = buttons
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
end]]

-- Tracer system. It's okay I guess, although would be nice to get effects fixed.
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

				local color
				if type==1 then
					color = Color(255,100,0)
				elseif type==2 then
					color = Color(0,255,255)
				elseif type==3 then
					color = Color(255,0,255)
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
			end
		end
	end
end