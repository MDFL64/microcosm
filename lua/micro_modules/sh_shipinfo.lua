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

--[[function ENTITY:CheckBroken(health,)
	return health < self:GetMaxHealth()*.3
end]]

function ENTITY:IsBroken()
	local frac = .3

	if self:GetClass()=="micro_ship" then
		frac=.1
	end

	return self:Health() < self:GetMaxHealth()*frac
end

function ENTITY:AddToExternalShip()
	local info = self:GetShipInfo()
	info.external_parts[self] = true

	if IsValid(info.entity) then info.entity:ExternalPartAdded(self) end
end

if SERVER then

	local cfg_shipdesign = CreateConVar("micro_cfg_shipdesigns","std",FCVAR_REPLICATED,"Sets ship design. Must be set on entity init. Cannot be changed during game. See sh_shipinfo.lua for values.")

	local function spawnInterior(ship_ent,micro_ship_origin,ship_design)

		ship_ent.info.player_spawn_point = micro_ship_origin+Vector(0,0,-30)

		--[[local thing = ents.Create("micro_component")
		thing:SetPos(micro_ship_origin+Vector(170,0,50))
		thing:SetAngles(Angle(-80,0,0))
		thing:Spawn()]]

		local helm = ents.Create("micro_comp_helm")
		if ship_design=="ufo" then
			helm:SetPos(micro_ship_origin+Vector(170,0,-57))
		else
			helm:SetPos(micro_ship_origin+Vector(480,0,10))
		end
		helm:SetAngles(Angle(0,180,0))
		helm:Spawn()

		-- Hull
		local hull = ents.Create("micro_hull")
		if ship_design=="ufo" then
			hull:SetModel("models/smallbridge/station parts/sbbridgevisort.mdl")
		else
			hull:SetModel("models/smallbridge/ships/hysteria_galapagos.mdl")
		end
		hull:SetPos(micro_ship_origin)
		hull:Spawn()

		if ship_design=="ufo" then
			local door = ents.Create("micro_subhull")
			door:SetModel("models/props_phx/construct/windows/window4x4.mdl")
			door:SetPos(micro_ship_origin+Vector(48,-48,-65))
			door:SetAngles(Angle(0,0,0))
			door:Spawn()

			local cannon = ents.Create("micro_comp_cannon")
			cannon:SetPos(micro_ship_origin+Vector(0,0,-60))
			cannon:SetGunName("Abductor")
			cannon:Spawn()
		else
			local door = ents.Create("micro_subhull")
			door:SetModel("models/smallbridge/ship parts/sbhulldsp.mdl")
			door:SetPos(micro_ship_origin+Vector(0,316,0))
			door:SetSkin(1)
			door:Spawn()

			local door = ents.Create("micro_subhull")
			door:SetModel("models/smallbridge/ship parts/sbhulldsp.mdl")			
			door:SetPos(micro_ship_origin+Vector(0,-316,0))
			door:SetAngles(Angle(0,180,0))
			door:SetSkin(1)
			door:Spawn()

			local cannon = ents.Create("micro_comp_cannon")
			cannon:SetPos(micro_ship_origin+Vector(0,310,0))
			cannon:SetAngles(Angle(-90,90,0))
			cannon:SetGunName("Port")
			cannon:Spawn()

			local cannon = ents.Create("micro_comp_cannon")
			cannon:SetPos(micro_ship_origin+Vector(0,-310,0))
			cannon:SetAngles(Angle(-90,-90,0))
			cannon:SetGunName("Starboard")
			cannon:Spawn()
		end
			
		local comms_panel = ents.Create("micro_comp_comms")
		if ship_design=="ufo" then
			comms_panel:SetPos(micro_ship_origin+Vector(0,180,0))
			comms_panel:SetAngles(Angle(-90,90,0))
		else
			comms_panel:SetPos(micro_ship_origin+Vector(0,110,122))
			comms_panel:SetAngles(Angle(-90,30,0))
		end
		comms_panel:Spawn()

		local health_panel = ents.Create("micro_comp_health")
		if ship_design=="ufo" then
			health_panel:SetPos(micro_ship_origin+Vector(0,-180,0))
			health_panel:SetAngles(Angle(-90,-90,0))
		else
			health_panel:SetPos(micro_ship_origin+Vector(-200,180,122))
			health_panel:SetAngles(Angle(-90,90,0))
		end
		health_panel:Spawn()

		local shop = ents.Create("micro_comp_shop")
		if ship_design=="ufo" then
			shop:SetPos(micro_ship_origin+Vector(-150,0,0))
		else
			shop:SetPos(micro_ship_origin+Vector(-422,0,8))
		end
		shop:Spawn()

		local nav = ents.Create("micro_comp_navigator")
		if ship_design=="ufo" then
			nav:SetPos(micro_ship_origin+Vector(50,-60,30))
			nav:SetAngles(Angle(-90,0,0))
		else
			nav:SetPos(micro_ship_origin+Vector(110,-50,110))
			nav:SetAngles(Angle(-70,0,0))
		end
		nav:Spawn()

		--disable this for now
		--[[local tele = ents.Create("micro_comp_teleporter")
		tele:SetPos(micro_ship_origin+Vector(-200,-225,0))
		tele:Spawn()]]

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
	end

	hook.easy("AcceptInput",function(ent, input, activator, caller, value )
		print("io",ent,input,activator,caller,value)
	end)

	hook.easy("InitPostEntity",function()
		--print("hi!")

		for _,v in pairs(ents.FindByClass("info_target")) do
			print(v,v:GetName())
		end

		for _,v in pairs(ents.FindByClass("point_clientcommand")) do
			print("cmd",v,v:GetName())
		end

		for i,base_ent in pairs(ents.FindByName("micro_ship_*")) do
			print("===>",i,base_ent)
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
			new_ship_info.components = {}
			new_ship_info.external_parts = {}

			local home = ents.Create("prop_physics")
			home:SetPos(MICRO_HOME_SPOTS[i][1])
			home:SetAngles(MICRO_HOME_SPOTS[i][2])
			home:SetColor(MICRO_TEAM_COLORS[i])
			home:SetModel("models/Mechanics/gears2/vert_24t1.mdl")
			home:Spawn()
			home:GetPhysicsObject():EnableMotion(false)

			table.insert(MICRO_SHIP_INFO,new_ship_info)

			-- Ship Ent
			local ship_ent = ents.Create("micro_ship")
			ship_ent:SetPos(home:GetPos()+Vector(0,0,25))
			ship_ent:SetAngles(home:GetAngles())
			ship_ent:SetShipID(i)
			ship_ent:SetColor(MICRO_TEAM_COLORS[i])
			ship_ent:Spawn()
			ship_ent.home = home
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

	hook.easy("SetupPlayerVisibility",function(ply)
		local ship_info = ply:GetShipInfo()
		if ship_info and IsValid(ship_info.entity) then
			AddOriginToPVS(ship_info.entity:GetPos())
		end

		if ply.last_ship_info != ship_info then
			local old = ply.last_ship_info
			local new = ship_info
			hook.Call("micro_changeship",GAMEMODE, ply, old, new)
		end

		ply.last_ship_info = ship_info
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
			MICRO_SHIP_INFO[i].components = {}
			MICRO_SHIP_INFO[i].external_parts = {}
		end
	end)

	hook.easy("PreRender",function()
		local ship_info = LocalPlayer():GetShipInfo()

		if ship_info and IsValid(ship_info.entity) then

			local origin = ship_info.origin

			local real_pos = ship_info.entity:GetPos()
			local real_ang = ship_info.entity:GetAngles()

			local eye_pos = LocalPlayer():EyePos()
			local eye_angs = LocalPlayer():EyeAngles()+LocalPlayer():GetViewPunchAngles()

			local view = hook.Call("CalcView",GAMEMODE, LocalPlayer())
			if view then
				eye_pos = view.origin or eye_pos
			end

			local cam_pos, cam_ang = LocalToWorld((eye_pos-origin)*MICRO_SCALE,eye_angs,real_pos,real_ang)

			MICRO_DRAW_EXTERNAL = true
			render.SuppressEngineLighting(false)
			render.RenderView{
				w=ScrW(),
				h=ScrH(),
				x=0,
				y=0,
				origin=cam_pos,
				angles=cam_ang,
				znear=0.1
			}
			MICRO_DRAW_EXTERNAL = false

			render.SuppressEngineLighting(true)

			render.SetModelLighting(BOX_FRONT, .1,.1,.1)
			render.SetModelLighting(BOX_BACK, .1,.1,.1)
			render.SetModelLighting(BOX_RIGHT, .1,.1,.1)
			render.SetModelLighting(BOX_LEFT, .1,.1,.1)
			if ship_info.entity:IsBroken() then
				render.SetModelLighting(BOX_TOP, 1,0,0)
			else
				render.SetModelLighting(BOX_TOP, 1,1,1)
			end
			render.SetModelLighting(BOX_BOTTOM, .1,.1,.1)
		else
			render.SuppressEngineLighting(false)
		end
	end)

	-- Failsafe to stop lighting from breaking when a client leaves.
	hook.easy("ShutDown",function()
		render.SuppressEngineLighting(false)
	end)
end