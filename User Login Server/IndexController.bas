B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
' Web Controller
' Version 1.06
Sub Class_Globals
	Private Request As ServletRequest 'ignore
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private DB As MiniORM
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
	DB.Initialize(Main.DBOpen, Main.DBEngine)
End Sub

Public Sub ShowIndexPage
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("index.html")
	Dim strHelp As String
	
	If Main.SHOW_API_ICON Then
		strHelp = $"        <li class="nav-item">
          <a class="nav-link mr-3 font-weight-bold text-white" href="${Main.Config.Get("ROOT_URL")}${Main.Config.Get("ROOT_PATH")}help"><i class="fas fa-cog" title="API"></i> API</a>
	</li>"$
	Else
		strHelp = ""
	End If
	
	strMain = WebApiUtils.BuildDocView(strMain, strView)
	strMain = WebApiUtils.BuildTag(strMain, "HELP", strHelp)
	strMain = WebApiUtils.BuildHtml(strMain, Main.Config)
	strMain = WebApiUtils.BuildScript(strMain, "")
	WebApiUtils.ReturnHTML(strMain, Response)
End Sub