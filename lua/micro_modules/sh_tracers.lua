-- Tracer system. It's okay I guess, although would be nice to get effects fixed.
if SERVER then
	util.AddNetworkString("micro_tracer")
	function SendTracer(type,start,stop)
		net.Start("micro_tracer")
		net.WriteUInt(type,8)
		net.WriteVector(start)
		net.WriteVector(stop)
		net.Broadcast()
	end
else
	local tracers = {}

	net.Receive("micro_tracer",function()
		local type = net.ReadUInt(8)
		local start = net.ReadVector()
		local stop = net.ReadVector()

		tracers[{type,start,stop}]=0
	end)

	local matShot = Material("trails/laser")

	function GM:PostDrawOpaqueRenderables(depth,sky)
		if (MICRO_DRAW_EXTERNAL or not IsValid(Entity(MICRO_SHIP_ID or -1))) and not sky then
			render.SetMaterial(matShot)
			for k,v in pairs(tracers) do

				local type,start,stop = k[1],k[2],k[3]

				local d = start:Distance(stop)

				local start2 = LerpVector(math.max(v-100/d,0),start,stop)
				local stop2 = LerpVector(v,start,stop)

				local color
				if type==1 then
					color = Color(255,100,0)
				elseif type==2 then
					color = Color(0,255,255)
				elseif type==3 then
					color = Color(255,0,255)
				end

				render.StartBeam(2)
				render.AddBeam(start2,4,0, color)
				render.AddBeam(stop2,4,1, color)
				render.EndBeam()

				if v>1 then
					tracers[k]=nil
				else
					tracers[k]=v + 2000*FrameTime()/d
				end
			end
		end
	end
end