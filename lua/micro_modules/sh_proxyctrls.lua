local micro_controlled_ent

if SERVER then
	util.AddNetworkString("micro_enablecontrol")

	local PLAYER = FindMetaTable("Player")
	function PLAYER:ProxyControls(ent)
		self.controlled_ent = ent
		--self.control_last_buttons = IN_USE
		net.Start("micro_enablecontrol")
		net.WriteEntity(ent or NULL)
		net.Send(self)
	end
else
	--local micro_controlled_ent
	local micro_last_eye = Angle(0,0,0)

	net.Receive("micro_enablecontrol",function()
		micro_controlled_ent = net.ReadEntity()
		if micro_controlled_ent:IsWorld() then print("AGGGH") micro_controlled_ent = nil end
	end)
end

hook.easy("FinishMove",function(ply,mv)
	if SERVER then
		if !IsValid(ply.controlled_ent) then return end
	else
		if !IsValid(micro_controlled_ent) then return end
	end

	return true
end)

--local PLAYER = FindMetaTable("Player")

-- Control system, needs to be refactored later.
--if SERVER then
	--[[util.AddNetworkString("micro_enablecontrol")
	util.AddNetworkString("micro_controls")

	function PLAYER:ProxyControls(ent)
		self.controlled_ent = ent
		self.control_last_buttons = IN_USE
		net.Start("micro_enablecontrol")
		net.WriteEntity(ent or NULL)
		net.Send(self)
	end

	net.Receive("micro_controls",function(_,ply)


		local buttons = net.ReadUInt(32)

		local bad_controlled_ent = !IsValid(ply.controlled_ent) or !isfunction(ply.controlled_ent.sendControls)

		-- really shitty solution, make user release USE before they can press it to exit.
		--[[if bit.band(buttons,IN_USE)==0 and not ply.control_ready_exit then
			ply.control_ready_exit=true
		end
		local buttons_pressed = bit.band(bit.bxor(ply.control_last_buttons,buttons),buttons)

		if
			!ply:Alive() or
			bad_controlled_ent or
			ply:GetPos():DistToSqr(ply.controlled_ent:GetPos())>150^2 or
			bit.band(buttons_pressed,IN_USE)!=0
		then
			net.Start("micro_enablecontrol")
			net.WriteEntity(nil)
			net.Send(ply)

			if !bad_controlled_ent then
				ply.controlled_ent:stopControl()
				ply.controlled_ent = nil
			end
		else
			if ply.controlled_ent.ControlEyeLock then
				local x = net.ReadInt(16)
				local y = net.ReadInt(16)
				ply.controlled_ent:sendControls(buttons,buttons_pressed,x,y)
			else
				local angs = ply:EyeAngles()
				ply.controlled_ent:sendControls(buttons,buttons_pressed,angs)
			end

			ply.control_last_buttons = buttons
		end
	end)
else
	MICRO_CONTROLLING = MICRO_CONTROLLING
	MICRO_LAST_EYE = MICRO_LAST_EYE or Angle(0,0,0)

	net.Receive("micro_enablecontrol",function()
		MICRO_CONTROLLING = net.ReadEntity()
		if MICRO_CONTROLLING:IsWorld() then MICRO_CONTROLLING = nil end
	end)

	function GM:CreateMove(cmd)
		if IsValid(MICRO_CONTROLLING) then
			if MICRO_CONTROLLING.ControlEyeLock then
				local angs_unlocked = cmd:KeyDown(IN_WALK)
				
				net.Start("micro_controls")
				net.WriteUInt(cmd:GetButtons(),32)
				net.WriteInt(angs_unlocked and 0 or cmd:GetMouseX(),16)
				net.WriteInt(angs_unlocked and 0 or cmd:GetMouseY(),16)
				net.SendToServer()
				
				cmd:ClearButtons()
				cmd:ClearMovement()

				if angs_unlocked then
					MICRO_LAST_EYE = cmd:GetViewAngles()
				else
					cmd:SetViewAngles(MICRO_LAST_EYE)
				end
			else
				net.Start("micro_controls")
				net.WriteUInt(cmd:GetButtons(),32)
				net.SendToServer()

				cmd:ClearButtons()
				cmd:ClearMovement()
			end
		else
			MICRO_LAST_EYE = cmd:GetViewAngles()
		end
	end
end]]