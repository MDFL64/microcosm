AddCSLuaFile()

ENT.Type = "anim"

local sound_fire = Sound("weapons/ar2/fire1.wav")
local sound_fire_hook = Sound("weapons/crossbow/fire1.wav")
local sound_fire_hook_nope = Sound("buttons/button2.wav")
local sound_fire_use = Sound("weapons/airboat/airboat_gun_lastshot1.wav")
local sound_empty = Sound("weapons/ar2/ar2_empty.wav")
local sound_select = Sound("weapons/shotgun/shotgun_cock.wav")

ENT.Ammo1Max = 200
ENT.Ammo2Max = 4
ENT.Ammo3Max = 4

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "GunName")
    
    self:NetworkVar("Int", 0, "SelectedAmmo")
    self:NetworkVar("Int", 1, "Ammo1")
    self:NetworkVar("Int", 2, "Ammo2")
    self:NetworkVar("Int", 3, "Ammo3")

    self:NetworkVar("Bool", 0,"HookTooFar")
	--self:NetworkVar("Float", 0, "Throttle")
	--self:NetworkVar("Bool", 0, "IsHome")
end

function ENT:Initialize()
    self:SetModel("models/smallbridge/ship parts/sbhulldsp.mdl")

	self:PhysicsInitStandard()

    if SERVER then
        self:GetPhysicsObject():EnableMotion(false)
        self:SetUseType(SIMPLE_USE)

        self.gun = ents.Create("prop_dynamic")
        self.gun:SetModel("models/slyfo/rover_snipercannon.mdl")
        self.gun:SetPos(self:LocalToWorld(Vector(0,50,50)))
        self.gun:Spawn()

        self:SetSelectedAmmo(1)
        self:SetAmmo1(self.Ammo1Max)
        self:SetAmmo2(self.Ammo2Max)
        self:SetAmmo3(self.Ammo3Max)

        self.next_fire = 0
        self.next_select = 0
    end
end

function ENT:Use(activator, caller, useType, value)
    if not IsValid(self.controller) then
        caller:ProxyControls(self)
        self.controller = caller
    else
        self:EmitSound("buttons/button11.wav")
    end
end

function ENT:sendControls(buttons,angs)
    local tr = util.TraceLine{start=self.gun:GetPos(),endpos=self.gun:GetPos()+angs:Forward()*10000,filter=self}
    
    if bit.band(buttons,IN_FORWARD)!=0 and CurTime()>self.next_select then
        if self:GetSelectedAmmo()==1 then
            self:SetSelectedAmmo(3)
        else
            self:SetSelectedAmmo(self:GetSelectedAmmo()-1)
        end
        sound.Play(sound_select,self.gun:GetPos(),75,150,1)
        self.next_select = CurTime()+.3
    end

    if bit.band(buttons,IN_BACK)!=0 and CurTime()>self.next_select then
        self:SetSelectedAmmo(self:GetSelectedAmmo()%3+1)
        sound.Play(sound_select,self.gun:GetPos(),75,150,1)
        self.next_select = CurTime()+.3
    end
    
    if tr.Entity:IsWorld() then
        self.gun:SetAngles(angs)
        self.fire = bit.band(buttons,IN_ATTACK)!=0
    else
        self.fire = false
    end
end

function ENT:Think()
    if SERVER then
        if self.fire and CurTime()>self.next_fire then
            local origin = self.ship:GetInternalOrigin()

            local real_pos = self.ship:GetPos()
            local real_ang = self.ship:GetAngles()

            local start_pos,start_ang = LocalToWorld((self.gun:GetPos()+self.gun:GetAngles():Forward()*150-origin)*MICRO_SCALE,self.gun:GetAngles(),real_pos,real_ang)
            
            if self:GetSelectedAmmo()==1 then
                if self:GetAmmo1()>0 then
                    sound.Play(sound_fire,self.gun:GetPos(),75,50,1)
                    
                    self:SetAmmo1(self:GetAmmo1()-1)

                    self.ship:FireBullets{
                        Src=start_pos,
                        Dir=start_ang:Forward(),
                        Spread=Vector(.03,.03,.03),
                        Damage=10,
                        Tracer=0,
                        Callback=function(attacker,tr,dmg)
                            SendTracer(1,tr.StartPos,tr.HitPos)
                        end
                    }
                else
                    sound.Play(sound_empty,self.gun:GetPos(),75,50,1)
                end
                self.next_fire = CurTime()+.1
            elseif self:GetSelectedAmmo()==2 then
                if self:GetAmmo2()>0 then

                    local tr = util.TraceLine{start=start_pos,endpos=start_pos+start_ang:Forward()*200,filter=self.ship}

                    --if tr.HitWorld then
                    --    tr.Entity = game.GetWorld()
                    --    print(tr.Entity)
                    --end
                    if IsValid(tr.Entity) or tr.Entity:IsWorld() then
                        sound.Play(sound_fire_hook,self.gun:GetPos(),75,150,1)
                        tr.Entity:Use(self.ship,self.ship,USE_ON,1)
                        self:SetAmmo2(self:GetAmmo2()-1)

                        local pos1 = self.ship:GetPos()
                        local pos2 = tr.HitPos

                        local rope_len = pos1:Distance(pos2)

                        local a,b = constraint.Rope(self.ship,tr.Entity,0,0,self.ship:WorldToLocal(pos1),tr.Entity:WorldToLocal(pos2),rope_len,0,0,.1,"cable/cable2.vmt",false)
                        if a then table.insert(self.ship.hook_ents,a) end
                        if b then table.insert(self.ship.hook_ents,b) end
                        self.ship:SetIsHooked(true)
                    else
                        sound.Play(sound_fire_hook_nope,self.gun:GetPos(),75,100,1)
                        self:SetHookTooFar(true)
                        timer.Simple(.8,function()
                            if IsValid(self) then
                                self:SetHookTooFar(false)
                            end
                        end)
                    end
                else
                    sound.Play(sound_empty,self.gun:GetPos(),75,50,1)
                end
                self.next_fire = CurTime()+1
            elseif self:GetSelectedAmmo()==3 then
                if self:GetAmmo3()>0 then
                    sound.Play(sound_fire_use,self.gun:GetPos(),75,100,1)

                    local tr = util.TraceLine{start=start_pos,endpos=start_pos+start_ang:Forward()*10000,filter=self.ship}
                    if IsValid(tr.Entity) then
                        tr.Entity:Use(self.ship,self.ship,USE_ON,1)
                    end
                    SendTracer(2,tr.StartPos,tr.HitPos)

                    self:SetAmmo3(self:GetAmmo3()-1)
                else
                    sound.Play(sound_empty,self.gun:GetPos(),75,50,1)
                end
                self.next_fire = CurTime()+1
            end
        end
        
        self:NextThink( CurTime() )
	    return true
    end
end

function ENT:stopControl()
    self.controller = nil
    --self.fire=false
end

function ENT:controlView(pos,angles,fov)
    local view = {}
    view.origin = self:LocalToWorld(Vector(0,-10,100))
    view.angles = angles
    view.fov = fov
    view.drawviewer = true
    return view
end

function ENT:controlHUD()
    local matrix = Matrix()
    matrix:Translate(Vector(ScrW()-400,ScrH()-200,0))
    matrix:Scale(Vector(2,2,2))
    cam.PushModelMatrix(matrix)
    self:drawInfo()
    cam.PopModelMatrix()
end

function ENT:Draw()

    self:DrawModel()

    cam.Start3D2D(self:LocalToWorld(Vector(-50,0,0)),self:GetAngles()+Angle(0,0,80), .5 )
        self:drawInfo()
    cam.End3D2D()
end

function ENT:drawInfo()
    local ship = Entity(MICRO_SHIP_ID or -1)

    local ship = Entity(MICRO_SHIP_ID or -1)
    if IsValid(ship) then
        local color = ship:GetColor()

        surface.SetDrawColor(Color( 0, 0, 0))
        surface.DrawRect( 0, 0, 200, 100 )

        surface.SetDrawColor(color)
        surface.DrawOutlinedRect(0,0,200,100)

        draw.SimpleText(self:GetGunName().." CANNON","DermaDefault",100,12,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        

            draw.SimpleText("->","DermaDefault",5,12+20*self:GetSelectedAmmo(),color,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

            draw.SimpleText("STANDARD SHELLS: "..self:GetAmmo1().." / "..self.Ammo1Max,"DermaDefault",20,32,Color(255,100,0),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
            
            if self:GetHookTooFar() then
                draw.SimpleText("HOOK OUT OF RANGE","DermaDefault",20,52,Color(255,0,0),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
            else
                draw.SimpleText("HOOK SHELLS: "..self:GetAmmo2().." / "..self.Ammo2Max,"DermaDefault",20,52,Color(100,100,100),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
            end

            draw.SimpleText("USE SHELLS: "..self:GetAmmo3().." / "..self.Ammo3Max,"DermaDefault",20,72,Color(0,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

    end
end