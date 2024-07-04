B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Web Handler class
' Version 2.07
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private Elements() As String
End Sub

Public Sub Initialize

End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	ProcessRequest
End Sub

Private Sub ElementLastIndex As Int
	Return Elements.Length - 1
End Sub

Private Sub ReturnHtmlPageNotFound
	WebApiUtils.ReturnHtmlPageNotFound(Response)
End Sub

Private Sub ProcessRequest
	If Main.PRINT_FULL_REQUEST_URL Then
		Log($"${Request.Method}: ${Request.FullRequestURI}"$)
	End If
	
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	
	' Handle /web/
	If ElementLastIndex < Main.Element.WebControllerIndex Then
		Dim IndexPage As IndexController
		IndexPage.Initialize(Request, Response)
		IndexPage.ShowIndexPage
		Return
	End If
	
	Log("Unknown url: " & Request.RequestURI)
	ReturnHtmlPageNotFound
End Sub