
function open_forgetPassword()
    showChat(false)

    setCameraMatrix(0,0,100,0,100,50)
    fadeCamera(true)

    showCursor(true,true)
    guiSetInputMode('no_binds')

    forgetForm = guiCreateWindow((screenW - 236) / 2, (screenH - 285) / 2, 230, 150, "AKARI MTA :: FORGET PASSWORD", false)

    guiWindowSetMovable(forgetForm,false)
    guiWindowSetSizable(forgetForm,false)

    forgetEmailLable = guiCreateLabel(20, 50, 200, 20, "Enter Your Registered Email", false, forgetForm)
    forgetEmailInputBox = guiCreateEdit(20, 70, 200, 20, "", false, forgetForm)
    guiEditSetMaxLength(forgetEmailInputBox,10)
    guiLabelSetColor(forgetEmailInputBox,0,128,255)
    guiFocus(forgetEmailInputBox)

    submitEmailButton = guiCreateButton(71, 100, 93, 30, "Send Email", false, forgetForm)
    addEventHandler("onClientGUIClick",submitEmailButton,onClickSubmitForgetPassword,false )

    backToLoginButton = guiCreateButton(71, 140, 93, 30, "Back to Login", false, forgetForm)
    addEventHandler("onClientGUIClick",backToLoginButton,showLoginGUI,false )
end
