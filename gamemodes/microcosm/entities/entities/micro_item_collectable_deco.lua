--shameless copy-pasta of SkyLight's micro_item_armorkit.lua which was a copy-pasta of Parakeet's micro_item_medkit.lua
--gottem

AddCSLuaFile()

ENT.Base = "micro_item"

ENT.ItemName = "Collectable Decorations Crate"
ENT.ItemModel = "models/Items/item_item_crate.mdl"
ENT.MaxCount = 1

local sound_unpacking = Sound("physics/cardboard/cardboard_box_break1.wav")

local deco = {"models/maxofs2d/gm_painting.mdl","models/props_phx/sp_screen.mdl","models/props/de_cbble/tapestry_c/tapestry_c.mdl",
            "models/props/de_inferno/picture1.mdl","models/props/de_inferno/picture2.mdl","models/props/de_inferno/picture3.mdl","models/props/de_tides/menu_stand.mdl",
            "models/props/de_tides/tides_banner_a.mdl","models/props/de_tides/sign_swinging.mdl","models/props_combine/breenbust.mdl","models/props/cs_office/plant01.mdl"}

function ENT:Use(ply)

    local ent1 = ents.Create("prop_physics")
    ent1:SetModel(deco[math.random(#deco)])
    ent1:SetPos(self:GetPos()+Vector(0,0,64))
    ent1:Spawn()

    self:EmitSound(sound_unpacking)
    self:Remove()
end

--hats
--models/props/cs_office/Snowman_hat.mdl
--models/props/de_tides/vending_hat.mdl
--models/player/items/humans/top_hat.mdl

--csgo
--models/props_signs/sign_horizontal_09.mdl
--models/props_street/garbage_can.mdl
--"models/props/de_cbble/knight_armour/knight_armour.mdl", sad face