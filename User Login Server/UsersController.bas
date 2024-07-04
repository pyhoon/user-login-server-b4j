B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
' Api Controller
' Version 1.06
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private DB As MiniORM
	Private Method As String
	Private Version As String
	Private Elements() As String
	Private ApiVersionIndex As Int
	Private ControllerIndex As Int
	Private ElementLastIndex As Int
	Private FirstIndex As Int
	Private FirstElement As String
	Private SecondIndex As Int
	Private SecondElement As String
	Type UserData (UserName As String, UserEmail As String, UserPassword As String, UserFlag As String, UserApiKey As String, UserToken As String, UserTokenExpiry As String, UserActive As Int)
	Type EmailData (RecipientName As String, RecipientEmail As String, Action As String, ActivateCode As String, ResetCode As String, TempPassword As String)
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
	DB.Initialize(Main.DBOpen, Main.DBEngine)
	'DB.ShowExtraLogs = True
End Sub

' Api Router
Public Sub RouteApi
	Method = Request.Method.ToUpperCase
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	ApiVersionIndex = Main.Element.ApiVersionIndex
	ControllerIndex = Main.Element.ApiControllerIndex
	Version = Elements(ApiVersionIndex)
	ElementLastIndex = Elements.Length - 1
	If ElementLastIndex > ControllerIndex Then
		FirstIndex = ControllerIndex + 1
		FirstElement = Elements(FirstIndex)
	End If
	If ElementLastIndex > ControllerIndex + 1 Then
		SecondIndex = ControllerIndex + 2
		SecondElement = Elements(SecondIndex)
	End If
	
	Select Method
		Case "GET"
			RouteGet
		Case "POST"
			RoutePost
		Case "PUT"
			RoutePut
		Case Else
			Log("Unsupported method: " & Method)
			ReturnMethodNotAllow
	End Select
End Sub

Private Sub RouteGet
	Select Version
		Case "v1"
			Select ElementLastIndex
				Case FirstIndex
					Select FirstElement
						Case "list"
							GetShowUserList
							Return
					End Select
				Case SecondIndex
					Select FirstElement
						Case "activate"
							GetActivateUser(SecondElement)
							Return
						Case "confirm-reset"
							GetConfirmResetPassword(SecondElement)
							Return
					End Select
			End Select
	End Select
	ReturnBadRequest
End Sub

Private Sub RoutePost
	Select Version
		Case "v1"
			Select ElementLastIndex
				Case FirstIndex
					Select FirstElement
						Case "register"
							PostRegisterUser
							Return
						Case "login"
							PostUserLogin
							Return
						Case "token"
							PostUserToken
							Return
						Case "profile"
							PostReadUserProfile
							Return
						Case "reset-password"
							PostResetUserPassword
							Return
					End Select
			End Select
	End Select
	ReturnBadRequest
End Sub

Private Sub RoutePut
	Select Version
		Case "v1"
			Select ElementLastIndex
				Case FirstIndex
					Select FirstElement
						Case "update"
							PutUpdateUserProfile
							Return
						Case "change-password"
							PutChangeUserPassword
							Return
					End Select
			End Select
	End Select
	ReturnBadRequest
End Sub

Private Sub ReturnApiResponse
	HRM.SimpleResponse = Main.SimpleResponse
	WebApiUtils.ReturnHttpResponse(HRM, Response)
End Sub

Private Sub ReturnBadRequest
	WebApiUtils.ReturnBadRequest(Response)
End Sub

Private Sub ReturnMethodNotAllow
	WebApiUtils.ReturnMethodNotAllow(Response)
End Sub

Private Sub ReMapKey (map As Map, key1 As String, key2 As String)
	If map.ContainsKey(key1) Then
		map.Put(key2, map.Get(key1))
		map.Remove(key1)
	End If
End Sub

Sub CurrentTimeStamp As String
	Select Main.DBEngine.ToUpperCase
		Case "MYSQL"
			Return "NOW()"
		Case "SQLITE"
			Return "datetime('Now')"
		Case Else
			Return ""
	End Select
End Sub

Sub CurrentTimeStampAddMinute (Value As Int) As String
	Select Main.DBEngine.ToUpperCase
		Case "MYSQL"
			Return $"DATE_ADD(NOW(), INTERVAL ${Value} MINUTE)"$
		Case "SQLITE"
			Return $"datetime('Now', '+${Value} minute')"$
		Case Else
			Return ""
	End Select
End Sub

Sub SendEmail (NewEmail As EmailData)
	Try
		Dim ROOT_URL As String = Main.Config.GetDefault("ROOT_URL", "http://localhost:17178")
		Dim ROOT_PATH As String = Main.Config.GetDefault("ROOT_PATH", "web")
		Dim APP_TRADEMARK As String = Main.Config.Get("APP_TRADEMARK")
		Dim SMTP_USERNAME As String = Main.Config.GetDefault("SMTP_USERNAME", "")
		Dim SMTP_PASSWORD As String = Main.Config.GetDefault("SMTP_PASSWORD", "")
		Dim SMTP_SERVER As String = Main.Config.GetDefault("SMTP_SERVER", "")
		Dim SMTP_USESSL As String = Main.Config.GetDefault("SMTP_USESSL", "True")
		Dim SMTP_PORT As Int = Main.Config.GetDefault("SMTP_PORT", 465)
		Dim EmailSubject As String
		Dim EmailBody As String
		
		Select True
			Case SMTP_USERNAME.EqualsIgnoreCase(""), _
				SMTP_PASSWORD.EqualsIgnoreCase(""), _
				SMTP_SERVER.EqualsIgnoreCase("")
				Log("Invalid SMTP Settings")
				Return
		End Select
		
		Select NewEmail.Action
			Case "send activation code"
				EmailSubject = APP_TRADEMARK
				EmailBody = $"Hi ${NewEmail.RecipientName},<br />
				Please click on this link to finish the registration process:<br />
				<a href="${ROOT_URL}/${ROOT_PATH}/users/activate/${NewEmail.ActivateCode}" id="user-activation-link" title="activate"
				target="_blank">${ROOT_URL}/${ROOT_PATH}/users/activate/${NewEmail.ActivateCode}</a><br />
				<br />
				If the link is not working, please copy the url to your browser.<br />
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$					
			Case "send change password notification"
				EmailSubject = "Your password has been changed"
				EmailBody = $"Hi ${NewEmail.RecipientName},<br />
				We have noticed that you have changed your password recently.<br />
				<br />
				If this action is not initiated by you, please contact us immediately.<br />
				Otherwise, please ignore this email.<br />
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$							
			Case "send reset code"
				EmailSubject = "Request to reset your password"
				EmailBody = $"Hi ${NewEmail.RecipientName},<br />
				We have received a request from you to reset your password.<br />
				<br />
				If this action is not initiated by you, please contact us immediately.<br />
				Otherwise, click the following link to confirm:<br />
				<br />
				<a href="${ROOT_URL}${ROOT_PATH}client/confirm-reset-password/${NewEmail.ResetCode}" id="reset-link" title="reset"
				target="_blank">${ROOT_URL}${ROOT_PATH}client/confirm-reset-password/${NewEmail.ResetCode}</a><br />
				<br />
				If the link is not working, please copy the url to your browser.<br />
				If you have changed your mind, just ignore this email.<br />				
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$
			Case "send temp password"
				EmailSubject = "Your password has been reset"
				EmailBody = $"Hi ${NewEmail.RecipientName},<br />
				Your password has been reset.<br />
				Please use the following temporary password to log in.<br />
				Password: ${NewEmail.TempPassword}<br />
				<br />
				Once you are able to log in, please change to a new password.<br />
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$
			Case Else
				Log("Wrong parameter")
				Return
		End Select

		Dim smtp As SMTP
		smtp.Initialize(SMTP_SERVER, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, "SMTP")
		smtp.UseSSL = IIf(SMTP_USESSL.EqualsIgnoreCase("True"), True, False)
		smtp.Sender = SMTP_USERNAME
		smtp.To.Add(NewEmail.RecipientEmail)
		smtp.AuthMethod = smtp.AUTH_LOGIN
		smtp.HtmlBody = True
		smtp.Subject = EmailSubject
		smtp.Body = EmailBody
		LogDebug("Sending email...")
		Wait For (smtp.Send) SMTP_MessageSent (Success As Boolean)
		If Success Then
			LogDebug("Message sent successfully")
		Else
			LogDebug("Error sending message")
			LogDebug(LastException)
		End If
	Catch
		LogDebug(LastException)
		WebApiUtils.ReturnError("Error Send Email", 400, Response)
	End Try
End Sub

Private Sub FindUserByAccessToken (Token As String) As UserData
	DB.Table = "tbl_users"
	DB.Where = Array("user_token = ?")
	DB.Parameters = Array(Token)
	DB.Query
	
	If DB.Found Then
		Dim user As Map = DB.First
		Dim TokenUser As UserData
		TokenUser.Initialize
		'TokenUser.UserName = user.Get("user_name")
		TokenUser.UserEmail = user.Get("user_email")
		'TokenUser.UserActive = user.Get("user_active")
		'TokenUser.UserFlag = user.Get("user_activation_flag")
		TokenUser.UserToken = user.Get("user_token")
		TokenUser.UserTokenExpiry = user.Get("user_token_expiry")
	End If
	DB.Close
	Return TokenUser
End Sub

Private Sub ValidateToken (Token As UserData) As Boolean
	Try
		If Token.IsInitialized = False Then
			HRM.ResponseCode = 401
			HRM.ResponseError = "Undefine User Token"
			ReturnApiResponse
			Return False
		End If
		
		If Token.UserToken = "" Then
			HRM.ResponseCode = 401
			HRM.ResponseError = "Invalid User Token"
			ReturnApiResponse
			Return False
		End If
		
		Dim CurrentDateFormat As String = DateTime.DateFormat
		DateTime.DateFormat = "yyyy-MM-dd"
		DateTime.TimeFormat = "HH:mm:ss"
		Dim date1() As String = Regex.Split(" ", Main.DBConnector.GetDateTime)
		Dim date2() As String = Regex.Split(" ", Token.UserTokenExpiry)
		Dim DateNow As String = date1(0)
		Dim TimeNow As String = date1(1)
		Dim DateExp As String = date2(0)
		Dim TimeExp As String = date2(1)
		Dim DateTime1 As Long = DateTime.DateTimeParse(DateNow, TimeNow)
		Dim DateTime2 As Long = DateTime.DateTimeParse(DateExp, TimeExp)
		DateTime.DateFormat = CurrentDateFormat
	Catch
		Log(LastException)
		HRM.ResponseCode = 401
		HRM.ResponseError = "Invalid User Token"
		ReturnApiResponse
		Return False
	End Try

	If DateTime1 > DateTime2 Then
		HRM.ResponseCode = 401
		HRM.ResponseError = "User Token Expired"
		ReturnApiResponse
		Return False
	End If
	Return True
End Sub

Private Sub GetShowUserList
	' #Version = v1
	' #Desc = Show list of all Users
	' #Elements = ["list"]
	
	Log($"${Request.Method}: ${Request.RequestURI}"$)
	Dim access_token As String = WebApiUtils.RequestBearerToken(Request)
	Dim user As UserData = FindUserByAccessToken(access_token)
	If ValidateToken(user) = False Then
		Return
	End If
	
	Select Main.DBEngine.ToUpperCase
		Case "MYSQL"
			Dim online As String = $"CASE WHEN (TIME_TO_SEC(TIMEDIFF(now(), user_last_login)) < 600)
			THEN 'Y' ELSE 'N' END AS online,
			TIME_TO_SEC(TIMEDIFF(now(), user_last_login)) AS last_online"$
		Case "SQLITE"
			Dim online As String = $"CASE WHEN (((strftime('%s', 'now') - strftime('%s', user_last_login)) / 60) < 10)
			THEN 'Y' ELSE 'N' END AS online,
			(strftime('%s', 'now') - strftime('%s', user_last_login)) AS last_online"$
	End Select

	DB.Reset
	DB.Select = Array("user_email AS email", "user_name AS name", online)
    DB.Query
	
    HRM.ResponseCode = 200
    HRM.ResponseData = DB.Results
	DB.Close
	ReturnApiResponse
End Sub

Private Sub GetActivateUser (ActivationCode As String)
	' #Version = v1
	' #Desc = Activate User by Code
	' #Elements = ["activate", ":code"]
	
	DB.Table = "tbl_users"
	DB.Select = Array("user_email", "user_hash", "user_salt", "user_activation_code")
	DB.Where = Array("user_activation_code = ?")
	DB.Parameters = Array(ActivationCode)
	DB.Query
	
	If DB.Found Then
		Dim api_key As String = Main.SHA1(DB.First.Get("user_hash"))
		Dim new_code As String = Main.MD5(Rnd(100001, 999999))
		
		DB.Reset
		DB.Columns = Array("user_api_key", "user_activation_code", "user_activation_flag", "user_active", "user_activated_date")
		DB.Where = Array("user_activation_code = ?")
		DB.Parameters = Array(api_key, new_code, "A", 1, Main.DBConnector.GetDateTime, ActivationCode)
		DB.Save
		
		Dim user1 As Map = DB.First
		Dim user2 As Map = CreateMap("email": user1.Get("user_email"), _
		"activated_date": user1.Get("user_activated_date"))

		HRM.ResponseCode = 200
		HRM.ResponseObject = user2
		HRM.ResponseMessage = "User activated successfully"
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "User not found"
	End If
	DB.Close
	ReturnApiResponse
End Sub

Private Sub GetConfirmResetPassword (ResetCode As String)
	' #Version = v1
	' #Desc = Confirm reset User password by Reset Code
	' #Elements = ["confirm-reset", ":code"]
	
	DB.Table = "tbl_users"
	DB.Select = Array("user_email", "user_hash", "user_salt", "user_activation_code")
	DB.Where = Array("user_activation_code = ?")
	DB.Parameters = Array(ResetCode)
	DB.Query
	
	If DB.Found Then
		Dim salt As String = Main.MD5(Rnd(100001, 999999))
		Dim temp As String = Main.MD5(Rnd(100001, 999999))
		temp = temp.SubString(temp.Length - 8) ' get last 8 letters
		Dim hash As String = Main.MD5(temp & salt)	' random password
		Dim code As String = Main.MD5(Rnd(100001, 999999))
		Dim apikey As String = Main.SHA1(hash)
		Dim token As String = Main.SHA1(Rnd(100001, 999999))

		DB.Reset
		DB.Columns = Array("user_hash", "user_salt", "user_apikey", "user_token", "user_activation_code")
		DB.Where = Array("user_activation_code = ?")
		DB.Parameters = Array(hash, salt, apikey, token, code, ResetCode)
		DB.Save

		Dim user1 As Map = DB.First
		If Main.CONFIRMATION_REQUIRED Then
			Dim ResetPasswordEmail As EmailData
			ResetPasswordEmail.Initialize
			ResetPasswordEmail.RecipientName = user1.Get("user_name")
			ResetPasswordEmail.RecipientEmail = user1.Get("user_email")
			ResetPasswordEmail.Action = "send temp password"
			ResetPasswordEmail.TempPassword = temp
			SendEmail(ResetPasswordEmail)
		End If
		
		Dim user2 As Map = CreateMap("email": user1.Get("user_email"), _
		"api_key": user1.Get("user_api_key"), _
		"token": user1.Get("user_token"), _
		"token_expiry": user1.Get("user_token_expiry"), _
		"modified_date": user1.Get("modified_date"))

		HRM.ResponseCode = 200
		HRM.ResponseObject = user2
		HRM.ResponseMessage = "Password updated successfully"
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "User not found"
	End If
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostRegisterUser
	' #Version = v1
	' #Desc = Register a New User
	' #Body = {<br>&nbsp; "name": "name",<br>&nbsp; "email": "email",<br>&nbsp; "password": "password"<br>}
	' #Elements = ["register"]
	
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If
	
	' Check whether required keys are provided
	Dim RequiredKeys As List = Array As String("name", "email", "password")
	For Each requiredkey As String In RequiredKeys
		If Not(data.ContainsKey(requiredkey)) Then
			HRM.ResponseCode = 400
			HRM.ResponseError = $"'${requiredkey}' key not found"$
			ReturnApiResponse
			Return
		End If
	Next

	' Remap keys to table column names
	ReMapKey(data, "name", "user_name")
	ReMapKey(data, "email", "user_email")
	ReMapKey(data, "password", "user_password")

	' Check conflict user account
	DB.Table = "tbl_users"
	DB.Where = Array("user_email = ?")
	DB.Parameters = Array(data.Get("user_email"))
	DB.Query
	
	If DB.Found Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "User already exist"
		DB.Close
		ReturnApiResponse
		Return
	End If

	Dim Columns As List
	Columns.Initialize
	Dim Values As List
	Values.Initialize
	For Each key As String In data.Keys
		Select key
			Case "user_name"
				Dim user_name As String = data.Get(key)
				Columns.Add(key)
				Values.Add(user_name)
			Case "user_email"
				Dim user_email As String = data.Get(key)
				Columns.Add(key)
				Values.Add(user_email)
			Case "user_password"
				Dim salt As String = Main.MD5(Rnd(100001, 999999))
				Dim hash As String = Main.MD5(data.Get("user_password") & salt)
				Columns.Add("user_salt")
				Values.Add(salt)
				Columns.Add("user_hash")
				Values.Add(hash)
		End Select
	Next
	
	' Additional columns
	If Main.ACTIVATION_REQUIRED Then
		Dim activation_flag As String = "R"
		Columns.Add("user_activation_flag")
		Values.Add(activation_flag)
		Dim activation_code As String = Main.MD5(salt & user_email)
		Columns.Add("user_activation_code")
		Values.Add(activation_code)
	Else
		Dim activation_flag As String = "A"
		Columns.Add("user_activation_flag")
		Values.Add(activation_flag)
		Dim api_key As String = Main.SHA1(hash)
		Columns.Add("user_api_key")
		Values.Add(api_key)
	End If
	
	' Insert new row
	DB.Reset
	DB.Columns = Columns
	DB.Parameters = Values
	DB.Insert
	DB.Execute

	Dim NewID As Int = DB.LastInsertID
	DB.Reset
	DB.Where = Array("user_id = ?")
	DB.Parameters = Array(NewID)
	DB.Query

	Dim user1 As Map = DB.First
	Dim msg_text As String = $"New user registered (${user_email})"$
	Main.WriteUserLog("user/register", "success", msg_text, user1.Get("user_id"))
	
	' If activation required and email configured
	If Main.ACTIVATION_REQUIRED Then
		Dim NewUserEmail As EmailData
		NewUserEmail.Initialize
		NewUserEmail.RecipientName = user_name
		NewUserEmail.RecipientEmail = user_email
		NewUserEmail.Action = "send activation code"
		NewUserEmail.ActivateCode = activation_code
		SendEmail(NewUserEmail)
	End If
	
	' Return new user
	Dim user2 As Map = CreateMap("email": user1.Get("user_email"), _
	"name": user1.Get("user_name"), _
	"location": user1.Get("user_location"), _
	"user_activation_flag": user1.Get("user_activation_flag"), _
	"created_date": user1.Get("created_date"))

	HRM.ResponseCode = 201
	HRM.ResponseObject = user2
	HRM.ResponseMessage = "User created successfully"
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostUserLogin
	' #Version = v1
	' #Desc = Retrieve Api Key by Logging in
	' #Body = {<br>&nbsp;"email": "user_email",<br>&nbsp;"password": "user_password"<br>}
	' #Elements = ["login"]
	
	Log($"${Request.Method}: ${Request.RequestURI}"$)
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Check whether required keys are provided
	Dim RequiredKeys As List = Array As String("email", "password")
	For Each requiredkey As String In RequiredKeys
		If Not(data.ContainsKey(requiredkey)) Then
			HRM.ResponseCode = 400
			HRM.ResponseError = $"'${requiredkey}' key not found"$
			ReturnApiResponse
			Return
		End If
	Next

	' Remap keys to table column names
	ReMapKey(data, "email", "user_email")
	ReMapKey(data, "password", "user_password")
	Dim user_email As String = data.Get("user_email")
	Dim user_password As String = data.Get("user_password")

	DB.Table = "tbl_users"
	DB.Select = Array("user_salt")
	DB.Where = Array("user_email = ?")
	DB.Parameters = Array(user_email)
	Dim user_salt As String = DB.Scalar
	Dim user_hash As String = Main.MD5(user_password & user_salt)

	' Check user exist
	DB.Table = "tbl_users"
	DB.Select = Array("user_email AS 'email'", _
	"user_name AS 'name'", _
	"user_location AS 'location'", _
	"ifnull(user_api_key, '') AS 'api_key'", _
	"user_activation_flag AS 'flag'")
	DB.Where = Array("user_email = ?", "user_hash = ?")
	DB.Parameters = Array As String(user_email, user_hash)
	DB.Query
	
	If DB.Found = False Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Password is incorrect"
		DB.Close
		ReturnApiResponse
		Return
	End If
	
	Dim user1 As Map = DB.First
	If user1.Get("flag") = "R" Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Email Not Activated"
		DB.Close
		ReturnApiResponse
		Return
	End If

	Dim user2 As Map = CreateMap("email": user1.Get("email"), _
	"name": user1.Get("name"), _
	"location": user1.Get("location"), _
	"api_key": user1.Get("api_key"))
	
	' Retrieve updated row
	HRM.ResponseCode = 200
	HRM.ResponseObject = user2
	HRM.ResponseMessage = "Api key retrieved successfully"
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostUserToken
	' #Version = v1
	' #Desc = Get User token
	' #Body = {<br>&nbsp;"email": "user_email",<br>&nbsp;"apikey": "api_key"<br>}
	' #Elements = ["token"]
	
	Log($"${Request.Method}: ${Request.RequestURI}"$)
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Check whether required keys are provided
	Dim RequiredKeys As List = Array As String("email", "apikey")
	For Each requiredkey As String In RequiredKeys
		If Not(data.ContainsKey(requiredkey)) Then
			HRM.ResponseCode = 400
			HRM.ResponseError = $"'${requiredkey}' key not found"$
			ReturnApiResponse
			Return
		End If
	Next

	' Remap keys to table column names
	ReMapKey(data, "email", "user_email")
	ReMapKey(data, "apikey", "user_api_key")
	Dim user_email As String = data.Get("user_email")
	Dim api_key As String = data.Get("user_api_key")

	DB.Table = "tbl_users"
	DB.Where = Array("user_email = ?", "user_api_key = ?")
	DB.Parameters = Array(user_email, api_key)
	DB.Query
	
	If DB.Found Then
		' Update user token
		Dim token As String = Main.SHA1(Rnd(100001, 999999))
		DB.Reset
		DB.Columns = Array("user_token", _
		"user_token_expiry = " & CurrentTimeStampAddMinute(10), _
		"user_last_login = " & CurrentTimeStamp, _
		"user_login_count++")
		DB.Where = Array("user_email = ?", "user_api_key = ?")
		DB.Parameters = Array(token, user_email, api_key)
		DB.Save
		
		Dim user1 As Map = DB.First
		Dim user2 As Map = CreateMap("email": user1.Get("user_email"), _
		"token": user1.Get("user_token"), _
		"token_expiry": user1.Get("user_token_expiry"))

		HRM.ResponseCode = 200
		HRM.ResponseObject = user2
	Else
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid Api Key"
	End If
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostReadUserProfile
	' #Version = v1
	' #Desc = Read a User profile
	' #Body = {<br>&nbsp;"email": "user_email"<br>}
	' #Elements = ["profile"]

	Dim access_token As String = WebApiUtils.RequestBearerToken(Request)
	Dim user As UserData = FindUserByAccessToken(access_token)
	If ValidateToken(user) = False Then
		Return
	End If

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Remap keys to table column names
	ReMapKey(data, "email", "user_email")
	Dim user_email As String = data.Get("user_email")
	
	Select Main.DBEngine.ToUpperCase
		Case "MYSQL"
			Dim online As String = $"CASE WHEN (TIME_TO_SEC(TIMEDIFF(now(), user_last_login)) < 600)
			THEN 'Y' ELSE 'N' END AS online,
			now() - user_last_login AS last_online"$
		Case "SQLITE"
			Dim online As String = $"CASE WHEN (((strftime('%s', 'now') - strftime('%s', user_last_login)) / 60) < 10)
			THEN 'Y' ELSE 'N' END AS online,
			(strftime('%s', 'now') - strftime('%s', user_last_login)) AS last_online"$
	End Select
	
	DB.Table = "tbl_users"
	DB.Select = Array("user_name", _
	"user_email", _
	"user_location", _
	"user_last_login", _
	online)
	DB.Where = Array("user_email = ?")
	DB.Parameters = Array(user_email)
	DB.Query
	
	If DB.Found Then
		Dim user1 As Map = DB.First
		Dim user2 As Map = CreateMap("email": user1.Get("user_email"), _
		"name": user1.Get("user_name"), _
		"location": user1.Get("user_location"), _
		"last_login": user1.Get("user_last_login"), _
		"online": user1.Get("online"), _
		"last_online": user1.Get("last_online"))

		HRM.ResponseCode = 200
		HRM.ResponseObject = user2
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "User Not Found"
	End If
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostResetUserPassword
	' #Version = v1
	' #Desc = Reset User password
	' #Body = {<br>&nbsp;"email": "user_email"<br>}
	' #Elements = ["reset-password"]

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Check whether required keys are provided
	Dim RequiredKeys As List = Array As String("email")
	For Each requiredkey As String In RequiredKeys
		If Not(data.ContainsKey(requiredkey)) Then
			HRM.ResponseCode = 400
			HRM.ResponseError = $"'${requiredkey}' key not found"$
			ReturnApiResponse
			Return
		End If
	Next

	' Remap keys to table column names
	ReMapKey(data, "email", "user_email")
	Dim user_email As String = data.Get("user_email")
	
	DB.Table = "tbl_users"
	DB.Where = Array("user_email = ?")
	DB.Parameters = Array(user_email)
	DB.Query
	If DB.Found Then
		Dim user1 As Map = DB.First
		If Main.CONFIRMATION_REQUIRED Then
			' Update activation code column with reset code
			Dim resetcode As String = Main.MD5(Rnd(100001, 999999))
			DB.Reset
			DB.Columns = Array("user_activation_code")
			DB.Where = Array("user_email = ?")
			DB.Parameters = Array(resetcode, user_email)
			DB.Save
		
			Dim ResetPasswordEmail As EmailData
			ResetPasswordEmail.Initialize
			ResetPasswordEmail.RecipientName = user1.Get("user_name")
			ResetPasswordEmail.RecipientEmail = user1.Get("user_email")
			ResetPasswordEmail.Action = "send reset code"
			ResetPasswordEmail.ResetCode = resetcode
			SendEmail(ResetPasswordEmail)
		Else
			' if email confirmation not required
			' Update user api key and token
			Dim salt As String = Main.MD5(Rnd(100001, 999999))
			Dim hash As String = Main.MD5("password" & salt) ' default password
			Dim apikey As String = Main.SHA1(hash)
			Dim token As String = Main.SHA1(Rnd(100001, 999999))
			
			DB.Reset
			DB.Columns = Array("user_hash", "user_salt", "user_api_key", "user_token", "user_token_expiry = " & CurrentTimeStampAddMinute(10))
			DB.Where = Array("user_email = ?")
			DB.Parameters = Array(hash, salt, apikey, token, user_email)
			DB.Save
		End If
		Dim user2 As Map = CreateMap("email": user1.Get("user_email"), _
		"token": user1.Get("user_token"))

		HRM.ResponseCode = 200
		HRM.ResponseObject = user2
		HRM.ResponseMessage = "Password set to default (password)"
	Else
		HRM.ResponseCode = 400
		HRM.ResponseError = "Email not found"
	End If
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PutUpdateUserProfile
	' #Version = v1
	' #Desc = Update User name and location data
	' #Body = {<br>&nbsp;"name": "name",<br>&nbsp;"location": "location"<br>}
	' #Elements = ["update-profile"]

	Dim access_token As String = WebApiUtils.RequestBearerToken(Request)
	Dim user As UserData = FindUserByAccessToken(access_token)
	If ValidateToken(user) = False Then
		Return
	End If

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Remap keys to table column names
	ReMapKey(data, "name", "user_name")
	ReMapKey(data, "location", "user_location")
	Dim user_name As String = data.Get("user_name")
	Dim user_location As String = data.Get("user_location")
						
	Dim Columns As List
	Columns.Initialize
	Dim Values As List
	Values.Initialize
	Columns.Add("user_name")
	Values.Add(user_name)
	Columns.Add("user_location")
	Values.Add(user_location)
	
	' Condition
	Values.Add(user.UserEmail)
	Values.Add(user.UserToken)
	
	DB.Reset
	DB.UpdateModifiedDate = True
	DB.Columns = Columns
	DB.Parameters = Values
	DB.Where = Array("user_email = ?", "user_token = ?")
	DB.Save
	
	Dim user1 As Map = DB.First
	Dim user2 As Map = CreateMap("email": user1.Get("user_email"), _
	"name": user1.Get("user_name"), _
	"location": user1.Get("user_location"), _
	"modified_date": user1.Get("modified_date"))

	HRM.ResponseCode = 200
	HRM.ResponseMessage = "User updated successfully"
	HRM.ResponseObject = user2
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PutChangeUserPassword
	' #Version = v1
	' #Desc = Update User password
	' #Body = {<br>&nbsp;"old": "current_password",<br>&nbsp;"new": "change_password"<br>}
	' #Elements = ["change-password"]

	Dim access_token As String = WebApiUtils.RequestBearerToken(Request)
	Dim user As UserData = FindUserByAccessToken(access_token)
	If ValidateToken(user) = False Then
		Return
	End If

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Check whether required keys are provided
	Dim RequiredKeys As List = Array As String("old", "new")
	For Each requiredkey As String In RequiredKeys
		If Not(data.ContainsKey(requiredkey)) Then
			HRM.ResponseCode = 400
			HRM.ResponseError = $"'${requiredkey}' key not found"$
			ReturnApiResponse
			Return
		End If
	Next

	Dim user_email As String = user.UserEmail
	Dim current_password As String = data.Get("old")
	Dim change_password As String = data.Get("new")
	
	DB.Table = "tbl_users"
	DB.Select = Array("user_salt")
	DB.Where = Array("user_email = ?")
	DB.Parameters = Array(user_email)
	Dim user_salt As String = DB.Scalar
	Dim user_hash As String = Main.MD5(current_password & user_salt)

	' Check user exist
	DB.Table = "tbl_users"
	DB.Select = Array("user_id AS 'id'", _
	"user_name AS 'name'", _
	"user_email AS 'email'", _
	"user_hash AS 'hash'", _
	"user_activation_flag AS 'flag'")
	DB.Where = Array("user_email = ?", "user_hash = ?")
	DB.Parameters = Array As String(user_email, user_hash)
	DB.Query
	
	If DB.Found = False Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Current password incorrect"
		DB.Close
		ReturnApiResponse
		Return
	End If

	If DB.First.Get("flag") = "R" Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Email Not Activated"
		DB.Close
		ReturnApiResponse
		Return
	End If

	If DB.First.Get("hash") = Main.MD5(change_password & user_salt) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "New password cannot be same"
		DB.Close
		ReturnApiResponse
		Return
	End If

	Dim salt As String = Main.MD5(Rnd(100001, 999999))
	Dim hash As String = Main.MD5(change_password & salt)
	Dim apikey As String = Main.SHA1(hash)
	Dim token As String = Main.SHA1(Rnd(100001, 999999))
	
	DB.Reset
	DB.UpdateModifiedDate = True
	DB.Columns = Array("user_hash", "user_salt", "user_api_key", "user_token", "user_token_expiry = " & CurrentTimeStampAddMinute(10))
	DB.Where = Array("user_email = ?")
	DB.Parameters = Array(hash, salt, apikey, token, user_email)
	DB.Save
	
	Dim user1 As Map = DB.First
	' Notify User of password change (optional)
	If Main.NOTIFICATION_ENABLED Then
		Dim NotifyEmail As EmailData
		NotifyEmail.Initialize
		NotifyEmail.RecipientName = user1.Get("user_name")
		NotifyEmail.RecipientEmail = user1.Get("user_email")
		NotifyEmail.Action = "send change password notification"
		SendEmail(NotifyEmail)
	End If
	
	Dim user2 As Map = CreateMap("email": user1.Get("user_email"), _
	"api_key": user1.Get("user_api_key"), _
	"token": user1.Get("user_token"), _
	"token_expiry": user1.Get("user_token_expiry"), _
	"modified_date": user1.Get("modified_date"))

	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Password updated successfully"
	HRM.ResponseObject = user2
	DB.Close
	ReturnApiResponse
End Sub