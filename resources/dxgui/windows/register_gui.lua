
function open_register()
    showChat(false)

    setCameraMatrix(0,0,100,0,100,50)
    fadeCamera(true)

    showCursor(true,true)
    guiSetInputMode('no_binds')

    registerForm = guiCreateWindow((screenW - 236) / 2, (screenH - 285) / 2, 236, 280, "AKARI MTA :: USER REGISTER", false)

    guiWindowSetMovable(registerForm,false)
    guiWindowSetSizable(registerForm,false)

    registerUsernameLable = guiCreateLabel(20, 50, 200, 20, "Username", false, registerForm)
    registerUsernameInputBox = guiCreateEdit(20, 70, 200, 20, "", false, registerForm)
    guiEditSetMaxLength(registerUsernameInputBox,10)
    guiLabelSetColor(registerUsernameInputBox,0,128,255)
    guiFocus(registerUsernameInputBox)

    registerPasswordLable = guiCreateLabel(20, 100, 200, 20, "Password", false, registerForm)
    registerPasswordInputBox = guiCreateEdit(20, 120, 200, 20, "", false, registerForm)
    guiLabelSetColor(registerPasswordInputBox,0,128,255)
    guiEditSetMasked(registerPasswordInputBox,true)
    guiEditSetMaxLength(registerPasswordInputBox,10)

    registerEmailLable = guiCreateLabel(20, 150, 200, 20, "Email", false, registerForm)
    registerEmailInputBox = guiCreateEdit(20, 170, 200, 20, "", false, registerForm)
    guiLabelSetColor(registerEmailInputBox,0,128,255)

    registerButton = guiCreateButton(71, 210, 93, 30, "Register", false, registerForm)
    addEventHandler("onClientGUIClick",registerButton,onClickRegisterButton,false )

    loginAccountButton = guiCreateButton(20, 250, 200, 25, "I have Account", false, registerForm)
    addEventHandler("onClientGUIClick",loginAccountButton,showLoginGUI,false )
end
