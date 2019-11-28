-- Addable stamina system for KZ maps

function ToggleStamina( ply )
	if ply.Style == Core.Config.Style.Legit or ply.Style == Core.Config.Style.Stamina then
		return "CommandFrictionStyles"
	else
		local bool = ply:EnableStamina( not ply.StaminaUse )
		return "CommandFrictionToggle", bool and "enabled" or "disabled"
	end
end