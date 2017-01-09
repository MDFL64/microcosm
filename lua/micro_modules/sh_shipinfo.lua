MICRO_SHIP_INFO = MICRO_SHIP_INFO or {}

local ENTITY = FindMetaTable("Entity")

function ENTITY:GetShipInfo()
	local pos = self:GetPos()
	for i,info in pairs(MICRO_SHIP_INFO) do
		if pos.z>info.maxs.z or pos.z<info.mins.z then continue end
		if pos.x>info.maxs.x or pos.x<info.mins.x then continue end
		if pos.y>info.maxs.y or pos.y<info.mins.y then continue end

		return info
	end
end

if SERVER then
	--MICRO_SHIP_ENTS = MICRO_SHIP_ENTS or {}

	local cfg_shipdesign = CreateConVar("micro_cfg_shipdesigns","std",FCVAR_REPLICATED,"Sets ship design. Must be set on entity init. Cannot be changed during game. See init.lua for values.")

	local function spawnInterior(ship_ent,micro_ship_origin,ship_design)

		ship_ent.info.player_spawn_point = micro_ship_origin+Vector(0,0,-30)

		local helm = ents.Create("micro_helm")
		if ship_design=="ufo" then
			helm:SetPos(micro_ship_origin+Vector(170,0,-57))
		else
			helm:SetPos(micro_ship_origin+Vector(480,0,10))
		end
		helm:SetAngles(Angle(0,180,0))
		helm:Spawn()
		helm.ship = ship_ent

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
		--ship_ent:SetMainHull(hull)

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


		--PrintTable(hull:GetMaterials())
		
	end

	hook.easy("InitPostEntity",function()
		--print("hi!")

		for i,base_ent in pairs(ents.FindByName("micro_ship_*")) do
			local new_ship_info = {}
			local base = base_ent:GetPos()

			local function doTrace(dir)
				local tr = util.TraceLine{start=base, endpos = base+dir*10000}
				return tr.HitPos
			end

			new_ship_info.maxs = Vector(
				doTrace(Vector(1,0,0)).x,
				doTrace(Vector(0,1,0)).y,
				doTrace(Vector(0,0,1)).z
			)
			new_ship_info.mins = Vector(
				doTrace(Vector(-1,0,0)).x,
				doTrace(Vector(0,-1,0)).y,
				doTrace(Vector(0,0,-1)).z
			)
			new_ship_info.origin = (new_ship_info.mins+new_ship_info.maxs)/2

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
			ship_ent:SetShipID(i)
			ship_ent:SetColor(MICRO_TEAM_COLORS[i])
			ship_ent:Spawn()
			ship_ent.home = home
			ship_ent.info = new_ship_info

			new_ship_info.entity = ship_ent

			--table.insert(MICRO_SHIP_ENTS,ship_ent)
			table.insert(MICRO_SHIP_INFO,new_ship_info)
		end

		-- Spawn interiors only after all info is actually ready
		for i,info in pairs(MICRO_SHIP_INFO) do
			local ship_design = cfg_shipdesign:GetString()
			if ship_design=="mix" then
				ship_design = i==2 and "ufo" or "std"
			end

			spawnInterior(info.entity,info.origin,ship_design)
		end
	end)

	util.AddNetworkString("micro_shipinfo")

	hook.easy("PlayerInitialSpawn",function(ply)
		net.Start("micro_shipinfo")
		net.WriteUInt(#MICRO_SHIP_INFO,8)
		for i,info in pairs(MICRO_SHIP_INFO) do
			--net.WriteEntity(info.entity)
			net.WriteVector(info.mins)
			net.WriteVector(info.maxs)
		end
		net.Send(ply)
	end)
else
	net.Receive("micro_shipinfo",function()
		local count = net.ReadUInt(8)

		--local ent_id = net.ReadUInt(8)

		for i=1,count do
			MICRO_SHIP_INFO[i]={}
			MICRO_SHIP_INFO[i].mins = net.ReadVector()
			MICRO_SHIP_INFO[i].maxs = net.ReadVector()
			MICRO_SHIP_INFO[i].origin = (MICRO_SHIP_INFO[i].mins+MICRO_SHIP_INFO[i].maxs)/2
		end
	end)
end



--[[hook.easy("Initialize",function()
	for i=1,100 do
		print("rerr")
	end
end)]]