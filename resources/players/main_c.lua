
-- Login / Register / Forget Password Window

function showRegisterGUI()
	guiSetVisible(loginForm,false)
	guiSetVisible(forgetForm,false)
	open_register()	
end

function showLoginGUI()
	guiSetVisible(registerForm,false)
	guiSetVisible(forgetForm,false)
	open_login()	
end

function showForgetPasswordGUI()
	guiSetVisible(registerForm,false)
	guiSetVisible(loginForm,false)
	open_forgetPassword()
end

--Button Click Function

function onClickLoginButton(button,state)
	if(button == "left" and state == "up") then
		_username = guiGetText(usernameInputBox)
		_password = guiGetText(passwordInputBox)
		triggerServerEvent("onReceivedLoginRequest",getLocalPlayer(),_username,_password)
	end
end

function onClickRegisterButton(button,state)
	if(button == "left" and state == "up") then
		_username = guiGetText(registerUsernameInputBox)
		_password = guiGetText(registerPasswordInputBox)
		_email = guiGetText(registerEmailInputBox)
		triggerServerEvent("onReceivedRegisterRequest",getLocalPlayer(),_username,_password,_email)
	end
end

function Error_msg(type, text)
	
	if type == "error" then	
		triggerEvent("add:notification",localPlayer,text,"error",true)
	elseif type == "success" then
		triggerEvent("add:notification",localPlayer,text,"success",true)
	end
end
addEvent("showNotification",true)
addEventHandler("showNotification",getResourceRootElement(getThisResource()),Error_msg)

-- main events

function Register_Success(username, password)
	hideCgui();
	triggerServerEvent("onReceivedLoginRequest",getLocalPlayer(),username,password)
end
addEvent("onClientRegisterSuccess",true)
addEventHandler("onClientRegisterSuccess",getResourceRootElement(getThisResource()),Register_Success)

function Login_Success(username, password)
	hideCgui();
	triggerServerEvent("onReceivedLoginRequest",getLocalPlayer(),username,password)
end
addEvent("onClientLoginSuccess",true)
addEventHandler("onClientLoginSuccess",getResourceRootElement(getThisResource()),Login_Success)

function selectCharacter( id, name )
	if id == -1 then
		-- new character
		exports.gui:show( 'create_character', true )
	elseif id == -2 then
		-- logout
		exports.gui:hide( )
		triggerServerEvent( getResourceName( resource ) .. ":logout", localPlayer )
	elseif loggedIn and name == getPlayerName( localPlayer ):gsub( "_", " " ) then
		exports.gui:hide( )
	else
		exports.gui:hide( )
		triggerServerEvent( getResourceName( resource ) .. ":spawn", localPlayer, id )
	end
end

addEvent( getResourceName( resource ) .. ":characters", true )
addEventHandler( getResourceName( resource ) .. ":characters", localPlayer,
		function( chars, spawn, token, ip )
			characters = chars
			exports.gui:updateCharacters( chars )
			isSpawnScreen = spawn
			if isSpawnScreen then
				exports.gui:show( 'characters', true, true, true )
				showChat( false )
				setPlayerHudComponentVisible( "radar", false )
				setPlayerHudComponentVisible( "area_name", false )
				loggedIn = false
			end

			-- auto-login
			if token and serverToken then
				local xml = xmlCreateFile( "login-" .. serverToken .. ".xml", "login" )
				if xml then
					xmlNodeSetValue( xml, token )
					if ip then
						xmlNodeSetAttribute( xml, "ip", ip )
						localIP = ip
					else
						xmlNodeSetAttribute( xml, "ip", localIP )
					end
					xmlSaveFile( xml )
					xmlUnloadFile( xml )
					xml = nil
				end
			end
		end
)

addEventHandler("onClientResourceStart",getResourceRootElement(getThisResource()),showLoginGUI)

