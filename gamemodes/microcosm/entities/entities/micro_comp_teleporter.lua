--[[
.___________. __    __   _______    ____    __    ____  ___________    __    ____  _______     _______.___________.    __          ___       _______  
|           ||  |  |  | |   ____|   \   \  /  \  /   / |   ____\   \  /  \  /   / |   ____|   /       |           |   |  |        /   \     |       \ 
`---|  |----`|  |__|  | |  |__       \   \/    \/   /  |  |__   \   \/    \/   /  |  |__     |   (----`---|  |----`   |  |       /  ^  \    |  .--.  |
    |  |     |   __   | |   __|       \            /   |   __|   \            /   |   __|     \   \       |  |        |  |      /  /_\  \   |  |  |  |
    |  |     |  |  |  | |  |____       \    /\    /    |  |____   \    /\    /    |  |____.----)   |      |  |        |  `----./  _____  \  |  '--'  |
    |__|     |__|  |__| |_______|       \__/  \__/     |_______|   \__/  \__/     |_______|_______/       |__|        |_______/__/     \__\ |_______/ 
                                                                                                                                                      
 _______ .______    __       _______.  ______    _______   _______     __                                                                             
|   ____||   _  \  |  |     /       | /  __  \  |       \ |   ____|   /_ |                                                                            
|  |__   |  |_)  | |  |    |   (----`|  |  |  | |  .--.  ||  |__       | |                                                                            
|   __|  |   ___/  |  |     \   \    |  |  |  | |  |  |  ||   __|      | |                                                                            
|  |____ |  |      |  | .----)   |   |  `--'  | |  '--'  ||  |____     | |                                                                            
|_______|| _|      |__| |_______/     \______/  |_______/ |_______|    |_|                                                                            
                                                                                                                                                      
 ____  _______ .__   __.   _______     _______   __    __  .______    ____                                                                            
|    ||   ____||  \ |  |  /  _____|   |       \ |  |  |  | |   _  \  |    |                                                                           
|  |-`|  |__   |   \|  | |  |  __     |  .--.  ||  |  |  | |  |_)  | `-|  |                                                                           
|  |  |   __|  |  . `  | |  | |_ |    |  |  |  ||  |  |  | |   _  <    |  |                                                                           
|  |  |  |____ |  |\   | |  |__| |    |  '--'  ||  `--'  | |  |_)  |   |  |                                                                           
|  |-.|_______||__| \__|  \______|    |_______/  \______/  |______/  .-|  |                                                                           
|____|                                                               |____|
--]]

-- SCENE 1: The Rekening
-- [inside Parakeet's secrete programming lab. Hours 2:40am.]

-- [Parakeet sits at his computer in the korner of the empty room watching his chinese cartoons by 4̶c̶h̶a̶n̶  4kids tv]
-- [SkyLight slams the door open]
-- [enter Sky]
-- [the big bang theory crowd laught]
-- Sky: Parakeet! this is genji's (new) teleporter!  it's the nearly working remix!
-- [Pair of Feet turns to face]
-- Parakeet: what to fuckl?
-- [crownd lauff]
-- Sky: thumbs up if u no the real genji or are a nympho!!!
--[[ [Sky thumbs up] Visual Representation:
            _
           /(|
          (  :
         __\  \  _____
       (____)  `|  
      (____)|   |  6
       (____).__|  9
        (___)__.|_____
--]]
-- Sky: if i'm going to program genji's telepotty it's gonna have memeshit plastered all over the code!!
-- Sky: note: making genji's teleporter is great way to make parakeet upsetti spaghettis!! :) Not as effective as genji's reflect tho! winkie face
-- [Ski winks at Parachute]
-- [crowd laughing again]
-- Parakeet: r u sure ur not a homosex?
-- [scene fades to african-american and crowd keeps laughing long time until quiet.]

AddCSLuaFile()

DEFINE_BASECLASS("micro_component")
ENT.Base = "micro_component"

ENT.ComponentModel = "models/props_wasteland/interior_fence002e.mdl"
ENT.ComponentScreenWidth = 180
ENT.ComponentScreenHeight = 45
ENT.ComponentScreenOffset = Vector(24,-22.5,46)
ENT.ComponentScreenRotation = Angle(0,90,90)


--local sound_add = Sound("ambient/levels/canals/windchime2.wav") --sik meme
local sound_buy = Sound("ambient/levels/citadel/weapon_disintegrate2.wav")
local team_ply_origin = Vector(0,0,0)
local player_at_home = true

function ENT:GetComponentName()
	return "Teleporter"
end

function ENT:Initialize()
	BaseClass.Initialize(self)
end

--so the problem with this, is that it will keep teleportering the player back and forth.  It'll go to team 2, then back to team 1, then to team 4. 

-- SEEN 2: 5NITES@GAZEBOOK.com
-- [parakeet is on facebook reading his wall and spots rare fazebook telephone post. Hours 12:00am high nude]
-- Sky: Please stop praying for genij's tekeporter!!! it is too strong and has escaped the hospital!! it too powerful!!!! (the teleporter's range needs to be limited)
-- [parakeet looks into camera that is on compute all weird like]
-- [laughing sounds]
-- [scene end]

function ENT:Use(ply)
	--AYYYYY

	if not self:IsBroken() then
		local team_number = 0

		print( team.GetName( Entity( 1 ):Team() ) )
		if team.GetName( Entity( 1 ):Team() ) == "Red" then
			team_number = 1
		elseif team.GetName( Entity( 1 ):Team() ) == "Green" then
			team_number = 2
		elseif team.GetName( Entity( 1 ):Team() ) == "Blue" then
			team_number = 3
		elseif team.GetName( Entity( 1 ):Team() ) == "Yellow" then
			team_number = 4
		end
		--print(team_number)
		for i,origin_ent in pairs(ents.FindByName("micro_ship_*")) do
			local micro_ship_origin = origin_ent:GetPos()
			-- SEAN 3: DEBUGGING
			-- [group arrives at construction site with hard (hats) on. hours 8:08am.]
			-- [group look confuse on face]
			-- [group turn and leave]
			-- [cut to commercial. then when they get back show credits.]

			--print(ship)
			--print(micro_ship_origin)

			--so the coords are each origin+-200,0,0
			--print(team)
			if player_at_home && i != team_number then --check to see if any are in range. maybe edit micro_ship for a function to check if far away.
				print("teleaway "..i)
				team_ply_origin = ply:GetPos()
				ply:SetPos(micro_ship_origin)
				player_at_home = false
			elseif not player_at_home then --same as above
				print("telehome "..i)
				ply:SetPos(team_ply_origin)
				player_at_home = true
			end
		end
	end
end

--[[
local tr = util.TraceLine{start=self:GetPos(),endpos=self:GetPos()+Vector(0,0,-30),filter=self}
	self:SetIsHome(tr.Entity==self.home)
--]]

function ENT:CheckBlocked()
	local r = 18
	local tr = util.TraceHull{start=self:GetItemSpawn(),endpos=self:GetItemSpawn(),mins=Vector(-1,-1,-1)*r, maxs=Vector(1,1,1)*r, filter=self}
	return tr.Hit
end

if CLIENT then
	function ENT:GetScreenText()
		local ship = self:GetShipInfo().entity
		local hurt = self:IsBroken()

		if hurt then
			return "HONK!",Color(255,0,255)
		elseif self:CheckBlocked() then
			return "Blocked",Color(255,0,0)
		elseif ship:GetIsHome() then
			return "Ready",Color(0,255,0)
		else
			return "Not Docked",Color(255,0,0)
		end
	end
end
                                                                                                                                                                                                 
--[[  KREDITS                                                                                                                                                                                                  
BBBBBBBBBBBBBBBBB   YYYYYYY       YYYYYYY                                                                                                                                                             
B::::::::::::::::B  Y:::::Y       Y:::::Y                                                                                                                                                             
B::::::BBBBBB:::::B Y:::::Y       Y:::::Y                                                                                                                                                             
BB:::::B     B:::::BY::::::Y     Y::::::Y                                                                                                                                                             
  B::::B     B:::::BYYY:::::Y   Y:::::YYY                                                                                                                                                             
  B::::B     B:::::B   Y:::::Y Y:::::Y    ::::::                                                                                                                                                      
  B::::BBBBBB:::::B     Y:::::Y:::::Y     ::::::                                                                                                                                                      
  B:::::::::::::BB       Y:::::::::Y      ::::::                                                                                                                                                      
  B::::BBBBBB:::::B       Y:::::::Y                                                                                                                                                                   
  B::::B     B:::::B       Y:::::Y                                                                                                                                                                    
  B::::B     B:::::B       Y:::::Y                                                                                                                                                                    
  B::::B     B:::::B       Y:::::Y        ::::::                                                                                                                                                      
BB:::::BBBBBB::::::B       Y:::::Y        ::::::                                                                                                                                                      
B:::::::::::::::::B     YYYY:::::YYYY     ::::::                                                                                                                                                      
B::::::::::::::::B      Y:::::::::::Y                                                                                                                                                                 
BBBBBBBBBBBBBBBBB       YYYYYYYYYYYYY                                                                                                                                                                 



                                           tttt         hhhhhhh                                          tttt            iiii                                                                         
                                        ttt:::t         h:::::h                                       ttt:::t           i::::i                                                                        
                                        t:::::t         h:::::h                                       t:::::t            iiii                                                                         
                                        t:::::t         h:::::h                                       t:::::t                                                                                         
  aaaaaaaaaaaaa      ssssssssss   ttttttt:::::ttttttt    h::::h hhhhh           eeeeeeeeeeee    ttttttt:::::ttttttt    iiiiiii     cccccccccccccccc                                                   
  a::::::::::::a   ss::::::::::s  t:::::::::::::::::t    h::::hh:::::hhh      ee::::::::::::ee  t:::::::::::::::::t    i:::::i   cc:::::::::::::::c                                                   
  aaaaaaaaa:::::ass:::::::::::::s t:::::::::::::::::t    h::::::::::::::hh   e::::::eeeee:::::eet:::::::::::::::::t     i::::i  c:::::::::::::::::c                                                   
           a::::as::::::ssss:::::stttttt:::::::tttttt    h:::::::hhh::::::h e::::::e     e:::::etttttt:::::::tttttt     i::::i c:::::::cccccc:::::c                                                   
    aaaaaaa:::::a s:::::s  ssssss       t:::::t          h::::::h   h::::::he:::::::eeeee::::::e      t:::::t           i::::i c::::::c     ccccccc                                                   
  aa::::::::::::a   s::::::s            t:::::t          h:::::h     h:::::he:::::::::::::::::e       t:::::t           i::::i c:::::c                                                                
 a::::aaaa::::::a      s::::::s         t:::::t          h:::::h     h:::::he::::::eeeeeeeeeee        t:::::t           i::::i c:::::c                                                                
a::::a    a:::::assssss   s:::::s       t:::::t    tttttth:::::h     h:::::he:::::::e                 t:::::t    tttttt i::::i c::::::c     ccccccc                                                   
a::::a    a:::::as:::::ssss::::::s      t::::::tttt:::::th:::::h     h:::::he::::::::e                t::::::tttt:::::ti::::::ic:::::::cccccc:::::c                                                   
a:::::aaaa::::::as::::::::::::::s       tt::::::::::::::th:::::h     h:::::h e::::::::eeeeeeee        tt::::::::::::::ti::::::i c:::::::::::::::::c                                                   
 a::::::::::aa:::as:::::::::::ss          tt:::::::::::tth:::::h     h:::::h  ee:::::::::::::e          tt:::::::::::tti::::::i  cc:::::::::::::::c                                                   
  aaaaaaaaaa  aaaa sssssssssss              ttttttttttt  hhhhhhh     hhhhhhh    eeeeeeeeeeeeee            ttttttttttt  iiiiiiii    cccccccccccccccc                                                   

								  meme

                                                                     dddddddd                                                                                                                         
                                                                     d::::::d                                               tttt            iiii                                                      
                                                                     d::::::d                                            ttt:::t           i::::i                                                     
                                                                     d::::::d                                            t:::::t            iiii                                                      
                                                                     d:::::d                                             t:::::t                                                                      
ppppp   ppppppppp   rrrrr   rrrrrrrrr      ooooooooooo       ddddddddd:::::d uuuuuu    uuuuuu      ccccccccccccccccttttttt:::::ttttttt    iiiiiii    ooooooooooo   nnnn  nnnnnnnn        ssssssssss   
p::::ppp:::::::::p  r::::rrr:::::::::r   oo:::::::::::oo   dd::::::::::::::d u::::u    u::::u    cc:::::::::::::::ct:::::::::::::::::t    i:::::i  oo:::::::::::oo n:::nn::::::::nn    ss::::::::::s  
p:::::::::::::::::p r:::::::::::::::::r o:::::::::::::::o d::::::::::::::::d u::::u    u::::u   c:::::::::::::::::ct:::::::::::::::::t     i::::i o:::::::::::::::on::::::::::::::nn ss:::::::::::::s 
pp::::::ppppp::::::prr::::::rrrrr::::::ro:::::ooooo:::::od:::::::ddddd:::::d u::::u    u::::u  c:::::::cccccc:::::ctttttt:::::::tttttt     i::::i o:::::ooooo:::::onn:::::::::::::::ns::::::ssss:::::s
 p:::::p     p:::::p r:::::r     r:::::ro::::o     o::::od::::::d    d:::::d u::::u    u::::u  c::::::c     ccccccc      t:::::t           i::::i o::::o     o::::o  n:::::nnnn:::::n s:::::s  ssssss 
 p:::::p     p:::::p r:::::r     rrrrrrro::::o     o::::od:::::d     d:::::d u::::u    u::::u  c:::::c                   t:::::t           i::::i o::::o     o::::o  n::::n    n::::n   s::::::s      
 p:::::p     p:::::p r:::::r            o::::o     o::::od:::::d     d:::::d u::::u    u::::u  c:::::c                   t:::::t           i::::i o::::o     o::::o  n::::n    n::::n      s::::::s   
 p:::::p    p::::::p r:::::r            o::::o     o::::od:::::d     d:::::d u:::::uuuu:::::u  c::::::c     ccccccc      t:::::t    tttttt i::::i o::::o     o::::o  n::::n    n::::nssssss   s:::::s 
 p:::::ppppp:::::::p r:::::r            o:::::ooooo:::::od::::::ddddd::::::ddu:::::::::::::::uuc:::::::cccccc:::::c      t::::::tttt:::::ti::::::io:::::ooooo:::::o  n::::n    n::::ns:::::ssss::::::s
 p::::::::::::::::p  r:::::r            o:::::::::::::::o d:::::::::::::::::d u:::::::::::::::u c:::::::::::::::::c      tt::::::::::::::ti::::::io:::::::::::::::o  n::::n    n::::ns::::::::::::::s 
 p::::::::::::::pp   r:::::r             oo:::::::::::oo   d:::::::::ddd::::d  uu::::::::uu:::u  cc:::::::::::::::c        tt:::::::::::tti::::::i oo:::::::::::oo   n::::n    n::::n s:::::::::::ss  
 p::::::pppppppp     rrrrrrr               ooooooooooo      ddddddddd   ddddd    uuuuuuuu  uuuu    cccccccccccccccc          ttttttttttt  iiiiiiii   ooooooooooo     nnnnnn    nnnnnn  sssssssssss    
 p:::::p                                                                                                                                                                                              
 p:::::p                                                                                                                                                                                              
p:::::::p                                                                                                                                                                                             
p:::::::p                                                                                                                                                                                             
p:::::::p                                                                                                                                                                                             
ppppppppp
--]]