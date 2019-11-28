-- Get rid of the doors on Impulse

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs(ents.FindByClass("trigger_teleport")) do
		if(v:GetPos() == Vector(10368, -556, -192)) then
			v:Remove()
		end
		if(v:GetPos() == Vector(10368, -532, -192)) then
			v:Remove()
		end
	end
	for k,v in pairs(ents.FindByClass("func_wall_toggle")) do
		v:Remove()
	end
end