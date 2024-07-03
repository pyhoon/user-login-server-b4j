B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
' Database Configuration class
' Version 2.07
Sub Class_Globals
	Private Conn As Conn
End Sub

Public Sub Initialize
	Conn.Initialize
	Conn.DBType = Main.Config.GetDefault("DbType", "")
	Conn.DBName = Main.Config.GetDefault("DbName", "")
	Conn.DBHost = Main.Config.GetDefault("DbHost", "")
	Conn.DBPort = Main.Config.GetDefault("DbPort", "")
	Conn.DBDir = Main.Config.GetDefault("DbDir", "")
	Conn.DriverClass = Main.Config.GetDefault("DriverClass", "")
	Conn.JdbcUrl = Main.Config.GetDefault("JdbcUrl", "")
	Conn.User = Main.Config.GetDefault("User", "")
	Conn.Password = Main.Config.GetDefault("Password", "")
	Conn.MaxPoolSize = Main.Config.GetDefault("MaxPoolSize", 0)
End Sub

' Configure Database (create if not exist)
Public Sub ConfigureDatabase
	Try
		'Log("Checking database...")
		Select Conn.DBType.ToUpperCase
			Case "SQLITE"
				#If SQLite
				Dim DBFound As Boolean
				If File.Exists(Conn.DBDir, Conn.DBName) Then
					DBFound = True
				End If
				Main.DBConnector.Initialize(Conn)
				#Else
				LogColor($"Build configuration does not match ${Conn.DBType} database settings!"$, -65536)
				LogColor($"Application is terminated."$, -65536)
				ExitApplication
				Return
				#End If
			Case "MYSQL"
				#If MYSQL
				Main.DBConnector.Initialize(Conn)
				Wait For (Main.DBConnector.DBExist2) Complete (DBFound As Boolean)
				#Else
				LogColor($"Build configuration does not match ${Conn.DBType}!"$, -65536)
				LogColor($"Application is terminated."$, -65536)
				ExitApplication
				Return
				#End If
			Case Else
				Main.DBConnector.Initialize(Conn)
				Wait For (Main.DBConnector.DBExist) Complete (DBFound As Boolean)
		End Select
		If DBFound Then
			Log($"${Conn.DBType} database found!"$)
		Else
			LogColor($"${Conn.DBType} database not found!"$, -65536)			
			CreateDatabase
		End If
	Catch
		LogError(LastException.Message)
		LogColor("Error checking database!", -65536)
		Log("Application is terminated.")
		ExitApplication
	End Try
End Sub

Private Sub CreateDatabase
	Log("Creating database...")
	Select Conn.DBType.ToUpperCase
		Case "SQLITE"
			Wait For (Main.DBConnector.DBCreate) Complete (Success As Boolean)
		Case "MYSQL"
			Wait For (Main.DBConnector.DBCreateMySQL) Complete (Success As Boolean)
	End Select
	If Not(Success) Then
		Log("Database creation failed!")
		Return
	End If
	
	Log("Creating tables...")
	Dim MDB As MiniORM
	MDB.Initialize(Main.DBOpen, Main.DBEngine)
	MDB.UseTimestamps = True
	
	MDB.Table = "tbl_users"
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_email")))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_hash")))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_salt")))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_name")))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_location")))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_image_file")))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_token", "Size": 40)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_api_key", "Size": 40)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_activation_code", "Size": 40)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_activation_flag", "Size": 1)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_activated_date", "Size": 30)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_token_expiry", "Size": 30)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_last_login", "Size": 30)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_login_count", "Type": MDB.INTEGER, "Default": 0)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "user_active", "Type": MDB.INTEGER, "Default": 0)))
	' Workaround for limitation in MiniORM v1.12 
	MDB.AddAfterCreate = False
	MDB.Create
	MDB.RawSQL = MDB.ToString.Replace("id", "user_id") ' custom primary key
	MDB.AddQuery

	MDB.Table = "tbl_users_log"
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "log_view", "Size": 30)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "log_type", "Size": 30)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "log_text", "Size": 1000)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "log_user", "Type": MDB.INTEGER)))
	MDB.AddAfterCreate = True
	MDB.Create

	MDB.Table = "tbl_error"
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "error_text", "Size": 1000)))
	MDB.Create
	
	Wait For (MDB.ExecuteBatch) Complete (Success As Boolean)
	If Success Then
		Log("Database is created successfully!")
	Else
		Log("Database creation failed!")
	End If
	MDB.Close
End Sub