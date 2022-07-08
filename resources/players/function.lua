local ids = { }

addEventHandler( "onPlayerJoin", root,
        function( )
            for i = 1, getMaxPlayers( ) do
                if not ids[ i ] then
                    ids[ i ] = source
                    setElementData( source, "playerid", i )
                    exports.server:message( "%C04[" .. i .. "]%C %B" .. getPlayerName( source ):gsub( "_", " " ) .. "%B joined the server (IP: %B" .. tostring( getPlayerIP( source ):sub(getPlayerIP( source ):find("%d+%.%d+%.")) ) .. "x.x%B)." )
                    break
                end
            end
        end
)

addEventHandler( "onResourceStart", resourceRoot,
        function( )
            for i, source in ipairs( getElementsByType( "player" ) ) do
                ids[ i ] = source
                setElementData( source, "playerid", i )
            end
        end
)

addEventHandler( "onPlayerQuit", root,
        function( type, reason, responsible )
            for i = 1, getMaxPlayers( ) do
                if ids[ i ] == source then
                    ids[ i ] = nil

                    if reason then
                        type = type .. " - " .. reason
                        if isElement( responsible ) and getElementType( responsible ) == "player" then
                            type = type .. " - " .. getPlayerName( responsible )
                        end
                    end
                    exports.server:message( "%C04[" .. i .. "]%C %B" .. getPlayerName( source ):gsub( "_", " " ) .. "%B left the server. (" .. type .. ")" )

                    break
                end
            end
        end
)

function getFromName( player, targetName, ignoreLoggedOut )
    if targetName then
        targetName = tostring( targetName )

        local match = { }
        if targetName == "*" then
            match = { player }
        elseif tonumber( targetName ) then
            match = { ids[ tonumber( targetName ) ] }
        elseif ( getPlayerFromName ( targetName ) ) then
            match = { getPlayerFromName ( targetName ) }
        else
            for key, value in ipairs ( getElementsByType ( "player" ) ) do
                if getPlayerName ( value ):lower():find( targetName:lower() ) then
                    match[ #match + 1 ] = value
                end
            end
        end

        if #match == 1 then
            if isLoggedIn( match[ 1 ] ) or ignoreLoggedOut then
                return match[ 1 ], getPlayerName( match[ 1 ] ):gsub( "_", " " ), getElementData( match[ 1 ], "playerid" )
            else
                if player then
                    outputChatBox( getPlayerName( match[ 1 ] ):gsub( "_", " " ) .. " is not logged in.", player, 255, 0, 0 )
                end
                return nil -- not logged in error
            end
        elseif #match == 0 then
            if player then
                outputChatBox( "No player matches your search.", player, 255, 0, 0 )
            end
            return nil -- no player
        elseif #match > 10 then
            if player then
                outputChatBox( #match .. " players match your search.", player, 255, 204, 0 )
            end
            return nil -- not like we want to show him that many players
        else
            if player then
                outputChatBox ( "Players matching your search are: ", player, 255, 204, 0 )
                for key, value in ipairs( match ) do
                    outputChatBox( "  (" .. getElementData( value, "playerid" ) .. ") " .. getPlayerName( value ):gsub ( "_", " " ), player, 255, 255, 0 )
                end
            end
            return nil -- more than one player. We list the player names + id.
        end
    end
end

addCommandHandler( "id",
        function( player, commandName, target )
            if isLoggedIn( player ) then
                local target, targetName, id = getFromName( player, target )
                if target then
                    outputChatBox( targetName .. "'s ID is " .. id .. ".", player, 255, 204, 0 )
                end
            end
        end
)

function getCharacterID( player )
    return player and p[ player ] and p[ player ].charID or false
end

function isLoggedIn( player )
    return getCharacterID( player ) and true or false
end

function getUserID( player )
    return player and p[ player ] and p[ player ].userID or false
end

function getUserName( player )
    return player and p[ player ] and p[ player ].username or false
end

function getCharacterName( characterID )
    if type( characterID ) == "number" then
        -- check if the player is online, if so we don't need to query
        for player, data in pairs( p ) do
            if data.charID == characterID then
                local name = getPlayerName( player ):gsub( "_", " " )
                return name
            end
        end

        local data = exports.mysql:query_assoc_single( "SELECT characterName FROM characters WHERE characterID = " .. characterID )
        if data then
            return data.characterName
        end
    end
    return false
end

function getID( player )
    local id = getElementData( player, "playerid" )
    if ids[ id ] == player then
        return id
    else
        for i = 1, getMaxPlayers( ) do
            if ids[ i ] == player then
                return id
            end
        end
    end
end

function setMoney( player, amount )
    amount = tonumber( amount )
    if amount >= 0 and isLoggedIn( player ) then
        if exports.mysql:query_free( "UPDATE characters SET money = " .. amount .. " WHERE characterID = " .. p[ player ].charID ) then
            p[ player ].money = amount
            setPlayerMoney( player, amount )
            return true
        end
    end
    return false
end

function giveMoney( player, amount )
    return amount >= 0 and setMoney( player, getMoney( player ) + amount )
end

function takeMoney( player, amount )
    return amount >= 0 and setMoney( player, getMoney( player ) - amount )
end

function getMoney( player, amount )
    return isLoggedIn( player ) and p[ player ].money or 0
end

function updateCharacters( player )
    if player and p[ player ].userID then
        local chars = exports.mysql:query_assoc( "SELECT characterID, characterName, skin FROM characters WHERE userID = " .. p[ player ].userID .. " ORDER BY lastLogin DESC" )
        triggerClientEvent( player, getResourceName( resource ) .. ":characters", player, chars, false )
        return true
    end
    return false
end

function createCharacter( player, name, skin )
    if player and p[ player ].userID then
        if exports.mysql:query_assoc_single( "SELECT characterID FROM characters WHERE characterName = '%s'", name ) then
            triggerClientEvent( player, "players:characterCreationResult", player, 1 )
        elseif exports.mysql:query_free( "INSERT INTO characters (characterName, userID, x, y, z, interior, dimension, skin, rotation) VALUES ('%s', " .. p[ player ].userID .. ", -1984.5, 138, 27.7, 0, 0, " .. tonumber( skin ) .. ", 270)", name ) then
            updateCharacters( player )
            triggerClientEvent( player, "players:characterCreationResult", player, 0 )

            exports.server:message( "%C04[" .. getID( player ) .. "]%C %B" .. p[ player ].username .. "%B created character %B" .. name .. "%B." )

            return true
        end
    end
    return false
end

function updateNametag( player )
    if player then
        local text = "[" .. getID( player ) .. "] "
        local vehicle = getPedOccupiedVehicle( player )
        if vehicle and exports.vehicles:hasTintedWindows( vehicle ) then
            text = text .. "? (Tinted Windows)"
        else
            text = text .. ( p[ player ] and p[ player ].characterName or getPlayerName( player ):gsub( "_", " " ) )
        end

        if getPlayerNametagText( player ) ~= tostring( text ) then
            setPlayerNametagText( player, tostring( text ) )
        end
        updateNametagColor( player )
        return true
    end
    return false
end

function getJob( player )
    return isLoggedIn( player ) and p[ player ].job or nil
end

function setJob( player, job )
    local charID = getCharacterID( player )
    if charID and exports.mysql:query_free( "UPDATE characters SET job = '%s' WHERE characterID = " .. charID, job ) then
        p[ player ].job = job
        return true
    end
    return false
end

function getOption( player, key )
    return player and p[ player ] and p[ player ].options and key and p[ player ].options[ key ] or nil
end

function setOption( player, key, value )
    if player and p[ player ] and p[ player ].options and type( key ) == 'string' then
        -- update the option
        local oldValue = p[ player ].options[ key ]
        p[ player ].options[ key ] = value


        local str = toJSON( p[ player ].options )
        if str then
            if str == toJSON( { } ) then
                local success = exports.mysql:query_free( "UPDATE mta_users SET userOptions = NULL WHERE userID = " .. getUserID( player ) )
                return success
            elseif exports.mysql:query_free( "UPDATE mta_users SET userOptions = '%s' WHERE userID = " .. getUserID( player ), str ) then
                return true
            end
        end

        -- if it failed, restore the old value
        p[ player ].options[ key ] = oldValue
    end
    return false
end

function getGroups( player )
    local g = { }
    if p[ player ] then
        for key, value in ipairs( groups ) do
            if isObjectInACLGroup( "user." .. p[ player ].username, aclGetGroup( value.aclGroup ) ) then
                table.insert( g, value )
            end
        end
        table.sort( g, function( a, b ) return a.priority > b.priority end )
    end
    return g
end