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
            drawviewmodel=true,
            origin=cam_pos,
            angles=cam_ang,
            znear=0.1
        }
        MICRO_DRAW_EXTERNAL = false

        render.SuppressEngineLighting(true)

        render.SetModelLighting(BOX_FRONT, .1,.1,.1)
        render.SetModelLighting(BOX_BACK, .1,.1,.1)
        render.SetModelLighting(BOX_RIGHT, .1,.1,.1)
        render.SetModelLighting(BOX_LEFT, .1,.1,.1)
        render.SetModelLighting(BOX_TOP, 1,1,1)
        render.SetModelLighting(BOX_BOTTOM, .1,.1,.1)
    else
        render.SuppressEngineLighting(false)
    end
end
--[[
Don't think this is needed.
If lighting ever starts to break after disconnect, enable this.

function GM:ShutDown()
    render.SuppressEngineLighting(false)
end]]

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

function GM:HUDPaint()
    if IsValid(MICRO_CONTROLLING) then
        if MICRO_CONTROLLING.controlHUD then
            MICRO_CONTROLLING:controlHUD()
        end
    end
end


function MICRO_SHOW_HELP()
    print("help")
end

function MICRO_SHOW_TEAM()
    local button_spots = {{10,40},{210,40},{10,140},{210,140},[0]={110,90}}

    local panel = vgui.Create("DFrame")
    panel:SetDraggable(false)
    panel:SetSizable(false)
    panel:SetTitle("Team Menu")
    panel:SetSize(320,210)
    panel:Center()
    panel:MakePopup()

    for i=0,4 do
        local button = panel:Add("DButton")
        button:SetFont("ChatFont")
        button:SetTextColor(Color(200,200,200))
        button:SetText(MICRO_TEAM_NAMES[i])
        button:SetPos(button_spots[i][1],button_spots[i][2])
        button:SetSize(100,50)

        function button:Paint(w,h)
            draw.RoundedBox(8,0,0,w,h,MICRO_TEAM_COLORS[i])
        end

        function button:DoClick()
            panel:Close()
            RunConsoleCommand("micro_jointeam",i)
        end
    end
end