AddCSLuaFile()

ENT.Type = "anim"

ENT.MaxMicroHealth = 100
function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "MicroHealth")
	--self:NetworkVar("Float", 1, "PingTime")
end

--local sound_ping = Sound("HL1/fvox/bell.wav")

function ENT:GetMicroHealthDisplayName()
	return "Navigation Computer"
end

local PING_INTERVAL = 5

function ENT:Initialize()
	self:SetModel("models/props_phx/construct/metal_plate1.mdl")

	self:PhysicsInitStandard()

	if SERVER then
		self:GetPhysicsObject():EnableMotion(false)
		--self:SetUseType(SIMPLE_USE)

		self:SetMicroHealth(self.MaxMicroHealth)

		self.next_refresh = 0
	end
end


if SERVER then
	util.AddNetworkString("micro_navdata")
	function ENT:Think()
		if CurTime()>self.next_refresh then
			net.Start("micro_navdata")
			if IsComponentHurt(self) then
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
					local rad = self.ship:GetPos():Distance(ent:GetPos())*(.8+math.random()*.4)
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
					if ship==self.ship then continue end
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
	MICRO_NAV_DATA = {}

	net.Receive("micro_navdata",function(...)
		MICRO_NAV_DATA = {}
		local count = net.ReadInt(8)
		for i=1,count do
			local ent = net.ReadEntity()
			local color = net.ReadColor()
			local pos = net.ReadVector()
			local r = net.ReadFloat()
			table.insert(MICRO_NAV_DATA,{ent=ent,color=color,pos=pos,r=r})
		end
	end)
end

function ENT:Draw()
	self:DrawModel()
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Up(),-90)

	cam.Start3D2D(self:LocalToWorld(Vector(22,22,4)),ang, .125 )
		local ship = Entity(MICRO_SHIP_ID or -1)
		local team = LocalPlayer():Team()
		if IsValid(ship) then
			local color = ship:GetColor()
			local hurt = IsComponentHurt(self)

			surface.SetDrawColor(Color( 0, 0, 0))
			surface.DrawRect( 0, 0, 352, 352 )

			surface.SetDrawColor(color)
			surface.DrawOutlinedRect(0,0,352,352)
			surface.DrawOutlinedRect(1,40,350,311)

			draw.SimpleText("NAVIGATOR","DermaLarge",176,20,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

			draw.SimpleText("N","DebugFixed",176,50,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			draw.SimpleText("S","DebugFixed",176,340,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			draw.SimpleText("E","DebugFixed",340,195,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			draw.SimpleText("W","DebugFixed",10,195,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			
			local function draw_obj(c,color,pos,ang)
				local x = 210+pos.y*.045
				local y = 190+pos.x*.045

				if isnumber(c) then
					surface.DrawCircle(x,y,c*.045, color.r,color.g,color.b,color.a)
				else
					draw.SimpleText(c,"DebugFixed",x,y,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
				end

				if ang then
					local yaw = math.rad(ang.y)

					local r = 10
					surface.SetDrawColor(color)
					surface.DrawLine(x,y,x+math.sin(yaw)*r,y+math.cos(yaw)*r)
				end
			end
			--local old_w,old_h = ScrW(),ScrH()

			--render.SetViewPort(100,100,200,200)
			
			local was_clipping = render.EnableClipping(true)

			local function clip(norm,pos)
				pos = self:LocalToWorld(pos)
				render.PushCustomClipPlane( norm,pos:Dot(norm))
			end

			clip(self:GetAngles():Forward(),Vector(-21.7,0,0))
			clip(-self:GetAngles():Forward(),Vector(16.8,0,0))
			clip(self:GetAngles():Right(),Vector(0,21.7,0))
			clip(-self:GetAngles():Right(),Vector(0,-21.7,0))

			draw_obj("*",color,ship:GetPos(),ship:GetAngles())

			if team!=5 then
				draw_obj("H",color,MICRO_HOME_SPOTS[team][1])
			end

			for i,data in pairs(MICRO_NAV_DATA) do
				if IsValid(data.ent) and !hurt then
					local tr = util.TraceLine{start=ship:GetPos(),endpos=data.ent:GetPos(),filter={ship,data.ent},mask=MASK_BLOCKLOS_AND_NPCS}
					if !tr.Hit then
						draw_obj("*",data.color,data.ent:GetPos(),data.ent:GetClass()=="micro_ship" and data.ent:GetAngles())
						continue
					end
				end
				
				draw_obj(data.r,data.color,data.pos)
			end

			for i=1,4 do
				render.PopCustomClipPlane()
			end
			render.EnableClipping(was_clipping)

			--render.SetViewPort(0,0,old_w,old_h)

			if hurt then
				DoHurtScreenEffect(color,352,352)
			end
		end
	cam.End3D2D()
end

--[[function MICRO_SHOW_NAV(ent)
		local panel = vgui.Create("DFrame")
		panel:SetDraggable(false)
		panel:SetSizable(false)
		panel:SetTitle("Navigator")
		panel:SetSize(ScrW()-200,ScrH()-200)
		panel:Center()
		panel:MakePopup()

		panel.Think = function(self)
			if !LocalPlayer():Alive() or IsComponentHurt(ent) then self:Close() end
		end
		
		panel.PaintOver = function(self)
			local old_w,old_h = ScrW(),ScrH()
			
			render.SetViewPort(0,0,100,100)

			--cam.Start3D()

			MICRO_DRAW_NAV = true
			render.SuppressEngineLighting(false)
			render.RenderView( {
				origin = Vector( 1100, 0, 100 ), -- change to your liking
				angles = Angle( 0, CurTime()*10, 0 ), -- change to your liking
				x = 110,
				y = 140,
				w = self:GetWide()-20,
				h = self:GetTall()-50
			} )
			render.SuppressEngineLighting(true)
			MICRO_DRAW_NAV = false

			local color = team.GetColor(LocalPlayer():Team())

			surface.SetDrawColor(Color( 0, 0, 0))
			surface.DrawRect(285, 30, 330, 40)

			surface.SetDrawColor(color)
			surface.DrawOutlinedRect(285, 30, 330, 40)]

			render.SetViewPort(0,0,old_w,old_h)
		end
	end]]