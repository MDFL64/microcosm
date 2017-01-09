-- this is genji's teleporter.  it's the WIP, not yet implemented, remix.
-- thumbs up if u hate adolf fucking hitler
--[[ if i'm going to program genji's telepotty it's gonna have memeshit plastered all over the code!!
            _
           /(|
          (  :
         __\  \  _____
       (____)  `|  
      (____)|   |  6
       (____).__|  9
        (___)__.|_____
--]]

-- note: making genji's teleporter is great way to make parakeet upsetti spaghettis!! :) Not as effective as genji's reflect tho! winkie face

AddCSLuaFile()

ENT.Type = "anim"

local sound_teleport = Sound("ambient/levels/citadel/weapon_disintegrate2.wav")

function ENT:TeleportIsInRange()
	local result = false
	--if false
	--
	--	result = true
	--end
	return result --true or false
end


ENT.MaxMicroHealth = 100
function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "MicroHealth")
end

function ENT:GetMicroHealthDisplayName()
	return "Teleporter"
end

function ENT:Initialize()
	self:SetModel("models/props_wasteland/interior_fence002e.mdl")

	self:PhysicsInitStandard()

	if SERVER then
		self:GetPhysicsObject():EnableMotion(false)
	end

	if SERVER then
		self:SetMicroHealth(self.MaxMicroHealth)
	end
end

--[[function ENT:CheckBlocked() ---------------night want to use for check blocking of teleporter on either end, byut WHO CARES?!!! (lol)
	local r = 18
	local tr = util.TraceHull{start=self:GetItemSpawn(),endpos=self:GetItemSpawn(),mins=Vector(-1,-1,-1)*r, maxs=Vector(1,1,1)*r, filter=self}
	return tr.Hit
end--]]

function ENT:GetScreenText()
	local ship = Entity(MICRO_SHIP_ID or -1)
	local hurt = IsComponentHurt(self)

	if hurt then
		return "GENJI'S TELEPORTER",Color(255,0,255)
	--elseif self:CheckBlocked() then
	--	return "BLOCKED",Color(255,0,0)
	elseif self:TeleportIsInRange() then ---getti is in range!!
		return "READY",Color(0,255,0)
	else
		return "NOT DOCKED",Color(255,0,0)
	end
end

function ENT:Draw() -- i thinking this is how make little screen.  maybe make TELEPORTER animation?!
	self:DrawModel()

	--local r = 18
	--render.DrawWireframeBox(self:GetItemSpawn(), Angle(0,0,0), Vector(-1,-1,-1)*r, Vector(1,1,1)*r, Color(255,0,0), true)

	cam.Start3D2D(self:LocalToWorld(Vector(25,-22,46)),self:GetAngles()+Angle(0,90,90), .25 )
		local ship = Entity(MICRO_SHIP_ID or -1)
		if IsValid(ship) then
			local color = ship:GetColor()
			local hurt = IsComponentHurt(self)

			surface.SetDrawColor(Color( 0, 0, 0))
			surface.DrawRect( 0, 0, 176, 176 )

			surface.SetDrawColor(color)
			surface.DrawOutlinedRect(0,0,176,176)
			surface.DrawOutlinedRect(1,40,174,135)

			draw.SimpleText("TELEPORTER","DermaLarge",88,20,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			
			local text,text_color = self:GetScreenText()
			draw.SimpleText(text,"DermaLarge",88,130,text_color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

			if hurt then
				DoHurtScreenEffect(color,176,176)
			end
		end
	cam.End3D2D()
end

function ENT:Use(ply)
  local hurt = IsComponentHurt(self)
  if not hurt then
    --local origin_ent = pairs(ents.FindByName("micro_ship_*"))
    --local micro_ship_origin = origin_ent:GetPos()
    --local micro_ship_angles = origin_ent:GetAngles()
    --local ship = Entity(MICRO_SHIP_ID or -1)
    for i,origin_ent in pairs(ents.FindByName("micro_ship_*")) d
      local micro_ship_origin = origin_ent:GetPos()
      --print(ship)
      print(micro_ship_origin)
      --print(micro_ship_angles)
      ---------------ply:SetPos(micro_ship_origin)
      --ply:SetAngles(micro_ship_angles)
    end
  end
end


--[[ copy-pasted code storage~
ply:SetPos(micro_ship_origin+Vector(0,0,1024))

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

local function write_ent(ent)
					local pos = ent:GetPos()
					pos.x = pos.x
					pos.y = pos.y

					net.WriteEntity(ent)
					local color = ent:GetColor()
					net.WriteColor(Color(color.r,color.g,color.b,color.a))
					net.WriteVector(pos)
				end

				for _,ship in pairs(MICRO_SHIP_ENTS) do
					if ship==self.ship then continue end
					write_ent(ship)
				end

--]]