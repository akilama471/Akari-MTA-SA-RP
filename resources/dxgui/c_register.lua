local function tryRegister()
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

function guiRegister()
    local registerForm = guiCreateWindow((screenW - 236) / 2, (screenH - 285) / 2, 236, 280, "AKARI MTA :: USER REGISTER", false)

    guiWindowSetMovable(registerForm,false)
    guiWindowSetSizable(registerForm,false)

    registerUsernameLable = guiCreateLabel(20, 50, 200, 20, "Username", false, registerForm)
    registerUsernameInputBox = guiCreateEdit(20, 70, 200, 20, "", false, registerForm)
    guiEditSetMaxLength(registerUsernameInputBox,20)
    guiLabelSetColor(registerUsernameInputBox,0,128,255)
    guiFocus(registerUsernameInputBox)

    registerPasswordLable = guiCreateLabel(20, 100, 200, 20, "Password", false, registerForm)
    registerPasswordInputBox = guiCreateEdit(20, 120, 200, 20, "", false, registerForm)
    guiEditSetMaxLength(registerPasswordInputBox,20)
    guiEditSetMasked(registerPasswordInputBox,true)
    guiLabelSetColor(registerPasswordInputBox,0,128,255)

    registerEmailLable = guiCreateLabel(20, 150, 200, 20, "Email", false, registerForm)
    registerEmailInputBox = guiCreateEdit(20, 170, 200, 20, "", false, registerForm)
    guiLabelSetColor(registerEmailInputBox,0,128,255)

    registerButton = guiCreateButton(71, 210, 93, 30, "Register", false, registerForm)
    addEventHandler("onClientGUIClick",registerButton,tryRegister,false )

    loginAccountButton = guiCreateButton(20, 250, 200, 25, "Already have Account", false, registerForm)
    addEventHandler("onClientGUIClick",loginAccountButton,showLoginGUI,false )
end