AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include("shared.lua")

resource.AddWorkshop("822566180")
resource.AddWorkshop("822569462")

local downscale = false

function GM:PlayerSpawn( ply )
	ply:StripWeapons()

	ply:SetModel("models/player/barney.mdl")

	local color = team.GetColor(ply:Team())
	ply:SetPlayerColor( Vector(color.r/255,color.g/255,color.b/255) )



	local info = MICRO_SHIP_INFO[ply:Team()]

	if info then
		ply:Give("weapon_physcannon")
		ply:Give("micro_fixer")

		ply:SetPos(info.player_spawn_point)
		ply:SetEyeAngles(Angle(0,0,0))

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
		--[[ply:SetModel("models/player/charple.mdl")
		ply:Give("weapon_crowbar")
		ply:Give("weapon_pistol")
		ply:Give("weapon_357")
		ply:Give("weapon_smg1")
		ply:Give("weapon_shotgun")]]

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

function GM:InitPostEntity()
	for _,v in pairs(ents.FindByClass("prop_door_rotating")) do
		v:SetKeyValue("returndelay",60*5)
		v:Fire("unlock")
	end
end

function GM:ShowHelp(ply)
	ply:SendLua("MICRO_SHOW_HELP()")
end

function GM:ShowTeam(ply)
	ply:SendLua("MICRO_SHOW_TEAM()")
end

function GM:ShowSpare1(ply)
	ply:SendLua("MICRO_SHOW_STEAM()")
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

		ply:KillSilent()
	end
end)

function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(5)
end

function GM:PlayerCanHearPlayersVoice(listener, talker)
	if listener:Alive() and talker:Alive() and listener:GetShipInfo() == talker:GetShipInfo() then
		return true, true
	end
	return false,false
end

function GM:PlayerCanSeePlayersChat(text, teamOnly, listener, talker)
	if listener:Alive() and talker:Alive() and listener:GetShipInfo() == talker:GetShipInfo() then
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
	elseif text=="/steam" or text=="!steam" then
		talker:SendLua("MICRO_SHOW_STEAM()")
		return ""
	end
	return text
end

hook.easy("EntityTakeDamage",function(ent,dmg)
	if ent:IsPlayer() then
		ent:EmitSound("vo/npc/male01/pain0"..math.random(9)..".wav")
	end
end)