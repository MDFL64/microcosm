AddCSLuaFile()

DEFINE_BASECLASS("micro_component")
ENT.Base = "micro_component"

local sound_message = Sound("HL1/fvox/beep.wav")
local sound_send = Sound("weapons/pistol/pistol_empty.wav")
local sound_important = Sound("ambient/alarms/klaxon1.wav")

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.text_lines = {}

	if SERVER then
		self.next_broken_message = 0
	end
end

function ENT:drawInfo(ship,broken)
	for text_y,line in pairs(self.text_lines) do
		local text_x = 0
		for _,chunk in pairs(line) do
			draw.SimpleText(chunk.text,"micro_fixed",20+text_x*8,40+text_y*12,chunk.color,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
			text_x = text_x+#chunk.text
		end
	end
end

function ENT:GetComponentName()
	return "Communication Computer"
end

function ENT:Use(ply)
	if not self:IsBroken() then
		ply:SendLua("MICRO_SHOW_COMMS(Entity("..self:EntIndex().."))")
	end
end

local MAX_LINE_LENGTH = 40
local MAX_LINES = 23

if SERVER then
	util.AddNetworkString("micro_commstext")

	hook.easy("micro_changeship",function(ply,old,new)
		timer.Simple(1,function()
			if !IsValid(ply) then return end

			if new then
				for comp,_ in pairs(new.components) do
					if comp:GetClass()=="micro_comp_comms" then
						comp:InitializeText(ply)
					end
				end
			end
		end)
	end)

	function ENT:InitializeText(ply)
		net.Start("micro_commstext")
		net.WriteEntity(self)
		net.WriteBool(true)
		net.WriteUInt(#self.text_lines,8)
		for _,line in pairs(self.text_lines) do
			net.WriteUInt(#line,8)
			for _,chunk in pairs(line) do
				net.WriteColor(chunk.color)
				net.WriteString(chunk.text)
			end
		end
		net.Send(ply)
	end

	function BroadcastComms(...)
		for _,ent in pairs(ents.FindByClass("micro_comp_comms")) do
			if ent:IsBroken() then continue end
			ent:EmitSound(sound_important)
			ent:AddText(...)
		end
	end

	function ENT:BroadcastComms(msg)
		local ship_info = self:GetShipInfo()
		if self:IsBroken() or !IsValid(ship_info.entity) then return end

		local team = ship_info.entity:GetShipID()

		local team_color = MICRO_TEAM_COLORS[team]
		local team_name = MICRO_TEAM_NAMES[team]
		
		for _,ent in pairs(ents.FindByClass("micro_comp_comms")) do
			if ent:IsBroken() then continue end
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
		local ship_info = self:GetShipInfo()
		if self:IsBroken() or !IsValid(ship_info.entity) then return end

		local team = ship_info.entity:GetShipID()

		local team_color = MICRO_TEAM_COLORS[team]
		local team_name = MICRO_TEAM_NAMES[team]

		local target_team_color = MICRO_TEAM_COLORS[target_i]
		local target_team_name = MICRO_TEAM_NAMES[target_i]

		self:EmitSound(sound_send)
		self:AddText(
			team_color,string.upper(team_name),
			Color(255,255,255)," [TO ",
			target_team_color,string.upper(target_team_name),
			Color(255,255,255),"]: "..msg
		)

		for target_ent,_ in pairs(MICRO_SHIP_INFO[target_i].components) do
			if target_ent:GetClass()=="micro_comp_comms" and !target_ent:IsBroken() then
				target_ent:EmitSound(sound_message)
				target_ent:AddText(
					team_color,string.upper(team_name),
					Color(255,255,255)," [",
					team_color,"PM",
					Color(255,255,255),"]: "..msg
				)
			end
		end
	end

	--local broken_override = false

	function ENT:Think()
		if self:IsBroken() and CurTime()>self.next_broken_message then
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

		local args = {...}

		if #args%2!=0 then
			error("AddText must have an even number of arguments!")
		end

		local chunks = {}

		for i=1,#args/2 do
			local chunk = {color=args[i*2-1],text=args[i*2]}
			if not IsColor(chunk.color) or not isstring(chunk.text) then
				print(chunk.color,chunk.text)
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
				budget = MAX_LINE_LENGTH
				chunk.text = string.sub(chunk.text,cut_pos+1)
				goto retry
			end
		end
		table.insert(newlines,newchunks)

		local lines = newlines

		net.Start("micro_commstext")
		net.WriteEntity(self)
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

		table.Add(self.text_lines,lines)

		while #self.text_lines>MAX_LINES do
			table.remove(self.text_lines,1)
		end
	end

else
	net.Receive("micro_commstext",function()
		local comms = net.ReadEntity()
		
		if !IsValid(comms) then return end
		
		local clear = net.ReadBool()

		if clear then
			comms.text_lines = {}
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
			table.insert(comms.text_lines,line)
		end

		while #comms.text_lines>MAX_LINES do
			table.remove(comms.text_lines,1)
		end
	end)
end

if SERVER then
	concommand.Add("micro_comms_send",function(ply,_,args)
		local comms_ent = Entity(tonumber(args[1]) or 0)
		local n = tonumber(args[2])
		local msg = args[3]

		if !ply:Alive() or !isnumber(n) or n>4 or n<0 or #msg>100 or msg=="" or !IsValid(comms_ent) or comms_ent:GetClass()!="micro_comp_comms" then return end

		if comms_ent:GetPos():Distance(ply:GetPos())>200 then return end

		if n==0 then
			comms_ent:BroadcastComms(msg)
		elseif n!=team then
			comms_ent:SendComms(msg,n)
		end
	end)
else
	function MICRO_SHOW_COMMS(ent)
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
			RunConsoleCommand("micro_comms_send",ent:EntIndex(),0,text:GetValue())
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
				RunConsoleCommand("micro_comms_send",ent:EntIndex(),i%5,text:GetValue())
			end

			function button:Paint(w,h)
				draw.RoundedBox(8,0,0,w,h,MICRO_TEAM_COLORS[i%5])
			end
		end

		
	end
end