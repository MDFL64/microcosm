AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include("shared.lua")
include("sv_artifact_control.lua")

resource.AddWorkshop("822566180")
resource.AddWorkshop("822569462")

--[[
local sun = list[1];

local sun_size = 20

local list = ents.FindByClass("env_sun")
if ( #list > 0 ) then
	sun = list[1]
end

sun:SetKeyValue("size", 0 )
sun:SetKeyValue("overlaysize", math.sqrt(sun_size)*0 )
]]

MICRO_SHIP_ENTS = MICRO_SHIP_ENTS or {}

local downscale = false

function GM:PlayerSpawn( ply )
	ply:StripWeapons()
	if IsValid(ply.micro_ship) then
		if !ply.shown_help_notify then
			ply.shown_help_notify=true
			ply:SendLua("MICRO_NOTIFY_REALHELP()")
		end

		ply:SetModel("models/player/barney.mdl")
		ply:Give("weapon_physcannon")
		ply:Give("micro_fixer")
		--ply:Give("weapon_frag")

		--ply:Give("gmod_camera")
		--ply:SetNoCollideWithTeammates(true)
	
		local ship = ply.micro_ship

		--ply:SetShip(ship)
		ply:SetPos(ship:GetInternalOrigin()+Vector(0,0,-30))
		ply:SetEyeAngles(Angle(0,0,0))
		local color = ship:GetColor()
		ply:SetPlayerColor( Vector(color.r/255,color.g/255,color.b/255) )

		if downscale then
			local scale = 1/64
			ply:SetModelScale(scale,.1)
			ply:SetViewOffset( Vector(0,0,64)*scale )
			ply:SetViewOffsetDucked( Vector(0,0,28)*scale )
			ply:SetHull( Vector(-16,-16,0)*scale, Vector(16,16,72)*scale )
			ply:SetHullDuck( Vector(-16,-16,0)*scale, Vector(16,16,36)*scale )

			ply:SetWalkSpeed(200*scale)
			ply:SetRunSpeed(400*scale)
			ply:SetCrouchedWalkSpeed(.2)
			ply:SetStepSize(18*scale)

			ply:SetJumpPower(0)
			ply:SetGravity(.05)
		
			ply:SetWalkSpeed(10)
			ply:SetRunSpeed(10)
			ply:SetCrouchedWalkSpeed(0)

			ply:SetStepSize(1)

			ply:SendLua[[
			local ply=LocalPlayer()
			local scale=1/64
			ply:SetHull(Vector(-16,-16,0)*scale,Vector(16,16,72)*scale)
			ply:SetHullDuck(Vector(-16,-16,0)*scale,Vector(16,16,36)*scale)
			ply.fixgrav = true
			]]
		end
	else
		ply:SetModel("models/player/charple.mdl")
		ply:Give("weapon_crowbar")
		ply:Give("weapon_pistol")
		ply:Give("weapon_357")
		ply:Give("weapon_smg1")
		ply:Give("weapon_shotgun")

		--ply:Give("micro_art_placer")
	end
	ply:SetupHands()
	ply:SetNoCollideWithTeammates(true)
end

function GM:AllowPlayerPickup(ply, item)
	return false
end

--local SHIP_ENT
--[[
util.AddNetworkString("airsup_minify")
local function minify(ent)

	local convexes = ent:GetPhysicsObject():GetMeshConvexes()
	for _,convex in pairs(convexes) do
		for k,vert in pairs(convex) do
			convex[k] = vert.pos/64
			print(vert.pos,convex[k])
		end
	end

	ent:PhysicsInitMultiConvex(convexes)
	ent:EnableCustomCollisions( true )

	timer.Simple(.1, function()
		if IsValid(ent) then
			net.Start("airsup_minify")
			net.WriteEntity(ent)
			net.Broadcast()
		end
	end)

end]]

local cfg_shipdesign = CreateConVar("micro_cfg_shipdesigns","std",0,"Sets ship design. Must be set on entity init. Cannot be changed during game. See init.lua for values.")

function GM:InitPostEntity()
	for i,origin_ent in pairs(ents.FindByName("micro_ship_*")) do

		local micro_ship_origin = origin_ent:GetPos()
		
		-- Spawn
		-- models/Mechanics/gears2/vert_24t1.mdl
		local home = ents.Create("prop_physics")
		home:SetPos(MICRO_HOME_SPOTS[i][1])
		home:SetAngles(MICRO_HOME_SPOTS[i][2])
		home:SetColor(MICRO_TEAM_COLORS[i])
		home:SetModel("models/Mechanics/gears2/vert_24t1.mdl")
		home:Spawn()
		home:GetPhysicsObject():EnableMotion(false)

		-- Ship Ent
		local ship_ent = ents.Create("micro_ship")
		ship_ent:SetPos(home:GetPos()+Vector(0,0,25))
		ship_ent:SetAngles(home:GetAngles())
		ship_ent:SetInternalOrigin(micro_ship_origin)
		ship_ent:SetColor(MICRO_TEAM_COLORS[i])
		ship_ent:Spawn()
		ship_ent.home = home
		ship_ent.team_id = i
		
		local ship_design = cfg_shipdesign:GetString()
		if ship_design=="mix" then
			ship_design = i==2 and "ufo" or "std"
		end

		local console = ents.Create("micro_console")
		if ship_design=="ufo" then
			console:SetPos(micro_ship_origin+Vector(170,0,-57))
		else
			console:SetPos(micro_ship_origin+Vector(480,0,10))
		end
		console:SetAngles(Angle(0,180,0))
		console:Spawn()
		console.ship = ship_ent

		-- Hull
		local hull = ents.Create("micro_hull")
		--SkyLight added some stuff around here, might want to review it and tell him how to make it better
		if ship_design=="ufo" then --make the UFO model be for the green team! Since there's a hole in the center of the model, you have to spawn a little further forward from it's center to not fall through.
			hull:SetModel("models/smallbridge/station parts/sbbridgevisort.mdl")
		else --otherwise, just do what you would have normally! :D
			hull:SetModel("models/smallbridge/ships/hysteria_galapagos.mdl")
		end
		-- Always spawn the hull at the same spot.
		-- Spawn the player differently if we need to.
		hull:SetPos(micro_ship_origin)
		hull:SetShip(ship_ent)
		hull:Spawn()
		ship_ent:SetMainHull(hull)

		if ship_design=="ufo" then --again, select for green team's UFO!  Little green men!
			local cannon = ents.Create("micro_cannon")
			cannon:SetPos(micro_ship_origin+Vector(0,0,-80)) --bottom and centered
			cannon:Spawn()
			cannon:SetGunName("Abductor")
			cannon:SetMicroHealth(100) --200 goes off the display :V, 100 is the default
			cannon:SetAngles(Angle(0,-90,-90))
			cannon.ship = ship_ent
			ship_ent.cannon_1 = cannon
		else
			local cannon = ents.Create("micro_cannon")
			cannon:SetPos(micro_ship_origin+Vector(0,316,0))
			cannon:Spawn()
			cannon:SetGunName("Port")
			cannon.ship = ship_ent
			ship_ent.cannon_1 = cannon

			local cannon = ents.Create("micro_cannon")
			cannon:SetPos(micro_ship_origin+Vector(0,-316,0))
			cannon:SetAngles(Angle(0,180,0))
			cannon:Spawn()
			cannon:SetGunName("Starboard")
			cannon.ship = ship_ent
			ship_ent.cannon_2 = cannon
		end
			
		local comms_panel = ents.Create("micro_comms")
		if ship_design=="ufo" then
			comms_panel:SetPos(micro_ship_origin+Vector(0,180,0))
			comms_panel:SetAngles(Angle(90,-90,0))
		else
			comms_panel:SetPos(micro_ship_origin+Vector(0,110,122))
			comms_panel:SetAngles(Angle(90,-160,0))
		end
		comms_panel:Spawn()
		comms_panel.ship = ship_ent
		ship_ent.comms_ent = comms_panel
		ship_ent.comms_ent.team = i

		local health_panel = ents.Create("micro_health")
		if ship_design=="ufo" then
			health_panel:SetPos(micro_ship_origin+Vector(0,-180,0))
			health_panel:SetAngles(Angle(90,90,0))
		else
			health_panel:SetPos(micro_ship_origin+Vector(-200,180,122))
			health_panel:SetAngles(Angle(90,-90,0))
		end
		health_panel:Spawn()
		health_panel.ship = ship_ent
		ship_ent.health_ent = health_panel

		local shop = ents.Create("micro_shop")
		if ship_design=="ufo" then
			shop:SetPos(micro_ship_origin+Vector(-128,0,0))
		else
			shop:SetPos(micro_ship_origin+Vector(-422,0,8))
		end
		shop:Spawn()
		shop.ship = ship_ent
		ship_ent.shop_ent = shop

		local nav = ents.Create("micro_nav")
		if ship_design=="ufo" then
			nav:SetPos(micro_ship_origin+Vector(-198,0,-35))
			nav:SetAngles(Angle(-70,180,0))
		else
			nav:SetPos(micro_ship_origin+Vector(110,-50,110))
			nav:SetAngles(Angle(-70,0,0))
		end
		nav:Spawn()
		nav.ship = ship_ent

		local spk = ents.Create("micro_speaker")
		spk:SetPos(micro_ship_origin+Vector(0,0,-100))
		spk:Spawn()
		spk:Setup("ambient/gas/cannister_loop.wav",70)
		ship_ent.speaker_strafe = spk

		local spk = ents.Create("micro_speaker")
		spk:SetPos(micro_ship_origin+Vector(-500,0,0))
		spk:Spawn()
		spk:Setup("npc/combine_gunship/dropship_engine_near_loop1.wav",80)
		ship_ent.speaker_engine = spk

		--ship_ent.sound_strafe = CreateSound(hull,"ambient/gas/steam_loop1.wav")
		--ship_ent.sound_strafe:Play()

		table.insert(MICRO_SHIP_ENTS,ship_ent)

		--PrintTable(hull:GetMaterials())
	end

	for _,v in pairs(ents.FindByClass("prop_door_rotating")) do
		--local kvs = v:GetKeyValues()
		--print(kvs["returndelay"])
		--PrintTable(kvs)
		--[[
			ltime
			PressureDelay
		]]
		v:SetKeyValue("returndelay",60*5)
		v:Fire("unlock")
	end
end


function GM:SetupPlayerVisibility(ply)
	if IsValid(ply.micro_ship) then
		AddOriginToPVS(ply.micro_ship:GetPos())
	end
end

function GM:ShowHelp(ply)
	ply:SendLua("MICRO_SHOW_HELP()")
end

function GM:ShowTeam(ply)
	ply:SendLua("MICRO_SHOW_TEAM()")
end

concommand.Add("micro_jointeam",function(ply,_,args)
	local team = tonumber(args[1])
	if isnumber(team) and team>=0 and team<=4 then
		
		
		local realteam = team
		if team==0 then
			realteam = 5
		end

		if (ply:Team()==realteam) then return end
		ply:SetTeam(realteam)

		ply:SetShip(MICRO_SHIP_ENTS[team])
		ply:KillSilent()
		--hook.Call("PlayerSpawn",GAMEMODE,ply)
		
		-- DON'T BITCH AT ME ABOUT SPAGHETTI CODE AND ABOUT
		-- HOW THIS IS TOO TIGHTLY COUPLED. I KNOW. I'LL FIX IT LATER.
		if team!=0 then
			MICRO_SHIP_ENTS[team].comms_ent:InitializeText(ply)
		end
	end
end)


function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(5)
end

function GM:PostPlayerDeath(ply)
	ply.respawn_time = CurTime()+10
end

function GM:PlayerDeathThink(ply)
	--print("rerr?",ply.respawn_time,CurTime())
	--return true
	if ply.respawn_time==nil or CurTime()>ply.respawn_time then
		ply:Spawn()
	end
end

function GM:PlayerCanHearPlayersVoice(listener, talker)
	if listener:Alive() and talker:Alive() and listener:Team() == talker:Team() then
		return true, true
	end
	return false,false
end

function GM:PlayerCanSeePlayersChat(text, teamOnly, listener, talker)
	if listener:Alive() and talker:Alive() and listener:Team() == talker:Team() then
		return true
	end
	return false
end

function GM:PlayerSay( talker, text, teamOnly )
	if text=="/team" or text=="!team" then
		talker:SendLua("MICRO_SHOW_TEAM()")
		return ""
	elseif text=="/help" or text=="!help" then
		talker:SendLua("MICRO_SHOW_HELP()")
		return ""
	end
	return text
end