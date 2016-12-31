AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include( "shared.lua" )

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

SHIP_ENTS = SHIP_ENTS or {}

local downscale = false

function GM:PlayerSpawn( ply )
    ply:StripWeapons()
    if IsValid(ply.micro_ship) then
        ply:SetModel("models/player/barney.mdl")
        ply:Give("weapon_physcannon")

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
        --ply:SetNoCollideWithTeammates(false)
        --ply:SetShip(nil)
    end
    ply:SetupHands()
    ply:SetNoCollideWithTeammates(true)    
    ply:SetTeam(1)
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

local spawns = {
    {Vector(-2805.373047,-2629.304932,176.031250),Angle(0,90,0)}, -- top of spawn
    {Vector(-1225.940552,1025.711182,232.031250),Angle(0,-90,0)}, -- above subway
    {Vector(1089.395142,1840.912476,-203.968750),Angle(0,-90,0)}, -- warehouse
    {Vector(1888.408936,-1887.610718,-495.968750),Angle(0,180,0)} -- back of train tunnel
}

function GM:InitPostEntity()
    for i,origin_ent in pairs(ents.FindByName("micro_ship_*")) do

        local micro_ship_origin = origin_ent:GetPos()
        
        -- Spawn
        -- models/Mechanics/gears2/vert_24t1.mdl
        local home = ents.Create("prop_physics")
        home:SetPos(spawns[i][1])
        home:SetAngles(spawns[i][2])
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

        local console = ents.Create("micro_console")
        console:SetPos(micro_ship_origin+Vector(480,0,10))
        console:SetAngles(Angle(0,180,0))
        console:Spawn()
        console.ship = ship_ent
        console:GetPhysicsObject():EnableMotion(false)

        -- Hull
        local hull = ents.Create("micro_hull")
        hull:SetPos(micro_ship_origin)
        hull:SetShip(ship_ent)
        hull:Spawn()

        local cannon = ents.Create("micro_cannon")
        cannon:SetPos(micro_ship_origin+Vector(0,316,0))
        cannon:SetSkin(1)
        cannon:Spawn()
        cannon:SetGunName("PORT")
        cannon.ship = ship_ent

        local cannon = ents.Create("micro_cannon")
        cannon:SetPos(micro_ship_origin+Vector(0,-316,0))
        cannon:SetAngles(Angle(0,180,0))
        cannon:SetSkin(1)
        cannon:Spawn()
        cannon:SetGunName("STARBOARD")
        cannon.ship = ship_ent

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

        table.insert(SHIP_ENTS,ship_ent)

        --PrintTable(hull:GetMaterials())
    end

    for _,v in pairs(ents.FindByClass("prop_door_rotating")) do
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
        ply:SetShip(SHIP_ENTS[team])
        ply:Spawn()
    end
end)