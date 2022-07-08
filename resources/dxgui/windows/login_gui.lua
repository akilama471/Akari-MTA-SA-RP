local function tryLogin( key )
    if key ~= 2 and destroy and destroy['g:login:username'] and destroy['g:login:password'] then
        local u = guiGetText( destroy['g:login:username'] )
        local p = guiGetText( destroy['g:login:password'] )
        if u and p then
            if #u == 0 then
                setMessage( "Please enter a username." )
            elseif #p == 0 then
                setMessage( "Please enter a password." )
            else
                triggerServerEvent( "players:login", getLocalPlayer( ), u, p )
            end
        end
    end
end

windows.login = {
    {
        type = "Window",
        id = "g:login:window_login",
        title = "AKARI MTA :: USER REGISTER",
        doMove = "false",
        doResize = "false"
    },
    {
        type = "label",
        id = "g:login:label_username",
        test = "Username",
        color = "0,128,255"
    },
    {
        type = "Edit",
        id = "g:login:edit_username",
        maxlength = "10",
        doFocus = "true"
    },
    {
        type = "label",
        id = "g:login:label_password",
        test = "Password",
        color = "0,128,255"
    },
    {
        type = "Edit",
        id = "g:login:edit_password",
        maxlength = "10",
        doMask = "true",
        doFocus = "true"
    },
    {
        type = "Button",
        id = "g:login:button_login",
        onClick = tryLogin
    }
}