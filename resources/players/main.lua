
-- Events
addEvent( "onCharacterLogin", false )
addEvent( "onCharacterLogout", false )

-- Import Groups
local groups = {
	{ groupName = "Moderators", groupID = 2, aclGroup = "Moderator", displayName = "Moderator", nametagColor = { 255, 255, 127 }, priority = 5 },
	{ groupName = "Admin", groupID = 1, aclGroup = "Admin", displayName = "Administrator", nametagColor = { 255, 255, 0 }, priority = 10, defaultForFirstUser = true },
	{ groupName = "Developers", groupID = 0, aclGroup = "Developer", displayName = "Developer", nametagColor = { 127, 255, 127 }, priority = 20, defaultForFirstUser = true },
}

p = { }

local function aclUpdate( player, saveAclIfChanged )
	local saveAcl = false
	
	if player then
		local info = p[ player ]
		if info and info.username then
			local shouldHaveAccount = false
			local account = getAccount( info.username )
			local groupinfo = exports.mysql:query_assoc( "SELECT groupID FROM akr_user_to_groups WHERE userID = " .. info.userID )
			if groupinfo then
				-- loop through all retrieved groups
				for key, group in ipairs( groupinfo ) do
					for key2, group2 in ipairs( groups ) do
						-- we have a acl group of interest
						if group.groupID == group2.groupID then
							-- mark as person to have an account
							shouldHaveAccount = true
							
							-- add an account if it doesn't exist
							if not account then
								outputServerLog( tostring( info.username ) .. " " .. tostring( info.mtasalt ) )
								account = addAccount( info.username, info.mtasalt ) -- due to MTA's limitations, the password can't be longer than 30 chars
								if not account then
									outputDebugString( "Account Error for " .. info.username .. " - addAccount failed.", 1 )
								else
									outputDebugString( "Added account " .. info.username, 3 )
								end
							end
							
							if account then
								-- if the player has a different account password, change it
								if not getAccount( info.username, info.mtasalt ) then
									setAccountPassword( account, info.mtasalt )
								end
								
								if isGuestAccount( getPlayerAccount( player ) ) and not logIn( player, account, info.mtasalt ) then
									-- something went wrong here
									outputDebugString( "Account Error for " .. info.username .. " - login failed.", 1 )
								else
									-- show him a message
									outputChatBox( "You are now logged in as " .. group2.displayName .. ".", player, 0, 255, 0 )
									if aclGroupAddObject( aclGetGroup( group2.aclGroup ), "user." .. info.username ) then
										saveAcl = true
										outputDebugString( "Added account " .. info.username .. " to " .. group2.aclGroup .. " ACL", 3 )
									end
								end
							end
						end
					end
				end
			end
			if not shouldHaveAccount and account then
				-- remove account from all ACL groups we use
				for key, value in ipairs( groups ) do
					if aclGroupRemoveObject( aclGetGroup( value.aclGroup ), "user." .. info.username ) then
						saveAcl = true
						outputDebugString( "Removed account " .. info.username .. " from " .. value.aclGroup .. " ACL", 3 )
						outputChatBox( "You are no longer logged in as " .. group.displayName .. ".", player, 255, 0, 0 )
					end
				end
				
				-- remove the account
				removeAccount( account )
				outputDebugString( "Removed account " .. info.username, 3 )
			end
			
			if saveAcl then
				updateNametagColor( player )
			end
		end
	else
		-- verify all accounts and remove invalid ones
		local checkedPlayers = { }
		local accounts = getAccounts( )
		for key, account in ipairs( accounts ) do
			local accountName = getAccountName( account )
			local player = getAccountPlayer( account )
			if player then
				checkedPlayers[ player ] = true
			end
			if accountName ~= "Console" then -- console may exist untouched
				local user = exports.mysql:query_assoc_single( "SELECT userID FROM mta_users WHERE username = '%s'", accountName )
				if user then
					-- account should be deleted if no group is found
					local shouldBeDeleted = true
					local userChanged = false
					
					if user.userID then -- if this doesn't exist, the user does not exist in the db
						-- fetch all of his groups groups
						local groupinfo = exports.mysql:query_assoc( "SELECT groupID FROM akr_user_to_groups WHERE userID = " .. user.userID )
						if groupinfo then
							-- look through all of our pre-defined groups
							for key, group in ipairs( groups ) do
								-- user does not have this group
								local hasGroup = false
								
								-- check if he does have it
								for key2, group2 in ipairs( groupinfo ) do
									if group.groupID == group2.groupID then
										-- has the group
										hasGroup = true
										
										-- shouldn't delete his account
										shouldBeDeleted = false
										
										-- make sure acl rights are set correctly
										if aclGroupAddObject( aclGetGroup( group.aclGroup ), "user." .. accountName ) then
											outputDebugString( "Added account " .. accountName .. " to ACL " .. group.aclGroup, 3 )
											saveAcl = true
											userChanged = true
											if player then
												outputChatBox( "You are now logged in as " .. group.displayName .. ".", player, 0, 255, 0 )
											end
										end
									end
								end
								
								-- doesn't have it
								if not hasGroup then
									-- make sure acl rights are removed
									if aclGroupRemoveObject( aclGetGroup( group.aclGroup ), "user." .. accountName ) then
										outputDebugString( "Removed account " .. accountName .. " from ACL " .. group.aclGroup, 3 )
										saveAcl = true
										userChanged = true
										
										if player then
											outputChatBox( "You are no longer logged in as " .. group.displayName .. ".", player, 255, 0, 0 )
										end
									end
								end
							end
						end
					end
					
					-- has no relevant group, thus we don't need the MTA account
					if shouldBeDeleted then
						if player then
							logOut( player )
						end
						outputDebugString( "Removed account " .. accountName, 3 )
						removeAccount( account )
					elseif player and isGuestAccount( getPlayerAccount( player ) ) and not logIn( player, account, p[ player ].mtasalt ) then
						-- something went wrong here
						outputDebugString( "Account Error for " .. accountName .. " - login failed.", 1 )
					end
					
					-- update the color since we have none
					if player and ( shouldBeDeleted or userChanged ) then
						updateNametagColor( player )
					end
				else
					-- Invalid user
					
					-- remove account from all ACL groups we use
					for key, value in ipairs( groups ) do
						if aclGroupRemoveObject( aclGetGroup( value.aclGroup ), "user." .. accountName ) then
							saveAcl = true
							outputDebugString( "Removed account " .. accountName .. " from " .. value.aclGroup .. " ACL", 3 )
							
							if player then
								outputChatBox( "You are no longer logged in as " .. group.displayName .. ".", player, 255, 0, 0 )
							end
						end
					end
					
					-- remove the account
					if player then
						logOut( player )
					end
					removeAccount( account )
					outputDebugString( "Removed account " .. accountName, 3 )
				end
			end
		end
		
		-- check all players not found by this for whetever they now have an account
		for key, value in ipairs( getElementsByType( "player" ) ) do
			if not checkedPlayers[ value ] then
				local success, needsAclUpdate = aclUpdate( value, false )
				if needsAclUpdate then
					saveAcl = true
				end
			end
		end
	end
	-- if we should save the acl, do it (permissions changed)
	if saveAclIfChanged and saveAcl then
		aclSave( )
	end
	return true, saveAcl
end

addEventHandler( "onResourceStart", resourceRoot,
	function( )
		if not exports.mysql:create_table( 'characters',
			{
				{ name = 'characterID', type = 'int(10) unsigned', auto_increment = true, primary_key = true },
				{ name = 'characterName', type = 'varchar(22)' },
				{ name = 'userID', type = 'int(10) unsigned' },
				{ name = 'x', type = 'float' },
				{ name = 'y', type = 'float' },
				{ name = 'z', type = 'float' },
				{ name = 'interior', type = 'tinyint(3) unsigned' },
				{ name = 'dimension', type = 'int(10) unsigned' },
				{ name = 'skin', type = 'int(10) unsigned' },
				{ name = 'rotation', type = 'float' },
				{ name = 'health', type = 'tinyint(3) unsigned', default = 100 },
				{ name = 'armor', type = 'tinyint(3) unsigned', default = 0 },
				{ name = 'money', type = 'bigint(20) unsigned', default = 100 },
				{ name = 'created', type = 'timestamp', default = 'CURRENT_TIMESTAMP' },
				{ name = 'lastLogin', type = 'timestamp', default = '2020-01-01 00:00:00' },
				{ name = 'weapons', type = 'varchar(255)', null = true },
				{ name = 'job', type = 'varchar(20)', null = true },
				{ name = 'languages', type = 'text', null = true },
			} ) then cancelEvent( ) return end
		
		if not exports.mysql:create_table( 'mta_users',
        {
            { name = 'userID', type = 'int(10) unsigned', auto_increment = true, primary_key = true },
			{ name = 'username', type = 'varchar(255)' },
			{ name = 'password', type = 'varchar(40)' },
			{ name = 'salt', type = 'varchar(40)' },
			{ name = 'email', type = 'varchar(40)' },
			{ name = 'banned', type = 'tinyint(1) unsigned', default = 0 },
			{ name = 'activationCode', type = 'int(10) unsigned', default = 0 },
			{ name = 'banReason', type = 'mediumtext', null = true },
			{ name = 'banUser', type = 'int(10) unsigned', null = true },
			{ name = 'lastIP', type = 'varchar(15)', null = true },
			{ name = 'lastSerial', type = 'varchar(32)', null = true },
			{ name = 'userOptions', type = 'text', null = true },
        } ) then cancelEvent( ) return end
    
        local success, didCreateTable = exports.mysql:create_table( 'mta_group',
        {
            { name = 'groupID', type = 'int(10) unsigned', auto_increment = true, primary_key = true },
            { name = 'groupName', type = 'varchar(255)', default = '' },
            { name = 'canBeFactioned', type = 'tinyint(1) unsigned', default = 1 }, -- if this is set to 0, you can't make a faction from this group.
        } )
		if not success then cancelEvent( ) return end
        
		if didCreateTable then
			-- add default groups
			for key, value in ipairs( groups ) do
				value.groupID = exports.mysql:query_insertid( "INSERT INTO mta_group (groupName, canBeFactioned) VALUES ('%s', 0)", value.groupName )
			end
		else
			-- import all groups
			local data = exports.mysql:query_assoc( "SELECT groupID, groupName FROM mta_group" )
			if data then
				for key, value in ipairs( data ) do
					for key2, value2 in ipairs( groups ) do
						if value.groupName == value2.groupName then
							value2.groupID = value.groupID
						end
					end
				end
			end
		end
		
		local success, didCreateTable = exports.mysql:create_table( 'mta_user_to_groups',
			{
				{ name = 'userID', type = 'int(10) unsigned', default = 0, primary_key = true },
				{ name = 'groupID', type = 'int(10) unsigned', default = 0, primary_key = true },
			} )
		if not success then cancelEvent( ) return end
		if didCreateTable then
			for key, value in ipairs( groups ) do
				if value.defaultForFirstUser then
					exports.mysql:query_free( "INSERT INTO mta_user_to_groups (userID, groupID) VALUES (1, " .. value.groupID .. ")" )
				end
			end
		end	
		aclUpdate( nil, true )	
	end
)

local function trim( str )
	return str:gsub("^%s*(.-)%s*$", "%1")
end

function onRequestRegister(username,password,email)
	-- check command source is client or not
	if source == client then
		--check username field empty or not
		if username  and password and email then
			username = trim( username )
			password = trim( password )
			email = trim( email )
			--check username length >= 5
			if #username >= 5 and #password >= 5 then
				--check Username All ready exist or not in Akari Database
				local info = exports.mysql:query_assoc_single( "SELECT COUNT(userID) AS usercount FROM mta_users WHERE username = '%s'", username )
				if not info then
					triggerClientEvent(source,"showNotification",getRootElement(),"error","Something Wrong. Try again later.....!")
				elseif info.usercount == 0 then
					-- generate a salt (SHA1)
					local salt = ''
					local chars = { 'a', 'b', 'c', 'd', 'e', 'f', 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
					for i = 1, 40 do
						salt = salt .. chars[ math.random( 1, #chars ) ]
					end

					if exports.mysql:query_free( "INSERT INTO mta_users (username,salt,password,email) VALUES ('%s', '%s', SHA1(CONCAT('%s', SHA1(CONCAT('%s', '" .. sha1( password ) .. "')))),'%s')", username, salt, salt, salt, email ) then
						triggerClientEvent( source,"onClientRegisterSuccess",getRootElement(),username,password)
						triggerClientEvent(source,"showNotification",getRootElement(),"success","successfully registered...!")
					else
						triggerClientEvent(source,"showNotification",getRootElement(),"error","Database Error...!")
					end
				else
					triggerClientEvent(source,"showNotification",getRootElement(),"error","This username already exists. !")
				end
			else
				triggerClientEvent(source,"showNotification",getRootElement(),"error","Username , Paasowrd be 5 characters or longer. !")
			end
		else
			triggerClientEvent(source,"showNotification",getRootElement(),"error","Username cannot be Empty !")
		end
	end
end
addEvent("onReceivedRegisterRequest",true)
addEventHandler("onReceivedRegisterRequest",getRootElement(),onRequestRegister)

local function getPlayerHash( player, remoteIP )
	local ip = getPlayerIP( player ) or "255.255.255.0"
	if ip == "127.0.0.1" and remoteIP then
		ip = exports.sql:escape_string( remoteIP )
	end
	return ip:sub(ip:find("%d+%.%d+%.")) .. ( getPlayerSerial( player ) or "R0FLR0FLR0FLR0FLR0FLR0FLR0FLR0FL" ) .. tostring( serverToken )
end

local loginAttempts = { }
local triedTokenAuth = { }

function onFuncPlayerLogin( username, password )
	if source == client then
		triedTokenAuth[ source ] = true
		if username and password and #username > 0 and #password > 0 then
			local info = exports.mysql:query_assoc_single( "SELECT CONCAT(SHA1(CONCAT(username, '%s')),SHA1(CONCAT(salt, SHA1(CONCAT('%s',SHA1(CONCAT(salt, SHA1(CONCAT(username, SHA1(password)))))))))) AS token FROM mta_users WHERE `username` = '%s' AND password = SHA1(CONCAT(salt, SHA1(CONCAT(salt, '" .. sha1(password) .. "'))))", getPlayerHash( source ), getPlayerHash( source ), username )
			p[ source ] = nil
			if not info then
				triggerClientEvent(source,"showNotification",getRootElement(),"error","Wrong username/password...!")
				loginAttempts[ source ] = ( loginAttempts[ source ] or 0 ) + 1
				if loginAttempts[ source ] >= 5 then
					-- ban for 15 minutes
					local serial = getPlayerSerial( source )

					banPlayer( source, true, false, false, root, "Too many login attempts.", 900 )
					if serial then
						addBan( nil, nil, serial, root, "Too many login attempts.", 900 )
					end
				end
			else
				loginAttempts[ source ] = nil
				hideCgui()
				performLogin( source, info.token, true )
			end
		end
	end
end
addEvent("onReceivedLoginRequest", true )
addEventHandler("onReceivedLoginRequest",getRootElement(),onFuncPlayerLogin)

function performLogin( source, token, isPasswordAuth, ip )
	if source and ( isPasswordAuth or not triedTokenAuth[ source ] ) then
		triedTokenAuth[ source ] = true
		if token then
			if #token == 80 then
				local info = exports.mysql:query_assoc_single( "SELECT userID, username, banned, activationCode, SUBSTRING(LOWER(SHA1(CONCAT(userName,SHA1(CONCAT(password,salt))))),1,30) AS salts, userOptions FROM mta_users WHERE CONCAT(SHA1(CONCAT(username, '%s')),SHA1(CONCAT(salt, SHA1(CONCAT('%s',SHA1(CONCAT(salt, SHA1(CONCAT(username, SHA1(password)))))))))) = '%s' LIMIT 1", getPlayerHash( source, ip ), getPlayerHash( source, ip ), token )
				p[ source ] = nil
				if not info then
					if isPasswordAuth then
						triggerClientEvent(source,"showNotification",getRootElement(),"error","Wrong username/password...!")
					end
					return false
				else
					if info.banned == 1 then
						triggerClientEvent(source,"showNotification",getRootElement(),"error","Ooooops..! , You are banned from this server...!")
						return false
					elseif info.activationCode > 0 then
						triggerClientEvent(source,"showNotification",getRootElement(),"error","Activation Required...!")
						return false
					else
						-- check if another user is logged in on that account
						for player, data in pairs( p ) do
							if data.userID == info.userID then
								triggerClientEvent(source,"showNotification",getRootElement(),"error","Another Player Already Login with this account...!")
								return false
							end
						end

						local username = info.username
						p[ source ] = { userID = info.userID, username = username, mtasalt = info.salts, options = info.userOptions and fromJSON( info.userOptions ) or { } }

						-- check for admin rights
						aclUpdate( source, true )

						-- show characters
						local chars = exports.mysql:query_assoc( "SELECT characterID, characterName, skin FROM characters WHERE userID = " .. info.userID .. " ORDER BY lastLogin DESC" )
						if isPasswordAuth then
							triggerClientEvent( source, getResourceName( resource ) .. ":characters", source, chars, true, token, getPlayerIP( source ) ~= "127.0.0.1" and getPlayerIP( source ) )
						else
							triggerClientEvent( source, getResourceName( resource ) .. ":characters", source, chars, true )
						end
						outputServerLog( "AKR MTA LOGIN: " .. getPlayerName( source ) .. " logged in as " .. info.username .. " (IP: " .. getPlayerIP( source ) .. ", Serial: " .. getPlayerSerial( source ) .. ")" )
						exports.server:message( "%C04[" .. getID( source ) .. "]%C %B" .. info.username .. "%B logged in (Nick: %B" .. getPlayerName( source ):gsub( "_", " " ) .. "%B)." )
						exports.mysql:query_free( "UPDATE mta_users SET lastIP = '%s', lastSerial = '%s' WHERE userID = " .. tonumber( info.userID ), getPlayerIP( source ), getPlayerSerial( source ) )

						return true
					end
				end
			end
		end
	end
	return false
end

local function savePlayer( player )
	if not player then
		for key, value in ipairs( getElementsByType( "player" ) ) do
			savePlayer( value )
		end
	else
		if isLoggedIn( player ) then
			-- save character since it's logged in
			local x, y, z = getElementPosition( player )
			local dimension = getElementDimension( player )
			local interior = getElementInterior( player )

			if hasObjectPermissionTo( player, "command.spectate", false ) and type( getElementData( player, "collisionless" ) ) == "table" then
				-- spectating
				x, y, z, dimension, interior = unpack( getElementData( player, "collisionless" ) )
			end

			exports.sql:query_free( "UPDATE characters SET x = " .. x .. ", y = " .. y .. ", z = " .. z .. ", dimension = " .. dimension .. ", interior = " .. interior .. ", rotation = " .. getPedRotation( player ) .. ", health = " .. math.floor( getElementHealth( player ) ) .. ", armor = " .. math.floor( getPedArmor( player ) ) .. ", weapons = " .. getWeaponString( player ) .. ", lastLogin = NOW() WHERE characterID = " .. tonumber( getCharacterID( player ) ) )
		end
	end
end
setTimer( savePlayer, 300000, 0 ) -- Auto-Save every five minutes

addEvent( getResourceName( resource ) .. ":logout", true )
addEventHandler( getResourceName( resource ) .. ":logout", root,
		function( )
			if source == client then
				savePlayer( source )
				if p[ source ].charID then
					triggerEvent( "onCharacterLogout", source )
					setPlayerTeam( source, nil )
					takeAllWeapons( source )
				end
				p[ source ] = nil
				showLoginScreen( source )

				if not isGuestAccount( getPlayerAccount( source ) ) then
					logOut( source )
				end
			end
		end
)

addEvent( getResourceName( resource ) .. ":spawn", true )
addEventHandler( getResourceName( resource ) .. ":spawn", root,
		function()
			if source == client and ( not isPedDead( source ) or not isLoggedIn( source ) ) then
				local userID = p[ source ] and p[ source ].userID
				if tonumber( userID ) and tonumber( charID ) then
					-- if the player is logged in, save him
					savePlayer( source )
					if p[ source ].charID then
						triggerEvent( "onCharacterLogout", source )
						setPlayerTeam( source, nil )
						takeAllWeapons( source )
						p[ source ].charID = nil
						p[ source ].money = nil
						p[ source ].job = nil
					end

					--
					local char = exports.mysql:query_assoc_single( "SELECT * FROM characters WHERE userID = " .. tonumber( userID ) .. " AND characterID = " .. tonumber( charID ) )
					if char then
						local mtaCharName = char.characterName:gsub( " ", "_" )
						local otherPlayer = getPlayerFromName( mtaCharName )
						if otherPlayer and otherPlayer ~= source then
							kickPlayer( otherPlayer )
						end
						setPlayerName( source, mtaCharName )

						-- spawn the player, as it's a valid char
						spawnPlayer( source, char.x, char.y, char.z, char.rotation, char.skin, char.interior, char.dimension )
						fadeCamera( source, true )
						setCameraTarget( source, source )
						setCameraInterior( source, char.interior )

						toggleAllControls( source, true, true, false )
						setElementFrozen( source, false )
						setElementAlpha( source, 255 )

						setElementHealth( source, char.health )
						setPedArmor( source, char.armor )

						p[ source ].money = char.money
						setPlayerMoney( source, char.money )

						p[ source ].charID = tonumber( charID )
						p[ source ].characterName = char.characterName
						updateNametag( source )

						-- restore weapons
						if char.weapons then
							local weapons = fromJSON( char.weapons )
							if weapons then
								for weapon, ammo in pairs( weapons ) do
									giveWeapon( source, weapon, ammo )
								end
							end
						end

						p[ source ].job = char.job

						-- restore the player's languages, remove invalid ones
						p[ source ].languages = fromJSON( char.languages )
						if not p[ source ].languages then
							-- default is English with full skill
							p[ source ].languages = { en = { skill = 1000, current = true } }
							saveLanguages( source, p[ source ].languages )
						else
							local changed = false
							local languages = 0
							for key, value in pairs( p[ source ].languages ) do
								if isValidLanguage( "en" ) then
									changed = true
									languages = languages + 1
									if not isValidLanguage( key ) then
										p[ source ].languages[ key ] = nil
										languages = languages - 1
									elseif type( value.skill ) ~= 'number' then
										value.skill = 0
									elseif value.skill < 0 then
										value.skill = 0
									elseif value.skill > 1000 then
										value.skill = 1000
									else
										changed = false
									end
								else
									languages = languages + 1
								end
							end

							if languages == 0 then
								-- player has no language at all
								p[ source ].languages = { en = { skill = 1000, current = true } }
								changed = true
							end

							if changed then
								saveLanguages( source, p[ source ].languages )
							end
						end

						setPlayerTeam( source, team )
						triggerClientEvent( source, getResourceName( resource ) .. ":onSpawn", source, p[ source ].languages )
						triggerEvent( "onCharacterLogin", source )

						showCursor( source, false )

						-- set last login to now
						exports.sql:query_free( "UPDATE characters SET lastLogin = NOW() WHERE characterID = " .. tonumber( charID ) )

						outputServerLog( "PARADISE CHARACTER: " .. p[ source ].username .. " is now playing as " .. char.characterName )
						exports.server:message( "%C04[" .. getID( source ) .. "]%C %B" .. p[ source ].username .. "%B is now playing in as %B" .. char.characterName .. "%B." )
					end
				end
			end
		end
)