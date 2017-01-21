AddCSLuaFile()

DEFINE_BASECLASS("micro_component")
ENT.Base = "micro_component"

ENT.ComponentModel = "models/props_phx/construct/metal_tube.mdl"
ENT.ComponentScreenWidth = 180
ENT.ComponentScreenHeight = 180
ENT.ComponentScreenOffset = Vector(24,-22.5,46)
ENT.ComponentScreenRotation = Angle(0,90,90)

ENT.StartingCash = 100


local sound_add = Sound("ambient/levels/canals/windchime2.wav")
local sound_buy = Sound("ambient/levels/citadel/weapon_disintegrate2.wav")

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Cash")
end

function ENT:GetComponentName()
	return "Shop"
end

local PAY_INTERVAL = 6

function ENT:Initialize()
	BaseClass.Initialize(self)

	if SERVER then
		self:SetCash(self.StartingCash)
		self.next_paytime = 0
	end
end

function ENT:Use(ply)
	if not self:IsBroken() then
		ply:SendLua("MICRO_SHOW_SHOP(Entity("..self:EntIndex().."))")
	end
end

if SERVER then
	function ENT:Think()
		if CurTime()>self.next_paytime and !self:IsBroken() then
			self:SetCash(self:GetCash()+1)
			self.next_paytime = CurTime()+6
		end
	end

	function ENT:AddCash(amount)
		if self:IsBroken() then return false end

		self:SetCash(self:GetCash()+amount)
		self:EmitSound(sound_add)
		return true
	end
end

function ENT:GetItemSpawn()
	return self:GetPos()+Vector(0,0,24)
end

function ENT:CheckBlocked()
	local r = 18
	local tr = util.TraceHull{start=self:GetItemSpawn(),endpos=self:GetItemSpawn(),mins=Vector(-1,-1,-1)*r, maxs=Vector(1,1,1)*r, filter=self}
	return tr.Hit
end

if CLIENT then
	function ENT:GetScreenText()
		local ship = self:GetShipInfo().entity
		local hurt = self:IsBroken()

		if hurt then
			return "HONK!",Color(255,0,255)
		elseif self:CheckBlocked() then
			return "Blocked",Color(255,0,0)
		elseif ship:GetIsHome() then
			return "Ready",Color(0,255,0)
		else
			return "Not Docked",Color(255,0,0)
		end
	end
end

function ENT:drawInfo(ship,broken)
	local cash = self:GetCash()
	if broken then cash = math.random(1000000,9999999) end

	draw.SimpleText("$"..cash,"micro_big",88,80,Color(255,255,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	
	local text,text_color = self:GetScreenText()
	draw.SimpleText(text,"micro_big",88,130,text_color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

-- rerr!

local items = {
	{
		name="Fix Everything",
		desc="Restores the ship's hull, all components, and all crew to full HP.",
		cost=50,
		pv="models/props_c17/tools_wrench01a.mdl",
		func = function(ship)
			ship:RepairAll()
		end
	},
	{
		name="Reload Guns",
		desc="Fully loads both cannons.",
		cost=25,
		pv="models/items/ammocrate_ar2.mdl",
		func = function(ship)
			ship:ReloadGuns()
		end
	},
	{
		name="Fixer Fuel",
		desc="Reloads 100 units of fixer fuel.",
		cost=5,
		pv="models/items/car_battery01.mdl",
		ent="micro_item_fixerfuel"
	},
	{
		name="Med Kit",
		desc="Restores 100 crew HP.",
		cost=5,
		pv="models/items/healthkit.mdl",
		ent="micro_item_medkit"
	},
	{
		name="Armor Kit",
		desc="Restores 200 crew armor.",
		cost=50,
		pv="models/items/battery.mdl",
		ent="micro_item_armorkit"
	},
	{
		name="Standard Cannon Shells",
		desc="Reloads 200 standard cannon shells.",
		cost=10,
		pv="models/items/ar2_grenade.mdl",
		ent="micro_item_shell_1"
	},
	{
		name="Hook Cannon Shells",
		desc="Reloads 4 hook cannon shells.",
		cost=5,
		pv="models/props_junk/meathook001a.mdl",
		ent="micro_item_shell_2"
	},
	{
		name="Use Cannon Shells",
		desc="Reloads 8 use cannon shells.",
		cost=5,
		pv="models/dav0r/buttons/button.mdl",
		ent="micro_item_shell_3"
	},
	{
		name="Collectable Food",
		desc="Exotic food that restores health! It's 1 of 11 collectable foods. Collect them all!",
		cost=50,
		pv="models/slyfo_2/acc_food_meatsandwich.mdl",
		ent="micro_item_collectable_food"
	},
	{
		name="Collectable Toy",
		desc="A ball, a doll, or something special. Contains 1 of 6. Collect them all!",
		cost=100,
		pv="models/props/de_tides/vending_turtle.mdl",
		ent="micro_item_collectable_toys"
	},
	{
		name="Collectable Decoration",
		desc="Show off loot in your richie-rich spaceship! Contains 1 of 11. Collect them all!",
		cost=500,
		pv="models/maxofs2d/gm_painting.mdl",
		ent="micro_item_collectable_deco"
	},
	{
		name="Manhack",
		desc="Want a challenge? Try sharing your ship with a few of these!",
		cost=500,
		pv="models/manhack.mdl",
		ent="npc_manhack"
	},
	{
		name="Rollermine",
		desc="beep boop",
		cost=500,
		pv="models/roller.mdl",
		ent="npc_rollermine"
	}
	--[[,
	{
		name="Scanner Buddy",
		desc="This one can't hurt you so I'm making it cost even more.",
		cost=10,
		pv="models/Combine_Scanner.mdl",
		ent="npc_cscanner"
	},]]
}

if SERVER then
	-- This is shitty.

	concommand.Add("micro_shop_buy",function(ply,_,args)
		local shop_ent = Entity(tonumber(args[1]) or 0)

		local n = tonumber(args[2])

		if !ply:Alive() or !isnumber(n) or items[n]==nil or !IsValid(shop_ent) or shop_ent:GetClass()!="micro_comp_shop" or shop_ent:IsBroken() then return end

		local ship = shop_ent:GetShipInfo().entity

		if !IsValid(ship) or !ship:GetIsHome() then return end

		if shop_ent:GetPos():Distance(ply:GetPos())>200 then return end

		local item = items[n]

		if isstring(item.ent) then
			if shop_ent:CheckBlocked() then return end
		elseif !isfunction(item.func) then return end

		-- point of no return
		if shop_ent:GetCash()<item.cost then return end
		shop_ent:SetCash(shop_ent:GetCash()-item.cost)

		shop_ent:EmitSound(sound_buy)

		if isstring(item.ent) then
			local ent = ents.Create(item.ent)
			if !IsValid(ent) then error("FAILED to make bought entity!") end
			--ent:SetModel("models/Items/item_item_crate.mdl")
			ent:SetPos(shop_ent:GetItemSpawn())
			ent:Spawn()
		else
			item.func(ship)
		end

	end)
else
	function MICRO_SHOW_SHOP(ent)
		local blocked

		local panel = vgui.Create("DFrame")
		panel:SetDraggable(false)
		panel:SetSizable(false)
		panel:SetTitle("Shop")
		panel:SetSize(640,480)
		panel:Center()
		panel:MakePopup()

		panel.Think = function(self)
			if !LocalPlayer():Alive() or ent:IsBroken() then
				self:Close()
			else
				blocked = ent:CheckBlocked()
			end
		end
		
		panel.PaintOver = function(self)
			local color = team.GetColor(LocalPlayer():Team())

			surface.SetDrawColor(Color( 0, 0, 0))
			surface.DrawRect(285, 30, 330, 40)

			surface.SetDrawColor(color)
			surface.DrawOutlinedRect(285, 30, 330, 40)

			local cash = ent:GetCash()
			draw.SimpleText("$"..cash,"micro_big",605,50,Color(255,255,0),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
			
			local text,text_color = ent:GetScreenText()
			draw.SimpleText(text,"micro_big",380,50,text_color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		end

		local scroll = panel:Add("DScrollPanel")
		scroll:Dock(FILL)
		scroll:DockMargin(0,50,0,0)

		for i,item in pairs(items) do
			local y_base = (i-1)*90

			local panel = scroll:Add("DPanel")
			panel:SetPos(0, y_base)
			panel:SetSize(610,80)

			local title = panel:Add("DLabel")
			title:SetPos(100,0)
			title:SetFont("DermaLarge")
			title:SetText(item.name)
			title:SetDark(true) 
			title:SizeToContents()

			local cost = panel:Add("DLabel")
			cost:SetFont("DermaLarge")
			cost:SetText("$"..item.cost)
			cost:SetDark(true) 
			cost:SizeToContents()
			cost:SetPos(600-cost:GetWide(),10)

			local icon = panel:Add("DModelPanel")
			icon:SetSize(70, 70)
			icon:SetPos(0,0)
			icon:SetModel(item.pv)
			icon:SetLookAt( Vector(0,0,0) )
			icon:SetFOV(1.5*icon:GetEntity():GetModelRadius())

			local desc = panel:Add("DLabel")
			desc:SetPos(100,40)
			desc:SetText(item.desc)
			desc:SetDark(true) 
			desc:SizeToContents()

			local button = panel:Add("DButton")
			button:SetText("Buy")
			button:SetPos(540,50)

			function button:DoClick()
				RunConsoleCommand("micro_shop_buy",ent:EntIndex(),i)
			end

			function button:Think()
				local cash = ent:GetCash()
				local ship = ent:GetShipInfo().entity

				-- WARNING! SLOW! DOES A TRACE FOR EVERY BUTTON!
				if item.cost>cash or !IsValid(ship) or !ship:GetIsHome() or (item.ent and blocked) then
					self:SetDisabled(true)
				else
					self:SetDisabled(false)
				end
			end
		end
	end
end