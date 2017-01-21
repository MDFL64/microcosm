include( 'shared.lua' )

surface.CreateFont("micro_big", {
	font = "Verdana",
	size = 32,
})

surface.CreateFont("micro_med", {
	font = "Verdana",
	size = 24,
})

surface.CreateFont("micro_shadow", {
	font = "Verdana",
	size = 16,
	antialias = false,
	shadow=true
})

surface.CreateFont("micro_fixed", {
	font = "Courier New",
	size = 16,
	antialias = false
})


timer.Simple(1,function()
	local function dereflect(name)
		local mat = Material(name)
		mat:SetUndefined("$envmap") 
		mat:Recompute()
	end

	local matGlass = Material("spacebuild/glass")
	matGlass:SetUndefined("$envmap") 
	matGlass:Recompute()

	dereflect("spacebuild/glass")
	dereflect("phoenix_storms/glass")
end)

hook.easy("PreDrawHUD",function()
	if !LocalPlayer():Alive() then
		cam.Start2D()
		surface.SetDrawColor(Color( 0, 0, 0))
		surface.DrawRect(0, 0, ScrW(), ScrH())
		draw.SimpleText("You will respawn shortly.","micro_big",ScrW()/2,ScrH()/2,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		draw.SimpleText("Press F1 or type /help to view help.","micro_med",ScrW()/2,ScrH()/2+60,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		draw.SimpleText("Press F2 or type /team to switch teams.","micro_med",ScrW()/2,ScrH()/2+90,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		draw.SimpleText("Press F3 or type /steam to join the steam group.","micro_med",ScrW()/2,ScrH()/2+120,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		cam.End2D()
	end
end)

hook.Add("HUDPaint","micro_hud",function()
	if LocalPlayer():Alive() then
		local tr = LocalPlayer():GetEyeTrace()
		if tr.Fraction < .003 and IsValid(tr.Entity) and tr.Entity.GetMicroHudText then
			local text = tr.Entity:GetMicroHudText()
			local font = "micro_big"
			
			surface.SetFont(font)
			local w,h = surface.GetTextSize(text)
			w=w+10
			h=h+10
			draw.RoundedBox(4,(ScrW()-w)/2,(ScrH()-h)/2,w,h,Color(0,0,0,150))
			draw.SimpleText(text,"micro_big",ScrW()/2,ScrH()/2,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

		end
	end
end)

local function help_panel(url)
	local panel = vgui.Create("DFrame")
	panel:SetDraggable(false)
	panel:SetSizable(false)
	panel:SetTitle("Help")
	panel:SetSize(ScrW()-100,ScrH()-100)
	panel:Center()
	panel:SetDeleteOnClose(false)

	local html = panel:Add("DHTML")
	html:Dock( FILL )
	html:OpenURL(url)
	return panel
end

function MICRO_SHOW_HELP()
	MICRO_PANEL_HELP = MICRO_PANEL_HELP or help_panel("http://micro.cogg.rocks/ingame/help.html")
	MICRO_PANEL_HELP:Show()
	MICRO_PANEL_HELP:MakePopup()
end

function MICRO_SHOW_TEAM()
	--local button_spots = {{10,40},{210,40},{10,140},{210,140},[0]={110,90}}

	local panel = vgui.Create("DFrame")
	panel:SetDraggable(false)
	panel:SetSizable(false)
	panel:SetTitle("Team Menu")
	panel:SetSize(640,480)
	panel:Center()
	panel:MakePopup()

	for i=0,4 do
		local button = panel:Add("DButton")
		button:SetFont("micro_shadow")
		button:SetTextColor(Color(255,255,255))
		button:SetText(MICRO_TEAM_NAMES[i])
		button:SetPos(30+i*120,30)
		button:SetSize(100,50)

		function button:Paint(w,h)
			draw.RoundedBox(8,0,0,w,h,MICRO_TEAM_COLORS[i])
		end

		function button:DoClick()
			panel:Close()
			RunConsoleCommand("micro_jointeam",i)
		end

		local frame = panel:Add("DPanel")
		frame:SetPos(20+i*120,100)
		frame:SetSize(120,350)

		function frame:Paint(w,h)
			--draw.RoundedBox(8,0,0,w,h,Color(0,0,0))
			surface.SetDrawColor(Color(0,0,0))
			surface.DrawRect(0,0,w,h)
			--surface.SetDrawColor(Color(255,255,255))
			--surface.DrawOutlinedRect(0,0,w,h)
			local n = i
			if n==0 then n=5 end
			for k,v in pairs(team.GetPlayers(n)) do
				draw.SimpleText(v:Nick(),"DermaDefault",10,k*15,MICRO_TEAM_COLORS[i],TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
			end
		end
	end
end

function MICRO_SHOW_STEAM()
	gui.OpenURL("http://steamcommunity.com/groups/paramicro")
end

function GM:OnPlayerChat(player, text, bTeamOnly, bPlayerIsDead)
	return bPlayerIsDead
end