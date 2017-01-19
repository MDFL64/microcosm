--[[
todo:	(Help me) There is an error when you're not on a team and have not yet joined each team.
			To get around this you have to join each team once.
		(Help me) Make it so teleporter sound only plays once
		add teleporter animation?  Like, a bunch of blue text that fills up its client display box.
		(We, in sh_shipinfo.lua) add location for UFO? Normal one could be:
		local tele = ents.Create("micro_comp_teleporter")
		tele:SetPos(micro_ship_origin+Vector(-200,-225,0)) --when facing forward, this is in the lower, back, right of the ship
		tele:Spawn()
--]]

AddCSLuaFile()

DEFINE_BASECLASS("micro_component")
ENT.Base = "micro_component"

ENT.ComponentModel = "models/props_wasteland/interior_fence002e.mdl"
ENT.ComponentScreenWidth = 230 --180
ENT.ComponentScreenHeight = 100 --90
ENT.ComponentScreenOffset = Vector(2,-27,55)
ENT.ComponentScreenRotation = Angle(0,90,90)

local sound_in_range = Sound("npc/overwatch/radiovoice/preparetoreceiveverdict.wav")

--variables to change for gameplay
local max_teleport_distance = 125
local teleporter_origin_fix = Vector(0,0,-128) --vector to be added to the origin of the teleporter's prop. Set manually :\
--end variables to change for gameplay

function ENT:GetComponentName()
	return "Teleporter"
end

function ENT:Initialize()
	BaseClass.Initialize(self)
	self.which_tele_is_closest = 0
	self.teleporter_distance = 0
	self.teleporter_distance_closest = 9999999
	self.is_within_range = false
	self.is_Home = true
	self.teleporter_guide_of_closest = {}
	for i=1,#MICRO_SHIP_INFO do
    	self.teleporter_guide_of_closest[i] = 0
	end
	local teleporter_entid = {}
	for i=1,#MICRO_SHIP_INFO do
    	teleporter_entid[i] = self:EntIndex()
    end
	local teleporter_pos = {}
    for i=1,#MICRO_SHIP_INFO do --i to be the ent index
    	teleporter_pos[i] = Vector(0,0,0)
    end
	--self:EntIndex()
	--self:GetPos()
	local teleporter_info = {}
    for i=1,#MICRO_SHIP_INFO do --i will be ship number, j will be entid, result will be teleporter position
		teleporter_info[i] = {}
		for j=1,#MICRO_SHIP_INFO do
			teleporter_info[i][j] = Vector(0,0,0)
		end
    end

end

function ENT:Use(ply)
	if not self:IsBroken() then
		print("It's ja boy's team! ".. ply:Team())
		if not is_Home then
			--maybe get each other teleporters in an array and get that one's position instead
			ply:SetPos(self.teleporter_pos[ply:Team()]+teleporter_origin_fix)
			is_Home = true
			print("TELEPORT HOMEO")
		elseif is_Home then
			print("TELESNORT AWAYWAYS ".. self.teleporter_pos[self.teleporter_guide_of_closest[ply:Team()]])
			ply:SetPos(self.teleporter_pos[self.teleporter_guide_of_closest[ply:Team()]]+teleporter_origin_fix)
			--ply:SetPos(MICRO_SHIP_INFO[self.teleporter_guide_of_closest[ply:Team()]].origin)
			is_Home = false
		end
	end
end

function ENT:Think()
	--get smallest distance away
	--7:17 AM - 0x5f3759df: you can use ent:GetShipInfo()
	--7:18 AM - 0x5f3759df: to get the ship info a player or entity is on
	
	if CLIENT then return end

	teleporter_distance_closest = 9999999
	--print("cancer cycle, start ************************************************************************************")
	for t=1,#MICRO_SHIP_INFO do --is really team number, hence t
		for i=1,#MICRO_SHIP_INFO do
			teleporter_distance = MICRO_SHIP_INFO[t].entity:GetPos():Distance(MICRO_SHIP_INFO[i].entity:GetPos()) --derps if you do not go to each ship.
			if teleporter_distance > 0 then --way easier than getting team number xD
				if teleporter_distance < max_teleport_distance && teleporter_distance <= teleporter_distance_closest then
					teleporter_distance_closest = teleporter_distance
					--print("telepoter distance closet "..teleporter_distance_closest)
					self.teleporter_guide_of_closest[t] = i
					is_within_range = true
					--print("tele guide info ".. self.teleporter_guide_of_closest[t])
				elseif is_within_range && teleporter_distance_closest >= max_teleport_distance then
					is_within_range = false
					self.teleporter_guide_of_closest[t] = 0
				end
			end
		end
	end
	--probably want to change or remove this if statement entirely. it makes it so the sound continously plays when in range...
	if teleporter_distance_closest <= max_teleport_distance then --use a flag? another instance variable of the entity
		self:EmitSound(sound_in_range)
	end
end

function ENT:isInRange()
	--print("IS IN RANGE CHECEK>>>>".. teleporter_distance_closest)
	--return teleporter_distance_closest <= max_teleport_distance

end

if CLIENT then --make network variable for isInRange, you can get and set it automatically!
	function ENT:GetScreenText()
		local ship = self:GetShipInfo().entity
		local hurt = self:IsBroken()

		if hurt then
			return "Genij place telepoty?",Color(255,0,255)
		elseif ship:GetIsHome() then
			return "Home",Color(0,255,0)
		elseif self:isInRange() then
			return "In Range",Color(0,255,0)
		else
			return "Not In Range",Color(255,0,0)
		end
	end
end

function ENT:drawInfo(ship,broken)
	local text,text_color = self:GetScreenText()
	draw.SimpleText(text,"micro_big",115,80,text_color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

--[[
same as
<16:49:11> "[parakeet] rerr^": function ENT:GetComponentName()
<16:49:20> "[parakeet] rerr^": function ENT.GetComponentName(self)

--]]