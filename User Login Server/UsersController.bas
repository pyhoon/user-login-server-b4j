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

' Snippet: Code_WebApiUtils_03 GET Route
Private Sub RouteGet
	Select Version
		Case "v1"
			Select ElementLastIndex
				Case FirstIndex
					Select FirstElement
						Case "list"
							GetUserShowList
							Return
					End Select
				Case SecondIndex
					Select FirstElement
						Case "activate"
							GetUserActivate(SecondElement)
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
						Case "connect"
							WebApiUtils.ReturnConnect(Response)
							Return
						Case "register"
							PostUserRegister
							Return
						Case "login"
							PostUserLogin
							Return
						Case "token"
							PostUserToken
							Return
						Case "profile"
							PostUserReadProfile
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

'Private Sub ReturnErrorUnprocessableEntity 'ignore
'	WebApiUtils.ReturnErrorUnprocessableEntity(Response)
'End Sub

Private Sub ReMapKey (map As Map, key1 As String, key2 As String)
	If map.ContainsKey(key1) Then
		map.Put(key2, map.Get(key1))
		map.Remove(key1)
	End If
End Sub

' Workaround for limitation in MiniORM v1.12
Sub CurrentDateTime As String
	Select Main.DBEngine.ToUpperCase
		Case "MYSQL"
			DB.RawSQL = "SELECT now()"
			Return DB.Scalar
		Case "SQLITE"
			DB.RawSQL = "SELECT datetime('now')"
			Return DB.Scalar
		Case Else
			Dim CurrentDateFormat As String = DateTime.DateFormat
			DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
			Dim Now As String = DateTime.Date(DateTime.Now)
			DateTime.DateFormat = CurrentDateFormat
			Return Now
	End Select
End Sub

' Workaround for limitation in MiniORM v1.12
Sub TokenExpiry As String
	Select Main.DBEngine.ToUpperCase
		Case "MYSQL"
			DB.RawSQL = "SELECT DATE_ADD(now(), INTERVAL 10 MINUTE)"
			Return DB.Scalar
		Case "SQLITE"		
			DB.RawSQL = "SELECT datetime('now', '+10 minute')"
			Return DB.Scalar
		Case Else
			Dim CurrentDateFormat As String = DateTime.DateFormat
			DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
			Dim Per As Period
			Per.Initialize
			Per.Minutes = 10
			Dim Exp As Long = DateUtils.AddPeriod(DateTime.Now, Per)
			Dim Expiry As String = DateTime.Date(Exp)
			DateTime.DateFormat = CurrentDateFormat
			Return Expiry
	End Select
End Sub

Sub SendEmail (NewEmail As EmailData) 'ignore
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
			Case "register"
				EmailSubject = APP_TRADEMARK
				EmailBody = $"Hi ${NewEmail.RecipientName},<br />
				Please click on this link to finish the registration process:<br />
				<a href="${ROOT_URL}/${ROOT_PATH}/users/activate/${NewEmail.ActivateCode}" 
				id="user-activation-link" title="activate" target="_blank">${ROOT_URL}/${ROOT_PATH}/users/activate/${NewEmail.ActivateCode}</a><br />
				<br />
				If the link is not working, please copy the url to your browser.<br />
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$					
			Case "change"
				EmailSubject = "Your password has been changed"
				EmailBody = $"Hi ${NewEmail.RecipientName},<br />
				We have noticed that you have changed your password recently.<br />
				<br />
				If this action is not initiated by you, please contact us immediately.<br />
				Otherwise, please ignore this email.<br />
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$							
			Case "forgot"
				EmailSubject = "Request to reset your password"
				EmailBody = $"Hi ${NewEmail.RecipientName},<br />
				We have received a request from you to reset your password.<br />
				<br />
				If this action is not initiated by you, please contact us immediately.<br />
				Otherwise, click the following link to confirm:<br />
				<br />
				<a href="${Main.Config.Get("ROOT_URL")}${Main.Config.Get("ROOT_PATH")}client/confirm-reset-password/${NewEmail.ResetCode}" id="reset-link" title="reset" target="_blank">${Main.Config.Get("ROOT_URL")}${Main.Config.Get("ROOT_PATH")}client/confirm-reset-password/${NewEmail.ResetCode}</a><br />
				<br />
				If the link is not working, please copy the url to your browser.<br />
				If you have changed your mind, just ignore this email.<br />				
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$
			Case "reset"
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
		
		'Log(EmailBody)
		Dim smtp As SMTP
		smtp.Initialize(SMTP_SERVER, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, "SMTP")
		If SMTP_USESSL.ToUpperCase = "TRUE" Then smtp.UseSSL = True Else smtp.UseSSL = False
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

Public Sub CreateEmailData (RecipientName As String, RecipientEmail As String, Action As String, ActivateCode As String, ResetCode As String, TempPassword As String) As EmailData
	Dim t1 As EmailData
	t1.Initialize
	t1.RecipientName = RecipientName
	t1.RecipientEmail = RecipientEmail
	t1.Action = Action
	t1.ActivateCode = ActivateCode
	t1.ResetCode = ResetCode
	t1.TempPassword = TempPassword
	Return t1
End Sub

Public Sub CreateUserData (UserName As String, UserEmail As String, UserPassword As String, UserFlag As String, UserApiKey As String, UserToken As String, UserTokenExpiry As String, UserActive As Int) As UserData
	Dim t1 As UserData
	t1.Initialize
	t1.UserName = UserName
	t1.UserEmail = UserEmail
	t1.UserPassword = UserPassword
	t1.UserFlag = UserFlag
	t1.UserApiKey = UserApiKey
	t1.UserToken = UserToken
	t1.UserTokenExpiry = UserTokenExpiry
	t1.UserActive = UserActive
	Return t1
End Sub

Private Sub FindUserByAccessToken (Token As String) As UserData
	Dim TokenUser As UserData
	DB.Table = "tbl_users"
	DB.Where = Array("user_token = ?")
	DB.Parameters = Array(Token)
	DB.Query
	
	If DB.Found Then
		Dim user As Map = DB.First
		TokenUser.Initialize
		TokenUser.UserName = user.Get("user_name")
		TokenUser.UserEmail = user.Get("user_email")
		TokenUser.UserActive = user.Get("user_active")
		TokenUser.UserFlag = user.Get("user_activation_flag")
		TokenUser.UserTokenExpiry = user.Get("user_token_expiry")
		
		' Update last login
		UpdateLastLogin(Token)
	End If
	Return TokenUser
End Sub

Private Sub UpdateLastLogin (Token As String)
	' Workaround for limitation in MiniORM v1.12
	Select Main.DBEngine.ToUpperCase
		Case "MYSQL"
			DB.RawSQL = $"UPDATE tbl_users SET
			user_last_login = now(),
			user_login_count = user_login_count + 1
			WHERE user_token = ?"$
		Case "SQLITE"
			DB.RawSQL = $"UPDATE tbl_users SET
			user_last_login = datetime('now'),
			user_login_count = user_login_count + 1
			WHERE user_token = ?"$
	End Select
	DB.Parameters = Array(Token)
	DB.Execute
End Sub

Private Sub GetUserShowList
	' #Version = v1
	' #Desc = Show list of all Users
	' #Elements = ["list"]
	
	Dim access_token As String = WebApiUtils.RequestBearerToken(Request)
	'Log("token:" & access_token)
	Dim user As UserData = FindUserByAccessToken(access_token)
	If Not(user.IsInitialized) Then
		HRM.ResponseCode = 401
		HRM.ResponseError = "Invalid User Token"
		ReturnApiResponse
		Return
	End If

	Select Main.DBEngine.ToUpperCase
		Case "MYSQL"
			Dim online As String = "CASE WHEN (TIME_TO_SEC(TIMEDIFF(now(), user_last_login)) < 600) THEN 'Y' ELSE 'N' END AS online, TIME_TO_SEC(TIMEDIFF(now(), user_last_login)) AS last_online"
		Case "SQLITE"
			Dim online As String = "CASE WHEN (((strftime('%s', 'now') - strftime('%s', user_last_login)) / 60) < 10) THEN 'Y' ELSE 'N' END AS online, (strftime('%s', 'now') - strftime('%s', user_last_login)) AS last_online"
	End Select
	
    DB.Table = "tbl_users"
	DB.Select = Array("user_name", _
	"user_email", _
	"user_last_login", _
	online)
    DB.Query
	
    HRM.ResponseCode = 200
    HRM.ResponseData = DB.Results
	DB.Close
	ReturnApiResponse
End Sub

Private Sub GetUserActivate (ActivationCode As String)
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
		DB.Parameters = Array(api_key, new_code, "A", 1, CurrentDateTime, ActivationCode)
		DB.Save
		
		HRM.ResponseCode = 200
		HRM.ResponseObject = DB.SelectOnly(Array("user_email", "user_activated_date"))
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "User not found"
	End If
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostUserRegister
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

	' If activation required and email configured
	Dim msg_text As String = $"New user registered (${user_email})"$
	Main.WriteUserLog("user/register", "success", msg_text, DB.First.Get("user_id"))
	
	If Main.ACTIVATION_REQUIRED Then
		Dim NewUserEmail As EmailData = CreateEmailData(user_name, user_email, "register", activation_code, "", "")
		SendEmail(NewUserEmail)
	End If
	
	' Return new user
	HRM.ResponseCode = 201
	HRM.ResponseObject = DB.SelectOnly(Array("user_name", "user_email", "user_location", "user_activation_flag", "created_date"))
	HRM.ResponseMessage = "User created successfully"
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostUserLogin
	' #Version = v1
	' #Desc = Retrieve Api Key by Logging in
	' #Body = {<br>&nbsp;"email": "user_email",<br>&nbsp;"password": "user_password"<br>}
	' #Elements = ["login"]
	
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
	DB.Select = Array("user_id AS 'id'", _
	"user_name AS 'name'", _
	"user_email AS 'email'", _
	"ifnull(user_api_key, '') AS 'api_key'", _
	"user_activation_flag AS 'flag'")
	DB.Where = Array("user_email = ?", "user_hash = ?")
	DB.Parameters = Array As String(user_email, user_hash)
	DB.Query
	
	If DB.Found = False Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "User not exist"
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
	
	' Retrieve updated row
	HRM.ResponseCode = 200
	HRM.ResponseObject = DB.SelectOnly(Array("name", "email", "location", "api_key"))
	HRM.ResponseMessage = "User login successfully"
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostUserToken '(apikey As String)
	' #Version = v1
	' #Desc = Get User token by Api Key
	' #Elements = ["token", ":apikey"]

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

	' Update user token
	Dim user_token As String = Main.SHA1(Rnd(100001, 999999))
	Dim token_expiry As String = TokenExpiry
	DB.Table = "tbl_users"
	DB.Columns = Array("user_token", "user_token_expiry")
	DB.Where = Array("user_email = ?", "user_api_key = ?")
	DB.Parameters = Array(user_token, token_expiry, user_email, api_key)
	DB.Save
	
	DB.Table = "tbl_users"
	DB.Select = Array("user_email", "user_token")
	DB.Where = Array("user_email = ?", "user_api_key = ?")
	DB.Parameters = Array(user_email, api_key)
	DB.Query
	
	If DB.Found Then
		HRM.ResponseCode = 200
		HRM.ResponseObject = DB.First
	Else
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid Api Key"
	End If
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostUserReadProfile
	' #Version = v1
	' #Desc = Read a User profile by email
	' #Body = {<br>&nbsp;"email": "user_email"<br>}
	' #Elements = ["profile", ":email"]

	Dim access_token As String = WebApiUtils.RequestBearerToken(Request)
	Dim user As UserData = FindUserByAccessToken(access_token)
	If Not(user.IsInitialized) Then
		HRM.ResponseCode = 401
		HRM.ResponseError = "Invalid User Token"
		ReturnApiResponse
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
			Dim online As String = "CASE WHEN (TIME_TO_SEC(TIMEDIFF(now(), user_last_login)) < 600) THEN 'Y' ELSE 'N' END AS online, now() - user_last_login AS last_online"
		Case "SQLITE"
			Dim online As String = "CASE WHEN (((strftime('%s', 'now') - strftime('%s', user_last_login)) / 60) < 10) THEN 'Y' ELSE 'N' END AS online, (strftime('%s', 'now') - strftime('%s', user_last_login)) AS last_online"
	End Select
	
	DB.Table = "tbl_users"
	DB.Select = Array("user_name", _
	"user_email", _
	"user_last_login", _
	online)
	DB.Where = Array("user_email = ?")
	DB.Parameters = Array(user_email)
	DB.Query
	
	If DB.Found Then
		HRM.ResponseCode = 200
		HRM.ResponseObject = DB.SelectOnly(Array("user_name", "user_email", "user_last_login", "online", "last_online"))
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "User Not Found"
	End If
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PutUpdateUserProfile
	' #Version = v1
	' #Desc = Update User name and location data
	' #Body = {<br>&nbsp;"name": "name",<br>&nbsp;"location": "location"<br>}
	' #Elements = ["update"]

	Dim access_token As String = WebApiUtils.RequestBearerToken(Request)
	Dim user As UserData = FindUserByAccessToken(access_token)
	If Not(user.IsInitialized) Then
		HRM.ResponseCode = 401
		HRM.ResponseError = "Invalid User Token"
		ReturnApiResponse
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

	HRM.ResponseCode = 200
	HRM.ResponseMessage = "User updated successfully"
	HRM.ResponseObject = DB.SelectOnly(Array("user_name", "user_email", "user_location", "modified_date"))
	DB.Close
	ReturnApiResponse
End Sub