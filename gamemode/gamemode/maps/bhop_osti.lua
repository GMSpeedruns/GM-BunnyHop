-- Gets rid of silly doors on Osti

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs(ents.FindByClass("func_door")) do
		local pos = v:GetPos()
		if(pos.x == -1873 && pos.z == 1137) then
			v:Remove()
		end
	end
end