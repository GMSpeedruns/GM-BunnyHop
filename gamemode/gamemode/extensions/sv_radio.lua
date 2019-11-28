-- Define config variables
Core.Config.Var.Add( "RadioYouTube", "radio_link", "", "The link to the YouTube handler of the radio\n - This must be setup on a webserver manually" )
Core.Config.Var.Add( "RadioKeyGoogle", "radio_key_google", "", "The Google Developer Console API key" )
Core.Config.Var.Add( "RadioKeySoundcloud", "radio_key_soundcloud", "", "The Soundcloud Developer API key" )
Core.Config.Var.Add( "RadioLimitSearch", "radio_limit_search", 25, "Amount of items to display when searching YouTube or Soundcloud" )
Core.Config.Var.Add( "RadioLimitFetch", "radio_limit_fetch", 25, "Amount of recently added items to display when the radio is opened" )
Core.Config.Var.Add( "RadioLimitQuery", "radio_limit_query", 50, "Amount of results to display on a search query against the radio table" )

-- Define the base table
local Radio = {}
Radio.Opened = {}
Radio.Volume = {}
Radio.Tuned = {}
Radio.Limits = { Search = Core.Config.Var.GetInt( "RadioLimitSearch" ), Fetch = Core.Config.Var.GetInt( "RadioLimitFetch" ), Query = Core.Config.Var.GetInt( "RadioLimitQuery" ) }
Radio.SQL, Radio.Net = SQLPrepare, Core.Prepare
Radio.IP = ""

-- All used radio paths and formats
Radio.Path = {
	YouTubePlayer = Core.Config.Var.Get( "RadioYouTube" ),
	SoundcloudPlayer = "https://api.soundcloud.com/tracks/%s/stream?client_id=%s",
	GoogleSearch = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=%s&maxResults=%d&order=viewCount&type=video&key=%s&userIp=%s",
	SoundcloudSearch = "https://api.soundcloud.com/tracks?q=%s&limit=%d&client_id=%s",
	GoogleDetails = "https://www.googleapis.com/youtube/v3/videos?id=%s&part=snippet,contentDetails&key=%s&userIp=%s",
	SoundcloudDetails = "https://api.soundcloud.com/tracks/%s?client_id=%s",
	SoundcloudResolve = "https://api.soundcloud.com/resolve/?url=%s&client_id=%s"
}

-- API keys
Radio.Keys = {
	Google = Core.Config.Var.Get( "RadioKeyGoogle" ),
	Soundcloud = Core.Config.Var.Get( "RadioKeySoundcloud" )
}


--[[
	Description: Initializes the racing system
--]]
function Radio.Init()
	-- Check if settings are good
	if Radio.Path.YouTubePlayer == "" or Radio.Keys.Google == "" or Radio.Keys.Soundcloud == "" then
		return Core.PrintC( "[Startup] Failed to load extension 'radio': not correctly configured" )
	end

	-- Get the main IP
	Radio.IP = GetConVar( "ip" ):GetString()
	
	-- Add the command
	Core.AddCmd( { "radio", "groove", "groovy", "music", "tunein", "jukebox", "listen", "sound", "soundcloud", "sc", "yt" }, Radio.Command )
	
	-- And initialize the language
	Radio.InitLang()
	
	-- Show that we loaded
	Core.Config.Var.Activate( "Radio", Radio )
	Core.PrintC( "[Startup] Extension 'radio' activated" )
end
Core.PostInitFunc = Radio.Init

--[[
	Description: The main radio command handler
--]]
function Radio.Command( ply, args )
	if args.Key == "tunein" and #args > 0 then
		local target
		for _,p in pairs( player.GetHumans() ) do
			if string.find( string.lower( p:Name() ), args[ 1 ], 1, true ) then
				target = p
				break
			end
		end
		
		if IsValid( target ) then
			Radio.Tuned[ ply ] = target
			Core.Print( ply, "General", Core.Text( "RadioTuneIn", target:Name() ) )
		else
			Core.Print( ply, "General", Core.Text( "RadioTuneOut" ) )
		end
		
		return
	end
	
	if #args > 0 then
		local str = string.Implode( " ", args.Upper )
		return Radio.SQL(
			"SELECT * FROM game_radio WHERE szID LIKE '%{0}%' OR szTitle LIKE '%{0}%' OR szArtist LIKE '%{0}%' OR szAlbum LIKE '%{0}%' ORDER BY nDate DESC LIMIT 1",
			{ str },
			{ UseOptions = true, StripQuotes = true }
		)( function( data, varArg )
			if Core.Assert( data, "szID" ) then
				local item = data[ 1 ]
				Radio.Play( ply, item["szID"], true )
				
				Core.Print( ply, "General", Core.Text( "AdminRadioQuickPlay", item["szTitle"] ) )
			else
				Core.Print( ply, "General", Core.Text( "AdminRadioQuickNone", str ) )
			end
		end )
	end
	
	if Radio.Opened[ ply ] then
		local ar = Radio.Net( "Radio/Net" )
		ar:UInt( 0, 4 )
		ar:Bit( true )
		ar:Send( ply )
	else
		local data = Radio.GetRecentEntries( function( got, data )
			local ar = Radio.Net( "Radio/Net" )
			ar:UInt( 0, 4 )
			ar:Bit( false )
			ar:Bit( Core.HasAdminAccess( ply, 0, "Moderator" ) )
			ar:Bit( got )
			
			if got then
				ar:UInt( #data, 16 )
				
				for i = 1, #data do
					ar:String( data[ i ].szID )
					ar:String( data[ i ].szTitle )
					ar:String( data[ i ].szArtist )
					ar:String( data[ i ].szAlbum )
					ar:UInt( data[ i ].nDuration, 20 )
					ar:UInt( data[ i ].nRequests, 20 )
					ar:UInt( data[ i ].nDate, 32 )
				end
			end
			
			ar:Send( ply )
			
			Radio.Opened[ ply ] = true
		end )
	end
end

--[[
	Description: Process a received command
--]]
function Radio.ReceiveCommand( ply, varArgs )
	local id = varArgs[ 1 ]
	local data = varArgs[ 2 ]
	
	if varArgs.Volume then
		Radio.Volume[ ply ] = math.Clamp( varArgs.Volume, 0, 100 )
	end
	
	if id == "Search" then
		Radio.Search( ply, data )
	elseif id == "Search_YT" then
		Radio.SearchYouTube( ply, data )
	elseif id == "Search_SC" then
		Radio.SearchSoundcloud( ply, data )
	elseif id == "Add_YT" then
		local yid = Radio.GetYouTubeID( data )
		if yid then
			Radio.Play( ply, yid )
			Radio.SQL(
				"SELECT nID FROM game_radio WHERE szID = {0}",
				{ yid }
			)( function( data, varArg )
				if not Core.Assert( data, "nID" ) then
					Radio.AddFromYouTube( ply, varArg )
				end
			end, yid )
		else
			Core.Send( ply, "GUI/Modal", { Title = "Parsing error", Text = Core.Text( "RadioYouTubeURL" ) } )
		end
	elseif id == "Add_SC" then
		local yid = tonumber( data )
		if yid then
			Radio.Play( ply, data )
			Radio.SQL(
				"SELECT nID FROM game_radio WHERE szID = {0}",
				{ yid }
			)( function( data, varArg )
				if not Core.Assert( data, "nID" ) then
					Radio.AddFromSoundcloud( ply, varArg, true )
				end
			end, yid )
		else
			Radio.AddFromSoundcloud( ply, data, false )
		end
	elseif id == "Play" then
		Radio.Play( ply, data, true, varArgs[ 3 ] )
	elseif id == "Edit" then
		if not Core.HasAdminAccess( ply, 0, "Moderator" ) then return end
		
		local columns = {
			"szTitle",
			"szArtist",
			"szAlbum",
			"nDuration",
			"nRequests"
		}
		
		local colId = columns[ varArgs[ 3 ] ]
		local value = varArgs[ 4 ]
		
		if not tonumber( value ) and (colId == "nDuration" or colId == "nRequests") then
			return Core.Print( ply, "Admin", Core.Text( "AdminRadioNumber" ) )
		end
		
		if colId == "szTitle" and value == "DELETE" then
			Radio.SQL(
				"DELETE FROM game_radio WHERE szID = {0}",
				{ data }
			)( function( data, varArg )
				Core.Print( ply, "Admin", Core.Text( unpack( varArg ) ) )
			end, { "AdminRadioDeleted", data } )
		else
			Radio.SQL(
				"UPDATE game_radio SET " .. colId .. " = {0} WHERE szID = {1}",
				{ value, data }
			)( function( data, varArg )
				Core.Print( ply, "Admin", Core.Text( unpack( varArg ) ) )
			end, { "AdminRadioUpdated", colId, data, value } )
		end
	end
end
Core.Register( "Global/Radio", Radio.ReceiveCommand )

--[[
	Description: Initiates playing a song on the player
--]]
function Radio.Play( ply, id, request, list )
	local ar = Radio.Net( "Radio/Net" )
	ar:UInt( 1, 4 )
	
	if tonumber( id ) then
		ar:Bit( true )
		ar:String( string.format( Radio.Path.SoundcloudPlayer, id, Radio.Keys.Soundcloud ) )
	else
		ar:Bit( false )
		ar:String( string.format( Radio.Path.YouTubePlayer, id, Radio.Volume[ ply ] or 100 ) )
	end
	
	ar:String( list or "" )
	ar:String( id )
	
	local send = ply
	for tuned,target in pairs( Radio.Tuned ) do
		if IsValid( target ) and target == ply then
			if type( send ) != "table" then
				send = { send }
			end
			
			send[ #send + 1 ] = tuned
		end
	end
	
	Radio.SQL(
		"SELECT szTitle, szArtist FROM game_radio WHERE szID = {0}",
		{ id }
	)( function( data, varArg )
		local title, artist = "", ""
		if Core.Assert( data, "szTitle" ) then
			title = data[ 1 ]["szTitle"] or ""
			artist = data[ 1 ]["szArtist"] or ""
		end
		
		varArg:String( title )
		varArg:String( artist )
		varArg:Send( send )
	end, ar )
	
	if request then
		Radio.AddRequest( id )
	end
end

--[[
	Description: Searches our own jukebox
--]]
function Radio.Search( ply, query )
	Radio.SQL(
		"SELECT * FROM game_radio WHERE szID LIKE '%{0}%' OR szTitle LIKE '%{0}%' OR szArtist LIKE '%{0}%' OR szAlbum LIKE '%{0}%' ORDER BY nDate DESC LIMIT " .. Radio.Limits.Query,
		{ query },
		{ UseOptions = true, StripQuotes = true }
	)( function( data, varArg )
		if Core.Assert( data, "szID" ) then
			local ar = Radio.Net( "Radio/Net" )
			ar:UInt( 4, 4 )
			ar:UInt( #data, 16 )
			
			for i = 1, #data do
				ar:String( data[ i ].szID )
				ar:String( data[ i ].szTitle )
				ar:String( data[ i ].szArtist )
				ar:String( data[ i ].szAlbum )
				ar:UInt( data[ i ].nDuration, 20 )
				ar:UInt( data[ i ].nRequests, 20 )
			end
			
			ar:Send( ply )
		else
			Core.Send( ply, "GUI/Modal", { Title = "Search result", Text = Core.Text( "RadioSearchBlank", query ) } )
		end
	end )
end

--[[
	Description: Searches the YouTube API
--]]
function Radio.SearchYouTube( ply, query )
	local url = string.format( Radio.Path.GoogleSearch, Radio.URLEncode( query ), Radio.Limits.Search, Radio.Keys.Google, Radio.IP )
	http.Fetch( url, function( body )
		local tab = util.JSONToTable( body or "" )
		if not tab or not tab.pageInfo then
			local reason = "."
			if tab and tab.error and tab.error.code then
				Core.PrintC( "[Error] Radio", "YouTube Search Error occurred", url )
				PrintTable( tab.error )
				
				reason = ".\n\nError code: " .. tab.error.code
			end
			
			return Core.Send( ply, "GUI/Modal", { Title = "Fetching error", Text = Core.Text( "RadioAPIContact", "YouTube", reason ) } )
		end
		
		local ar = Radio.Net( "Radio/Net" )
		ar:UInt( 2, 4 )
		ar:String( "YT" )
		ar:UInt( #tab.items, 32 )
		
		for _,item in pairs( tab.items ) do
			ar:String( item.id.videoId )
			ar:String( item.snippet.title )
			ar:String( item.snippet.channelTitle != "" and item.snippet.channelTitle or "Google+ channel" )
			ar:String( string.Explode( "T", item.snippet.publishedAt )[ 1 ] )
		end
		
		if #tab.items == 0 then
			ar:String( "No results found!" )
			ar:String( "" )
			ar:String( "" )
			ar:String( "" )
		end
		
		ar:Send( ply )
	end, function( err )
		Core.Send( ply, "GUI/Modal", { Title = "Fetching error", Text = Core.Text( "RadioAPIContact", "YouTube", ".\n\nError code: HTTP 1" ) } )
	end )
end

--[[
	Description: Searches the Soundcloud API
--]]
function Radio.SearchSoundcloud( ply, query )
	local url = string.format( Radio.Path.SoundcloudSearch, Radio.URLEncode( query ), Radio.Limits.Search, Radio.Keys.Soundcloud )
	http.Fetch( url, function( body )
		local tab = util.JSONToTable( body or "" )
		if not tab or tab.errors then
			local reason = "."
			if tab and tab.errors and tab.errors[ 1 ] and tab.errors[ 1 ].error_message then
				Core.PrintC( "[Error] Radio", "Soundcloud Search Error occurred", url )
				PrintTable( tab.errors )
				
				reason = ".\n\nError code: " .. tab.errors[ 1 ].error_message
			end
			
			return Core.Send( ply, "GUI/Modal", { Title = "Fetching error", Text = Core.Text( "RadioAPIContact", "Soundcloud", reason ) } )
		end
		
		local ar = Radio.Net( "Radio/Net" )
		ar:UInt( 2, 4 )
		ar:String( "SC" )
		ar:UInt( #tab, 32 )
		
		for _,item in pairs( tab ) do
			ar:String( item.id )
			ar:String( item.title )
			ar:String( item.user and item.user.username or "Unknown" )
			ar:String( string.gsub( string.Explode( " ", item.created_at )[ 1 ], "/", "-" ) )
		end
		
		if #tab == 0 then
			ar:String( "" )
			ar:String( "No results found!" )
			ar:String( "" )
			ar:String( "" )
		end
		
		ar:Send( ply )
	end, function( err )
		Core.Send( ply, "GUI/Modal", { Title = "Fetching error", Text = Core.Text( "RadioAPIContact", "Soundcloud", ".\n\nError code: HTTP 1" ) } )
	end )
end

--[[
	Description: Adds from the YouTube API
--]]
function Radio.AddFromYouTube( ply, id )
	local url = string.format( Radio.Path.GoogleDetails, Radio.URLEncode( id ), Radio.Keys.Google, Radio.IP )
	http.Fetch( url, function( body )
		local tab = util.JSONToTable( body or "" )
		if not tab or not tab.pageInfo then
			local reason = "."
			if tab and tab.error and tab.error.code then
				Core.PrintC( "[Error] Radio", "YouTube Add Error occurred", url )
				PrintTable( tab.error )
				
				reason = ".\n\nError code: " .. tab.error.code
			end
			
			return Core.Send( ply, "GUI/Modal", { Title = "Fetching error", Text = Core.Text( "RadioAPIContact", "YouTube", reason ) } )
		end
		
		local out = false
		if tab.items and tab.items[ 1 ] then
			local item = tab.items[ 1 ]
			if item.contentDetails and item.snippet then
				out = {}
				out.id = item.id
				out.title = item.snippet.title
				out.artist = item.snippet.channelTitle != "" and item.snippet.channelTitle or ""
				out.duration = Radio.YoutubeTimeToSeconds( item.contentDetails.duration or "" )
			end
		end
		
		if out then
			Radio.AddItem( out, ply )
		else
			Core.Send( ply, "GUI/Modal", { Title = "Import error", Text = Core.Text( "RadioAPIResponse", "YouTube" ) } )
		end
	end, function( err )
		Core.Send( ply, "GUI/Modal", { Title = "Fetching error", Text = Core.Text( "RadioAPIContact", "YouTube", ".\n\nError code: HTTP 1" ) } )
	end )
end

--[[
	Description: Adds from the Soundcloud API
--]]
function Radio.AddFromSoundcloud( ply, query, num )
	local url = string.format( num and Radio.Path.SoundcloudDetails or Radio.Path.SoundcloudResolve, Radio.URLEncode( query ), Radio.Keys.Soundcloud )
	http.Fetch( url, function( body )
		local tab = util.JSONToTable( body or "" )
		if not tab or tab.errors then
			local reason = "."
			if tab and tab.errors and tab.errors[ 1 ] and tab.errors[ 1 ].error_message then
				Core.PrintC( "[Error] Radio", "Soundcloud Add Error occurred", url )
				PrintTable( tab.errors )
				
				reason = ".\n\nError code: " .. tab.errors[ 1 ].error_message
			end
			
			return Core.Send( ply, "GUI/Modal", { Title = "Fetching error", Text = Core.Text( "RadioAPIContact", "Soundcloud", reason ) } )
		end
		
		local out = {}
		out.id = tab.id
		out.title = tab.title
		out.artist = tab.user and tab.user.username or "Unknown"
		out.duration = math.Round( tab.duration / 1000 )
		
		if out.id and out.title and out.duration then
			if not num then
				Radio.Play( ply, out.id )
				Radio.SQL(
					"SELECT nID FROM game_radio WHERE szID = {0}",
					{ out.id }
				)( function( data, varArg )
					if not Core.Assert( data, "nID" ) then
						Radio.AddItem( varArg, ply )
					end
				end, out )
			else
				Radio.AddItem( out, ply )
			end
		else
			Core.Send( ply, "GUI/Modal", { Title = "Import error", Text = Core.Text( "RadioAPIResponse", "Soundcloud" ) } )
		end
	end, function( err )
		Core.Send( ply, "GUI/Modal", { Title = "Fetching error", Text = Core.Text( "RadioAPIContact", "Soundcloud", ".\n\nError code: HTTP 1" ) } )
	end )
end


--[[
	Description: Gets the most recent database entries
--]]
function Radio.GetRecentEntries( callback )
	Radio.SQL(
		"SELECT * FROM game_radio ORDER BY nDate DESC LIMIT {0}",
		{ Radio.Limits.Fetch }
	)( function( data, varArg )
		if Core.Assert( data, "nID" ) then
			callback( true, data )
		else
			callback( false )
		end
	end, callback )
end

--[[
	Description: Adds an entry to the database
--]]
function Radio.AddItem( tab, ply )
	Radio.SQL(
		"INSERT INTO game_radio (szID, szTitle, szArtist, szAlbum, nDuration, nRequests, nDate) VALUES ({0}, {1}, {2}, {3}, {4}, {5}, {6})",
		{ tab.id, tab.title, tab.artist, "", tab.duration, 1, os.time() }
	)( SQLVoid )
	
	if ply then
		local ar = Radio.Net( "Radio/Net" )
		ar:UInt( 3, 4 )
		ar:String( tab.id )
		ar:String( tab.title )
		ar:String( tab.artist )
		ar:UInt( tab.duration, 20 )
		ar:Send( ply )
	end
end

--[[
	Description: Adds a single request to the entry
--]]
function Radio.AddRequest( id )
	Radio.SQL(
		"UPDATE game_radio SET nRequests = nRequests + 1 WHERE szID = {0}",
		{ id }
	)( SQLVoid )
end



--[[
	Description: Encodes special characters into HTML characters
--]]
function Radio.URLEncode( str )
	str = string.gsub( str, "([^%w ])", function( s ) return string.format( "%%%02X", string.byte( s ) ) end )
	str = string.gsub( str, " ", "+" )
	
	return str
end

--[[
	Description: Converts an ISO 8601 string to normal seconds
--]]
function Radio.YoutubeTimeToSeconds( str )
	local data = {}
	local build = ""
	
	for i = 1, #str do
		local at = string.sub( str, i, i )
		if tonumber( at ) then
			build = build .. at
		else
			data[ at ] = tonumber( build )
			build = ""
		end
	end
	
	return (data["D"] or 0) * 24 * 3600 + (data["H"] or 0) * 3600 + (data["M"] or 0) * 60 + (data["S"] or 0)
end

--[[
	Description: Extracts the YouTube ID from a URL
--]]
function Radio.GetYouTubeID( str )
	local m1s, m1e = string.find( str, "youtu.be/", 1, true )
	local m2s, m2e = string.find( str, "youtube.com/watch?v=", 1, true )
	local m3s, m3e = string.find( str, "youtube.com/v/", 1, true )
	local me = m1e or m2e or m3e
	
	if #str == 11 then
		return str
	elseif me then
		return string.sub( str, me + 1, me + 11 )
	end
end


--[[
	Description: Loads all extension related language
--]]
function Radio.InitLang()
	-- Language
	Core.AddText( "RadioTuneIn", "You are now tuned in to '1;' and will hear all songs they play as well!" )
	Core.AddText( "RadioTuneOut", "You are now tuned out." )
	Core.AddText( "RadioSearchBlank", "Couldn't find any results for your search query!\n\nSearch terms: 1;" )
	Core.AddText( "RadioYouTubeURL", "The entered URL doesn't look like a valid YouTube URL.\nPlease enter a correct URL or only enter the Video ID." )
	Core.AddText( "RadioAPIContact", "An error occurred while contacting the 1; API.\nPlease try again or consult the forums if the issue persists2;" )
	Core.AddText( "RadioAPIResponse", "An invalid response was received while contacting the 1; API.\nPlease try again or consult the forums if the issue persists." )
	Core.AddText( "AdminRadioNumber", "The duration column and requests column have to be entered as numbers." )
	Core.AddText( "AdminRadioUpdated", "The 1; column for entry 2; has been changed to 3;" )
	Core.AddText( "AdminRadioDeleted", "The entry with ID 1; has been deleted!" )
	Core.AddText( "AdminRadioQuickNone", "No entries found for query '1;'" )
	Core.AddText( "AdminRadioQuickPlay", "Now playing '1;'" )

	-- Help commands
	local cmd = Core.ContentText( nil, true ).Commands
	cmd["radio"] = "Opens a radio with which you can play neat tunes"
end