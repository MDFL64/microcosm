AddCSLuaFile()

--DEFINE_BASECLASS("micro_component")
ENT.Base = "micro_component"

ENT.ComponentModel = "models/props_phx/construct/metal_plate1.mdl"
ENT.ComponentScreenWidth = 180
ENT.ComponentScreenHeight = 180
ENT.ComponentScreenOffset = Vector(22.5,22.5,4)

function ENT:GetComponentName()
	return "Navigator"
end

local PING_INTERVAL = 5

if SERVER then
	util.AddNetworkString("micro_navdata")
	function ENT:Think()
		local ship_info = self:GetShipInfo()

		if IsValid(ship_info.entity) and (self.next_refresh==nil or CurTime()>self.next_refresh) then
			net.Start("micro_navdata")
			net.WriteEntity(self)
			net.WriteVector(ship_info.entity.home:GetPos())
			if self:IsBroken() then
				net.WriteInt(10,8)
				for i=1,10 do
					net.WriteEntity(NULL)
					net.WriteColor(ColorRand())
					net.WriteVector(VectorRand()*5000)
					net.WriteFloat(math.random()*5000)
				end
			else
				local count=3
				for _,goal in pairs(MICRO_ARTIFACTS) do
					if IsValid(goal) then count=count+1 end
				end
				net.WriteInt(count,8)

				local function write_ent(ent)
					local rad = ship_info.entity:GetPos():Distance(ent:GetPos())*(.8+math.random()*.4)
					local pos = ent:GetPos()
					pos.x = pos.x + math.random()*rad
					pos.y = pos.y + math.random()*rad

					net.WriteEntity(ent)
					local color = ent:GetColor()
					net.WriteColor(Color(color.r,color.g,color.b,color.a))
					net.WriteVector(pos)
					net.WriteFloat(rad)
				end

				for _,info in pairs(MICRO_SHIP_INFO) do
					local ship = info.entity
					if ship==ship_info.entity then continue end
					write_ent(ship)
				end
				for _,goal in pairs(MICRO_ARTIFACTS) do
					if IsValid(goal) then
						write_ent(goal)
					end
				end
			end
			net.SendPVS(self:GetPos())

			self.next_refresh = CurTime()+5
		end
	end
else
	net.Receive("micro_navdata",function()
		local nav_ent = net.ReadEntity()
		if not IsValid(nav_ent) then return end
		
		nav_ent.home_pos = net.ReadVector()

		nav_ent.data = {}
		local count = net.ReadInt(8)
		for i=1,count do
			local ent = net.ReadEntity()
			local color = net.ReadColor()
			local pos = net.ReadVector()
			local r = net.ReadFloat()
			table.insert(nav_ent.data,{ent=ent,color=color,pos=pos,r=r})
		end
	end)
end

function ENT:drawInfo(ship,broken)
	draw.SimpleText("N","micro_shadow",90,50,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	draw.SimpleText("S","micro_shadow",90,165,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	draw.SimpleText("E","micro_shadow",165,105,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	draw.SimpleText("W","micro_shadow",15,105,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

	local function draw_obj(c,color,pos,ang)
		local x = 105+pos.y*.022
		local y = 120+pos.x*.022

		if isnumber(c) then
			surface.DrawCircle(x,y,c*.022, color.r,color.g,color.b,color.a)
		else
			draw.SimpleText(c,"micro_shadow",x,y,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		end

		if ang then
			local yaw = math.rad(ang.y)

			local r = 8
			surface.SetDrawColor(color)
			surface.DrawLine(x,y,x+math.sin(yaw)*r,y+math.cos(yaw)*r)
		end
	end

	draw_obj("*",ship:GetColor(),ship:GetPos(),ship:GetAngles())
	draw_obj("#",ship:GetColor(),self.home_pos)

	for i,data in pairs(self.data) do
		if IsValid(data.ent) and !hurt then
			local tr = util.TraceLine{start=ship:GetPos(),endpos=data.ent:GetPos(),filter={ship,data.ent},mask=MASK_BLOCKLOS_AND_NPCS}
			if !tr.Hit then
				draw_obj("*",data.color,data.ent:GetPos(),data.ent:GetClass()=="micro_ship" and data.ent:GetAngles())
				continue
			end
		end
		
		draw_obj(data.r,data.color,data.pos)
	end
end