AddCSLuaFile()

ENT.Type = "anim"

--function ENT:Initialize()

--end

function ENT:Setup(sound,level)
	self.file = sound
	self.level = level or 75
end

function ENT:Play(pitch)
	pitch = pitch or 100
	if self.sound==nil then
		self.sound = CreateSound(self,self.file)
		self.sound:SetSoundLevel(self.level)
		self.sound:Play()
	end
	self.sound:ChangePitch(pitch)
end

function ENT:Stop()
	if self.sound!=nil then
		self.sound:Stop()
		self.sound = nil
	end
end


function ENT:Draw() end