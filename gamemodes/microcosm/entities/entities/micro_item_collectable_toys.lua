--shameless copy-pasta of SkyLight's micro_item_armorkit.lua which was a copy-pasta of Parakeet's micro_item_medkit.lua
--gottem

AddCSLuaFile()

ENT.Base = "micro_item"

ENT.ItemName = "Collectable Toy Crate"
ENT.ItemModel = "models/Items/item_item_crate.mdl"
ENT.MaxCount = 1

local sound_unpacking = Sound("items/battery_pickup.wav")

local toys = {"models/XQM/Rails/gumball_1.mdl","models/props_phx/misc/soccerball.mdl","models/balloons/balloon_dog.mdl","models/maxofs2d/companion_doll.mdl",
            "models/maxofs2d/hover_rings.mdl","models/props/de_tides/vending_turtle.mdl"}

function ENT:Use(ply)

    local ent2 = ents.Create("prop_physics")
    ent2:SetModel(toys[math.random(#toys)])
    ent2:SetPos(self:GetPos()+Vector(0,0,40))
    ent2:SetColor(Color(math.random(255), math.random(255), math.random(255)))
    ent2:Spawn()

    self:EmitSound(sound_unpacking)
    self:Remove()
end

--toys
--models/props/cs_office/radio.mdl
--models/props_lab/citizenradio.mdl

--in by default?
--models/items/cs_gift.mdl
--models/katharsmodels/present/type-2/big/present2.mdl
--models/dynamite/dynamite.mdl

--csgo
--models/props_fairgrounds/elephant.mdl
--models/props_fairgrounds/giraffe.mdl