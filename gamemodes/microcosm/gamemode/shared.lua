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
	-- meh
	--cfg_dev = GetConVar("micro_cfg_dev")
end

function GM:PlayerNoClip()
	if SERVER then
		return GetConVar("micro_cfg_dev"):GetBool()
	else
		return false
	end
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