AddCSLuaFile()

ENT.Base = "micro_item"

ENT.ItemName = "Med Kit"
ENT.ItemModel = "models/items/healthkit.mdl"
ENT.MaxCount = 100

local sound_heal = Sound("items/smallmedkit1.wav")

function ENT:Use(ply)
	local hp_needed = ply:GetMaxHealth() - ply:Health()
	local hp_taken = self:TryTake(hp_needed)

	if hp_taken>0 then
		self:EmitSound(sound_heal)
		ply:SetHealth(ply:Health()+hp_taken)
	end
end