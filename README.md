Garry's Mod Skill Gamemodes
==============

This gamemode houses functionality to host a Bunny Hop or Skill Surf server
The files will be exactly the same and it determines the type by looking at the sv_downloadurl set in the server.cfg; this structure has been used so that I don't have to worry about having the correct files on the matching server

==============

How to set up the gamemode:
1. You need to make sure the gamemode can determine which type it's running. For that you need to change modules/sh_config.lua accordingly:  
  1.1. First change the keys under the `_public` key.  
    - `ServerName` is your community's full server name
    - `Identifier` is how the data is saved to the settings
    - `Prefix` is how settings files and other datastrings are prefixed
    - `Material` is what folder your content is in. (Keep this at 'gmskill' if you don't have anything modified to save users loading time)
    - **Note:** If you only have one server, then fill `single` with the server key you list in the next step.

  1.2. Next up are the servers that are active within your community running on this gamemode.
  - First comes the server key / identifier between the brackets. This doesn't need to be unique and cannot contain spaces. Example: 'bhopeasy', 'bhopeu', 'skillsurf'
  - `Base` determines how exactly the gamemode engine runs (Possibilities are 'bhop and 'surf' by default)
  - `Name` is what's shown in the welcome message
  - `Short` is what is shown on the scoreboard in the credits
  - `FastDL` this one is important. If you're NOT using `single` in `_public`, then this will allow the gamemode to be recognized on your server. Simply put your FastDL URL here, but make sure it's also in server.cfg. If you don't have a FastDL, put something in this format: 'asset://fastdl/[serverkey]/', resulting in for example 'asset://fastdl/bhopeasy/'. Don't forget the trailing slash!

2. Next we need to sync our changes over to server.cfg of the server is question. The contents will differ for each server if you have multiple.
  - The most important is that `sv_downloadurl` is set to the corresponding FastDL as in sh_config.lua
  - Next are all the game related settings:
  - `game_server_id` the ID of your server. Increment this if you have multiple of these servers on the same database (for table naming). Keep this at 0 if you have a full database per server.

There was more to do when setting it up, but I'm sure you'll figure it out.

Additional stuff to get this running:
- Copy contents from lua/autorun into lua/autorun
- Copy contents from data/web into data/web



Setting up a FastDL:
1. Set sv_downloadurl in server.cfg to the designated host. Make sure to end with a trailing slash
2. Also set game_server_dl to the same value as set in sv_downloadurl
3. Edit your sh_config.lua with the above said values.
4. Copy all files from the `content` folder to the fastdl root
5. For faster downloads compress each file to BZ2 with a program like 7-Zip
