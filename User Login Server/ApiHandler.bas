﻿B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Api Handler class
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

Private Sub ReturnBadRequest
	WebApiUtils.ReturnBadRequest(Response)
End Sub

Private Sub ProcessRequest
    #Region Example
	' ============================================================================
	' What is Index and Element? Controller, First, Second and Last?
	' ============================================================================
	' For URL: http://127.0.0.1:8080/web/api/v2/data/:index/:key
	' 					  |      |    |   |	 |   |		|	  |
	'  			 Root URL ┘		 |    |   |	 |   |		|	  |
	'                Server Port ┘    |   |	 |   |		|	  |
	'    					Root Path ┘   |	 |   |		|	  |
	' 							 API Name ┘	 |   |		|	  |
	'                    APIVersionIndex = 3 ┘   |		|	  |
	'						 ControllerIndex = 4 ┘		|	  |
	'									 FirstIndex = 5 ┘	  |
	'							 (last index) SecondIndex = 6 ┘
	'
	' Index is the position of an element inside the URL
	' If Controller is used, at least ControllerIndex has to be used
	' FirstIndex, SecondIndex, etc are optional
	' ElementLastIndex returns the last position of the rightmost element of URL
	' ============================================================================
    #End Region
	If Main.PRINT_FULL_REQUEST_URL Then
		Log($"${Request.Method}: ${Request.FullRequestURI}"$)
	End If
	
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	
	If ElementLastIndex < Main.Element.ApiControllerIndex Then
		ReturnBadRequest
		Return
	End If

	Dim ControllerIndex As Int = Main.Element.ApiControllerIndex
	Dim ControllerElement As String = Elements(ControllerIndex)
	Select ControllerElement
		Case "users"
			Dim Users As UsersController
			Users.Initialize(Request, Response)
			Users.RouteApi
			Return
	End Select
	Log("Unknown controller: " & ControllerElement)
	ReturnBadRequest
End Sub