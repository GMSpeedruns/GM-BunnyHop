__HOOK[ "InitPostEntity" ] = function()
	-- Get the current value
	local opt = Core.GetMapVariable( "Options" )
	
	-- Get the list
	local list = Core.GetMapVariable( "OptionList" )
	
	-- Add our custom option
	opt = bit.bor( opt, list.NoSpeedLimit )
	
	-- Set the variable
	Core.SetMapVariable( "Options", opt )
	
	-- Finally reload the options
	Core.ReloadMapOptions()
end