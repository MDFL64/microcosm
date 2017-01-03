AddCSLuaFile()

ENT.Type = "anim"

local sound_add = Sound("ambient/levels/canals/windchime2.wav")
local sound_buy = Sound("ambient/levels/citadel/weapon_disintegrate2.wav")

ENT.MaxMicroHealth = 100
function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "MicroHealth")
    self:NetworkVar("Int", 1, "Cash")
end

function ENT:GetMicroHealthDisplayName()
    return "Shop Terminal"
end

function ENT:Initialize()
    self:SetModel("models/props_phx/construct/metal_tube.mdl")

	self:PhysicsInitStandard()

    if SERVER then
        self:GetPhysicsObject():EnableMotion(false)
        self:SetUseType(SIMPLE_USE)
    end

    if SERVER then
        self:SetMicroHealth(self.MaxMicroHealth)
        self:SetCash(100)
        self.next_paytime = 0
    end
end

function ENT:Use(ply)
    local hurt = IsComponentHurt(self)
    if not hurt then
        ply:SendLua("MICRO_SHOW_SHOP(Entity("..self:EntIndex().."))")
    end
end

if SERVER then
    function ENT:Think()
        if CurTime()>self.next_paytime and !IsComponentHurt(self) then
            self:SetCash(self:GetCash()+1)
            self.next_paytime = CurTime()+3
        end
    end

    function ENT:AddCash(amount)
        if IsComponentHurt(self) then return false end

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

function ENT:GetScreenText()
    local ship = Entity(MICRO_SHIP_ID or -1)
    local hurt = IsComponentHurt(self)

    if hurt then
        return "HONK",Color(255,0,255)
    elseif self:CheckBlocked() then
        return "BLOCKED",Color(255,0,0)
    elseif ship:GetIsHome() then
        return "READY",Color(0,255,0)
    else
        return "NOT DOCKED",Color(255,0,0)
    end
end

function ENT:Draw()
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
            
            local cash = self:GetCash()
            if hurt then cash = math.random(100,999) end

            draw.SimpleText("SHOP","DermaLarge",88,20,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            draw.SimpleText("$"..cash,"DermaLarge",88,80,Color(255,255,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            
            local text,text_color = self:GetScreenText()
            draw.SimpleText(text,"DermaLarge",88,130,text_color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

            if hurt then
                DoHurtScreenEffect(color,176,176)
            end
        end
    cam.End3D2D()
end

local items = {
    {
        name="Fix Everything",
        desc="Restores the ship's hull, all components, and all crew to full HP.",
        cost=50,
        pv="models/props_c17/tools_wrench01a.mdl",
        func = function(ship)
            ship.health_ent:RepairAll()
            for k,v in pairs(team.GetPlayers(ship.team_id)) do
                v:SetHealth(v:GetMaxHealth())
            end
        end
    },
    {
        name="Reload Guns",
        desc="Fully loads both cannons.",
        cost=50,
        pv="models/items/ammocrate_ar2.mdl",
        func = function(ship)
            local function full_reload(cannon)
                cannon:SetAmmo1(cannon.Ammo1Max)
                cannon:SetAmmo2(cannon.Ammo2Max)
                cannon:SetAmmo3(cannon.Ammo3Max)
            end

            full_reload(ship.cannon_1)
            full_reload(ship.cannon_2)
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
        desc="Reloads 4 use cannon shells.",
        cost=5,
        pv="models/dav0r/buttons/button.mdl",
        ent="micro_item_shell_3"
    }
}

if SERVER then
    concommand.Add("micro_shop_buy",function(ply,_,args)
        local n = tonumber(args[1])
        local team = ply:Team()
        if !ply:Alive() or !isnumber(n) or items[n]==nil or team==5 then return end

        local ship = MICRO_SHIP_ENTS[team]

        if !ship:GetIsHome() then return end

        local shop_ent = ship.shop_ent

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
        local panel = vgui.Create("DFrame")
        panel:SetDraggable(false)
        panel:SetSizable(false)
        panel:SetTitle("Shop")
        panel:SetSize(640,480)
        panel:Center()
        panel:MakePopup()

        panel.Think = function(self)
            if !LocalPlayer():Alive() or IsComponentHurt(ent) then self:Close() end
        end
        
        panel.PaintOver = function(self)
            local color = team.GetColor(LocalPlayer():Team())

            surface.SetDrawColor(Color( 0, 0, 0))
            surface.DrawRect(285, 30, 330, 40)

            surface.SetDrawColor(color)
            surface.DrawOutlinedRect(285, 30, 330, 40)

            local cash = ent:GetCash()
            draw.SimpleText("$"..cash,"DermaLarge",605,50,Color(255,255,0),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
            
            local text,text_color = ent:GetScreenText()
            draw.SimpleText(text,"DermaLarge",380,50,text_color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
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
                RunConsoleCommand("micro_shop_buy",i)
            end

            function button:Think()
                local cash = ent:GetCash()
                local ship = Entity(MICRO_SHIP_ID or -1)

                -- WARNING! SLOW! DOES A TRACE FOR EVERY BUTTON!
                if item.cost>cash or !IsValid(ship) or !ship:GetIsHome() or (item.ent and  ent:CheckBlocked()) then
                    self:SetDisabled(true)
                else
                    self:SetDisabled(false)
                end
            end
        end
    end
end