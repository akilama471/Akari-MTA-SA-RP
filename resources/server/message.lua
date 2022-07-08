
-- send a message to irc
function message( message )
    outputServerLog( message:gsub( "%%C%d%d", "" ):gsub( "%%C", "" ):gsub( "%%B", "" ) )
    if getResourceFromName( "irc" ) and getResourceState( getResourceFromName( "irc" ) ) == "running" then
        exports.irc:message( message )
    end
end
