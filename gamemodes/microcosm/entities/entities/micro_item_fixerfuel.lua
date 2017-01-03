AddCSLuaFile()

ENT.Base = "micro_item"

ENT.ItemName = "Fixer Fuel"
ENT.ItemModel = "models/items/car_battery01.mdl"
ENT.MaxCount = 100

local sound_charge = Sound("items/battery_pickup.wav")

function ENT:Use(ply)
    local fixer = ply:GetWeapon("micro_fixer")

    if IsValid(fixer) then
        local fuel_needed = fixer.Primary.ClipSize - fixer:Clip1()
        local fuel_taken = self:TryTake(fuel_needed)

        if fuel_taken>0 then
            self:EmitSound(sound_charge)
            fixer:SetClip1(fixer:Clip1()+fuel_taken)
        end
    end
end