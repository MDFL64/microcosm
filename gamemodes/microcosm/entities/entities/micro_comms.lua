AddCSLuaFile()

ENT.Type = "anim"

local sound_message = Sound("HL1/fvox/beep.wav")
local sound_send = Sound("weapons/pistol/pistol_empty.wav")
local sound_important = Sound("ambient/alarms/klaxon1.wav")

ENT.MaxMicroHealth = 100
function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "MicroHealth")
end

function ENT:GetMicroHealthDisplayName()
    return "Comms Computer"
end

function ENT:Initialize()
    self:SetModel("models/props_phx/construct/metal_plate2x2.mdl")

	self:PhysicsInitStandard()

    if SERVER then
        self:GetPhysicsObject():EnableMotion(false)
        self:SetUseType(SIMPLE_USE)
    end

    if SERVER then
        self.sv_text_lines = {}
        self.next_broken_message = 0
        self:SetMicroHealth(self.MaxMicroHealth)
    end
end

if CLIENT then
    CL_MICRO_COMM_TEXT_LINES = CL_MICRO_COMM_TEXT_LINES or {}
end

function ENT:Draw()
    self:DrawModel()

    cam.Start3D2D(self:LocalToWorld(Vector(-45,-45,4)),self:GetAngles()+Angle(90,90,90), .25 )
        local ship = Entity(MICRO_SHIP_ID or -1)
        if IsValid(ship) then
            local color = ship:GetColor()

            surface.SetDrawColor(Color( 0, 0, 0))
            surface.DrawRect( 0, 0, 360, 360 )

            surface.SetDrawColor(color)
            surface.DrawOutlinedRect(0,0,360,360)
            surface.DrawOutlinedRect(1,40,358,319)

            draw.SimpleText("COMMS","DermaLarge",180,20,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            
            for text_y,line in pairs(CL_MICRO_COMM_TEXT_LINES) do
                local text_x = 0
                for _,chunk in pairs(line) do
                    draw.SimpleText(chunk.text,"DebugFixed",20+text_x*7,50+text_y*10,chunk.color,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
                    text_x = text_x+#chunk.text
                end
            end

            local hurt = IsComponentHurt(self)
            if hurt then
                DoHurtScreenEffect(color,360,360)
            end
        end
    cam.End3D2D()
end

function ENT:Use(ply)
    local hurt = IsComponentHurt(self)
    if not hurt then
        ply:SendLua("MICRO_SHOW_COMMS()")
    end
end

local MAX_LINE_LENGTH = 45
local MAX_LINES = 27

if SERVER then
	util.AddNetworkString("micro_commstext")

    function ENT:InitializeText(ply)
		net.Start("micro_commstext")
		net.WriteBool(true)
        net.WriteUInt(#self.sv_text_lines,8)
        for _,line in pairs(self.sv_text_lines) do
            net.WriteUInt(#line,8)
            for _,chunk in pairs(line) do
                net.WriteColor(chunk.color)
                net.WriteString(chunk.text)
            end
        end
		net.Send(ply)
	end

    function BroadcastComms(...)
        for _,ent in pairs(ents.FindByClass("micro_comms")) do
            if IsComponentHurt(ent) then continue end
            ent:EmitSound(sound_important)
            ent:AddText(...)
        end
    end

    function ENT:BroadcastComms(msg)
        local hurt = IsComponentHurt(self)
        if hurt then return end

        local team_color = MICRO_TEAM_COLORS[self.team]
        local team_name = MICRO_TEAM_NAMES[self.team]
        
        for _,ent in pairs(ents.FindByClass("micro_comms")) do
            if IsComponentHurt(ent) then continue end
            if ent==self then
                ent:EmitSound(sound_send)
            else
                ent:EmitSound(sound_message)
            end

            ent:AddText(
                team_color,string.upper(team_name)..":",
                Color(255,255,255)," "..msg
            )
        end
    end

    function ENT:SendComms(msg,target_i)
        local hurt = IsComponentHurt(self)
        if hurt then return end

        local team_color = MICRO_TEAM_COLORS[self.team]
        local team_name = MICRO_TEAM_NAMES[self.team]

        local target_team_color = MICRO_TEAM_COLORS[target_i]
        local target_team_name = MICRO_TEAM_NAMES[target_i]

        local target_ent = MICRO_SHIP_ENTS[target_i].comms_ent

        self:EmitSound(sound_send)
        self:AddText(
            team_color,string.upper(team_name),
            Color(255,255,255)," [TO ",
            target_team_color,string.upper(target_team_name),
            Color(255,255,255),"]: "..msg
        )

        if IsComponentHurt(target_ent) then return end

        target_ent:EmitSound(sound_message)
        target_ent:AddText(
            team_color,string.upper(team_name),
            Color(255,255,255)," [",
            team_color,"PM",
            Color(255,255,255),"]: "..msg
        )

    end

    --local broken_override = false

    function ENT:Think()
        local hurt = IsComponentHurt(self)
        if hurt and CurTime()>self.next_broken_message then
            self.next_broken_message=CurTime()+math.random(1,5)
            --broken_override = true
            local color = HSVToColor(math.random(0,360),1,1)
            local text = ""
            for i=1,math.random(100) do
                text=text..string.char(math.random(33,126))
            end
            self:AddText(Color(color.r,color.g,color.b),text)
            self:EmitSound(sound_message)
            --broken_override = false
        end
    end

    function ENT:AddText(...)
        --local hurt = IsComponentHurt(self)
        --if hurt and not broken_override then return end

        local args = {...}

        if #args%2!=0 then
            error("AddText must have an even number of arguments!")
        end

        local chunks = {}

        for i=1,#args/2 do
            local chunk = {color=args[i*2-1],text=args[i*2]}
            if not IsColor(chunk.color) or not isstring(chunk.text) then
                error("AddText arguments wrong!")
            end
            table.insert(chunks, chunk)
        end

        local newlines = {}
        local newchunks = {}
        local budget = MAX_LINE_LENGTH
        for _,chunk in pairs(chunks) do
            ::retry::
            if budget>#chunk.text then
                table.insert(newchunks,chunk)
                budget = budget-#chunk.text
            else
                local cut_pos = budget
                for i=cut_pos,1,-1 do
                    if chunk.text[i]==" " or chunk.text[i]=="\t" then
                        cut_pos = i
                        break
                    end
                end
                table.insert(newchunks,{color=chunk.color,text=string.sub(chunk.text,1,cut_pos)})
                table.insert(newlines,newchunks)
                newchunks = {}
                budget = 45
                chunk.text = string.sub(chunk.text,cut_pos+1)
                goto retry
            end
        end
        table.insert(newlines,newchunks)

        local lines = newlines

        net.Start("micro_commstext")
		net.WriteBool(false)
        net.WriteUInt(#lines,8)
        for _,line in pairs(lines) do
            net.WriteUInt(#line,8)
            for _,chunk in pairs(line) do
                net.WriteColor(chunk.color)
                net.WriteString(chunk.text)
            end
        end
		net.SendPVS(self:GetPos())

        table.Add(self.sv_text_lines,lines)

        while #self.sv_text_lines>MAX_LINES do
            table.remove(self.sv_text_lines,1)
        end
    end

else
	net.Receive("micro_commstext",function()
		local clear = net.ReadBool()
        if clear then
            CL_MICRO_COMM_TEXT_LINES = {}
        end
        
        local line_count = net.ReadUInt(8)
        for line_i=1,line_count do
            local line = {}
            local chunk_count = net.ReadUInt(8)
            for line_i=1,chunk_count do
                local color = net.ReadColor()
                local text = net.ReadString()
                table.insert(line,{color=color,text=text})
            end
            table.insert(CL_MICRO_COMM_TEXT_LINES,line)
        end

        while #CL_MICRO_COMM_TEXT_LINES>MAX_LINES do
            table.remove(CL_MICRO_COMM_TEXT_LINES,1)
        end
	end)
end

if SERVER then
    concommand.Add("micro_comms_send",function(ply,_,args)
        local n = tonumber(args[1])
        local msg = args[2]
        local team = ply:Team()
        if !ply:Alive() or !isnumber(n) or n>4 or n<0 or #msg>100 or msg=="" or team==5 then return end

        local comms_ent = MICRO_SHIP_ENTS[team].comms_ent

        if comms_ent:GetPos():Distance(ply:GetPos())>200 then return end

        if n==0 then
            comms_ent:BroadcastComms(msg)
        elseif n!=team then
            comms_ent:SendComms(msg,n)
        end
    end)
else
    function MICRO_SHOW_COMMS()
        local panel = vgui.Create("DFrame")
        panel:SetDraggable(false)
        panel:SetSizable(false)
        panel:SetTitle("Comms")
        panel:SetSize(640,130)
        panel:SetPos(ScrW()/2-320,ScrH()-200)
        panel:MakePopup()

        panel.Think = function(self)
            if !LocalPlayer():Alive() then self:Close() end
        end

        local text = panel:Add("DTextEntry")
        text:SetPos(10,30)
        text:SetFont("CloseCaption_Normal")
        text:SetSize(620,40)
        text:RequestFocus()
        text.OnEnter = function( self )
            panel:Close()
            RunConsoleCommand("micro_comms_send",0,text:GetValue())
        end
        local x_offset = 150
        for i=1,5 do
            if i==LocalPlayer():Team() then continue end
            local button = panel:Add("DButton")
            if i==5 then
                button:SetText("Broadcast [ENTER]")
                button:SetSize(150,40)
            else
                button:SetText("PM "..MICRO_TEAM_NAMES[i])
                button:SetSize(100,40)
            end
            button:SetPos(x_offset,80) 
            x_offset = x_offset+110
            button:SetFont("micro_shadow")
            button:SetTextColor(Color(255,255,255))

            function button:DoClick()
                panel:Close()
                RunConsoleCommand("micro_comms_send",i%5,text:GetValue())
            end

            function button:Paint(w,h)
                draw.RoundedBox(8,0,0,w,h,MICRO_TEAM_COLORS[i%5])
            end
        end

        
    end
end