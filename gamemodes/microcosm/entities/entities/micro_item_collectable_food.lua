--shameless copy-pasta of SkyLight's micro_item_armorkit.lua which was a copy-pasta of Parakeet's micro_item_medkit.lua
--gottem

AddCSLuaFile()

ENT.Base = "micro_item"

ENT.ItemName = "Exotic Food"
ENT.ItemModel = "models/Items/BoxMRounds.mdl"
ENT.MaxCount = 100

local sound_eat = Sound("npc/headcrab_fast/headbite.wav")
local sound_unpacking = Sound("physics/cardboard/cardboard_box_break1.wav")

local food = {"models/noesis/donut.mdl","models/slyfo/cup_noodle.mdl","models/slyfo_2/acc_food_meatplate.mdl","models/slyfo_2/acc_food_meatsandwich.mdl",
            "models/slyfo_2/acc_food_meatsandwichhalf.mdl","models/slyfo_2/acc_food_snckspacemix.mdl","models/slyfo_2/acc_food_snckstridernugs.mdl",
            "models/props_junk/watermelon01.mdl","models/props_junk/garbage_takeoutcarton001a.mdl","models/props_junk/garbage_plasticbottle001a.mdl",
            "models/props_junk/PopCan01a.mdl"}


function ENT:Use(ply)
    
    if not self.is_broken then
        self:EmitSound(sound_unpacking)
        self:SetModel(food[math.random(#food)])
        -- im not going to bother with unfucking the collisions for now...
        self.is_broken = true
        return
    end

	local hp_needed = ply:GetMaxHealth() - ply:Health()
	local hp_taken = self:TryTake(hp_needed)

	if hp_taken>0 then
		self:EmitSound(sound_eat)
		ply:SetHealth(ply:Health()+hp_taken)
	end

end

--in by default?
--models/food/burger.mdl
--models/food/hotdog.mdl --free hotdogs mod?