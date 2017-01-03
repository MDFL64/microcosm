include( 'shared.lua' )

--[[local lau = {
    set = function(keys)
        local set = {}
        for _,key in pairs(keys) do
            set[key] = true
        end
        return set
    end
}]]

-- limit hud shit
--[[function GM:HUDShouldDraw(name)
    local ship_ent = Entity(MICRO_SHIP_ID or -1)

    if IsValid(ship_ent) and name=="CHudHealth" then return false end
    return true
end]]

-- particle/particle_glow_05_add_15ob_minsize
-- particle/particle_glow_05_additive

--local matBlack = Material("tools/toolsblack")
--local matStar = Material("engine/lightsprite")

timer.Simple(1,function()
    local matGlass = Material("spacebuild/glass")
    matGlass:SetUndefined("$envmap") 
    matGlass:Recompute()
    --PrintTable(matGlass:GetKeyValues())
end)

--local matSky = Material("tools/toolsskybox")

--print("shader",matSky:GetTexture("$basetexture"):GetName())

-- 10 light years
local stars = {}

for i=1,1000 do
    table.insert(stars,VectorRand() * 50)
end
 
--local x = -1000

--local sky_mode = "city"

--local killed_rendering=false

--[[
function GM:PostDraw2DSkyBox()
    render.SetStencilEnable(false)
end]]

--local m = Material("skybox/militia_hdru")
--print(m:GetTexture("$basetexture"))

--airsup_ship_origin = ents.FindByName("airsup_ship")[1]
--print("==>")
--print(airsup_ship_origin)

function DoHurtScreenEffect(color,w,h)
    for i=1,20 do
        draw.SimpleText(string.char(math.random(33,126)),"DebugFixed",5+math.random()*(w-10),5+math.random()*(h-10),color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
end

function GM:PreRender()
    local ship_ent = Entity(MICRO_SHIP_ID or -1)

    if IsValid(ship_ent) then
        local origin = ship_ent:GetInternalOrigin()

        local real_pos = ship_ent:GetPos()
        local real_ang = ship_ent:GetAngles()

        local eye_pos = LocalPlayer():EyePos()
        local eye_angs = LocalPlayer():EyeAngles()+LocalPlayer():GetViewPunchAngles()

        local view = hook.Call("CalcView",GAMEMODE)
        if view then
            eye_pos = view.origin or eye_pos
        end

        local cam_pos, cam_ang = LocalToWorld((eye_pos-origin)*MICRO_SCALE,eye_angs,real_pos,real_ang)

        MICRO_DRAW_EXTERNAL = true
        render.SuppressEngineLighting(false)
        render.RenderView{
            w=ScrW(),
            h=ScrH(),
            --drawviewmodel=true,
            --fov=150,
            origin=cam_pos,
            angles=cam_ang,
            znear=0.1
        }
        MICRO_DRAW_EXTERNAL = false

        render.SuppressEngineLighting(true)

        local main_hull = ship_ent:GetMainHull()


        render.SetModelLighting(BOX_FRONT, .1,.1,.1)
        render.SetModelLighting(BOX_BACK, .1,.1,.1)
        render.SetModelLighting(BOX_RIGHT, .1,.1,.1)
        render.SetModelLighting(BOX_LEFT, .1,.1,.1)
        if IsComponentHurt(main_hull) then
            render.SetModelLighting(BOX_TOP, 1,0,0)
        else
            render.SetModelLighting(BOX_TOP, 1,1,1)
        end
        render.SetModelLighting(BOX_BOTTOM, .1,.1,.1)
    else
        render.SuppressEngineLighting(false)
    end
end

-- Failsafe to stop lighting from breaking when a client leaves.
function GM:ShutDown()
    render.SuppressEngineLighting(false)
end

-- This is a hack to fix gravity not being predicted correctly.
--[[function GM:SetupMove(ply,mv,cmd)
    if ply.fixgrav then
        local vel = mv:GetVelocity()
        vel.z=vel.z+8
        mv:SetVelocity(vel)
    end
end]]

--[[
net.Receive("airsup_minify", function()
    local ent = net.ReadEntity()

    if IsValid(ent) then
        print("ye")
        local m = Matrix()
        m:Scale(Vector(1,1,1)/64)
        ent:EnableMatrix("RenderMultiply",m)
    end
end)]]


function GM:CalcView(ply, pos, angles, fov)
    if IsValid(MICRO_CONTROLLING) then
        if MICRO_CONTROLLING.controlView then
            local t = MICRO_CONTROLLING:controlView(pos,angles,fov)
            return t
        end
    end
end

hook.Add("HUDPaint","micro_hud",function()
    if !LocalPlayer():Alive() then
        surface.SetDrawColor(Color( 0, 0, 0))
        surface.DrawRect(0, 0, ScrW(), ScrH())
        draw.SimpleText("You will respawn shortly.","DermaLarge",ScrW()/2,ScrH()/2,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    elseif IsValid(MICRO_CONTROLLING) then
        if MICRO_CONTROLLING.controlHUD then
            MICRO_CONTROLLING:controlHUD()
        end
    else
        local tr = LocalPlayer():GetEyeTrace()
        if tr.Fraction < .003 and IsValid(tr.Entity) and tr.Entity.GetMicroHudText then
            local text = tr.Entity:GetMicroHudText()
            local font = "DermaLarge"
            
            surface.SetFont(font)
            local w,h = surface.GetTextSize(text)
            w=w+10
            h=h+10
            draw.RoundedBox(4,(ScrW()-w)/2,(ScrH()-h)/2,w,h,Color(0,0,0,150))
            draw.SimpleText(text,"DermaLarge",ScrW()/2,ScrH()/2,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

        end
    end
end)


function MICRO_SHOW_HELP()
    print("help")
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
        button:SetFont("ChatFont")
        button:SetTextColor(Color(200,200,200))
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