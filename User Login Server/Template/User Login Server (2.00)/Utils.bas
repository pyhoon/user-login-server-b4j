B4J=true
Group=Modules
ModulesStructureVersion=1
Type=StaticCode
Version=10
@EndOfDesignText@
' Utils
Sub Process_Globals
	
End Sub

Public Sub MD5 (str As String) As String
	Dim data() As Byte
	Dim MD As MessageDigest
	Dim BC As ByteConverter

	data = BC.StringToBytes(str, "UTF8")
	data = MD.GetMessageDigest(data, "MD5")
	Return BC.HexFromBytes(data).ToLowerCase
End Sub

Public Sub SHA1 (str As String) As String
	Dim data() As Byte
	Dim MD As MessageDigest
	Dim BC As ByteConverter

	data = BC.StringToBytes(str, "UTF8")
	data = MD.GetMessageDigest(data, "SHA-1")
	Return BC.HexFromBytes(data).ToLowerCase
End Sub

Public Sub ReMapKey (map As Map, key1 As String, key2 As String)
	If map.ContainsKey(key1) Then
		map.Put(key2, map.Get(key1))
		map.Remove(key1)
	End If
End Sub

Public Sub CurrentTimeStamp As String
	Select Main.DBEngine.ToUpperCase
		Case "MYSQL"
			Return "NOW()"
		Case "SQLITE"
			Return "datetime('Now')"
		Case Else
			Return ""
	End Select
End Sub

Public Sub CurrentTimeStampAddMinute (Value As Int) As String
	Select Main.DBEngine.ToUpperCase
		Case "MYSQL"
			Return $"DATE_ADD(NOW(), INTERVAL ${Value} MINUTE)"$
		Case "SQLITE"
			Return $"datetime('Now', '+${Value} minute')"$
		Case Else
			Return ""
	End Select
End Sub