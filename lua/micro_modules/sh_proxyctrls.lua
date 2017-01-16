if SERVER then
	util.AddNetworkString("micro_proxyctrls")

	local PLAYER = FindMetaTable("Player")
	function PLAYER:ProxyControls(ent)
		self.proxyctrls_ent = ent
		self.proxyctrls_lastbuttons = IN_USE
		self.proxyctrls_use_pressed = false
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

--[[hook.easy("CreateMove",function(cmd)
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
end)]]

hook.easy("StartCommand",function(ply,cmd)
	if !IsValid(ply.proxyctrls_ent) then return end

	if SERVER then
		local ent_okay = IsValid(ply.proxyctrls_ent) and isfunction(ply.proxyctrls_ent.sendControls)

		local function key_down(key) return cmd:KeyDown(key) end
		local function key_pressed(key) return cmd:KeyDown(key) and bit.band(key,ply.proxyctrls_lastbuttons)==0 end
		local function key_released(key) return not cmd:KeyDown(key) and bit.band(key,ply.proxyctrls_lastbuttons)!=0 end

		if 
			!ply:Alive() or
			!ent_okay or
			ply:GetPos():DistToSqr(ply.proxyctrls_ent:GetPos())>150^2 or
			(ply.proxyctrls_use_pressed and key_released(IN_USE))
		then
			--timer.Simple(.1,function()
				if ent_okay then
					ply.proxyctrls_ent:stopControl()
				end

				ply:ProxyControls()
			--end)
		else
			if key_pressed(IN_USE) then ply.proxyctrls_use_pressed=true end

			if ply.proxyctrls_ent.ControlEyeLock then
				local mx = cmd:GetMouseX()
				local my = cmd:GetMouseY()
				ply.proxyctrls_ent:sendControls(key_down,key_pressed,key_released,mx,my)
			else
				local angs = cmd:GetViewAngles()
				ply.proxyctrls_ent:sendControls(key_down,key_pressed,key_released,angs)
			end
		end

		ply.proxyctrls_lastbuttons = cmd:GetButtons()

		cmd:ClearMovement()
		cmd:ClearButtons()
	else
		local unlocked = cmd:KeyDown(IN_WALK) or !ply.proxyctrls_ent.ControlEyeLock

		if unlocked then
			ply.proxyctrls_eye = cmd:GetViewAngles()
			cmd:SetMouseX(0)
			cmd:SetMouseY(0)
		else
			cmd:SetViewAngles(ply.proxyctrls_eye)
		end
	end
end)

if CLIENT then
	hook.easy("SetupMove",function(ply,mv,cmd)
		if !IsValid(ply.proxyctrls_ent) then return end

		mv:SetOldButtons(0)
		mv:SetButtons(0)
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
		mv:SetUpSpeed(0)
	end)

	hook.easy("CalcView",function(ply, pos, angles, fov)
		if IsValid(ply.proxyctrls_ent) then
			if ply.proxyctrls_ent.controlView then
				return ply.proxyctrls_ent:controlView(pos,angles,fov)
			end
		end
	end)
end