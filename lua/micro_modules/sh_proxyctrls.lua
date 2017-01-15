if SERVER then
	util.AddNetworkString("micro_proxyctrls")

	local PLAYER = FindMetaTable("Player")
	function PLAYER:ProxyControls(ent)
		self.proxyctrls_ent = ent
		self.proxyctrls_lastbuttons = IN_USE
		net.Start("micro_proxyctrls")
		net.WriteEntity(ent)
		net.Send(self)
	end
else
	local micro_last_eye = Angle(0,0,0)

	net.Receive("micro_proxyctrls",function()
		local ent = net.ReadEntity()
		LocalPlayer().proxyctrls_ent = ent
		LocalPlayer().proxyctrls_eye = LocalPlayer():EyeAngles()
	end)
end

hook.easy("CreateMove",function(cmd)
	local ply = LocalPlayer()
	if !IsValid(ply.proxyctrls_ent) then return end

	local unlocked = cmd:KeyDown(IN_WALK) or !ply.proxyctrls_ent.ControlEyeLock

	if unlocked then
		ply.proxyctrls_eye = cmd:GetViewAngles()
		cmd:SetMouseX(0)
		cmd:SetMouseY(0)
	else
		cmd:SetViewAngles(ply.proxyctrls_eye)
	end
end)

hook.easy("SetupMove",function(ply,mv,cmd)
	if !IsValid(ply.proxyctrls_ent) then return end

	if SERVER then
		mv:SetOldButtons(ply.proxyctrls_lastbuttons)

		local ent_okay = IsValid(ply.proxyctrls_ent) and isfunction(ply.proxyctrls_ent.sendControls)

		if 
			!ply:Alive() or
			!ent_okay or
			ply:GetPos():DistToSqr(ply.proxyctrls_ent:GetPos())>150^2 or
			mv:KeyPressed(IN_USE)
		then

			if ent_okay then
				ply.proxyctrls_ent:stopControl()
			end

			ply:ProxyControls()
		else
			mv:SetSideSpeed(-cmd:GetMouseX())
			mv:SetUpSpeed(cmd:GetMouseY())

			ply.proxyctrls_ent:sendControls(mv)
		end

		ply.proxyctrls_lastbuttons = mv:GetButtons()
	end

	--cmd:ClearButtons()

	mv:SetOldButtons(0)
	mv:SetButtons(0)
	mv:SetForwardSpeed(0)
	mv:SetSideSpeed(0)
	mv:SetUpSpeed(0)
	--mv:SetVelocity(Vector(0,0,0))
end)

hook.easy("PlayerUse",function(ply)
	if IsValid(ply.proxyctrls_ent) then return false end
end)

hook.easy("CalcView",function(ply, pos, angles, fov)
	if IsValid(ply.proxyctrls_ent) then
		if ply.proxyctrls_ent.controlView then
			return ply.proxyctrls_ent:controlView(pos,angles,fov)
		end
	end
end)