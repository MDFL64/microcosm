--shameless copy-pasta of Parakeet's micro_item_medkit.lua

AddCSLuaFile()

ENT.Base = "micro_item"

ENT.ItemName = "Armor Kit"
ENT.ItemModel = "models/items/battery.mdl"
ENT.MaxCount = 200
 
local sound_armorup = Sound("items/battery_pickup.wav")

function ENT:Use(ply)
  local armor_needed = 200 - ply:Armor()
  local armor_taken = self:TryTake(armor_needed)

  if armor_taken>0 then
    self:EmitSound(sound_armorup)
    ply:SetArmor(ply:Armor()+armor_taken)
  end
end